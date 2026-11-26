# Úloha 5a: Vlastnosti CIM třídy pro správu tiskáren a změna umístění faxu
#
# Tiskárny spravuje třída Win32_Printer (namespace root/cimv2).
# Změna umístění (Location) vyžaduje spuštění jako správce.

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Umisteni = 'Kancelář 101'
)

$trida = 'Win32_Printer'

# --- Vlastnosti a metody třídy -------------------------------------------
$cimTrida = Get-CimClass -ClassName $trida

Write-Host "=== Vlastnosti třídy $trida ===" -ForegroundColor Cyan
$cimTrida.CimClassProperties |
    Select-Object Name,
        @{ N = 'Typ';    E = { $_.CimType } },
        @{ N = 'Zápis';  E = { if ($_.Qualifiers.Name -contains 'write') { 'ano' } else { '' } } } |
    Sort-Object Name |
    Format-Table -AutoSize | Out-Host

Write-Host "=== Metody třídy $trida ===" -ForegroundColor Cyan
$cimTrida.CimClassMethods | Select-Object -ExpandProperty Name | Out-Host

# --- Seznam tiskáren --------------------------------------------------------
Write-Host "`n=== Nainstalované tiskárny ===" -ForegroundColor Cyan
Get-CimInstance -ClassName $trida |
    Format-Table Name, DriverName, PortName, Location, Default -AutoSize | Out-Host

# --- Změna umístění faxu ----------------------------------------------------
# Fax poznáme podle názvu nebo ovladače (Microsoft Shared Fax Driver)
$fax = Get-CimInstance -ClassName $trida |
    Where-Object { $_.Name -like '*Fax*' -or $_.DriverName -like '*Fax*' }

if (-not $fax) {
    Write-Warning 'Fax nebyl nalezen (v nových Windows je nutné doinstalovat volitelnou funkci "Fax a skenování").'
    return
}

foreach ($f in $fax) {
    Write-Host "`nFax '$($f.Name)' – původní umístění: '$($f.Location)'" -ForegroundColor Yellow

    if ($PSCmdlet.ShouldProcess($f.Name, "Nastavit umístění na '$Umisteni'")) {
        Set-CimInstance -InputObject $f -Property @{ Location = $Umisteni }

        $novy = Get-CimInstance -ClassName $trida -Filter "Name = '$($f.Name -replace "'", "''")'"
        Write-Host "Fax '$($novy.Name)' – nové umístění:   '$($novy.Location)'" -ForegroundColor Green
    }
}
