#variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
}
