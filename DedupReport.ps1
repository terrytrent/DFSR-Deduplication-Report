$results=$null
$User = "domain\userAccount"
$File = "C:\Password.txt"
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)

$getDedupStatus={
	$dedup=get-dedupjob | where {$_.state -eq "Running"}
	$dedupstat=(get-dedupstatus -volume $dedup.Volume)
    $savedSpace=[math]::round(($dedupstat.SavedSpace)/1024/1024/1024,2)
	$freeSpace=[math]::round(($dedupstat.FreeSpace)/1024/1024/1024,2)

    $stats= @{

		Volume = $dedup.volume
		'Start Time' = $dedup.StartTime
		'Job Type' = $dedup.Type
		'Job Progress' = $dedup.Progress
		'Job State' = $dedup.State
		'Optimized Files' = $dedupstat.OptimizedFilesCount
		'Saved Space' = $savedSpace
		'Free Space' = $freeSpace
	}
    $allStats= New-Object psobject -property $stats

    $allStats | select-object Volume,'Start Time','Job Type','Job Progress','Optimized Files','Saved Space','Free Space'
	        	
	        
}

$Server1Session=new-pssession -ComputerName Server1.domain.com -credential $credential
$Server2Session=new-pssession -ComputerName Server2.domain.com -credential $credential

$Server1Returned=Invoke-Command -Session $Server1Session -Scriptblock $getDedupStatus
sleep 1
$Server2Returned=Invoke-Command -Session $Server2Session -Scriptblock $getDedupStatus
sleep 1
get-pssession | remove-pssession
$allReturned=@($Server1Returned,$Server2Returned)

foreach($return in $allReturned){

    $Volume=$return.volume
    $StartTime=$return.'Start Time'
    $JobType=$return.'Job Type'
    $JobProgress=$return.'Job Progress'
    $OptimizedFiles=$return.'Optimized Files'
    $SavedSpace=$return.'Saved Space'
    $FreeSpace=$return.'Free Space'
    $Server=($return.PSComputerName -replace ".domain.com","").substring(0,1).toupper()+($return.PSComputerName -replace ".domain.com","").substring(1).tolower()

    $results+=@( "`
Server: $Server`
Volume: $Volume`
Start Time: $StartTime`
Job Type: $JobType`
Job Progress: $JobProgress %`
Optimized Files: $OptimizedFiles`
Saved Space: $SavedSpace GB`
Free Space: $FreeSpace GB
")


}

$body="$results"

Send-MailMessage -Body $body -From Deduplication@domain.net -SmtpServer smtp.domain.com -Subject "Deduplication Results" -To ReportCollector@domain.net