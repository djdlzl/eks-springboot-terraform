# Terraform 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}

# AWS 프로바이더 설정
provider "aws" {
  region = var.region

  # 리소스에 기본적으로 적용할 태그
  default_tags {
    tags = var.common_tags
  }
}

# VPC 모듈 호출
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # VPC 이름 설정
  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.availability_zones
  public_subnets   = var.public_subnet_cidrs
  private_subnets  = var.private_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # 서브넷 이름 설정
  public_subnet_names = var.public_subnet_names
  private_subnet_names = var.private_subnet_names

  # 인터넷 게이트웨이 이름 설정
  igw_tags = {
    Name = "${var.vpc_name}-igw"
  }

  # NAT 게이트웨이 이름 설정
  nat_gateway_tags = {
    Name = "${var.vpc_name}-nat"
  }

  # 리소스 공통 태그
  tags = var.common_tags

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# 현재 AWS 계정 ID 가져오기
data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    spring_node_group = {
      instance_types = [var.node_instance_type]
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      subnet_ids     = module.vpc.private_subnets
    }
  }

  # AWS IAM 인증 설정
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  # 클러스터 생성자에게 관리자 권한 부여
  authentication_mode = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  tags = merge(var.common_tags)

  depends_on = [ module.vpc ]
}

# ALB Ingress Controller를 위한 IAM 정책 및 역할
data "aws_iam_policy_document" "alb_ingress_controller" {
  statement {
    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

# ALB Ingress Controller IAM 정책 설정
resource "aws_iam_policy" "alb_ingress_controller" {
  name        = "ALBIngressControllerIAMPolicy-${module.eks.cluster_name}"
  description = "Policy for ALB Ingress Controller"
  policy      = data.aws_iam_policy_document.alb_ingress_controller.json
}

# ALB Ingress Controller IRSA 역할 설정
# - EKS 클러스터의 OIDC 프로바이더와 연결된 IAM 역할
# - kube-system 네임스페이스의 aws-load-balancer-controller 서비스 어카운트에 연결
module "alb_ingress_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "alb-ingress-controller-${module.eks.cluster_name}"

  attach_load_balancer_controller_policy = true
  tags = var.common_tags

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# Kubernetes provider 설정
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# kubectl provider 설정
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# AWS Auth ConfigMap 업데이트
resource "kubectl_manifest" "aws_auth" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      mapRoles: |
        - rolearn: ${module.eks.eks_managed_node_groups["spring_node_group"].iam_role_arn}
          username: system:node:{{EC2PrivateDNSName}}
          groups:
            - system:bootstrappers
            - system:nodes
  YAML

  depends_on = [module.eks]
}

# Spring Boot 애플리케이션 배포
resource "kubectl_manifest" "spring_app" {
  for_each = fileset("${path.module}/spring", "*.yaml")
  
  yaml_body = file("${path.module}/spring/${each.value}")
  
  force_conflicts = true
  
  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller,
    kubectl_manifest.aws_auth,
  ]
}

# Helm provider 설정
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.region
      ]
    }
  }
}

# ALB Ingress Controller 설치
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.1"
  timeout    = 300

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.alb_ingress_controller_irsa_role.iam_role_arn
  }

  set {
    name = "region"
    value = var.region
  }

  set {
    name = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks,
    kubectl_manifest.aws_auth
  ]
}
