terraform {
  backend "s3" {
    bucket         = "tf-state-pipeline-bucket"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
