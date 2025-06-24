terraform {
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
