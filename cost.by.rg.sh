#!/bin/bash

RGROUPS=`az group list --output tsv | awk '{print $1}' | awk -F / '{print $5}'`

while IFS= read -r group; do
  awk '{print $1, $2, $3, $4}' < bill.2017.06.29.txt | grep -iE "^5.*2017.*$group" | awk '{print $3}' | perl -pi -e 's/[$|-]//g' | awk -v var=$group '{s+=$1} END {print var, s}'
done <<< "$RGROUPS" > 2017.06.29.Cost.by.RG.txt
