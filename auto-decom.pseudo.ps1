#USAGE: .\auto-decom.pseudo.ps1 [INSTANCE_ID],[INSTANCE_ID]

param (
[string[]]$instanceIds
#[switch]$silent=$false #option to run silently
#[string]$instanceIds_file=""
)

#if ($silent -eq $true)
#{
##TO DO
##-----------
##load instanceIds_file into InstanceIds
##load instancsIds_file_documentation into $documented
#}

foreach ($instanceId in $instanceIds)
{
  write-host "Processing $instanceId..."
  
  $verified = aws ec2 describe-instances --instance-id $instanceId

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
    $volumes = aws ec2 describe-volumes --filters Name="attachment.instance-id",Values=$instanceId --query "Volumes[*].[Attachments[0].Device,Size,DeleteOnTermination,VolumeId]" --output text
    $volCount = $volumes.count
    write-host "  $volCount found."
    if ($volumes.count -ge 1)
    {
      foreach ($volumeInfo in $volumes)
      {
        $volumeInfoList = $volumeInfo.split("`t")
        $tuple = [System.Tuple]::Create("Volume",$volumeInfoList)
        [void]$decomList.add($tuple)
    
        #fetch snapshot information
        $volumeId = $volumeInfoList[$volumeInfoList.count - 1]
        write-host "    Gathering snapshots for $volumeId..."
        $snapshots = aws ec2 describe-snapshots --filters Name="volume-id",Values=$volumeId --query "Snapshots[*].SnapshotId" --output text
        if ($snapshots -ge 1)
        { 
          $snapshotList = $snapshots.split("`t")
      
          #add each snapshot's information to the decom list
          $snapCount = $snapshotList.count
          write-host "    $snapCount found."
          foreach($snapId in $snapshotList)
          {
            $snapInfoList = $volumeId,$snapId
            $tuple = [System.Tuple]::Create("Snapshot",$snapInfoList)
            [void]$decomList.add($tuple)
          }
        }
        else{write-host "    0 found."}
      }
    }
    #fetch Elastic IP Information
    write-host "  Gathering elastic IPs..."
    $EIPs = aws ec2 describe-addresses  --filters Name="instance-id",Values=$instanceId --query "Addresses[*].[PublicIp,AllocationId]" --output text
    
    #add each Elastic IP's intformation to the decom list
    $EIP_Count = $EIPs.count
    write-host "  $EIP_Count found."
    if($EIPs -ge 1)
    {
      foreach ($EIP in $EIPs)
      {
        $EIP_List = $EIP.split("`t")
        $tuple = [System.Tuple]::Create("Elastic IP",$EIP_List)
        [void]$decomList.add($tuple)
      }
    }
    
    #query the user    
    $delete_instance = read-host "delete instance"$instanceId"? `[Y/N`]"
    if ($delete_instance -eq "Y")
    {
      $EIPs = "0"
      $volumes = "0"
      $snaps = "0"
      $documentation = "Md7h77yoo73UM3j"
  
      if ($EIP_Count -ge 1){$EIPs = read-host "delete Elastic IPs?         `[Y/N`]"}
      if ($volCount  -ge 1){$volumes = read-host "delete volumes?             `[Y/N`]"}
      if ($snapCount -ge 1){$snaps = read-host "delete snapshots?           `[Y/N`]"}
      $accountAliases = aws iam list-account-aliases --output text
      if($accountAliases){$accountAlias = $accountAliases.split("`t")[1]}
  
      if ($delete_volumes -eq "Y" -and $delete_snaps -eq "Y" -and $accountAlias -eq "****")
      {write-host "Deleting both volumes and snapshots from production requires 30 days notice to the application owner."
       $documentation = read-host "Please note where this is documented for $instanceId"}
       
       #create the report
       $timestamp = get-date -f yyyy.MM.dd_HH.mm.ss
       $out = new-object System.Collections.ArrayList
  
       [void]$out.add("Decomissioning Report for $instanceId")
       [void]$out.add("Started $timestamp")
       [void]$out.add("-------------------------------------")
       [void]$out.add("Delete Elastic IPs:     $EIPs")
       [void]$out.add("Delete Volumes:         $volumes")
       [void]$out.add("Delete snapshots:       $snaps")
       if($documentation -ne "Md7h77yoo73UM3j"){[void]$out.add("user notification documentation: $documentation")}
       [void]$out.add("-----Decomissioning Details-----")
       foreach ($tuple in $decomList)
       {
         $str =""
         foreach ($info in $tuple.Item2)
         {
           $str +="$info,"
         }
         $str = $str.substring(0,$str.length - 2)
         $str = '(' + $tuple.Item1 + ',(' + $str + '))'
         [void]$out.add($str)
       }
  
       #delete stuff
       write-host "Deleting $instanceId..."
       aws ec2 terminate-instances --instance-ids $instanceId --output text
       do
       {
         Write-Host -NoNewline "."
         sleep(1)
         $state = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text
       }
       Until($state -eq "terminated")
           

       foreach($tuple in $decomList)
       {
         if ($tuple.Item1 -eq "Elastic IP" -and $EIPs -eq "Y") {
           aws ec2 release-address --allocation-id $tuple.Item2[$tuple.Item2.count - 1] --output text
           $str = 'Deleting ' + $tuple.Item2[$tuple.Item2.count - 1] + '...';write-host $str
         }
         if ($tuple.Item1 -eq "Volume" -and $volumes -eq "Y") {
           aws ec2 delete-volume --volume-id $tuple.Item2[$tuple.Item2.count - 1] --output text
           $str = 'Deleting ' + $tuple.Item2[$tuple.Item2.count - 1] + '...';write-host $str
         }
         if ($tuple.Item1 -eq "Snapshot" -and $snaps -eq "Y") {
           aws ec2 delete-snapshot --snapshot-id $tuple.Item2[$tuple.Item2.count - 1] --output text
           $str = 'Deleting ' + $tuple.Item2[$tuple.Item2.count - 1] + '...';write-host $str
         }
       }

    #output the report
    $filename = $timestamp + "_decomReport_" + $instanceId
    $filename = [Environment]::GetFolderPath("Desktop") + '\'+  $filename + '.txt'
    $w =  New-Object System.IO.StreamWriter($filename)
    foreach ($line in $out){[void]$w.WriteLine($line)}
    $w.close()

    #upload to S3
    }
  }
#DEBUG: Print Tuple List
#-----------------------
#  foreach ($tuple in $decomList)
#  {
#    $str =""
#    foreach ($info in $tuple.Item2)
#    {
#      $str +="$info,"
#    }
#    $str = $str.substring(0,$str.length - 2)
#    $str = '(' + $tuple.Item1 + ',(' + $str + '))'
#    write-host $str
#  }
#-----------------------
}

#TO DO
#-----------------------
#  list associated AMIs, or at least report them (via snapshots)
#  add to decom list, label as AMI

#  figure out how to escape on termination protection
#  Better error handling for volumes when not found, snapshots protected by AMIs

#  multi-thread the delete process

#  list associated security groups
#  add to decom list where COUNT = 0, label as SG
#  aws ec2 describe-stale-security-groups --vpc-id ???

#  list keypair
#  add to decom list where COUNT = 0, label as KP

#  list VPC
#  add to decom list where COUNT = 0, label as VPC
#-----------------------
