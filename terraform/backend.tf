terraform {
  backend "s3" {
    bucket  = "tfstate-bucket-workload"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}