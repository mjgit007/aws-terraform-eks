variable "cluster_version" {
  description = "EKS cluster version to use."
  type        = string
  default     = "1.34"
}

variable "use_latest_ami_release_version" {
  description = "Whether to use the latest EKS AMI from SSM Parameter Store"
  type        = bool
  default     = true
}


variable "account_name" {
  default     = "OnlineBoutique"
  description = "account name"
}

variable "define_workload" {
  description = "Map of workload definitions with automode, managed_nodes, and fargate_nodes as booleans"
  type = map(object({
    automode      = bool
    managed_nodes = bool
    fargate_nodes = bool
  }))
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


# Variables for Managed Node Group
variable "managed_nodegroup_capacity_type" {
  description = "Capacity type for EKS managed node group (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "managed_nodegroup_labels" {
  description = "Map of labels to apply to the EKS managed node group."
  type        = map(string)
  default = {
    "nodetype" = "managed"
  }
}
variable "managed_nodegroup_ami_id" {
  description = "AMI ID to use for EKS managed node group. If null and use_latest_ami_release_version is true, will be derived from SSM parameter."
  type        = string
  default     = null
}
variable "managed_nodegrouptaints" {
  description = "List of taints to apply to the node group. Each taint is an object with key, effect, and optional value."
  type = list(object({
    key    = string
    effect = string
    value  = optional(string)
  }))
  default = null
}
variable "managed_nodegroup_ebs_config" {
  description = "EBS configuration for node group launch template. Object with volume_size, volume_type, iops, throughput, and encrypted."
  type = object({
    volume_size = number
    volume_type = string
    iops        = optional(number)
    throughput  = optional(number)
    encrypted   = optional(bool)
  })
  default = {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = false
  }
}
variable "managed_nodegroup_instance_type" {
  description = "EC2 instance type for EKS managed node group."
  type        = string
  default     = "t3.medium"
}

variable "managed_nodegroup_use_launch_template" {
  description = "Whether to use a custom launch template for the managed node group. If false, AWS will use default settings."
  type        = bool
  default     = false
}

variable "managed_nodegroup_disk_size" {
  description = "Disk size in GB for the managed node group root volume."
  type        = number
  default     = 20
}

variable "managed_nodegroup_use_key_pair" {
  description = "Whether to create and use an EC2 key pair for SSH access to managed node group instances. Requires 'eks-node-public-key' secret in AWS Secrets Manager."
  type        = bool
  default     = false
}

variable "managed_nodegroup_ami_type" {
  description = "AMI type for EKS nodes."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}



variable "managed_nodegroup_user_data" {
  description = <<-EOT
    User data script for EKS nodes. 
    
    For AL2023 managed node groups:
    - When null (default), AWS automatically handles bootstrap - RECOMMENDED
    - Node labels should be set via nodegroup_labels variable instead
    - Only provide custom user_data if you need specific customizations
    
    If custom user_data is required for AL2023, use nodeadm YAML format.
    The template will be automatically generated using managed_nodegroup_kubelet_config variables.
    
    Note: For managed node groups, AWS provides cluster metadata automatically,
    so custom user_data is typically not needed.
  EOT
  type        = string
  default     = null
}

variable "managed_nodegroup_kubelet_max_pods" {
  description = "Maximum number of pods that can run on a node. If not set, AWS will use default based on instance type."
  type        = number
  default     = null
}

variable "managed_nodegroup_kubelet_extra_args" {
  description = "Additional kubelet arguments to pass to nodes. Example: '--register-with-taints=key=value:NoSchedule'"
  type        = string
  default     = ""
}


# variable "managed_nodegroup_eks_addons" {
#   description = "Map of EKS add ons with service acccounts"
#   type = map(object({
#     addon_name     = string
#     addon_version  = string
#     serviceaccount = optional(string)
#     namespace      = optional(string)
#   }))
#   default = {
#     metrics_server = {
#       addon_name    = "metrics-server"
#       addon_version = "v0.8.0-eksbuild.5"
#       order         = 6

#     }
#     vpc_cni = {
#       addon_name     = "vpc-cni"
#       addon_version  = "v1.20.4-eksbuild.3"
#       serviceaccount = "aws-node"
#       namespace      = "kube-system"
#       order          = 1
#     }
#     coredns = {
#       addon_name    = "coredns"
#       addon_version = "v1.11.4-eksbuild.2"
#       order         = 4


#     }
#     kube_proxy = {
#       addon_name    = "kube-proxy"
#       addon_version = "v1.33.3-eksbuild.4"
#       order         = 3

#     }
#     eks_pod_identity_agent = {
#       addon_name    = "eks-pod-identity-agent"
#       addon_version = "v1.3.10-eksbuild.1"
#       order         = 2

#     }
#     amazon-cloudwatch-observability = {
#       addon_name     = "amazon-cloudwatch-observability"
#       addon_version  = "v4.7.0-eksbuild.1"
#       serviceaccount = "cloudwatch-agent"
#       order          = 5

#     }
#   }
# }