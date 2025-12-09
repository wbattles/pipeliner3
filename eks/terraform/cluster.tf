locals {
  eks_subnets = {
    us-east-1 = [aws_subnet.public["us-east-1a"].id, aws_subnet.public["us-east-1b"].id]
  }

  cluster_name = "pipeliner-cluster"

  kube_version = "1.34" 
  create_delay_duration = "30s"
  eks_addons = ["vpc-cni", "kube-proxy", "coredns", "eks-pod-identity-agent"]
}

resource "aws_eks_cluster" "pipeliner_cluster" {
  name = "pipeliner-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = local.kube_version
  
  vpc_config {
    subnet_ids = local.eks_subnets["us-east-1"]
    security_group_ids = []
    endpoint_public_access  = true
    endpoint_private_access = false
  }
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  kubernetes_network_config {
    service_ipv4_cidr = "10.170.0.0/16"
  }
}

resource "aws_eks_node_group" "pipeliner_node_group" {
  cluster_name    = aws_eks_cluster.pipeliner_cluster.name
  node_group_name = "pipeliner-cluster-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = local.eks_subnets["us-east-1"]

  capacity_type = "ON_DEMAND"
  instance_types = ["t2.micro"]
  ami_type      = "BOTTLEROCKET_x86_64"
  version       = local.kube_version
  disk_size     = 30

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }
}

resource "time_sleep" "eks" {
  create_duration = "30s"

  triggers = {
    cluster_name = aws_eks_node_group.pipeliner_node_group.cluster_name
  }

  depends_on = [
    aws_eks_node_group.pipeliner_node_group
  ]
}

resource "aws_eks_addon" "cluster_addons" {
  for_each = toset(local.eks_addons)
  
  cluster_name = time_sleep.eks.triggers["cluster_name"]
  addon_name   = each.value
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

data "aws_eks_addon_version" "cluster_addons" {
  for_each = toset(local.eks_addons)
  
  addon_name         = each.value
  kubernetes_version = local.kube_version
  most_recent        = true
}
