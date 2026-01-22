terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "t3_micro" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-t3-micro"
  }
}
