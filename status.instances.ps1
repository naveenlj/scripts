param(
[string[]]$instanceIds
)

foreach ($instanceId in $instanceIds)
{
    $status = aws ec2 describe-instances --filter Name="instance-id",Values="$instanceId" --query "Reservations[*].Instances[*].{name: Tags[?Key=='Name'] | [0].Value, instance_id: InstanceId, ip_address: PrivateIpAddress, state: State.Name, OS: Platform}" --output text

    $fields = $status -split "`t"
    
    foreach($field in $fields)
    {
        $field = $field.substring(0,[System.Math]::Min(15, $field.Length))
	write-host -NoNewline $field"`t"
    }
    write-host ""

}
