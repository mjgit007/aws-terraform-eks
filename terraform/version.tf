terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    ###########################################
    ## Helm and Kubectl providers were added ##
    ###########################################
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10"
    }
    ###########################################
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}