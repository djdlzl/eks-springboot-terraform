# Terraform 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
# EKS 클러스터를 위한 네트워크 인프라 구성
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.availability_zones

  public_subnets   = var.public_subnet_cidrs
  private_subnets  = var.private_subnet_cidrs

  public_subnet_names = var.public_subnet_names
  private_subnet_names = var.private_subnet_names

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = var.vpc_name
  })

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
    # AZ별로 노드 그룹 분리 (각 프라이빗 서브넷에 노드)
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

  tags = merge(var.common_tags, {
    Name = var.vpc_name
  })
}

# Application Load Balancer (ALB) 모듈 설정
# 퍼블릭 서브넷에 ALB를 생성하고 관리합니다.
module "alb" {
  source = "./modules/alb"

  alb_name           = var.alb_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
  environment       = var.environment
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Name        = var.alb_name
    ManagedBy   = "terraform"
  }
}