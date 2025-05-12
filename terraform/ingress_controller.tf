resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.5.0" # Use the latest stable version

  values = [
    <<EOF
clusterName: "${aws_eks_cluster.OnlineBoutique.name}" # Replace with your EKS cluster name
region: "${var.region}"           # Replace with your AWS region
vpcId: "${module.vpc.vpc_id}"            # Replace with your VPC ID
serviceAccount:
  create: false
  name: "${kubernetes_service_account.aws_load_balancer_controller.metadata[0].name}" 
EOF
  ]
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.OnlineBoutique.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.OnlineBoutique.identity.0.oidc.0.issuer
}

# resource "aws_iam_role" "alb_controller_role" {
#   name = "alb-controller-role"

#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "pods.eks.amazonaws.com"
#         },
#         "Action" : [
#           "sts:AssumeRole",
#           "sts:TagSession"
#         ]
#       }
#     ]
#   })
# }

locals {
  OIDC_URL = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}


resource "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "${aws_iam_openid_connect_provider.cluster.arn}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" : {
            "StringEquals" : {
            "${local.OIDC_URL}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller" }
          }
        }

      ]
    }
  )
}

resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policy-files/awscontroller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_lbcontroller_policy_attachment" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
    }
  }
}


# resource "aws_eks_pod_identity_association" "awslb_controller_pia" {
#   cluster_name    = aws_eks_cluster.OnlineBoutique.name
#   namespace       = "kube-system"
#   service_account = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
#   role_arn        = aws_iam_role.alb_controller_role.arn
# }



# resource "aws_iam_openid_connect_provider" "cluster" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = []
#   url             = aws_eks_cluster.OnlineBoutique.identity.0.oidc.0.issuer
# }

# resource "aws_eks_identity_provider_config" "oidc" {
#   cluster_name = aws_eks_cluster.OnlineBoutique.name
#   oidc {
#     identity_provider_config_name = "oidc"
#     issuer_url                    = "https://oidc.eks.eu-west-1.amazonaws.com/id/9430D882EDC7A328D48C3728DC8E0901"
#     client_id                     = "sts.amazonaws.com"
#   }
# }