data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  cidr = "10.0.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.0.0/20","10.0.16.0/20"]
  map_public_ip_on_launch = true
  enable_nat_gateway = false
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}

resource "random_id" "sfx" {
  byte_length = 4
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project}-artifacts-${random_id.sfx.hex}"
  force_destroy = true
}

resource "aws_ecr_repository" "demo" {
  name = "demo-app"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "random_password" "token" {
  length = 24
  special = false
}

resource "aws_secretsmanager_secret" "token" {
  name = "lab-token"
  recovery_window_in_days = 0
  tags = { "jenkins:credentials:type" = "string" }
}

resource "aws_secretsmanager_secret_version" "token" {
  secret_id     = aws_secretsmanager_secret.token.id
  secret_string = random_password.token.result
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnets" {
  value = module.vpc.public_subnets
}
output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
output "ecr_url" {
  value = aws_ecr_repository.demo.repository_url
}
output "token_secret_arn" {
  value = aws_secretsmanager_secret.token.arn
}
