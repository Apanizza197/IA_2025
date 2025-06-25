terraform {
  backend "s3" {
    bucket = "state-bucket-grupo-v"
    key    = "ia/terraform.tfstate"
    region = "us-east-2"
  }
  
  required_providers {
    aws    = {
        source = "hashicorp/aws",
        version = "~> 5.50"
        }
  }
}

provider "aws" {
  region = "us-east-2"
}


resource "aws_s3_bucket" "flavios_bucket" {
  bucket = "flavios-bucket-ia-caj"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}