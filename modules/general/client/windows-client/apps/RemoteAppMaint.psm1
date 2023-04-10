function Get-InstalledApps {
    param(
        [Parameter(mandatory)][string] $MachineName,
        [Parameter(mandatory)][string] $OutputPath
    )

    New-Item -ItemType Directory -Path $OutputPath\$MachineName -Force -EA SilentlyContinue

    $AppsList32 = Invoke-Command -ComputerName $MachineName -ScriptBlock {Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty | Select-Object "DisplayName","Publisher","InstallDate","DisplayVersion","PSChildName" | Sort-Object -Property DisplayName}
    foreach ($app in $AppsList32){$app | Add-Member -NotePropertyName Architecture -NotePropertyValue "32 bit"}
    $AppsList64 = Invoke-Command -ComputerName $MachineName -ScriptBlock {Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty | Select-Object "DisplayName","Publisher","InstallDate","DisplayVersion","PSChildName" | Sort-Object -Property DisplayName}
    foreach ($app in $AppsList64){$app | Add-Member -NotePropertyName Architecture -NotePropertyValue "64 bit"}

    $AppsList = $AppsList32 + $AppsList64

    $AppsList | ConvertTo-Json -depth 100 | Out-File "$OutputPath\$MachineName\InstalledApps.json"
    # Enable below line to debug bad JSON exports/imports
    #notepad.exe $OutputPath\$($MachineName)\InstalledApps.json
}
    
function Remove-ListedApps {
    param (
        [Parameter(mandatory)][string] $MachineName,
        [Parameter(mandatory)][string] $InputPath
    )
    
        try {
            $AppsToRemove = Get-Content -Raw -Path .\AppsToRemove.json | ConvertFrom-Json
        }
        catch {
            Write-Host "AppsToRemove.json was not found or could not be read. `n Please verify that the file exists and can be read by the current user."
            Write-Output $_
        }
    
        try {
            Get-InstalledApps -MachineName $MachineName -InfoLevel 0
        }
        catch {
            Write-Host "$($MachineName) could not be contacted via remote command. `n Please verify that the machine is powered on."
            Write-Output $_
        }
    
        ForEach ($App in $AppsToRemove){
            $SelectedApp = $AppsList | Where-Object {$_.Name -eq "$App"}
    
            try {
                Invoke-Command -ComputerName $MachineName -ScriptBlock {$SelectedApp.Uninstall()}
            }
            catch {
                Write-Host "Could not remove $App. Consult the logfile for more details."
            }
    
            
        }
        
    }

Export-ModuleMember -Function Get-InstalledApps, Remove-ListedApps