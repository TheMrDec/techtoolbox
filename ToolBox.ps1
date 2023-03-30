$rundir = Get-Location
$modules = Get-Childitem -Path $rundir\modules -Filter *.psm1 -Recurse -EA SilentlyContinue -Force

ForEach ($module in $modules) {
    Write-Host $module.FullName
    Import-Module $module.FullName
}