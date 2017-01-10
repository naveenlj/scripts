#!/bin/bash

INSTANCES=`./show-running-instances.sh | awk '{print $2}' | perl -pe 's/\n/,/g'`;INSTANCES=${INSTANCES:0:`expr length $INSTANCES`-1}
#INSTANCES="i-bcd84cdc"
VOLUMES=`aws ec2 describe-volumes --filters Name="attachment.instance-id",Values="$INSTANCES" --query "Volumes[*].[VolumeId]" --output text`

TODAY_NUM=`date | awk '{print $3}'`
TODAY_DAY=`date | awk '{print $1}'`

while IFS= read -r volume
do
    echo "Taking a snapshot of $volume..."
    if ( [ $TODAY_NUM -ne "1" ] && [ $TODAY_DAY != "Sun" ] ); then
        echo "Daily"
        aws ec2 create-snapshot --volume-id $volume --description "Daily automated snapshot. Please delete if older than 7 days." --output text
    elif [ $TODAY_NUM -eq "1" ];then
        echo "Monthly"
        aws ec2 create-snapshot --volume-id $volume --description "Monthly automated snapshot. Please delete if older than 3 months." --output text
    else
        echo "Weekly"
        aws ec2 create-snapshot --volume-id $volume --description "Weekly automated snapshot. Please delete if older than 8 weeks." --output text
    fi

done <<< "$VOLUMES"
