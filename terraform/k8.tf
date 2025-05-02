# data "aws_eks_cluster_auth" "eks" {
#   name = module.eks_al2.cluster_name
# }
# module "eks_al2" {
#   source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.23.0"

#   cluster_name    = local.name
#   cluster_version = "1.28"

#   # EKS Addons
#   cluster_addons = {
#     coredns                = {}
#     eks-pod-identity-agent = {}
#     kube-proxy             = {}
#     vpc-cni                = {}
#   }

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

# #   eks_managed_node_groups = {
# #     worker_node = {
# #       # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
# #       ami_type       = "AL2_x86_64"
# #       instance_types = ["t3a.xlarge"]

# #       min_size = 1
# #       max_size = 1
# #       # This value is ignored after the initial creation
# #       # https://github.com/bryantbiggs/eks-desired-size-hack
# #       desired_size = 1
# #     }
# #   }
#   enable_cluster_creator_admin_permissions = true

#   node_security_group_tags = {
#     "karpenter.sh/discovery" = local.name
#   }

# #   # access_entries = {
# #   #   # One access entry with a policy associated
# #   #   tf_user = {
# #   #     kubernetes_groups = []
# #   #     principal_arn     = "arn:aws:iam::730335194486:role/workload_admin"

# #   #     policy_associations = {
# #   #       tf_user = {
# #   #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
# #   #         access_scope = {
# #   #           namespaces = ["*"]
# #   #           type       = "namespace"
# #   #         }
# #   #       }
# #   #     }
# #   #   },
# #   #   root_user = {
# #   #     kubernetes_groups = []
# #   #     principal_arn     = "arn:aws:iam::730335194486:root"

# #   #     policy_associations = {
# #   #       tf_user = {
# #   #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
# #   #         access_scope = {
# #   #           namespaces = ["*"]
# #   #           type       = "namespace"
# #   #         }
# #   #       }
# #   #     }
# #   #   }
# #   # }

#   cluster_endpoint_public_access = true

#   cluster_endpoint_public_access_cidrs = ["51.241.128.76/32"]

#   tags = local.tags
# }