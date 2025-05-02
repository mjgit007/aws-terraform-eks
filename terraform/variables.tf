variable "account_name" {
  default     = "workload"
  description = "account name"
}

variable "environment" {
  default     = "dev"
  description = "env name"
}


variable "account_cidr" {
  default     = "10.0.0.0/16"
  description = "account CIDR"
}

variable "azs" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "public_subnet_cidr" {
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnet_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}