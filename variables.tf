variable "region" {
  description = "AWS region"
  type        = string
}

variable "bucket_name" {
  description = "The S3 bucket for the cluster"
  type        = string
}

variable "lustre_subnets" {
  description = "Subnets for Lustre FSx"
  type        = list(any)
  default     = []
}

variable "filesystem_version" {
  description = "Lustre FSx version"
  type        = string
}

variable "lustre_storage_capacity" {
  description = "Lustre Storage Capacity"
  type        = number
  default     = 1200 #in GB
}

variable "lustre_storage_throughput" {
  description = "Lustre Per Unit Storage Throughput"
  type        = number
  default     = 1000 #[125,250,500,1000]
}

variable "pv_name" {
  description = "Kubernetes Persistent Volume name"
  type        = string
}

variable "pvc_name" {
  description = "Kubernetes Persistent Volume Claim name"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace for application"
  type        = string
}