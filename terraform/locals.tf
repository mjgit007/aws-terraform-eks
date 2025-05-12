locals {
  name = "${var.account_name}-${var.environment}"

  tags = {
    Name        = local.name
    Owner       = "Cloudops"
    Environment = "demo"
  }
}