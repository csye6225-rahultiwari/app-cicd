variable "vpc_region" {
  type        = string
  default = "us-east-1"
  description = "select aws region"
}

variable "aws_profile" {
  type = string
  default = "devadmin"
  description = "aws profile"
}

variable "domain_name" {
  type = string
  default = "dev.rahultiwari.me"
  description = "domain name"
}