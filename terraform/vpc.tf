

module "vpc" {
  source          = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.12.0"
  name            = local.name
  cidr            = var.account_cidr
  azs             = var.azs
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  enable_nat_gateway = true
  single_nat_gateway = true
  tags               = local.tags

  public_subnet_tags = {
    "Name"                   = "${local.name}-public-subnet"
    "kubernetes.io/role/elb" = 1

  }

  private_subnet_tags = {
    "Name"                            = "${local.name}-private-subnet"
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  vpc_flow_log_iam_role_name            = "vpc-flowlog-role"
  vpc_flow_log_iam_role_use_name_prefix = false
  enable_flow_log                       = true
  create_flow_log_cloudwatch_log_group  = true
  create_flow_log_cloudwatch_iam_role   = true
  flow_log_max_aggregation_interval     = 60
}