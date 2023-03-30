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

function Write-InstalledAppstoXML {
param (
    [Parameter(mandatory)][string] $MachineName,
    [string] $InfoLevel,
    [Parameter(mandatory)][string] $XMLPath
)
    Get-InstalledApps $MachineName $InfoLevel
    $Appslist | Export-Clixml -Path $XMLPath\$($MachineName)\InstalledApps.xml
    notepad.exe $XMLPath\$($MachineName)\InstalledApps.xml
}

function Remove-ListedApps {
param (
    [Parameter(mandatory)][string] $MachineName
)
    $RunningDirectory = Get-Location
    $AppsToRemove = Get-Content $RunningDirectory\AppsToRemove.xml
    
}

Export-ModuleMember -Function Get-InstalledApps, Write-InstalledAppstoXML, Remove-ListedApps