
## Setup terraform to use aws provider and credentials stored locally
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  region  = var.aws_region
  profile = "studocu"

  assume_role {
    role_arn = "arn:aws:iam::007238813143:role/candidate"
  }
}
