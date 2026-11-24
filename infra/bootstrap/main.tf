terraform {
    required_version = ">= 1.11.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0.0"
        }
        random = {
            source = "hashicorp/random"
            version = "~> 3.6.0"
        }
    }
}
provider "aws" {
    region = "eu-west-2"
}

resource "random_id" "sfx" { byte_length = 4}

resource "aws_s3_bucket" "state" {
    bucket = "arm-ci-lab-tfstate-${random_id.sfx.hex}"
    force_destroy = true
}
resource "aws_s3_bucket_versioning" "state" {
    bucket = aws_s3_bucket.state.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "state" {
    bucket = aws_s3_bucket.state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

output "state_bucket" {
    value = aws_s3_bucket.state.bucket
}