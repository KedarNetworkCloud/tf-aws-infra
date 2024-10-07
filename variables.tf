variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use i.e. dev or demo"
}

variable "aws_region" {
  type        = string
  description = "AWS Region closest to us in Boston that we will use for VPC"
}