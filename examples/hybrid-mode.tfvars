account_name = "OnlineBoutique"
environment  = "demo"
account_cidr = "10.0.0.0/16"
azs          = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnet_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
private_subnet_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
account = "263383611865"
region  = "eu-west-1"

define_workload = {
  default = {
    automode      = true
    managed_nodes = true
    fargate_nodes = false
  }
}

eks_user_access = {
  cloudops_captain = {
    groups   = []
    policies = ["arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"]
  }
}

managed_nodegroup_use_launch_template = false
