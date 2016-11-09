param(
[string[]]$ipAddresses
)

foreach ($ipAddress in $ipAddresses)
{
    $status = aws ec2 describe-instances --filter Name="private-ip-address",Values="$ipAddress" --query "Reservations[*].Instances[*].{name: Tags[?Key=='Name'] | [0].Value, instance_id: InstanceId, ip_address: PrivateIpAddress,  state: State.Name}" --output text

    $fields = $status -split "`t"
    
    foreach($field in $fields)
    {
        $field = $field.substring(0,[System.Math]::Min(15, $field.Length))
	write-host -NoNewline $field"`t"
    }
    write-host ""

}
