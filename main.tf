terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "securescale-terraform-state-485141928563"
    key            = "securescale/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "securescale-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}