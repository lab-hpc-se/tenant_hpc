terraform {

  backend "s3" {
    bucket = "lab-hpc-se-state"
    key    = "tenant/hpc"
    region = "us-east-1"
  }

  # cloud {
  #   workspaces {
  #     name = "learn-terraform-eks"
  #   }
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.4"
    }
  }

  required_version = "~> 1.9"
}

