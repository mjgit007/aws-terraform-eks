variable "account_name" {
  default     = "OnBoutique"
  description = "account name"
}

variable "environment" {
  default     = "demo"
  description = "env name"
}


variable "account_cidr" {
  default     = "10.0.0.0/16"
  description = "account CIDR"
}

variable "azs" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "public_subnet_cidr" {
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnet_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}


variable "account" {
  description = "AWS Account ID"
  type        = string
  default     = "263383611865"
}


variable "region" {
  description = "AWS region ID"
  type        = string
  default     = "eu-west-1"
}

variable "eks_addons" {
  description = "Map of EKS add ons with service acccounts"
  type = map(object({
    addon_name     = string
    addon_version  = string
    serviceaccount = optional(string)
    namespace      = optional(string)
  }))
  default = {
    metrics_server = {
      addon_name    = "metrics-server"
      addon_version = "v0.7.2-eksbuild.3"

    }
    vpc_cni = {
      addon_name     = "vpc-cni"
      addon_version  = "v1.19.4-eksbuild.1"
      serviceaccount = "aws-node"
      namespace      = "kube-system"
    }
    coredns = {
      addon_name    = "coredns"
      addon_version = "v1.11.4-eksbuild.2"


    }
    kube_proxy = {
      addon_name    = "kube-proxy"
      addon_version = "v1.32.3-eksbuild.7"

    }
    eks_pod_identity_agent = {
      addon_name    = "eks-pod-identity-agent"
      addon_version = "v1.3.4-eksbuild.1"

    }
  }
}


variable "eks_user_access" {
  description = "Map of EKS users with their groups and policies"
  type = map(object({
    groups   = list(string)
    policies = list(string)
  }))
  default = {
    "cloudops_captain" = {
      groups   = []
      policies = ["arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"]
    }
  }
}