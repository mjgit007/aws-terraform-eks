# module "karpenter" {
#   version = "v19.16.0"
#   source  = "terraform-aws-modules/eks/aws//modules/karpenter"

#   cluster_name = module.eks_al2.cluster_name

#   irsa_oidc_provider_arn          = module.eks_al2.oidc_provider_arn
#   irsa_namespace_service_accounts = ["karpenter:karpenter"]

#   create_iam_role = false
#   iam_role_arn    = module.eks_al2.eks_managed_node_groups["worker_node"].iam_role_arn

#   policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }


# # Provider and data resources will help us to mitigate AWS Public ECR related bug:
# # https://github.com/aws/karpenter/issues/3015
# provider "aws" {
#   region = "us-east-1"
#   alias  = "virginia"
# }

# data "aws_ecrpublic_authorization_token" "token" {
#   provider = aws.virginia
# }

# resource "helm_release" "karpenter" {
#   namespace        = "karpenter"
#   create_namespace = true

#   # We will be using AWS Public ECR to download needed chart as mentioned Above.
#   name                = "karpenter"
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "1.0.0"
#   # upgrade_install     = true

#   # We are setting the cluster name of our already created EKS cluster
#   set {
#     name  = "settings.clusterName"
#     value = module.eks_al2.cluster_name
#   }

#   # Setting EKS Endpoint URL which looks like https://<Gibberish>.yl4.eu-central-1.eks.amazonaws.com
#   set {
#     name  = "settings.clusterEndpoint"
#     value = module.eks_al2.cluster_endpoint
#   }

#   set {
#     name  = "replicas"
#     value = 1
#   }

#   # We will be using IRSA role ARN which we created previously with Karpenter module
#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.karpenter.irsa_arn
#   }

#   # We will be using instance profile name which we created previously with Karpenter module
#   set {
#     name  = "settings.defaultInstanceProfile"
#     value = module.karpenter.instance_profile_name
#   }

#   # We will be using SQS queue name which we created previously with Karpenter module
#   set {
#     name  = "settings.interruptionQueueName"
#     value = module.karpenter.queue_name
#   }

#   depends_on = [
#     module.eks_al2
#   ]
# }

# resource "kubectl_manifest" "karpenter_provisioner" {
#   yaml_body = <<YAML
# apiVersion: karpenter.sh/v1
# kind: NodePool
# metadata:
#   name: default
# spec:
#   template:
#     spec:
#       requirements:
#         - key: kubernetes.io/arch
#           operator: In
#           values: ["amd64"]
#         - key: kubernetes.io/os
#           operator: In
#           values: ["linux"]
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["on-demand"]
#         - key: node.kubernetes.io/instance-type
#           operator: In
#           values: ["t3.medium", "t3.large", "t3a.xlarge"]
#       nodeClassRef:
#         group: karpenter.k8s.aws
#         kind: EC2NodeClass
#         name: default
#       expireAfter: 720h # 30 * 24h = 720h
#     limits:
#         cpu: 1000
#     disruption:
#         consolidationPolicy: WhenEmptyOrUnderutilized
#         consolidateAfter: 1m
# YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# resource "kubectl_manifest" "karpenter_node_template" {
#   yaml_body = <<-YAML
# apiVersion: karpenter.k8s.aws/v1
# kind: EC2NodeClass
# metadata:
#   name: default
# spec:
#   amiFamily: AL2023
#   role: "${module.eks_al2.eks_managed_node_groups["worker_node"].iam_role_name}"
#   subnetSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${module.eks_al2.cluster_name}"
#   securityGroupSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${module.eks_al2.cluster_name}"
#   amiSelectorTerms:
#     - alias: al2023@v20240807

# YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }


# test

