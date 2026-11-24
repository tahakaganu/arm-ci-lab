data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "random_password" "admin" {
    length  = 20
    special = false
}

resource "aws_secretsmanager_secret" "admin" {
    name = "jenkins-ec2-admin"
    recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin" {
    secret_id     = aws_secretsmanager_secret.admin.id
    secret_string = random_password.admin.result
}

resource "aws_security_group" "jenkins" {
    name        = "jenkins-ec2-sg"
    description = "Allow SSH and HTTP access"
    vpc_id      = local.foundation.vpc_id

    ingress {
        description = "HTTP"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_iam_policy_document" "ec2_trust" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "jenkins" {
    name               = "jenkins-ec2-role"
    assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
    role       = aws_iam_role.jenkins.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "jenkins" {
    statement {
        actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        resources = ["arn:aws:s3:::${local.foundation.artifacts_bucket}", "arn:aws:s3:::${local.foundation.artifacts_bucket}/*"]
    }
    statement {
        actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        resources = [local.foundation.token_secret_arn, aws_secretsmanager_secret.admin.arn]
    }
    statement {
        actions   = ["secretsmanager:ListSecrets"]
        resources = ["*"]
    }
}

resource "aws_iam_role_policy" "jenkins" {
    name   = "jenkins-ec2-policy"
    role   = aws_iam_role.jenkins.id
    policy = data.aws_iam_policy_document.jenkins.json
}

resource "aws_iam_instance_profile" "jenkins" {
    name = "jenkins-ec2"
    role = aws_iam_role.jenkins.name
}

resource "aws_instance" "jenkins" {
    ami           = data.aws_ssm_parameter.al2023_arm64.value
    instance_type = "t4g.medium"
    subnet_id     = local.foundation.public_subnets[0]
    vpc_security_group_ids = [aws_security_group.jenkins.id]
    iam_instance_profile = aws_iam_instance_profile.jenkins.name
    metadata_options {
        http_tokens = "required"
        http_put_response_hop_limit = 2
    }
    root_block_device {
        volume_size = 20
    }
    user_data = templatefile("${path.module}/user_data.sh", {
        repo = var.github_repo
        region = var.region
        admin_secret = aws_secretsmanager_secret.admin.name
    })
    tags = { Name = "jenkins-ec2"}
}

output "jenkins_url" {
    value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "instance_id" {
    value = aws_instance.jenkins.id
}
