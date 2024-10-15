# resource "aws_eks_cluster" "hpc_1" {
#   name     = "hpc-1"
#   role_arn = aws_iam_role.hpc_1_eks_role.arn
#   vpc_config {
#     subnet_ids         = ["10.10.0.0"]
#     security_group_ids = []
#   }
# }

# locals {
#   cluster_name = "hpc-1-cluster"
# }

module "hpc_1_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.hpc_1_vpc.vpc_id
  subnet_ids = module.hpc_1_vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "hpc-1-group-1"
      labels = {
        role         = "application"
        usage        = "workloads"
        capacityType = "ON_DEMAND"
        nodegroup    = "hpc-1-group-1"
      }

      instance_types = ["t3.small"]

      min_size     = 0
      max_size     = 3
      desired_size = 0

      #enable_bootstrap_user_data = true
      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      # mount Lustre
      sudo amazon-linux-extras install -y lustre
      sudo mkdir -p /lustre_fsx
      echo "fs-07f18b5579b332a37.fsx.us-east-1.amazonaws.com@tcp:/ptq27b4v /lustre_fsx lustre defaults,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=network.service 0 0" >> /etc/fstab
      sudo mount -t lustre -o relatime,flock fs-07f18b5579b332a37.fsx.us-east-1.amazonaws.com@tcp:/ptq27b4v /lustre_fsx
      sudo chmod 2770 /lustre_fsx
      EOT
    }

    two = {
      name = "hpc-1-group-2"
      labels = {
        role         = "unused"
        usage        = "workloads"
        capacityType = "ON_DEMAND"
        nodegroup    = "hpc-1-group-2"
      }

      instance_types = ["t3.small"]

      min_size     = 0
      max_size     = 3
      desired_size = 0
    }
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.hpc_1_cluster.cluster_name}"
  provider_url                  = module.hpc_1_cluster.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}