# resource "kubernetes_manifest" "karpenter_node_pool" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1beta1"
#     kind       = "NodePool"
#     metadata = {
#       name = "general-purpose"
#       annotations = {
#         "kubernetes.io/description" = "General purpose NodePool for generic workloads"
#       }
#     }
#     spec = {
#       template = {
#         spec = {
#           requirements = [
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values  = ["amd64"]
#             },
#             {
#               key      = "kubernetes.io/os"
#               operator = "In"
#               values  = ["linux"]
#             },
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values  = ["on-demand"]
#             },
#             {
#               key      = "karpenter.k8s.aws/instance-family"
#               operator = "In"
#               values  = ["t3.medium", "t3.large", "t3a.xlarge"]
#             }
#           ]
#           nodeClassRef = {
#             apiVersion = "karpenter.k8s.aws/v1beta1"
#             kind       = "EC2NodeClass"
#             name       = "default"
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_manifest" "karpenter_ec2_node_class" {
#   manifest = {
#     apiVersion = "karpenter.k8s.aws/v1beta1"
#     kind       = "EC2NodeClass"
#     metadata = {
#       name = "default"
#       annotations = {
#         "kubernetes.io/description" = "General purpose EC2NodeClass for running Amazon Linux 2 nodes"
#       }
#     }
#     spec = {
#       amiFamily                   = "AL2" # Amazon Linux 2
#       role                       = "${module.eks_al2.eks_managed_node_groups["worker_node"].iam_role_name}"
#       subnetSelectorTerms = [
#         {
#           tags = {
#             "karpenter.sh/discovery" = "${module.eks_al2.cluster_name}"
#           }
#         }
#       ]
#       securityGroupSelectorTerms = [
#         {
#           tags = {
#             "karpenter.sh/discovery" = "${module.eks_al2.cluster_name}"
#           }
#         }
#       ]
#     }
#   }
# }


# # Creating a provisioner which will create additional nodes for unscheduled pods
# resource "kubernetes_manifest" "karpenter_provisioner" {
#   # Terraform by default doesn't tolerate values changing between configuration and apply results.
#   # Users are required to declare these tolerable exceptions explicitly.
#   # With a kubernetes_manifest resource, you can achieve this by using the computed_fields meta-attribute.
# manifest = yamldecode(<<-EOF
# ---
# apiVersion: karpenter.sh/v1beta1
# kind: NodePool
# metadata:
#   name: general-purpose
#   annotations:
#     kubernetes.io/description: "General purpose NodePool for generic workloads"
# spec:
#   template:
#     spec:
#       requirements:
#         - key: kubernetes.io/arch
#           operator: In
#           values: ["amd64"]
#         - key: kubernetes.io/os
#           operator: In
#           values: ["linux"]
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["on-demand"]
#         - key: "karpenter.k8s.aws/instance-family"
#           operator: In
#           values: ["t3.medium","t3.large","t3a.xlarge"]
#       nodeClassRef:
#         apiVersion: karpenter.k8s.aws/v1beta1
#         kind: EC2NodeClass
#         name: default
# ---
# apiVersion: karpenter.k8s.aws/v1beta1
# kind: EC2NodeClass
# metadata:
#   name: default
#   annotations:
#     kubernetes.io/description: "General purpose EC2NodeClass for running Amazon Linux 2 nodes"
# spec:
#   amiFamily: AL2 # Amazon Linux 2
#   role: "${module.eks_al2.eks_managed_node_groups["worker_node"].iam_role_name}"
#   subnetSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${module.eks_al2.cluster_name}"
#   securityGroupSelectorTerms:
#     - tags:
#         karpenter.sh/discovery: "${module.eks_al2.cluster_name}"
#   EOF
#   )
# computed_fields = ["spec.requirements", "spec.limits"]
# manifest = yamldecode(<<-EOF
#   apiVersion: karpenter.sh/v1alpha5
#   kind: Provisioner
#   metadata:
#     name: default
#   spec:
#     requirements:
#       - key: karpenter.sh/capacity-type
#         operator: In
#         values: ["ondemand"]
#       - key: "karpenter.k8s.aws/instance-family"
#         operator: In
#         values: ["t3.medium","t3.large","t3a.xlarge"]
#     providerRef:
#       name: default
#     ttlSecondsAfterEmpty: 30
# EOF
# )

# depends_on = [
#   helm_release.karpenter, module.eks_al2
# ]
# }

# resource "kubernetes_manifest" "karpenter_node_pool" {
#   # Terraform by default doesn't tolerate values changing between configuration and apply results.
#   # Users are required to declare these tolerable exceptions explicitly.
#   # With a kubernetes_manifest resource, you can achieve this by using the computed_fields meta-attribute.
#   # computed_fields = ["spec.requirements", "spec.limits"]
#   manifest = yamldecode(<<-EOF
#     apiVersion: karpenter.sh/v1
#     kind: NodePool
#     metadata:
#       name: default
#     spec:
#       template:
#         spec:
#           nodeClassRef:
#             group: karpenter.k8s.aws
#             kind: EC2NodeClass
#             name: default
#   EOF
#   )

#   depends_on = [
#     helm_release.karpenter, module.eks_al2
#   ]
# }

