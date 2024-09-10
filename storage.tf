resource "aws_s3_bucket" "lab_hpc_se_state" {
  bucket = "lab-hpc-se-state"
}

resource "aws_s3_bucket" "hpc_1_storage" {
  bucket = "hpc-1-bucket"
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
