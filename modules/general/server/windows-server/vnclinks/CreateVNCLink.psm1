function New-VNCLinks {
    $VNCDIR = "\\server1\UPDATE$\QNSOU\VNCLINKS\TEST"
    $VNCContent = (Get-Content .\Desktop\VNCCONFIG.json | Out-String | ConvertFrom-Json)

    New-Item -ItemType Directory -Path $VNCDIR 

    $VNCComputers = Get-ADComputer -Filter * -SearchBase "OU=MANAGED,OU=COMPUTERS,OU=QNSOU,DC=mhs101,DC=pulski,DC=k12,DC=il,DC=us" | Select-Object Name 

    foreach ($computer in $VNCComputers) {
        $computerName = $computer.Name
        $OPDir = "$VNCDIR\$($computerName.Substring(0,8))"
        New-Item -ItemType Directory -Path $OPDir -ErrorAction SilentlyContinue

        New-Item -Path $OPDir -ItemType File -Name "$computerName.vnc"
        $VNCContent.connection[0] = "host=$computerName"
        $VNCContent.connection = $VNCContent.connection -join "`n"
        $VNCContent.options = $VNCContent.options -join "`n"
        $Payload = "[connection]`n$($VNCContent.connection)`n[options]`n$($VNCContent.options)`n"
        Set-Content -Path "$OPDir\$computerName.vnc" -Value $Payload -ErrorAction SilentlyContinue
        
    }

}