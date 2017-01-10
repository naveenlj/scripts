#!/bin/bash

SEVEN_DAYS_AGO=$(date --date '7 days ago' +%s)
EIGHT_WEEKS_AGO=$(date --date '8 weeks ago' +%s)
THREE_MONTHS_AGO=$(date --date '3 months ago' +%s)

DAILIES=`aws ec2 describe-snapshots --filters Name="description",Values="Daily*" --query Snapshots[*].[StartTime,SnapshotId] --output text`
WEEKLIES=`aws ec2 describe-snapshots --filters Name="description",Values="Weekly*" --query Snapshots[*].[StartTime,SnapshotId] --output text`
MONTHLIES=`aws ec2 describe-snapshots --filters Name="description",Values="Monthly*" --query Snapshots[*].[StartTime,SnapshotId] --output text`

while IFS= read -r snap_data;do
        snap_date=$(echo $snap_data | cut -f1 -d' ')
        stamp=$(date --date $snap_date +%s)
        if [ $stamp -ge $SEVEN_DAYS_AGO ];then
                snap_id=$(echo $snap_data | cut -f2 -d' ')
                aws ec2 delete-snapshot --snapshot-id $snap_id
        fi
done <<< "$DAILIES"

while IFS= read -r snap_data;do
        snap_date=$(echo $snap_data | cut -f1 -d' ')
        stamp=$(date --date $snap_date +%s)
        if [ $stamp -ge $EIGHT_WEEKS_AGO ];then
                snap_id=$(echo $snap_data | cut -f2 -d' ')
                aws ec2 delete-snapshot --snapshot-id $snap_id
        fi
done <<< "$WEEKLIES"

while IFS= read -r snap_data;do
        snap_date=$(echo $snap_data | cut -f1 -d' ')
        stamp=$(date --date $snap_date +%s)
        if [ $stamp -ge $THREE_MONTHS_AGO ];then
                snap_id=$(echo $snap_data | cut -f2 -d' ')
                aws ec2 delete-snapshot --snapshot-id $snap_id
        fi
done <<< "$MONTHLIES"
