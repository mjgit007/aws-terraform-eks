terraform {
  backend "s3" {
    bucket  = "tfstate-workload-bucket"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}