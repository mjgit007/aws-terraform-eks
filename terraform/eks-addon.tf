resource "aws_iam_role" "eks_addon_role" {
  name = "eks-addon-role"
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
  role       = aws_iam_role.eks_addon_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_cwo_policy_attachment" {
  role       = aws_iam_role.eks_addon_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  count         = var.define_workload["default"].managed_nodes ? 1 : 0
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  addon_name    = "vpc-cni"
  addon_version = "v1.20.4-eksbuild.3"
  pod_identity_association {
    service_account = "aws-node"
    role_arn        = aws_iam_role.eks_addon_role.arn
  }
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  count         = var.define_workload["default"].managed_nodes ? 1 : 0
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  addon_name    = "kube-proxy"
  addon_version = "v1.33.3-eksbuild.4"
}

resource "aws_eks_addon" "coredns" {
  count         = var.define_workload["default"].managed_nodes ? 1 : 0
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  addon_name    = "coredns"
  addon_version = "v1.11.4-eksbuild.2"

  # depends_on requires a static list expression
  # Since this resource is only created when managed_nodes = true,
  # the node group will always exist when this resource is created
  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_node_group.managed[0]
  ]
}

resource "aws_eks_addon" "metrics_server" {
  count         = var.define_workload["default"].managed_nodes ? 1 : 0
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  addon_name    = "metrics-server"
  addon_version = "v0.8.0-eksbuild.5"

  depends_on = [aws_eks_addon.coredns]
}

resource "aws_eks_addon" "amazon_cloudwatch_observability" {
  count         = var.define_workload["default"].managed_nodes ? 1 : 0
  cluster_name  = aws_eks_cluster.OnlineBoutique.name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = "v4.7.0-eksbuild.1"

  pod_identity_association {
    service_account = "cloudwatch-agent"
    role_arn        = aws_iam_role.eks_addon_role.arn
  }

  depends_on = [
    aws_eks_addon.metrics_server
  ]
}

# resource "aws_eks_pod_identity_association" "cni_pod_identity_association" {
#   cluster_name    = aws_eks_cluster.OnlineBoutique.name
#   namespace       = "kube-system"
#   service_account = "aws-node"
#   role_arn        = aws_iam_role.eks_addon_role.arn

#   # EKS Pod Identity is built-in for Kubernetes 1.30+, no addon required
# }

# resource "aws_eks_pod_identity_association" "obsr_pod_identity_association" {
#   cluster_name    = aws_eks_cluster.OnlineBoutique.name
#   namespace       = "amazon-cloudwatch"
#   service_account = "cloudwatch-agent"
#   role_arn        = aws_iam_role.eks_addon_role.arn

#   # EKS Pod Identity is built-in for Kubernetes 1.30+, no addon required


# }