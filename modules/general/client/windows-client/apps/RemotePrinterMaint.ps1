#TODO 

# Temporary fix for machine list not being populated.
$DistrictID = "001"
$IncludeOU = "UN"
# Comma delimited list of printers to hunt. Using shortened names may cause unwanted behavior or may not work at all.
$PrinterList = ""
# Below value switches between dry-run and armed states. 
# It is recommended to perform a dry-run first to prevent any unwanted deletions
$armstate = "dry-run"


$timestamp = Get-Date -Format "ddMMyyyy_HH_mm"
$logdir = "C:\TEMP\PrinterMaint\$timestamp"
$logfile = "$logdir\PrinterMaintLog.txt"
$errvar
Start-Transcript $logdir\PrintMaintTranscript.txt
New-Item -Path $logdir -Name "PrinterMaintLog.txt" -ItemType "file"

$IncludePC = $DistrictID+$IncludeOU+"*"

function Test-Online(){
        #This does not output a PSList object. needs to be converted to a list after result
        # EX. [System.Linq.Enumerable]::ToList([psobject[]](Test-Online -ComputerName $Workstations | Where-Object {$_.online}))        
        param(
            # make parameter pipeline-aware
            [Parameter(Mandatory,ValueFromPipeline)]
            [string[]]
            $ComputerName,$TimeoutMillisec = 1000,$Simultaneous = 100
        )
        begin{
            # use this to collect computer names that were sent via pipeline
            [Collections.ArrayList]$bucket = @()
        
            # hash table with error code to text translation
            $StatusCode_ReturnValue = @{
                0='Success'
                11001='Buffer Too Small'
                11002='Destination Net Unreachable'
                11003='Destination Host Unreachable'
                11004='Destination Protocol Unreachable'
                11005='Destination Port Unreachable'
                11006='No Resources'
                11007='Bad Option'
                11008='Hardware Error'
                11009='Packet Too Big'
                11010='Request Timed Out'
                11011='Bad Request'
                11012='Bad Route'
                11013='TimeToLive Expired Transit'
                11014='TimeToLive Expired Reassembly'
                11015='Parameter Problem'
                11016='Source Quench'
                11017='Option Too Big'
                11018='Bad Destination'
                11032='Negotiating IPSEC'
                11050='General Failure'
            }
        
            # hash table with calculated property that translates
            # numeric return value into friendly text

            $statusFriendlyText = @{
                Name = 'Status'
                Expression = {$StatusCode_ReturnValue[([int]$_.StatusCode)]}
            }

            # calculated property that returns $true when status -eq 0
            $IsOnline = @{
                Name = 'Online'
                Expression = { $_.StatusCode -eq 0 }
            }
        }
        process{
            # add each computer name to the bucket
            # we either receive a string array via parameter, or 
            # the process block runs multiple times when computer
            # names are piped
            $ComputerName | ForEach-Object {
                $null = $bucket.Add($_)
            }
        }
        end{
            # convert list of computers into a WMI query string
            if($bucket.count -lt $simultaneous){$i = $bucket.count}Else{$i = $simultaneous}
            $j = 0
            $stopwatch = [system.diagnostics.stopwatch]::StartNew()
            Write-Host "Pinging $($bucket.count) Workstations" -ForegroundColor Yellow
            While($i -le $bucket.count){
                Write-Progress -Activity "Pinged $j-$i of $($bucket.count) Workstations" -PercentComplete ([math]::Round(($j/$($bucket.count)*100)))
                $query = $bucket[$j..$i] -join "' or Address='"
                #Write-Host "$j-$i of $($bucket.count)"
                try{
                    $result += Get-WmiObject -Class Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" -ErrorAction Stop | Select-Object -Property Address, $IsOnline, $statusFriendlyText
                }Catch{
                    Write-Host "A Generic error occurred.. Trying block $j-$i of $($bucket.count) Again" -ForegroundColor Red
                    $result += Get-WmiObject -Class Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" | Select-Object -Property Address, $IsOnline, $statusFriendlyText
                }
                $j = $i + 1
                $i += $simultaneous
            }
            Write-Progress -Activity "Pinged $j-$i of $($bucket.count) Workstations" -Completed
            $stopwatch.Stop()
            Write-Host "Completed in $($Stopwatch.Elapsed)"
        return $result
        }
    }

$NumToPingAtOnce = 50
$Machinelist = Get-ADComputer -Filter {
Enabled -eq $True -and
Name -like $IncludePC -and
Name -notlike "*SUS*" -and
Name -notlike "*KAV*"
} | Select Name


try{
    $OnlineComputers = [System.Linq.Enumerable]::ToList([psobject[]](Test-Online -ComputerName $Machinelist.name -simultaneous $NumToPingAtOnce | Where-Object {$_.Online}))
    Write-Host "$($OnlineComputers.count) Online Workstation Found" -ForegroundColor Yellow
}Catch{
    Write-Host "No Online Workstations found" -ForegroundColor Red
}

foreach($Machine in $OnlineComputers.address){
    Write-Host "Starting Printer Maintenance on $Machine" -ForegroundColor Green
    Add-Content $logfile "Starting Printer Maintenance on $Machine"
    try{
        $PrinterObj = Get-Printer -ComputerName $Machine -ErrorAction Stop | Select-Object -Property Name, PortName
        Write-Host "Found Printer Objects:" -ForegroundColor Green
        Write-Host "$($PrinterObj.name -join ", ")" -ForegroundColor Yellow
        Add-Content $logfile "`tFound Printer Objects:"
        Add-Content $logfile "`t$($PrinterObj.name -join ", ")"
        foreach($Printer in $PrinterList){
            if($PrinterObj.name -match $Printer){
                Switch($armstate){
                    armed{
                        Write-Host "`tAttempt to remove $Printer from $Machine | " -NoNewline -ForegroundColor Green
                        Add-Content $logfile "`t Attempt to remove $Printer from $Machine | " -NoNewline
                        try{
                            remove-printer -ComputerName $Machine -Name $Printer -ErrorAction Stop
                            Write-host "Success" -ForegroundColor Green
                            Add-Content $logfile "Success"

                        }
                        Catch{
                            Write-Host "Fail" -ForegroundColor Red
                            Add-Content $logfile $_.Exception.Message
                        }
                    }
                    dry-run{
                        Write-Host "Would remove $Printer from $Machine"
                    }
                }
            }
            else{
            Write-Host "`t$Printer not found on $Machine" -ForegroundColor Red
            Add-Content $logfile "`t$Printer not found on $Machine"
            }

        }
    }
    catch{
        Write-Host "Could not retrieve printer list" -ForegroundColor Red
        Add-content $logfile "Could not retrieve printer list for $Machine"
    }
    
}

Stop-Transcript
