$alias_output = aws iam list-account-aliases --output text
if ($alias_output)
{ $alias = $alias_output.split("`t")[1] }
else
{ $alias = "No alias for this account" }

$number = aws ec2 describe-security-groups --query 'SecurityGroups[0].IpPermissions[0].UserIdGroupPairs[0].UserId' --output text

if ($number -eq "None")
{
    $number = aws ec2 describe-security-groups --query 'SecurityGroups[0].OwnerId' --output text
}

Write-Host $alias ":" $number
