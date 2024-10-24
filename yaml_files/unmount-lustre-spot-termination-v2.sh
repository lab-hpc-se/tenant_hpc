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
    case "${flag}" in
        p) # FSx Mount Path
           fsx_mount_path=${OPTARG};;
        i) # Container Image Name
           container_image_name=${OPTARG};;
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

    HTTP_CODE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s -w %{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action)

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
    NUMBER_CONTAINERS_USING_LUSTRE=$(ctr -n k8s.io containers list | grep -i "${IMAGENAME}" | wc -l)

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
    if ! umount -c "${FSXPATH}"; then
        logger "$LOG_MSG Error unmounting '$FSXPATH' at $(date)"

        logger "$LOG_MSG Retrying..."
        continue
    fi

    # Start a graceful shutdown of the host
    logger "$LOG_MSG Unmounting Lustre FSx filesystem $FSXPATH COMPLETED at $(date)"
    logger "$LOG_MSG Shutting down spot instance at $(date)"
    #shutdown now

done
