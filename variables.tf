variable "name" {
  description = "Base name for tagging resources"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "region" {
  description = "AWS region for AZ resolution and endpoints"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs to use (length 2-3)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (must match AZs length)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (must match AZs length)"
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "EKS cluster name for Kubernetes tagging"
  type        = string
}

variable "create_gateway_endpoints" {
  description = "Whether to create S3 and DynamoDB gateway endpoints"
  type        = bool
  default     = false
}

