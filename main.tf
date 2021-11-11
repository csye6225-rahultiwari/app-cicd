resource "aws_codedeploy_app" "code_deploy_app" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.code_deploy_role.name
}



resource "aws_iam_role" "code_deploy_role" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codedeploy_deployment_group" "code_deploy_deployment_group" {
  app_name               = aws_codedeploy_app.code_deploy_app.name
  deployment_group_name  = "csye6225-webapp-deployment"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = aws_iam_role.code_deploy_role.arn




  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "webapp_ec2"
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }


  depends_on = [aws_codedeploy_app.code_deploy_app]
}



// resource "aws_iam_user_policy_attachment" "ghactions_ec2_policy_attach" {
//   user       = "ghactions"
//   policy_arn = "${aws_iam_policy.ghactions_user_policy.arn}"
// }

resource "aws_iam_policy" "gh_upload_s3" {
  name   = "gh_upload_s3"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                  "s3:Get*",
                  "s3:List*",
                  "s3:PutObject",
                  "s3:DeleteObject",
                  "s3:DeleteObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::codedeploy.kdab-a5-bucket",
                "arn:aws:s3:::codedeploy.kdab-a5-bucket/*"
              ]
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "ghactions_s3_policy_attach" {
  user       = "ghactions-app"
  policy_arn = aws_iam_policy.gh_upload_s3.arn
}


resource "aws_iam_policy" "gh_Code_Deploy" {
  name   = "gh-Code-Deploy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.vpc_region}:${local.aws_user_account_id}:application:${aws_codedeploy_app.code_deploy_app.name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
         "arn:aws:codedeploy:${var.vpc_region}:${local.aws_user_account_id}:deploymentgroup:${aws_codedeploy_app.code_deploy_app.name}/${aws_codedeploy_deployment_group.code_deploy_deployment_group.deployment_group_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.vpc_region}:${local.aws_user_account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}


data "aws_caller_identity" "current_user" {}

locals {
  aws_user_account_id = data.aws_caller_identity.current_user.account_id
}

resource "aws_iam_user_policy_attachment" "ghactions_codedeploy_policy_attach" {
  user       = "ghactions-app"
  policy_arn = aws_iam_policy.gh_Code_Deploy.arn
}

data "aws_instance" "myinstance" {

  filter {
    name   = "tag:Name"
    values = ["webapp_ec2"]
  }
}


# add/update the DNS record api.dev.yourdomainname.tld. to the public IP address of the EC2 instance 
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "A"
  ttl     = "60"
  records = ["${data.aws_instance.myinstance.public_ip}"]
}