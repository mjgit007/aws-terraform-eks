# aws-terraform-eks

This repository contains Terraform configuration to provision a comprehensive AWS Elastic Kubernetes Service (EKS) environment. It includes the setup of the EKS cluster, VPC networking, Managed Node Groups, and essential EKS addons. This repository contains basic configuration for eks cluster to work with Auto mode and Managed node groups with and without custom launch template.

## Features

- **EKS Cluster**: Deploys an EKS cluster (default version 1.34) with API authentication mode.
- **VPC Networking**: Sets up a VPC with configurable CIDR, public, and private subnets across multiple Availability Zones.
- **Flexible Workload Modes**:
    - **Managed Nodes**: Provision EKS Managed Node Groups with EC2 instances. Supports On-Demand/Spot, custom Launch Templates, and configurable storage.
    - **EKS Auto Mode**: Serverless-like managed compute where AWS handles node lifecycle.
    - **Hybrid Mode**: Run both Managed Nodes and Auto Mode in the same cluster.
- **EKS Addons** (**Required only for Managed Nodes**): Automatically installs and configures key addons:
    - VPC CNI
    - CoreDNS
    - Kube Proxy
    - Metrics Server
    - EKS Pod Identity Agent
    - Amazon CloudWatch Observability
- **Security & IAM**: Granular IAM roles and policies for the Cluster, Nodes, and specific user access.

## Resource Dependencies (Managed Nodes)

For configurations using Managed Nodes, resources are created in this specific dependency order:

1. **Networking Layer**: VPC, Subnets, Internet Gateway, and **NAT Gateways**.
2. **Security Layer**: Security Groups and IAM Roles/Policies.
3. **Cluster Foundation**: EKS Control Plane.
4. **Initial Add-ons**: `EKS Pod Identity` and `VPC CNI` (Required for nodes to join).
5. **Compute Layer**:
   - **Launch Template**: Defines instance specs.
   - **Managed Node Group**: Provisions the EC2 instances (Depends on VPC CNI).
6. **Post-Compute Add-ons**: `CoreDNS`, `Kube Proxy`, `Metrics Server` (Require active nodes).

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
   - **Managed Node (Custom LT)**: [examples/managed-node-custom-template.tfvars](examples/managed-node-custom-template.tfvars)
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


## Test Cases

1. Managed Node Group with default configuration
2. Managed Node Group with custom launch template
3. Mnaaged Node group and EKS Auto Mode(Hybrid mode with Managed node group first in the order)

