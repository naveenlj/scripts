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
Write-Host "                Volume Information                "
Write-Host "--------------------------------------------------"

for ($i=0;$i -lt $table.count; $i++)
{
    $table[$i] = $table[$i] +($i+1)
    Write-Host ($i+1 -as [string])")" $table[$i]
}

[string]$response = Read-Host "Would you like to snapshot these volumes? (Y/N)"

if ($response -eq "Y" -or $response -eq "y")
{
    foreach ($row in $table)
    {
        Write-Host "Taking a snapshot of "$row[2]"..."
        $snapshotInfo = aws ec2 create-snapshot --volume-id $row[2] --description "Created by ECS team for SecureCloud Maintenance.  Please delete if older than 30 days." --output text
        $snapshotCells = $snapshotInfo.split("`t")
        #foreach ($cell in $snapshotCells)
        #{
        #    Write-Host $Cell
        #}
        Write-Host $row[2] -> $snapshotCells[4]
    } 
}
else
{
    Write-Host "Exiting..."
    exit
}
