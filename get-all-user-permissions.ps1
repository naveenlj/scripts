param (
    [string]$username
)

$Groups = aws iam list-groups-for-user --user-name $username --output text | %{ $_.split("`t")[4]}

foreach ($Group in $Groups)
{
echo "----------------------------------- $Group -----------------------------------"
    aws iam list-attached-group-policies --group-name $Group --output table
}
aws iam list-attached-user-policies --user-name $username --output table

echo "-------- Inline Policies --------"
foreach ($Group in $Groups)
{
    aws iam list-group-policies --group-name $Group --output table
}
aws iam list-user-policies --user-name $username --output table
