# aws-terraform-eks

This repository contains Terraform configuration to provision a comprehensive AWS Elastic Kubernetes Service (EKS) environment. It includes the setup of the EKS cluster, VPC networking, Managed Node Groups, and essential EKS addons.

## Features

- **EKS Cluster**: Deploys an EKS cluster (default version 1.34) with API authentication mode.
- **VPC Networking**: Sets up a VPC with configurable CIDR, public, and private subnets across multiple Availability Zones.
- **Managed Node Groups**: Supports provisioning of EKS Managed Node Groups with:
    - On-Demand or Spot capacity types.
    - Custom Launch Templates.
    - Configurable disk size, instance types, and AMI types (AL2023).
- **EKS Auto Mode**: specialized configuration for EKS Auto Mode workloads.
- **EKS Addons**: Automatically installs and configures key addons:
    - VPC CNI
    - CoreDNS
    - Kube Proxy
    - Metrics Server
    - EKS Pod Identity Agent
    - Amazon CloudWatch Observability
- **Security & IAM**: granular IAM roles and policies for the Cluster, Nodes, and specific user access.

## Prerequisites

- Terraform >= 1.0
- AWS Credentials configured

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Select a Configuration:**
   We provide three example configurations in the `examples/` directory:
   - **Managed Node Groups**: [examples/managed-node.tfvars](examples/managed-node.tfvars)
   - **EKS Auto Mode**: [examples/auto-mode.tfvars](examples/auto-mode.tfvars)
   - **Hybrid Mode**: [examples/hybrid-mode.tfvars](examples/hybrid-mode.tfvars)

3. **Review Plan:**
   Run the plan command with your chosen variable file:
   ```bash
   terraform plan -var-file="examples/managed-node.tfvars"
   ```

4. **Apply Configuration:**
   Apply the configuration using the same variable file:
   ```bash
   terraform apply -var-file="examples/managed-node.tfvars"
   ```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_version` | EKS cluster version to use. | `string` | `"1.34"` | No |
| `use_latest_ami_release_version` | Whether to use the latest EKS AMI from SSM Parameter Store | `bool` | `true` | No |
| `account_name` | Account name | `string` | `"OnlineBoutique"` | No |
| `account` | AWS Account ID | `string` | `"263383611865"` | No |
| `region` | AWS region ID | `string` | `"eu-west-1"` | No |
| `environment` | Environment name | `string` | `"demo"` | No |
| `account_cidr` | Account CIDR block | `string` | `"10.0.0.0/16"` | No |
| `azs` | Availability Zones | `list(string)` | `["eu-west-1a", "eu-west-1b", "eu-west-1c"]` | No |
| `public_subnet_cidr` | CIDR blocks for public subnets | `list(string)` | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` | No |
| `private_subnet_cidr` | CIDR blocks for private subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | No |
| `define_workload` | Map of workload definitions with automode, managed_nodes, and fargate_nodes booleans | `map(object({...}))` | - | **Yes** |
| `eks_user_access` | Map of EKS users with their groups and policies | `map(object({...}))` | *See variables.tf* | No |
| `managed_nodegroup_capacity_type` | Capacity type for EKS managed node group (ON_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | No |
| `managed_nodegroup_instance_type` | EC2 instance type for EKS managed node group | `string` | `"t3.medium"` | No |
| `managed_nodegroup_disk_size` | Disk size in GB for the managed node group root volume | `number` | `20` | No |
| `managed_nodegroup_ami_type` | AMI type for EKS nodes | `string` | `"AL2023_x86_64_STANDARD"` | No |
| `managed_nodegroup_use_launch_template` | Whether to use a custom launch template | `bool` | `false` | No |
| `managed_nodegroup_use_key_pair` | Whether to use an EC2 key pair for SSH access | `bool` | `false` | No |
| `managed_nodegroup_labels` | Map of labels to apply to the EKS managed node group | `map(string)` | `{"nodetype" = "managed"}` | No |
| `managed_nodegroup_ebs_config` | EBS configuration for node group | `object` | `{volume_size=20, volume_type="gp2", ...}` | No |

*Note: There are additional optional variables for advanced customization (taints, user_data, kubelet args, etc.). Please refer to `terraform/variables.tf` for the full list.*

## Output Variables

This module currently does not defined any output variables.

## Karpenter

The repository contains configuration for **Karpenter** in `terraform/karpenter.tf`, but it is currently commented out and disabled by default.
