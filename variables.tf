variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name used for tagging"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

variable "asg_min" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}