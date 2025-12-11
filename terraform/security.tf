# # EKS Cluster Security Group (per AWS best practices)
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name}-eks-cluster-sg"
  description = "Security group for EKS control plane and cluster ENIs"
  vpc_id      = module.vpc.vpc_id


  # Allow all traffic within the cluster security group (self-referencing rule)
  ingress {
    description = "Allow all traffic within the cluster security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }


  # Minimum required outbound rules (restricting cluster traffic)
  egress {
    description = "Allow cluster to communicate with nodes on 443 (API)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name                                  = "${local.name}-eks-cluster-sg"
    "kubernetes.io/cluster/${local.name}" = "owned"
    "aws:eks:cluster-name"                = local.name
  })
}
# EKS Managed Node Group Security Group (per AWS best practices)
# resource "aws_security_group" "eks_node_group" {
#   name        = "${local.name}-eks-node-group-sg"
#   description = "Security group for EKS managed node groups"
#   vpc_id      = module.vpc.vpc_id

#   # Allow all traffic within the node group (self-referencing rule)
#   ingress {
#     description = "Allow node to node communication (all ports, all protocols)"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     self        = true
#   }

# Optionally, allow SSH (restrict as needed)
# ingress {
#   description = "Allow SSH access to nodes (optional)"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]
# }

# Allow all outbound traffic (default)
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(local.tags, {
#     Name = "${local.name}-eks-node-group-sg"
#   })
# }
