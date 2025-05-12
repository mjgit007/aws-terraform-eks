resource "aws_eks_cluster" "OnlineBoutique" {
  name = "OnlineBoutique"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.32"

  bootstrap_self_managed_addons = false


  compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["51.241.128.76/32"]
    subnet_ids              = module.vpc.private_subnets
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

resource "aws_iam_role" "node" {
  name = "eks-auto-node-Ot"
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.node.name
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

resource "aws_iam_role" "eks_cni_role" {
  name = "eks-cni-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "pods.eks.amazonaws.com"
        },
        "Action" : [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_cni_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
# resource "aws_eks_addon" "addons" {
#   for_each      = var.eks_addons
#   cluster_name  = aws_eks_cluster.OnlineBoutique.name
#   addon_name    = each.value.addon_name
#   addon_version = each.value.addon_version
#   # pod_identity_association {
#   #   role_arn        = aws_iam_role.eks_cni_role.arn
#   #   service_account = each.value.serviceaccount
#   # }
#   tags = {
#     Name = "${each.value.addon_name}-addon"
#   }
# }

# # resource "aws_eks_pod_identity_association" "pod_identity_association" {
# #   for_each        = { for key, value in var.eks_addons : key => value if try(value.serviceaccount, null) != null }
# #   cluster_name    = aws_eks_cluster.OnlineBoutique.name
# #   namespace       = try(each.value.namespace, "default") # Use "default" if namespace is not provided
# #   service_account = each.value.serviceaccount
# #   role_arn        = aws_iam_role.eks_cni_role.arn
# # }

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


# # data "aws_eks_cluster_auth" "eks" {
# #   name = module.eks_al2.cluster_name
# # }
# # module "eks_al2" {
# #   source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.23.0"

# #   cluster_name    = local.name
# #   cluster_version = "1.28"

# #   # EKS Addons
# #   cluster_addons = {
# #     coredns                = {}
# #     eks-pod-identity-agent = {}
# #     kube-proxy             = {}
# #     vpc-cni                = {}
# #   }

# #   vpc_id     = module.vpc.vpc_id
# #   subnet_ids = module.vpc.private_subnets

# # #   eks_managed_node_groups = {
# # #     worker_node = {
# # #       # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
# # #       ami_type       = "AL2_x86_64"
# # #       instance_types = ["t3a.xlarge"]

# # #       min_size = 1
# # #       max_size = 1
# # #       # This value is ignored after the initial creation
# # #       # https://github.com/bryantbiggs/eks-desired-size-hack
# # #       desired_size = 1
# # #     }
# # #   }
# #   enable_cluster_creator_admin_permissions = true

# #   node_security_group_tags = {
# #     "karpenter.sh/discovery" = local.name
# #   }

# # #   # access_entries = {
# # #   #   # One access entry with a policy associated
# # #   #   tf_user = {
# # #   #     kubernetes_groups = []
# # #   #     principal_arn     = "arn:aws:iam::730335194486:role/workload_admin"

# # #   #     policy_associations = {
# # #   #       tf_user = {
# # #   #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
# # #   #         access_scope = {
# # #   #           namespaces = ["*"]
# # #   #           type       = "namespace"
# # #   #         }
# # #   #       }
# # #   #     }
# # #   #   },
# # #   #   root_user = {
# # #   #     kubernetes_groups = []
# # #   #     principal_arn     = "arn:aws:iam::730335194486:root"

# # #   #     policy_associations = {
# # #   #       tf_user = {
# # #   #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
# # #   #         access_scope = {
# # #   #           namespaces = ["*"]
# # #   #           type       = "namespace"
# # #   #         }
# # #   #       }
# # #   #     }
# # #   #   }
# # #   # }

# #   cluster_endpoint_public_access = true

# #   cluster_endpoint_public_access_cidrs = ["51.241.128.76/32"]

# #   tags = local.tags
# # }