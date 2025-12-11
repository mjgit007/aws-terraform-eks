MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==BOUNDARY=="

--==BOUNDARY==
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${cluster_name}
    apiServerEndpoint: ${cluster_endpoint}
    certificateAuthority: ${cluster_ca_data}
    cidr: ${service_ipv4_cidr}
  kubelet:
    config:
      maxPods: ${max_pods}
      clusterDNS:
      - ${cluster_dns_ip}
    flags:
%{ if node_labels != "" ~}
    - "--node-labels=${node_labels}"
%{ endif ~}
%{ if kubelet_extra_args != "" ~}
    - "${kubelet_extra_args}"
%{ endif ~}

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
# Optional: Custom post-bootstrap commands can be added here
# Example: Install additional packages, configure system settings, etc.
# dnf install -y custom-package

--==BOUNDARY==--
