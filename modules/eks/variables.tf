variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets (optional)"
  type        = list(string)
  default     = []
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
}

variable "node_desired_size" {
  description = "Desired number of nodes per node group"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of nodes per node group"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes per node group"
  type        = number
}

variable "environment" {
  description = "Environment name"
  type        = string
}