terraform {
  required_version = "~>1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config" # Path to your kubeconfig file
#   }
# }

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# provider "tls" {}


# provider "kubernetes" {
#   host                   = module.eks_al2.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks_al2.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }



# # Add Helm provider
# provider "helm" {
#   kubernetes {
#     host                   = module.eks_al2.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks_al2.cluster_certificate_authority_data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }

# provider "kubectl" {
#   host                   = module.eks_al2.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks_al2.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.eks.token
#   load_config_file       = false
# }

