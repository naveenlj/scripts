﻿$idxA = (get-eventlog -LogName Application -Newest 1).Index
$idxS = (get-eventlog -LogName System -Newest 1).Index

while ($true)
{
  $idxA2 = (Get-EventLog -LogName Application -newest 1).index
  $idxS2 = (Get-EventLog -LogName System -newest 1).index


  echo "-----" >> applog.txt
  Get-Date >> applog.txt
  get-eventlog -logname Application -newest ($idxA2 - $idxA) |  sort index >> applog.txt
  $idxA = $idxA2
  
  echo "-----" >> syslog.txt
  Get-Date >> syslog.txt
  get-eventlog -logname System -newest ($idxS2 - $idxS) |  sort index >> syslog.txt
  $idxS = $idxS2

  start-sleep -Seconds 30
  }
