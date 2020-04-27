/*
 * Provider
 */

provider "aws" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.2"
}

terraform {
  required_version = ">= 0.12.0"
}
