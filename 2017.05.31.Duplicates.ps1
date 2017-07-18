$row, $col = 1,2

$excel = new-object -com excel.application
$wb = $excel.workbooks.open("C:\Users\859845\Documents\2017.05.31.AWS.IAM.xlsx")

$bigList = new-object system.collections.arraylist($null) 
for ($i=4; $i -le $wb.sheets.count;$i++)
{
    $theSheet=$wb.Sheets.Item($i)
    $rowMax = ($theSheet.usedrange.rows).count
    
    for ($j=1;$j -le $rowMax-1;$j++)
    {
        [void]$bigList.Add($theSheet.cells.item($row+$j,$col).text)
    }
}
$excel.Workbooks.Close()

$shortList = $bigList | Select-Object -Unique

foreach ($member in $shortList)
{
    $member >> "C:\Users\859845\Documents\unique.txt"
}

Write-Host "Total Users: " $bigList.Count.ToString()
Write-Host "Unique Users: " $shortList.Count.ToString()



