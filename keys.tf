# data "aws_caller_identity" "current" {}

# // Extract to data.aws_iam_policy_document
# resource "aws_kms_key" "hpc_1" {
#   description             = "A CMEK Key"
#   enable_key_rotation     = true
#   deletion_window_in_days = 20
#   policy = jsonencode({
#     version = "2012-10-17"
#     Id      = "hpc-1"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn.aws.iam::${data.aws_caller_identity.current.account_id}"
#         },
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow administration of the Key"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn.aws.iam::${data.aws_caller_identity.current.account_id}"
#         },
#         Action = [
#           "kms:ReplicationKey",
#           "kms:Create*",
#           "kms:Describe*",
#           "kms:Enable*",
#           "kms:List*",
#           "kms:Put*",
#           "kms:Update*",
#           "kms:Revoke*",
#           "kms:Disable*",
#           "kms:Get*",
#           "kms:Delete*",
#           "kms:ScheduleKeyDeletion",
#           "kms:CancelKeyDeletion"
#         ],
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow use of Key"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn.aws.iam::${data.aws_caller_identity.current.account_id}"
#         },
#         Action = [
#           "kms:DescribeKey",
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey",
#           "kms:GenerateDataKeyWithoutPlaintext"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
