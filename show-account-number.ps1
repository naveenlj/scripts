$alias_output = aws iam list-account-aliases --output text
$alias = $alias_output.split("`t")[1]
$number = aws ec2 describe-security-groups --query 'SecurityGroups[0].IpPermissions[0].UserIdGroupPairs[*].UserId' --output text

if (-not $number)
{
    $number = aws ec2 describe-security-groups --query 'SecurityGroups[0].OwnerId' --output text
}

Write-Host $alias ":" $number
