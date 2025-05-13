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
}

# VPC 모듈 호출
module "vpc" {
  source = "./modules/vpc"

  vpc_name            = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment         = var.environment
}

# EKS 모듈 호출
module "eks" {
  source = "./modules/eks"

  cluster_name        = var.eks_cluster_name
  cluster_version     = var.eks_cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_type  = var.node_instance_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  environment         = var.environment
}

# ALB 모듈 호출
module "alb" {
  source = "./modules/alb"

  alb_name        = var.alb_name
  vpc_id          = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  environment     = var.environment
}