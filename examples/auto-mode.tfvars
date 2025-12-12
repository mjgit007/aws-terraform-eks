# Common Variables
cluster_version = "1.34"
account_name    = "OnlineBoutique"
account         = "123456789012" # Dummy Account ID
region          = "eu-west-1"
environment     = "demo"

# Network Configuration
account_cidr        = "10.0.0.0/16"
azs                 = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnet_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
private_subnet_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# Workload Definition (Auto Mode Only)
define_workload = {
  default = {
    automode      = true
    managed_nodes = false
    fargate_nodes = false
  }
}

# User Access
eks_user_access = {
  "cloudops_captain" = {
    groups   = []
    policies = ["arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"]
  }
}
