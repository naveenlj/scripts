#!/bin/bash

aws ec2 run-instances --image-id xxx --count 1 --instance-type t2.micro --key-name xxx --security-group-ids sg-xxx --associate-public-ip-address --subnet-id subnet-xxx --iam-instance-profile Arn="arn:aws:iam::xxx:instance-profile/xxx-administrator" --query 'Instances[0].[InstanceId,PrivateIpAddress]' --output text
