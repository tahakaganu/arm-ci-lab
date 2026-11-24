terraform {
    required_version = ">= 1.11.0"
    backend "s3" {}
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
        random = {
            source = "hashicorp/random"
            version = "~> 3.6.0"
        }
    }
}
provider "aws" {
    region = var.region
    default_tags {
        tags = {
            Project = var.project
        }
    }
}