resource "aws_s3_bucket" "lab_hpc_se_state" {
  bucket = "lab-hpc-se-state"
}

resource "aws_s3_bucket" "hpc_1_storage" {
  bucket = "lab-hpc-se-hpc-1-storage"
}

# resource "aws_fsx_lustre_file_system" "hpc_1_lustre" {
#   import_path      = "s3://${aws_s3_bucket.hpc_1_storage.bucket}"
#   storage_capacity = 1200
#   subnet_ids       = [aws_subnet.hpc_1_lustre_a.id]

#   tags = {
#     "ams:rt:ams-monitoring-policy" = "ams-monitored"
#   }
# }

# # Is this required?
# resource "aws_fsx_file_cache" "lustre" {
#   file_cache_type         = "LUSTRE"
#   file_cache_type_version = "2.12"
#   storage_capacity        = 1200
#   subnet_ids              = [aws_subnet.hpc_1_lustre_a.id]
# }




module "fsx_lustre" {
  source  = "terraform-aws-modules/fsx/aws//modules/lustre"
  version = "1.1.1"

  name                        = local.lustre_name
  deployment_type             = "PERSISTENT_2"
  file_system_type_version    = var.filesystem_version
  kms_key_id                  = module.kms_hpc_key1.key_arn
  per_unit_storage_throughput = var.lustre_storage_throughput #[125,250,500,1000]

  # log_configuration = {
  #   level = "ERROR_ONLY"
  # }

  # root_squash_configuration = {
  #   root_squash = "365534:65534"
  # }

  storage_capacity = var.lustre_storage_capacity
  storage_type     = "SSD"
  subnet_ids       = length(var.lustre_subnets) != 0 ? var.lustre_subnets : [data.aws_subnets.private_subnets.ids[0]]


  # Data Repository Association(s)
  data_repository_associations = {
    example = {
      batch_import_meta_data_on_create = true
      data_repository_path             = "s3://${aws_s3_bucket.hpc_1_storage.id}" #"s3://lab-hpc-se-hpc-1-storage-test"
      delete_data_in_filesystem        = false
      file_system_path                 = "/"
      #imported_file_chunk_size         = 128

      s3 = {
        auto_import_policy = {
          events = ["NEW", "CHANGED", "DELETED"]
        }
      }
    }
  }

  # Security group
  security_group_ingress_rules = {
    in = {
      cidr_ipv4   = data.aws_vpc.selected.cidr_block
      description = "Allow all traffic from the VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "tcp"
    }
  }
  security_group_egress_rules = {
    out = {
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all traffic"
      ip_protocol = "-1"
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}
