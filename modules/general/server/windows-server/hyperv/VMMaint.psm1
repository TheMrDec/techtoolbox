function Get-VMNames {
param(
    [Parameter(mandatory)][string] $VMHostName,
    [string] $InfoLevel
    )

    # InfoLevel states; 0=name only, 1=name/state/status, 2=all stats

    Switch ($InfoLevel)
    {
        $null {$InfoArray = @("Name","State","Status")}
        0 {$InfoArray = @("Name")}
        1 {$InfoArray = @("Name","State","Status")}
        2 {$InfoArray = @("Name","State","Status","Uptime","CPUUsage","MemoryAssigned","Version")}
    }

    Write-Host Get-VM -ComputerName $VMHostName | Select-Object $InfoArray
}

function Set-VMProcessTask {
param(
    [Parameter(mandatory)][string] $VMHostName,
    [Parameter(mandatory)][string] $VMName,
    [Parameter(mandatory)][string] $TaskOption
    )

    Switch ($TaskOption)
    {
        "start" {Start-VM -ComputerName $VMHostName -Name $VMName}
        "restart" {Restart-VM -ComputerName $VMHostName -Name $VMName}
        "stop" {Stop-VM -ComputerName $VMHostName -Name $VMName}
        "forcestop" {
            $VMID = (Get-VM -ComputerName $VMHostName $VMName)
            $VMPROC = (Get-WMIObject Win32_Process | Where-Object {$_.Name -match 'VMWP' -and $_.CommandLine -match $VMID})
            Stop-Process ($VMPROC.ProcessId) -Force
        }
    }
}

Export-ModuleMember -Function Get-VMNames, Set-VMProcessTask
