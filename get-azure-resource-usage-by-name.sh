#!/bin/bash

RGROUPS=`az group list --output tsv | grep -i test | awk '{print $1}' | awk -F / '{print $5}'`

while IFS= read -r group;
do 
    echo -e "#$group"
    START=`date "+%Y-%m-%dT0:00:00Z" --date "-89 day"`
    az monitor activity-log list --resource-group $group --start-time $START --output table
    az resource list -g $group --output table
    echo -e "####"
done <<< "$RGROUPS" > 2017.06.27.RG.Usage.txt
