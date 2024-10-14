locals {
  cluster_name            = "hpc-1-cluster"
  lustre_name             = "hpc-lab-lustre-${var.region}"
  sqs_name                = "hpc-lab-sqs-${var.region}"
  kms_hpc_key1_alias_name = "hpc-lab-kms-key1-${var.region}"
}