

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.12.0"

  name = local.name

  cidr = var.account_cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  enable_nat_gateway = false
  single_nat_gateway = false

  tags = local.tags

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1

  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }
}