# resource "kubernetes_manifest" "karpenter_node_temp" {
#   # Terraform by default doesn't tolerate values changing between configuration and apply results.
#   # Users are required to declare these tolerable exceptions explicitly.
#   # With a kubernetes_manifest resource, you can achieve this by using the computed_fields meta-attribute.
#   # computed_fields = ["spec.requirements", "spec.limits"]
#   manifest = yamldecode(<<-EOF
#     apiVersion: karpenter.k8s.aws/v1beta1
#     kind: EC2NodeClass
#     metadata:
#       name: default
#     spec:
#       amiFamily: AL2
#       role: ${module.eks_al2.eks_managed_node_groups["worker_node"].iam_role_name}
#       subnetSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${module.eks_al2.cluster_name}
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${module.eks_al2.cluster_name}
#   EOF
#   )

#   depends_on = [
#     kubernetes_manifest.karpenter_node_pool, module.eks_al2
#   ]
# }




# stand alone code

# data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(module.eks_al2.cluster_oidc_issuer_url, "https://", "")}:sub" 
#       values   = ["system:serviceaccount:karpenter:karpenter"]
#     }

#     principals {
#       identifiers = [module.eks_al2.oidc_provider_arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "karpenter_controller_role" {
#   name               = "karpenter-controller-role-${var.environment}"
#   assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
# }

# resource "aws_iam_policy" "karpenter_controller_iam_policy" {
#   name   = "KarpenterController-${var.environment}"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "KarpenterCreateEC2",
#       "Effect": "Allow",
#       "Action": [
#           "ssm:GetParameter",
#           "iam:PassRole",
#           "ec2:RunInstances",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeLaunchTemplates",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeInstanceTypeOfferings",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DeleteLaunchTemplate",
#           "ec2:CreateTags",
#           "ec2:CreateLaunchTemplate",
#           "ec2:CreateFleet",
#           "ec2:DescribeSpotPriceHistory"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Sid": "KarpenterConditionalEC2Termination",
#       "Effect": "Allow",
#       "Action": "ec2:TerminateInstances",
#       "Resource": "*",
#       "Condition": {
#           "StringLike": {
#             "ec2:ResourceTag/Name": "*karpenter*"
#           }
#       }
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "karpenter_controller_iam_policy_attach" {
#   role       = aws_iam_role.karpenter_controller_role.name
#   policy_arn = aws_iam_policy.karpenter_controller_iam_policy.arn
# }

# resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
#   name = "Karpenter-Node-InstanceProfile-${var.environment}"
#   role = "workload_worker_role"
# }

# resource "helm_release" "karpenter" {
#   namespace        = "karpenter"
#   create_namespace = true
#   name       = "karpenter"
#   repository = "https://charts.karpenter.sh"
#   chart      = "karpenter"
#   version    = "v0.16.3"


#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.karpenter_controller_role.arn
#   }

#   set {
#     name  = "clusterName"
#     value = module.eks_al2.cluster_name
#   }

#   set {
#     name  = "clusterEndpoint"
#     value = module.eks_al2.cluster_endpoint
#   }

#   set {
#     name  = "aws.defaultInstanceProfile"
#     value = aws_iam_instance_profile.karpenter_node_instance_profile.name
#   }

# }

# resource "kubectl_manifest" "karpenter_node_class" {
#   yaml_body = <<-YAML
#   apiVersion: karpenter.k8s.aws/v1
#   kind: EC2NodeClass
#   metadata:
#     name: default
#   spec:
#     amiFamily: AL2
#     role: ${aws_iam_role.karpenter_controller_role.name}
#     subnetSelectorTerms:
#       - tags:
#           karpenter.sh/discovery: ${module.eks_al2.cluster_name}
#     securityGroupSelectorTerms:
#       - tags:
#           karpenter.sh/discovery: ${module.eks_al2.cluster_name}
#     tags:
#       karpenter.sh/discovery: ${module.eks_al2.cluster_name}
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# resource "kubectl_manifest" "karpenter_node_pool" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1beta1
#     kind: NodePool
#     metadata:
#       name: default
#     spec:
#       template:
#         spec:
#           nodeClassRef:
#             name: default
#           requirements:
#             - key: "karpenter.k8s.aws/instance-category"
#               operator: In
#               values: ["c", "m", "r"]
#             - key: "karpenter.k8s.aws/instance-cpu"
#               operator: In
#               values: ["4", "8"]
#             - key: "karpenter.k8s.aws/instance-family"
#               operator: In
#               values: ["t3"]
#             - key: "topology.kubernetes.io/zone"
#               operator: In
#               values: ["eu-west-1"]
#       limits:
#         cpu: 1000
#       disruption:
#         consolidationPolicy: WhenEmpty
#         consolidateAfter: 30s
#   YAML

#   depends_on = [
#     kubectl_manifest.karpenter_node_class
#   ]
# }
