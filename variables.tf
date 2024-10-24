variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use i.e. dev or demo"
}

variable "aws_region" {
  type        = string
  description = "AWS Region closest to us in Boston that we will use for VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC we created"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR Block for the VPC we created"
}

// Public Subnet CIDR Blocks
variable "public_subnet_cidr_1" {
  type        = string
  description = "CIDR block for public subnet 1"
}

variable "public_subnet_cidr_2" {
  type        = string
  description = "CIDR block for public subnet 2"
}

variable "public_subnet_cidr_3" {
  type        = string
  description = "CIDR block for public subnet 3"
}

// Private Subnet CIDR Blocks
variable "private_subnet_cidr_1" {
  type        = string
  description = "CIDR block for private subnet 1"
}

variable "private_subnet_cidr_2" {
  type        = string
  description = "CIDR block for private subnet 2"
}

variable "private_subnet_cidr_3" {
  type        = string
  description = "CIDR block for private subnet 3"
}

variable "subnet_1_zone" {
  type        = string
  description = "Availability zone for public subnet 1 and private subnet 1"
}

variable "subnet_2_zone" {
  type        = string
  description = "Availability zone for public subnet 2 and private subnet 2"
}

variable "subnet_3_zone" {
  type        = string
  description = "Availability zone for public subnet 3 and private subnet 3"
}

variable "Kedar_AMI_ID" {
  type        = string
  description = "AMID ID of the image I create using packer"
}

variable "EC2_Instance_Type" {
  type        = string
  description = "Type of the AWS EC2 instance we are launching"
}

variable "RDS_INSTANCE_KEDAR_PASSWORD" {
  type        = string
  description = "RDS Instance Password"
}

variable "RDS_INSTANCE_USERNAME" {
  type        = string
  description = "RDS Instance USERNAME"
}

variable "RDS_INSTANCE_DB_NAME" {
  type        = string
  description = "RDS Instance DB NAME"
}

variable "RDS_INSTANCE_IDENTIFIER" {
  type        = string
  description = "RDS Instance IDENTIFIER"
}

variable "RDS_INSTANCE_ENGINE" {
  type        = string
  description = "RDS Instance ENGINE"
}

variable "RDS_INSTANCE_ENGINE_VERSION" {
  type        = string
  description = "RDS Instance ENGINE VERSION"
}

variable "RDS_INSTANCE_INSTANCE_CLASS" {
  type        = string
  description = "RDS Instance INSTANCE CLASS"
}