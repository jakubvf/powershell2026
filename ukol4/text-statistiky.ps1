# Úloha: Statistiky zadaného textu
# Vypíše:
#   - počet znaků s mezerami
#   - počet znaků bez mezer
#   - počet samohlásek (včetně českých s diakritikou)
#   - počet slov

param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Text
)

# Samohlásky včetně českých znaků s diakritikou
$samohlasky = 'aáeéěiíoóuúůyýAÁEÉĚIÍOÓUÚŮYÝ'

function Get-Statistiky {
    param([string]$Vstup)

    $znakySMezerami  = $Vstup.Length
    $znakyBezMezer   = ($Vstup -replace '\s', '').Length

    $pocetSamohlasek = 0
    foreach ($znak in $Vstup.ToCharArray()) {
        if ($samohlasky.Contains($znak)) {
            $pocetSamohlasek++
        }
    }

    # Slova = skupiny neprázdných znaků oddělené bílými znaky
    $slova = $Vstup -split '\s+' | Where-Object { $_ -ne '' }
    $pocetSlov = @($slova).Count

    return [PSCustomObject]@{
        Text              = $Vstup
        ZnakySMezerami    = $znakySMezerami
        ZnakyBezMezer     = $znakyBezMezer
        Samohlasky        = $pocetSamohlasek
        Slova             = $pocetSlov
    }
}

function Show-Statistiky {
    param([string]$Vstup)

    $s = Get-Statistiky $Vstup

    Write-Host '=========================================' -ForegroundColor Cyan
    Write-Host ('Text: {0}' -f $s.Text)
    Write-Host '-----------------------------------------'
    Write-Host ('  Znaků s mezerami : {0}' -f $s.ZnakySMezerami)
    Write-Host ('  Znaků bez mezer  : {0}' -f $s.ZnakyBezMezer)
    Write-Host ('  Samohlásek       : {0}' -f $s.Samohlasky)
    Write-Host ('  Slov             : {0}' -f $s.Slova)
    Write-Host '=========================================' -ForegroundColor Cyan
    Write-Host ''
}

# --- Text předán jako argument(y) na příkazovém řádku ---
if ($Text -and $Text.Count -gt 0) {
    Show-Statistiky ($Text -join ' ')
    return
}

# --- Interaktivní zadání ---
$zadany = Read-Host 'Zadejte text (Enter ukončí)'
while (-not [string]::IsNullOrWhiteSpace($zadany)) {
    Show-Statistiky $zadany
    $zadany = Read-Host 'Zadejte další text (Enter ukončí)'
}

Write-Host 'Hotovo.' -ForegroundColor Cyan
