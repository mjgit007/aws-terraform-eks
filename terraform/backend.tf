terraform {
  backend "s3" {
    bucket  = "tfstate-bucket-workload"
    key     = "infra.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}