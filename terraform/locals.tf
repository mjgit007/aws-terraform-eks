locals {
  name = "${var.account_name}-${var.environment}"

  tags = {
    Name        = local.name
    Owner       = "workload"
    Environment = "dev"
  }
}