terraform {
  required_version = ">= 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
    lambdazip = {
      source  = "winebarrel/lambdazip"
      version = "~> 0.12"
    }
  }
}
