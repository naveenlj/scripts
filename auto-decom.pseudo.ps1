param (
[string[]]$instanceIds
#[switch]$silent=$false #option to run silently
#[string]$instanceIds_file=""
)

function Decomission
{
param ($EIPs,$volumes,$snaps,$decomList,$documentation)

#create decom report
#upload to S3
#decom resources appropriately

}


if ($silent -eq $true)
{
#TO DO
#-----------
#load instanceIds_file into InstanceIds
#load instancsIds_file_documentation into $documented
}

foreach ($instanceId in $instanceIds)
{
  write-host "Processing $instanceId..."
  
  try{$verified = aws ec2 describe-instances --instance-id $instanceId}
  catch{write-host "$instanceId not found"}

  if ($verified)
  { 
    $decomList = new-object System.Collections.ArrayList 
    $tuple = [System.Tuple]::Create("InstanceId",$instanceId)
    [void]$decomList.add($tuple)

    [int]$volCount = 0
    [int]$snapCount = 0
    [int]$EIP_Count = 0
  
    #fetch volume information
    write-host "  Gathering volumes..."
    $volumeInfo1 = aws ec2 describe-volumes --filters Name="attachment.instance-id",Values=$instanceId --query "Volumes[*].Attachments[*].{Device:Device,auto_delete:DeleteOnTermination}" --output text
  
    $volumeInfo2 = aws ec2 describe-volumes --filters Name="attachment.instance-id",Values=$instanceId --query "Volumes[*].{Size:Size,volume_id:VolumeId}" --output text
    #add each volume's information to the decom list
    $volCount = $volumeInfo1.count
    write-host "  $volCount found."
    if ($volumeInfo1.count -gt 1)
    {
      for ($i=0;$i -lt $volumeInfo1.count; $i++)
      {
        $tuple = [System.Tuple]::Create("Volume",$volumeInfo1[$i] + "`t" + $volumeInfo2[$i])
        [void]$decomList.add($tuple)
      }
    }
    elseif ($volumeInfo1.count -eq 1)
    {
        $tuple = [System.Tuple]::Create("Volume",$volumeInfo1 + "`t" + $volumeInfo2)
        [void]$decomList.add($tuple)
    }
    
    #fetch snapshot information
    write-host "  Gathering snapshots..."
    $volumeIds = aws ec2 describe-volumes --filters Name="attachment.instance-id",Values=$instanceId --query "Volumes[*].{volume_id:VolumeId}" --output text
    foreach($volumeId in $VolumeIds)
    {
      $snapshotInfo1 = aws ec2 describe-snapshots --filters Name="volume-id",Values=$volumeId --query "Snapshots[*].SnapshotId" --output text
      if ($snapshotInfo1 -ge 1)
      { 
        $snapshotInfo2 = $snapshotInfo1.split("`t")
    
        #add each snapshot's information to the decom list
        $snapCount = $snapshotInfo2.count
        write-host "  $snapCount found."
        foreach($snapId in $snapshotInfo2)
        {
          $tuple = [System.Tuple]::Create("Snapshot",$volumeId + "`t" + $snapId)
          [void]$decomList.add($tuple)
        }
      }
    }
    #fetch Elastic IP Information
    write-host "  Gathering elastic IPs..."
    $EIP_Info1 = aws ec2 describe-addresses  --filters Name="instance-id",Values=$instanceId --query "Addresses[*].PublicIp" --output text
    $EIP_Info2 = aws ec2 describe-addresses  --filters Name="instance-id",Values=$instanceId --query "Addresses[*].AllocationId" --output text
    
    #add each Elastic IP's intformation to the decom list
    $EIP_Count = $EIP_Info1.count
    write-host "  $EIP_Count found."
    if($EIP_Info1.count -gt 1)
    {
      for($i=0;$i -lt $EIP_Info1.count;$i++)
      {
        $tuple = [System.Tuple]::Create("Elastic IP",$EIP_Info1[$i] + "`t" + $EIP_Info2[$i])
        [void]$decomList.add($tuple)
      }
    }
    elseif ($EIP_Info1.count -eq 1)
    {
        $tuple = [System.Tuple]::Create("Elastic IP",$EIP_Info1 + "`t" + $EIP_Info2)
        [void]$decomList.add($tuple)
    }
    
    $delete_instance = read-host "delete instance"$instanceId"? `[Y/N`]"
    if ($delete_instance -eq "Y")
    {
      $EIPs = "N"
      $volumes = "N"
      $snaps = "N"
      $documentation = ""
  
      if ($EIP_Count -ge 1){$EIPs = read-host "delete Elastic IPs?         `[Y/N`]"}
      if ($volCount  -ge 1){$volumes = read-host "delete volumes?             `[Y/N`]"}
      if ($snapCount -ge 1){$snaps = read-host "delete snapshots?           `[Y/N`]"}
      $accountAliases = aws iam list-account-aliases --output text
      $accountAlias = $accountAliases.split("`t")[1]
  
      if ($delete_volumes -eq "Y" -and $delete_snaps -eq "Y" -and $accountAlias -eq "****")
      {write-host "Deleting both volumes and snapshots from production requires 30 days notice to the application owner."
       $documentation = read-host "Please note where this is documented for $instanceId"}
  
      Decomission($EIPs,$volumes,$snaps,$decomList,$documentation)
    }
  }
#DEBUG: Print Tuple List
#-----------------------
#  foreach ($tuple in $decomList)
#  {
#    write-host $tuple[0]
#    foreach ($item in $tuple[1])
#    {
#      write-host $item
#    }
#  }
#-----------------------
}

#TO DO
#-----------------------
#  list associated AMIs
#  add to decom list, label as AMI

#  list associated security groups
#  add to decom list where COUNT = 0, label as SG
#  aws ec2 describe-stale-security-groups --vpc-id ???

#  list keypair
#  add to decom list where COUNT = 0, label as KP

#  list VPC
#  add to decom list where COUNT = 0, label as VPC
#-----------------------
