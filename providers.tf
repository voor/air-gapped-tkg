/*
 * Provider
 */

 terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 0.13.0"
}
