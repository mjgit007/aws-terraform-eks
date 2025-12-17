# EKS Addon Installation Order:
# Note: EKS Pod Identity is built-in for Kubernetes 1.30+ (no addon required)
# 1. Pod identity associations are created first (no addon dependency needed)
# 2. Addons that use pod identity install after associations are created
# 2. vpc-cni, kube proxy , managed node group and then install other addons

resource "aws_eks_cluster" "OnlineBoutique" {
  name = local.name

  access_config {
    authentication_mode = "API"

  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.34"

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = var.define_workload["default"].automode
    node_pools    = var.define_workload["default"].automode ? ["general-purpose"] : []
    node_role_arn = var.define_workload["default"].automode ? aws_iam_role.node[0].arn : ""
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = var.define_workload["default"].automode
    }
  }

  storage_config {
    block_storage {
      enabled = var.define_workload["default"].automode
    }
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = concat(["51.241.128.76/32", "176.253.170.95/32"], [for ip in module.vpc.nat_public_ips : "${ip}/32"])
    subnet_ids              = module.vpc.private_subnets
    # security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSNetworkingPolicy,
  ]
}

# IAM Role for Auto Mode nodes - only created when automode is enabled
resource "aws_iam_role" "node" {
  count = var.define_workload["default"].automode ? 1 : 0
  name  = "eks-auto-node-Ot"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodeMinimalPolicy" {
  count      = var.define_workload["default"].automode ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  count      = var.define_workload["default"].automode ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-Ot"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSComputePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSNetworkingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_eks_access_entry" "user_access" {
  for_each = var.eks_user_access

  cluster_name      = aws_eks_cluster.OnlineBoutique.name
  principal_arn     = "arn:aws:iam::${var.account}:user/${each.key}"
  kubernetes_groups = each.value.groups
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "eksuser_policy_association" {
  for_each      = var.eks_user_access
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  policy_arn    = each.value.policies[0]
  principal_arn = "arn:aws:iam::${var.account}:user/${each.key}"
  access_scope {
    type = "cluster"
  }
}


# resource "aws_eks_addon" "addons" {
#   for_each = { for idx, addon in local.sorted_addons : idx => addon }

#   cluster_name  = aws_eks_cluster.OnlineBoutique.name
#   addon_name    = each.value.addon_name
#   addon_version = each.value.addon_version

#   tags = {
#     Name = "${each.value.addon_name}-addon"
#   }
# }




