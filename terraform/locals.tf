locals {
  name = "${var.account_name}-${var.environment}"


  tags = {
    Name        = local.name
    Owner       = "Cloudops"
    Environment = "demo"
  }

  service_account = {
    lb_controller = "lb-controller-sa"
  }

  ssm_cluster_version = var.cluster_version != null ? var.cluster_version : ""
  ssm_ami_type        = var.managed_nodegroup_ami_type != null ? var.managed_nodegroup_ami_type : ""

  ssm_ami_type_to_ssm_param = {
    AL2_x86_64                 = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2/recommended"
    AL2_x86_64_GPU             = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2-gpu/recommended"
    AL2_ARM_64                 = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2-arm64/recommended"
    CUSTOM                     = "NONE"
    BOTTLEROCKET_ARM_64        = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}/arm64/latest/image_version"
    BOTTLEROCKET_x86_64        = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}/x86_64/latest/image_version"
    BOTTLEROCKET_ARM_64_FIPS   = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-fips/arm64/latest/image_version"
    BOTTLEROCKET_x86_64_FIPS   = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-fips/x86_64/latest/image_version"
    BOTTLEROCKET_ARM_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-nvidia/arm64/latest/image_version"
    BOTTLEROCKET_x86_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-nvidia/x86_64/latest/image_version"
    WINDOWS_CORE_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-EKS_Optimized-${local.ssm_cluster_version}"
    WINDOWS_FULL_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-${local.ssm_cluster_version}"
    WINDOWS_CORE_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-EKS_Optimized-${local.ssm_cluster_version}"
    WINDOWS_FULL_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Core-EKS_Optimized-${local.ssm_cluster_version}"
    AL2023_x86_64_STANDARD     = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/x86_64/standard/recommended"
    AL2023_ARM_64_STANDARD     = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/arm64/standard/recommended"
    AL2023_x86_64_NEURON       = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/x86_64/neuron/recommended"
    AL2023_x86_64_NVIDIA       = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/x86_64/nvidia/recommended"
  }

  # Only resolve AMI ID if using launch template, otherwise AWS will use default AMI
  eks_ami_id = local.use_launch_template ? (
    var.managed_nodegroup_ami_id != null ? var.managed_nodegroup_ami_id : (
      var.use_latest_ami_release_version && length(data.aws_ssm_parameter.ami) > 0 ? jsondecode(data.aws_ssm_parameter.ami[0].value).image_id : null
    )
  ) : null
  create_managed_nodes = try(var.define_workload["default"].managed_nodes, false)
  use_launch_template  = local.create_managed_nodes && var.managed_nodegroup_use_launch_template


  service_ipv4_cidr = try(
    aws_eks_cluster.OnlineBoutique.kubernetes_network_config[0].service_ipv4_cidr,
    "172.20.0.0/16" # Default EKS service CIDR
  )

  # Calculate cluster DNS IP (service CIDR .10 IP)
  # Example: 172.20.0.0/16 -> 172.20.0.10
  # Using cidrhost to get the 10th IP in the CIDR block
  cluster_dns_ip = cidrhost(local.service_ipv4_cidr, 10)

  # Convert node labels map to kubelet format: key1=value1,key2=value2
  node_labels_string = join(",", [for k, v in var.managed_nodegroup_labels : "${k}=${v}"])

  # Default max pods if not specified (AWS calculates based on instance type, but we can override)
  max_pods = var.managed_nodegroup_kubelet_max_pods != null ? var.managed_nodegroup_kubelet_max_pods : 110

  al2023_user_data = templatefile("${path.module}/templates/al2023-eks-userdata.tpl", {
    cluster_name       = aws_eks_cluster.OnlineBoutique.name
    cluster_endpoint   = aws_eks_cluster.OnlineBoutique.endpoint
    cluster_ca_data    = aws_eks_cluster.OnlineBoutique.certificate_authority[0].data
    service_ipv4_cidr  = local.service_ipv4_cidr
    cluster_dns_ip     = local.cluster_dns_ip
    max_pods           = local.max_pods
    node_labels        = local.node_labels_string
    kubelet_extra_args = var.managed_nodegroup_kubelet_extra_args
    ami_id             = local.eks_ami_id != null ? local.eks_ami_id : ""
    capacity_type      = var.managed_nodegroup_capacity_type
    ng_name            = "${local.name}-managed"
  })


  # sorted_addons = [
  #   for addon in sort([for key, value in var.managed_nodegroup_eks_addons : value], value.order) : addon
  # ]


}