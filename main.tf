// resource "aws_codedeploy_app" "code_deploy_app" {
//   compute_platform = "Server"
//   name             = "csye6225-webapp"
// }

// resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
//   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
//   role       = aws_iam_role.code_deploy_service_role.name
// }



// resource "aws_iam_role" "code_deploy_service_role" {
//   name = "CodeDeployServiceRole"

//   assume_role_policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Sid": "",
//       "Effect": "Allow",
//       "Principal": {
//         "Service": "codedeploy.amazonaws.com"
//       },
//       "Action": "sts:AssumeRole"
//     }
//   ]
// }
// EOF
// }

// resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
//   app_name               = aws_codedeploy_app.code_deploy_app.name
//   deployment_group_name  = "csye6225-webapp-deployment"
//   deployment_config_name = "CodeDeployDefault.AllAtOnce"
//   service_role_arn       = aws_iam_role.code_deploy_service_role.arn




//   ec2_tag_filter {
//     key   = "Name"
//     type  = "KEY_AND_VALUE"
//     value = "csye6225-ec2-instance"
//   }

//   deployment_style {
//     deployment_option = "WITHOUT_TRAFFIC_CONTROL"
//     deployment_type   = "IN_PLACE"
//   }

//   auto_rollback_configuration {
//     enabled = true
//     events  = ["DEPLOYMENT_FAILURE"]
//   }


//   depends_on = [aws_codedeploy_app.code_deploy_app]
// }


// resource "aws_iam_policy" "GH_Upload_To_S3" {
//   name   = "gh_upload_to_s3"
//   policy = <<EOF
// {
//     "Version": "2012-10-17",
//     "Statement": [
//         {
//             "Effect": "Allow",
//             "Action": [
//                   "s3:Get*",
//                   "s3:List*",
//                   "s3:PutObject",
//                   "s3:DeleteObject",
//                   "s3:DeleteObjectVersion"
//             ],
//             "Resource": [
//                 "arn:aws:s3:::${var.codedeploy_bucket}",
//                 "arn:aws:s3:::${var.codedeploy_bucket}/*"
//               ]
//         }
//     ]
// }
// EOF
// }

// resource "aws_iam_user_policy_attachment" "ghactions_s3_policy_attach" {
//   user       = "ghactions-app"
//   policy_arn = aws_iam_policy.GH_Upload_To_S3.arn
// }


// resource "aws_iam_policy" "GH_Code_Deploy" {
//   name   = "GH-Code-Deploy"
//   policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Effect": "Allow",
//       "Action": [
//         "codedeploy:RegisterApplicationRevision",
//         "codedeploy:GetApplicationRevision"
//       ],
//       "Resource": [
//         "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:application:${aws_codedeploy_app.code_deploy_app.name}"
//       ]
//     },
//     {
//       "Effect": "Allow",
//       "Action": [
//         "codedeploy:CreateDeployment",
//         "codedeploy:GetDeployment"
//       ],
//       "Resource": [
//          "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:deploymentgroup:${aws_codedeploy_app.code_deploy_app.name}/${aws_codedeploy_deployment_group.csye6225-webapp-deployment.deployment_group_name}"
//       ]
//     },
//     {
//       "Effect": "Allow",
//       "Action": [
//         "codedeploy:GetDeploymentConfig"
//       ],
//       "Resource": [
//         "arn:aws:codedeploy:${var.region}:${local.aws_user_account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
//       ]
//     }
//   ]
// }
// EOF
// }


// data "aws_caller_identity" "current_user" {}

// locals {
//   aws_user_account_id = data.aws_caller_identity.current_user.account_id
// }

// resource "aws_iam_user_policy_attachment" "ghactions_codedeploy_policy_attach" {
//   user       = "ghactions-app"
//   policy_arn = aws_iam_policy.GH_Code_Deploy.arn
// }

data "aws_instance" "csye6225-ec2-instance" {
  filter {
    name   = "tag:Name"
    values = ["csye6225-ec2-instance"]
  }
}

data "aws_lb" "application_load_balancer" {}

# add/update the DNS record api.dev.yourdomainname.tld. to the public IP address of the EC2 instance 
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "A"

  
   alias {
    name = data.aws_lb.application_load_balancer.dns_name
    zone_id = data.aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}