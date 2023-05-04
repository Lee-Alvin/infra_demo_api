terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-file-infra-demo-api"
    key            = "infra-demo-api/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_state_lock_infra_demo_api"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
