module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 21.0"

    name = var.project
    kubernetes_version = "1.35"
    endpoint_public_access = true
    enable_cluster_creator_admin_permissions = true

    vpc_id = local.foundation.vpc_id
    subnet_ids = local.foundation.public_subnets

    addons = {
        coredns = {}
        kube-proxy = {}
        vpc-cni = { before_compute = true }
        eks-pod-identity-agent = { before_compute = true }
    }
    eks_managed_node_groups = {
        arm64 = {
            ami_type = "AL2023_ARM_64_STANDARD"
            instance_type = "t4g.medium"
            capacity_type = "ON_DEMAND"
            min_size = 1
            max_size = 3
            desired_size = 2
            labels = { pool = "arm64" }
        }
        x86 = {
            ami_type = "AL2023_x86_64_STANDARD"
            instance_type = ["t3.medium", "t3a.medium"]
            capacity_type = "SPOT"
            min_size = 1
            max_size = 2
            desired_size = 1
            labels = { pool = "x86" }
        }
    }
}

data "aws_iam_policy_document" "pod_trust" {
    statement {
        actions = ["sts:AssumeRole", "sts:TagSession"]
        principals {
            type        = "Service"
            identifiers = ["pods.eks.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "jenkins" {
    name = "${var.project}-jenkins-pods"
    assume_role_policy = data.aws_iam_policy_document.pod_trust.json
}

resource "aws_iam_role_policy_attachment" "ecr" {
    role       = aws_iam_role.jenkins.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

data "aws_iam_policy_document" "jenkins" {
    statement {
        actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        resources = [local.foundation.token_secret_arn]
    }
    statement {
        actions   = ["secretsmanager:ListSecrets"]
        resources = ["*"]
    }
    statement {
        actions   = ["bedrock:InvokeModel"]   # Converse uses this permission
        resources = ["*"]                     # lab: tighten to the model ARN in production
    }
}

resource "aws_iam_role_policy" "jenkins" {
    role   = aws_iam_role.jenkins.id
    policy = data.aws_iam_policy_document.jenkins.json
}

resource "aws_eks_pod_identity_association" "controller" {
    cluster_name = module.eks.cluster_name
    namespace = "jenkins"
    service_account = "jenkins"
    role_arn = aws_iam_role.jenkins.arn
}

resource "aws_eks_pod_identity_association" "agents" {
    cluster_name = module.eks.cluster_name
    namespace = "jenkins"
    service_account = "jenkins-agent"
    role_arn = aws_iam_role.jenkins.arn
}

