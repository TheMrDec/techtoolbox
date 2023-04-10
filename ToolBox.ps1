$LogPath = "C:\TechToolbox\Logging\$(Get-Date -Format "MMddyyyy")"
$LogFile = "Log.txt"
New-Item $LogPath\$LogFile -ItemType File -Force -EA SilentlyContinue
Get-Job | Stop-Job; Get-Job | Remove-Job
Start-Transcript -Path $LogPath\Transcript.txt

$modules = Get-Childitem -Path .\modules -Filter *.psm1 -Recurse -EA SilentlyContinue -Force

ForEach ($module in $modules) {
    Write-Host $module.FullName
    Import-Module $module.FullName
}



Stop-Transcript