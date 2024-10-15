data "aws_region" "selected" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "selected" {}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = local.cluster_name
}

data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}
