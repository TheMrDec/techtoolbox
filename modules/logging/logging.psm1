function Set-LogDefaults {
    $LogPath = "C:\TechToolbox\Logging\$(Get-Date -Format "MMddyyyy")"
    $LogFile = "Log.txt"
    New-Item $LogPath\$LogFile -ItemType File -Force -EA SilentlyContinue
    Get-Job | Stop-Job; Get-Job | Remove-Job
    Start-Transcript -Path $LogPath\Transcript.txt
}

Export-ModuleMember -Function Set-LogDefaults
