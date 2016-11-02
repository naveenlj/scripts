param (
    [string]$instanceId
)

$deviceList = New-Object System.Collections.ArrayList
$deviceList = aws ec2 describe-volumes --filters Name="attachment.instance-id",Values="$instanceId" --query "Volumes[*].Attachments[*].Device" --output text

$volumeInfo = New-Object System.Collections.ArrayList
$volumeInfo = aws ec2 describe-volumes --filters Name="attachment.instance-id",Values="$instanceId" --query "Volumes[*].{Size:Size,volume_id:VolumeId,zone:AvailabilityZone,type:VolumeType}" --output text

$table = New-Object System.Collections.ArrayList
foreach ($volume in $volumeInfo)
{
    $table_row = $volume.split("`t")
    [void]$table.Add($table_row)
}

 $deviceTable = New-Object System.Collections.ArrayList
 foreach($device in $deviceList)
{
    $table_row = $device.split("`t")
    [void]$deviceTable.Add($table_row)
}

for($i=0 ; $i -lt $table.count; $i++)
{
    $table[$i] = $table[$i] + $deviceTable[$i]
}

Write-Host "--------------------------------------------------"
Write-Host "      Which volume would you like to mimic?"
Write-Host "--------------------------------------------------"

for ($i=0;$i -lt $table.count; $i++)
{
    $table[$i] = $table[$i] +($i+1)
    Write-Host ($i+1 -as [string])")" $table[$i]
}

[int]$userChoice = Read-Host "Enter Number"

[int]$rownum = 99
for ($i=0; $i -lt $table.count; $i++)
{
    if($i+1 -eq $userChoice)
    {
	$rownum = $i
    }
}
if ($table[$rownum][5] -eq $UserChoice -and $rownum -ne 99)
{
    Write-Host "You've chosen to create an volume of"$table[$rownum][0] "GB and attach it to"$instanceId".  Is this correct?"
    $Continue = Read-Host "Y to continue"
    if ($Continue -eq "y" -or $Continue -eq "Y")
    {
        Write-Host "Creating Volume..."    
        $size = $table[$rownum][0]
        $zone = $table[$rownum][3]
        $type = $table[$rownum][1]
	if ($type -eq "standard")
	{
		$type = "gp2"
	}
        $newVolumeInfo = aws ec2 create-volume --size $size --region us-east-1 --availability-zone $zone --volume-type $type --output text

       $volumeCells = $newVolumeInfo.split("`t")
       $volumeId = ""
       foreach ($cell in $volumeCells)
       {
          #Write-Host $cell

           if ($cell -match "^vol-.*$")
           {
               $volumeId = $cell
           }
       }
       Write-Host "New volume created:"$volumeId
       [string]$newDeviceName = ""
       [bool]$rejected = $false
       [string]$reason = ""
       while ($newDeviceName -eq "")
       {

           [string]$candidateDeviceName = Read-Host "Please specify a device name [xvdf - xvdp]"
           if ($candidateDeviceName -cmatch "^xvd[f-p]$" -eq $false)
           {
               
               $rejected = $true
               $reason = "invalid volume name.  Volume name must be all lower case and match the format xvd[f-p]."
           }
           else
           {
               for ($i=0;$i -lt $table.count;$i++)
               {
                    if ($candidateDeviceName -eq $table[$i][4])
                    {
                        $rejected = $true
                        $reason = "A device named " + $table[$i][4] + " already exists"
                    }
               }       
          }

          if($rejected -eq $true)
          {
            Write-Host $reason
            $rejected = $false
          }
          else
          {
              $newDeviceName = $candidateDeviceName
              Write-Host "Attaching Volume to"$instanceId
              $attachVolumeInfo = aws ec2 attach-volume --volume-id $volumeId --instance-id $instanceId --device $newDeviceName --output text
              Write-Host $attachVolumeInfo
          }
       }
    }
    else
    {
        Write-Host "Exiting..."
        exit
    }
}
