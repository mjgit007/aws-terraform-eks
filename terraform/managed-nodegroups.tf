# Release version data source - only needed when NOT using launch template
data "aws_ssm_parameter" "eks_ami_release_version" {
  count = local.create_managed_nodes && !local.use_launch_template ? 1 : 0
  name  = "/aws/service/eks/optimized-ami/${aws_eks_cluster.OnlineBoutique.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
}

resource "aws_eks_node_group" "managed" {
  count           = local.create_managed_nodes ? 1 : 0
  cluster_name    = aws_eks_cluster.OnlineBoutique.name
  node_group_name = "${local.name}-managed"
  node_role_arn   = aws_iam_role.eks_node_group[0].arn
  subnet_ids      = module.vpc.private_subnets
  # version and release_version can only be set when NOT using launch template
  # When using launch template, AMI (including version) is specified in the launch template
  version         = local.use_launch_template ? null : aws_eks_cluster.OnlineBoutique.version
  release_version = local.use_launch_template ? null : (length(data.aws_ssm_parameter.eks_ami_release_version) > 0 ? nonsensitive(data.aws_ssm_parameter.eks_ami_release_version[0].value) : null)
  instance_types  = local.use_launch_template ? null : [var.managed_nodegroup_instance_type]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable_percentage = 50
  }

  dynamic "launch_template" {
    for_each = local.use_launch_template ? [1] : []
    content {
      id      = aws_launch_template.eks_node_group[0].id
      version = "$Latest"
    }
  }

  capacity_type = var.managed_nodegroup_capacity_type
  labels        = var.managed_nodegroup_labels
  # disk_size is only used when NOT using launch template
  # When using launch template, disk size comes from launch template EBS configuration
  disk_size = local.use_launch_template ? null : var.managed_nodegroup_disk_size

  dynamic "taint" {
    for_each = var.managed_nodegrouptaints == null ? [] : var.managed_nodegrouptaints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }


  tags = {
    Name     = "${local.name}-managed"
    type     = "Managed"
    instance = var.managed_nodegroup_instance_type
  }

  depends_on = [aws_eks_addon.vpc_cni]
  # aws_eks_pod_identity_association.cni_pod_identity_association

}
# EKS Managed Node Group Launch Template and IAM Resources

# Key pair is optional - only create if needed for SSH access
data "aws_secretsmanager_secret_version" "eks_node_public_key" {
  count     = local.use_launch_template && var.managed_nodegroup_use_key_pair ? 1 : 0
  secret_id = "eks-node-public-key"
}

resource "aws_key_pair" "eks_node" {
  count      = local.use_launch_template && var.managed_nodegroup_use_key_pair ? 1 : 0
  key_name   = "${local.name}-eks-node-key"
  public_key = local.use_launch_template && var.managed_nodegroup_use_key_pair ? data.aws_secretsmanager_secret_version.eks_node_public_key[0].secret_string : null
}

resource "aws_iam_role" "eks_node_group" {
  count = local.create_managed_nodes ? 1 : 0
  name  = "${local.name}-eks-node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  count      = local.create_managed_nodes ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cni" {
  count      = local.create_managed_nodes ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  count      = local.create_managed_nodes ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "eks_node_group" {
  count = local.create_managed_nodes ? 1 : 0
  name  = "${local.name}-eks-node-group-profile"
  role  = aws_iam_role.eks_node_group[0].name
}


# Use SSM Parameter to get latest EKS AMI if enabled (only needed when using launch template)
data "aws_ssm_parameter" "ami" {
  count = local.use_launch_template && var.use_latest_ami_release_version ? 1 : 0
  name  = local.ssm_ami_type_to_ssm_param[var.managed_nodegroup_ami_type]
}

resource "aws_launch_template" "eks_node_group" {
  count                  = local.use_launch_template ? 1 : 0
  name_prefix            = "${local.name}-eks-node-group"
  image_id               = local.eks_ami_id
  instance_type          = var.managed_nodegroup_instance_type
  key_name               = local.use_launch_template && var.managed_nodegroup_use_key_pair && length(aws_key_pair.eks_node) > 0 ? aws_key_pair.eks_node[0].key_name : null
  vpc_security_group_ids = [aws_eks_cluster.OnlineBoutique.vpc_config[0].cluster_security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      # When using launch template, use disk_size variable for volume_size
      volume_size           = var.managed_nodegroup_disk_size
      volume_type           = var.managed_nodegroup_ebs_config.volume_type
      delete_on_termination = true
      encrypted             = try(var.managed_nodegroup_ebs_config.encrypted, null)
      iops                  = try(var.managed_nodegroup_ebs_config.iops, null)
      throughput            = try(var.managed_nodegroup_ebs_config.throughput, null)
    }
  }


  # For managed node groups, AWS handles bootstrap automatically
  # Custom user_data is only needed for specific customizations
  # If var.managed_nodegroup_user_data is null, use the generated al2023_user_data template
  # If var.managed_nodegroup_user_data is provided, use that instead
  # Node labels are set via managed_nodegroup_labels variable above
  user_data = var.managed_nodegroup_user_data != null ? base64encode(var.managed_nodegroup_user_data) : base64encode(local.al2023_user_data)
}


