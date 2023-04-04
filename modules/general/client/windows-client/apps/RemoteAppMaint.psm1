function Get-InstalledApps {
param(
    [Parameter(mandatory)][string] $MachineName,
    [string] $InfoLevel
)

    Switch ($InfoLevel) 
    {
        $null {$InfoArray = @("Name","Vendor","Version")}
        0 {$InfoArray = @("Name")}
        1 {$InfoArray = @("Name","Vendor","Version")}
        2 {$InfoArray = @("Name","Vendor","Version","Caption","IdentifyingNumber")}
    }

    $Domain = (Get-ADDomain).DNSRoot
    $PSCred = Get-Credential "$($Domain)\"

    $AppsList =  Get-WmiObject -ComputerName $MachineName -Class Win32_Product -Credential $PSCred | Select-Object $InfoArray

    return($AppsList)
}

function Write-InstalledAppstoFile {
param (
    [Parameter(mandatory)][string] $MachineName,
    [string] $InfoLevel,
    [Parameter(mandatory)][string] $XMLPath
)
    Get-InstalledApps $MachineName $InfoLevel
    $Appslist | ConvertTo-Json -depth 100 | Out-File "$XMLPath\$($MachineName)\InstalledApps.json"
    # Enable below line to debug bad JSON exports/imports
    # notepad.exe $XMLPath\$($MachineName)\InstalledApps.json
}

function Remove-ListedApps {
param (
    [Parameter(mandatory)][string] $MachineName
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

Export-ModuleMember -Function Get-InstalledApps, Write-InstalledAppstoXML, Remove-ListedApps