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
      taints = {
        ondemandInstance = {
          key    = "odInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
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
      #
      # mount s3
      curl -fsSL -o mount-s3.rpm https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
      sudo yum install -y ./mount-s3.rpm
      sudo mkdir -p /s3_bucket
      sudo mount-s3 --region us-east-1 lab-hpc-se-hpc-1-s3mount-storage /s3_bucket
      EOT
    }

    two = {
      name = "hpc-1-group-2"
      labels = {
        role         = "application"
        usage        = "workloads"
        capacityType = "ON_DEMAND"
        nodegroup    = "hpc-1-group-2"
      }

      instance_types = ["t3.small"]

      min_size     = 0
      max_size     = 3
      desired_size = 0

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      # mount Lustre
      sudo amazon-linux-extras install -y lustre
      sudo mkdir -p /lustre_fsx
      echo "fs-07f18b5579b332a37.fsx.us-east-1.amazonaws.com@tcp:/ptq27b4v /lustre_fsx lustre defaults,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=network.service 0 0" >> /etc/fstab
      sudo mount -t lustre -o relatime,flock fs-07f18b5579b332a37.fsx.us-east-1.amazonaws.com@tcp:/ptq27b4v /lustre_fsx
      sudo chmod 2770 /lustre_fsx
      #
      # mount s3
      curl -fsSL -o mount-s3.rpm https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
      sudo yum install -y ./mount-s3.rpm
      sudo mkdir -p /s3_bucket
      sudo mount-s3 --region us-east-1 lab-hpc-se-hpc-1-s3mount-storage /s3_bucket
      EOT
    }

    spot_2vcpu_2mem = {
      node_group_name = "hpc-1-group-3-spot"
      capacity_type   = "SPOT"
      instance_types  = ["t3.small", "t3a.small"]
      #instance_types = ["r5d.24xlarge", "r6i.24xlarge"]
      min_size     = 0
      max_size     = 3
      desired_size = 0

      taints = {
        spotInstance = {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
      }

      labels = {
        role         = "application-spot"
        usage        = "workloads"
        capacityType = "SPOT"
        nodegroup    = "hpc-1-group-3-spot"
      }

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      # mount Lustre
      sudo amazon-linux-extras install -y lustre
      sudo mkdir -p /lustre_fsx
      echo "fs-07f18b5579b332a37.fsx.us-east-1.amazonaws.com@tcp:/ptq27b4v /lustre_fsx lustre defaults,noatime,flock,_netdev,x-systemd.automount,x-systemd.requires=network.service 0 0" >> /etc/fstab
      sudo mount -t lustre -o relatime,flock fs-07f18b5579b332a37.fsx.us-east-1.amazonaws.com@tcp:/ptq27b4v /lustre_fsx
      sudo chmod 2770 /lustre_fsx
      #
      ## mount s3
      curl -fsSL -o mount-s3.rpm https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
      sudo yum install -y ./mount-s3.rpm
      sudo mkdir -p /s3_bucket
      sudo mount-s3 --region us-east-1 lab-hpc-se-hpc-1-s3mount-storage /s3_bucket
      #
      ## Spot Instance unmount FSx script
      # Create spot-fsx-unmount.sh script
      cat <<- "EOF" > /tmp/spot-fsx-unmount.sh
      #!/bin/bash

      #######################################################################################
      # Script to check if there are connections to Lustre FSx mount
      # by checking if there are any application containers still running in the node.
      # If there are no connections, then unmount FSx.
      # Script version: 1.0
      # Date creation: Oct 16, 2024
      # Feature:
      #   - Only support one Lustre FSx mount.
      # Usage:
      #   ./unmount-lustre-spot-termination.sh -p <fsx_mount_path> -i <container_image_name>
      # Example: ./unmount-lustre-spot-termination.sh -p /lustre_fsx -i my-container-image
      #######################################################################################

      # Timestamp when this script was being executed.
      SCRIPT_TIMESTAMP=$(date +"%s")
      LOG_MSG="[$0]:"

      # Check and validate the script parameter arguments
      while getopts p:i: flag
      do
          case "$${flag}" in
              p) # FSx Mount Path
                fsx_mount_path=$${OPTARG};;
              i) # Container Image Name
                container_image_name=$${OPTARG};;
            \?) # Invalid flag
                logger "$LOG_MSG Error: Invalid argument options."
                logger "$LOG_MSG Valid argument options are '$0 -p <fsx_mount_path> -i <container_image_name>'"
                exit 1;;
          esac
      done

      shift "$(( OPTIND - 1 ))"
      if [[ -z "$fsx_mount_path" ]] || [[ -z "$container_image_name" ]]; then
          logger "$LOG_MSG Error: Invalid argument options. Missing -p or -i arguments."
          logger "$LOG_MSG Valid argument options are '$0 -p <fsx_mount_path> -i <container_image_name>'"
          exit 1
      fi


      # Specify the FSx mount point and container image name from the script parameter arguments
      FSXPATH=$fsx_mount_path
      IMAGENAME=$container_image_name

      # Timestamp when this script was being executed.
      logger "$LOG_MSG This script was executed at $(date -d @$SCRIPT_TIMESTAMP) to check container image '$IMAGENAME' accessing Lustre FSx mount '$FSXPATH'"

      # Verify if the given fsx_mount_path argument is a valid linux mount in /etc/mtab
      if [[ "$(cat /etc/mtab | grep -w $FSXPATH | wc -l)" -eq 0 ]]; then
          logger "$LOG_MSG WARNING: Cannot find the provided fsx_mount_path argument:'$FSXPATH' in /etc/mstab"
      fi


      cd /

      TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
      if [ "$?" -ne 0 ]; then
          logger "$LOG_MSG Error running 'curl' command" >&2
          exit 1
      fi

      # Periodically check for termination every 5 seconds
      while sleep 5
      do

          HTTP_CODE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s -w %%{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action)

          if [[ "$HTTP_CODE" -eq 401 ]] ; then
              # Refreshing Authentication Token
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 30")
              continue
          elif [[ "$HTTP_CODE" -ne 200 ]] ; then
              # If the return code is not 200, the instance is not going to be interrupted
              continue
          fi

          # Write log entry to indicate Spot Instance interruption has started
          if [[ -f "/tmp/spot_interruption_$SCRIPT_TIMESTAMP" ]] ; then
              # Local file containing Spot Interruption timestamp exists. Read timestamp from the file.
              SPOT_INTERRUPTION_TIMESTAMP=$(cat /tmp/spot_interruption_$SCRIPT_TIMESTAMP)
          else
              # Local file containing Spot Interruption timestamp does NOT exist. Create one.
              SPOT_INTERRUPTION_TIMESTAMP=$(date +"%s")
              echo "$SPOT_INTERRUPTION_TIMESTAMP" > /tmp/spot_interruption_$SCRIPT_TIMESTAMP
          fi

          logger "$LOG_MSG Received Spot Instance interruption notice at $(date -d @$SPOT_INTERRUPTION_TIMESTAMP)" # TODO: Change this to the timestamp of the notification signal from curl output
          logger "$LOG_MSG Spot Instance is getting terminated. Unmounting '$FSXPATH' ..."
          curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/spot/instance-action
          echo

          # Check if there are any containers still running accessing Lustre FSx mount
          NUMBER_CONTAINERS_USING_LUSTRE=$(ctr -n k8s.io containers list | grep -i "$${IMAGENAME}" | wc -l)

          if [[ "$NUMBER_CONTAINERS_USING_LUSTRE" -eq 0 ]] ; then
              # No containers are accessing Lustre mount
              logger "$LOG_MSG No containers are accessing Lustre FSx mount at $(date)"
          else
              # Write log entry to indicate which containers are still accessing Lustre mount
              logger "$LOG_MSG There are $NUMBER_CONTAINERS_USING_LUSTRE containers still accessing Lustre FSx mount at $(date)"
              continue
          fi


          # Unmount FSx For Lustre filesystem
          if [[ -f "/tmp/lustre_unmount_$SCRIPT_TIMESTAMP" ]] ; then
              # Local file containing Lustre unmount timestamp exist. Read timestamp from the file.
              LUSTRE_UNMOUNT_TIMESTAMP=$(cat /tmp/lustre_unmount_$SCRIPT_TIMESTAMP)
          else
              # Local file containing Lustre unmount timestamp does NOT exist. Create one.
              LUSTRE_UNMOUNT_TIMESTAMP=$(date +"%s")
              echo "$LUSTRE_UNMOUNT_TIMESTAMP" > /tmp/lustre_unmount_$SCRIPT_TIMESTAMP
          fi

          logger "$LOG_MSG Unmounting Lustre FSx filesystem $FSXPATH STARTED at $(date -d @$LUSTRE_UNMOUNT_TIMESTAMP)"
          if ! umount -c "$${FSXPATH}"; then
              logger "$LOG_MSG Error unmounting '$FSXPATH' at $(date)"

              logger "$LOG_MSG Retrying..."
              continue
          fi

          # Start a graceful shutdown of the host
          logger "$LOG_MSG Unmounting Lustre FSx filesystem $FSXPATH COMPLETED at $(date)"
          logger "$LOG_MSG Shutting down spot instance at $(date)"
          #shutdown now

      done

      EOF

      # Execute the /tmp/spot-fsx-unmount.sh script
      chmod 775 /tmp/spot-fsx-unmount.sh
      /tmp/spot-fsx-unmount.sh -p /lustre_fsx -i "aimvector" &
      disown

      EOT
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
