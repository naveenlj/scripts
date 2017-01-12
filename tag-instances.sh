#!/bin/bash

aws ec2 create-tags --resources $1 \
        --tags \
        Key="Name",Value="" \
        Key="Department",Value="ECS" \
        Key="Solution",Value="" \
        Key="Solution Owner",Value="Charles Peters" \
        Key="Impact",Value="DEVTEST" \
        Key="Hostname",value=""
