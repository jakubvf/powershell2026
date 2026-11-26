# Úloha 5b: Název (jmenovka) disku C: a přejmenování na "System"
#
# Pro čtení stačí Win32_LogicalDisk (vlastnost VolumeName),
# pro změnu použijeme Win32_Volume (vlastnost Label).
# Přejmenování vyžaduje spuštění jako správce.

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Disk      = 'C:',
    [string]$NovyNazev = 'System'
)

Write-Host '=== Logické disky ===' -ForegroundColor Cyan
Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' |
    Format-Table DeviceID, VolumeName, FileSystem,
        @{ N = 'Velikost (GB)'; E = { [math]::Round($_.Size / 1GB, 1) } },
        @{ N = 'Volno (GB)';    E = { [math]::Round($_.FreeSpace / 1GB, 1) } } -AutoSize |
    Out-Host

$svazek = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$Disk'"
if (-not $svazek) {
    Write-Warning "Disk $Disk nebyl nalezen."
    return
}

Write-Host "Disk $Disk se jmenuje: '$($svazek.Label)'"

if ($svazek.Label -ceq $NovyNazev) {
    Write-Host "Disk už se jmenuje '$NovyNazev', není co měnit." -ForegroundColor Green
    return
}

if ($PSCmdlet.ShouldProcess($Disk, "Přejmenovat z '$($svazek.Label)' na '$NovyNazev'")) {
    Set-CimInstance -InputObject $svazek -Property @{ Label = $NovyNazev }

    $novy = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = '$Disk'"
    Write-Host "Disk $Disk se nyní jmenuje: '$($novy.VolumeName)'" -ForegroundColor Green
}
