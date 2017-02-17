#Environment Variables required for EC2
setx EC2_HOME "C:\Program Files (x86)\ec2-api-tools-1.7.5.1"
setx JAVA_HOME "C:\Program Files (x86)\Java\jre1.8.0_101"

function catchOutput ($test) #Sends either the command line error or the output to the Event Viewer.  Uncomment the write event to debug the script.
{
    #Write-EventLog -LogName Application -Source HA_Monitor -EntryType Information -EventID 0 -Message "$test"
    return $test
}
function writeMessage($str) #sends a message to the Event Viewer.
{
	Write-EventLog -LogName Application -Source HA_Monitor -EntryType Information -EventID 1 -Message "$str"
}

writeMessage("Running Heartbeat script.")
#$EC2_HOME = catchOutput(Get-ChildItem Env:EC2_HOME | out-string -stream) 
#$JAVA_HOME = catchOutput(Get-ChildItem Env:JAVA_HOME | out-string -stream)
#$PATH_RUNTIME = catchOutput(Get-ChildItem Env:Path | out-string -stream)

#Static Confugration Data
$primaryAID = "eipalloc-c2cac8a7"
$partnerIID = "i-3e9217aa"

#Fetch local data
$instanceID = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-id
$availabilityZone = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone
$region = "$availabilityZone" -replace "[a-z]$",""
$MyVIP = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/public-ipv4

$VIP = catchOutput(ec2-describe-addresses $primaryAID --region $region 2>&1) | %{ $_.split("`t")[1]}
$HA_Partner_IP = catchOutput(ec2-describe-instances $partnerIID --region $region 2>&1) | findstr "PRIVATEIPADDRESS" | %{ $_.split("`t")[1]}


if ($myVIP -ne $VIP) {
    $pingResult = catchOutput(ping -n 3 -w 3 $HA_Partner_IP 2>&1)
    if ($pingResult | select-string -pattern "100`% loss") {
        $rval = catchOutput(ec2-associate-address --region $region -a $primaryAID -i $instanceID --allow-reassociation 2>&1)
        writeMessage("Partner reports offline.  Successfully obtained primary public IP $VIP")
    }
    elseif ($pingResult | select-string -pattern "0`% loss") {
        writeMessage("Partner reports online; no action necessary")
    }
    else {
        writeMessage("Partner state unknown.")
    }
}
else {
    writeMessage("The local node $instanceID already possesses the primary public IP $VIP")

}
writeMessage("Hearbeat Complete")
