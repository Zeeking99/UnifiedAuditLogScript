Connect-ExchangeOnline

$sites = Import-Csv -Path ".\auditsites.csv" #CSV Input File with a single column sites

foreach ($site in $sites)
{    
    #Modify the values for the following variables to configure the audit log search.
    $logFile = ".\{0}-Log.txt" -f $site.names
    $outputFile = ".\{0}.csv" -f $site.names
    $objectIds = @($site.sites)
    [DateTime]$start = "10/15/2024" #Date format MM/DD/YYYY
    [DateTime]$end = "01/10/2025"  #Date format MM/DD/YYYY
    $record = "AzureActiveDirectory"
    $resultSize = 5000
    $intervalMinutes = 1440 # Use 1440 for 1 day intervals

    #Start script
    [DateTime]$currentStart = $start
    [DateTime]$currentEnd = $end

    Function Write-LogFile ([String]$Message)
    {
        $final = [DateTime]::Now.ToUniversalTime().ToString("s") + ":" + $Message
        $final | Out-File $logFile -Append
    }

    Write-LogFile "BEGIN: Retrieving audit records between $($start) and $($end), RecordType=$record, PageSize=$resultSize."
    Write-Host "Retrieving audit records for the site $($site.names) for the date range between $($start) and $($end), RecordType=$record, ResultsSize=$resultSize"

    $totalCount = 0
    while ($true)
    {
        $currentEnd = $currentStart.AddMinutes($intervalMinutes)
        if ($currentEnd -gt $end)
        {
            $currentEnd = $end
        }

    if ($currentStart -eq $currentEnd)
        {
            break
        }

    $sessionID = [Guid]::NewGuid().ToString() + "_" +  "ExtractLogs" + (Get-Date).ToString("yyyyMMddHHmmssfff")
        Write-LogFile "INFO: Retrieving audit records for the $($site.names) activities performed between $($currentStart) and $($currentEnd)"
        Write-Host "Retrieving audit records for activities performed between $($currentStart) and $($currentEnd) on the site $($site.names)"
        $currentCount = 0

    $sw = [Diagnostics.StopWatch]::StartNew()
        do
        {
            $results = Search-UnifiedAuditLog -StartDate $currentStart -EndDate $currentEnd -ObjectIds $objectIds -SessionId $sessionID -SessionCommand ReturnLargeSet -ResultSize $resultSize

            if (($results | Measure-Object).Count -ne 0)
            {
                $results | export-csv -Path $outputFile -Append -NoTypeInformation

                $currentTotal = $results[0].ResultCount
                $totalCount += $results.Count
                $currentCount += $results.Count
                Write-LogFile "INFO: Retrieved $($currentCount) audit records out of the total $($currentTotal)"

                if ($currentTotal -eq $results[$results.Count - 1].ResultIndex)
                {
                    $message = "INFO: Successfully retrieved $($currentTotal) audit records for the current time range for $($site.names). Moving on!"
                    Write-LogFile $message
                    Write-Host "Successfully retrieved $($currentTotal) audit records for the current time range for $($site.names). Moving on to the next interval." -foregroundColor Yellow 
                    break
                }
            }
        }
        while (($results | Measure-Object).Count -ne 0)

    $currentStart = $currentEnd
    }

    Write-LogFile "END: Retrieving audit records for the site $($site.names) between $($start) and $($end), RecordType=$record, PageSize=$resultSize, total count: $totalCount."
    Write-Host "Script complete! Finished retrieving audit records for the date range between $($start) and $($end). Total count: $totalCount" -foregroundColor Green
}