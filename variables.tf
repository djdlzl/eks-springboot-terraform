variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "jw-eks-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.21.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_names" {
  description = "List of names for public subnets"
  type        = list(string)
  default     = ["jw-eks-vpc-public-a", "jw-eks-vpc-public-c"]
}

variable "private_subnet_names" {
  description = "List of names for private subnets"
  type        = list(string)
  default     = ["jw-eks-vpc-private-a", "jw-eks-vpc-private-c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.21.0.0/24", "10.21.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.21.32.0/24", "10.21.33.0/24"]
}


variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "jw-eks-cluster"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of nodes per node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes per node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes per node group"
  type        = number
  default     = 2
}

variable "common_tags" {
  description = "공통으로 적용할 태그"
  type        = map(string)
  default     = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "eks-infra"
  }
}