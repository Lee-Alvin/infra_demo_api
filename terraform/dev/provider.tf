terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-file-cointracker-hello-world"
    key            = "cointracker-hello-world/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_state_lock_cointracker_hello_world"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
