MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
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
    - "--node-labels=${node_labels},eks.amazonaws.com/nodegroup-image=${ami_id},eks.amazonaws.com/capacityType=${capacity_type},eks.amazonaws.com/nodegroup=${ng_name},nodetype=managed"
%{ else ~}
    - "--node-labels=eks.amazonaws.com/nodegroup-image=${ami_id},eks.amazonaws.com/capacityType=${capacity_type},eks.amazonaws.com/nodegroup=${ng_name},nodetype=managed"
%{ endif ~}
%{ if kubelet_extra_args != "" ~}
    - "${kubelet_extra_args}"
%{ endif ~}

--//--