module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = length(var.public_subnet_ids) > 0 ? concat(var.private_subnet_ids, var.public_subnet_ids) : var.private_subnet_ids

  eks_managed_node_groups = {
    # AZ별로 노드 그룹 분리 (각 프라이빗 서브넷에 노드)
    node_group_a = {
      instance_types = [var.node_instance_type]
      desired_size   = var.node_desired_size / 2
      min_size       = var.node_min_size / 2
      max_size       = var.node_max_size / 2
      subnet_ids     = [var.private_subnet_ids[0]] # ap-northeast-2a
    }
    node_group_c = {
      instance_types = [var.node_instance_type]
      desired_size   = var.node_desired_size / 2
      min_size       = var.node_min_size / 2
      max_size       = var.node_max_size / 2
      subnet_ids     = [var.private_subnet_ids[1]] # ap-northeast-2c
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}