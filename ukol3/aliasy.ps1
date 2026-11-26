# Úloha 3: Aliasy np (notepad.exe) a ct (control.exe)
#   1. Vytvoření aliasů
#   2. Záloha do JSON a do XML
#   3. Smazání a obnova z JSON
#   4. Smazání a obnova z XML
#
# Aliasy se vytvářejí v globálním scope, aby po doběhnutí skriptu zůstaly
# k dispozici v aktuální relaci PowerShellu.

$nazvy      = 'np', 'ct'
$slozka     = $PSScriptRoot
$jsonSoubor = Join-Path $slozka 'aliasy.json'
$xmlSoubor  = Join-Path $slozka 'aliasy.xml'

function Show-Aliasy {
    param([string]$Nadpis)

    Write-Host "`n=== $Nadpis ===" -ForegroundColor Cyan
    $aliasy = Get-Alias -Name $nazvy -ErrorAction SilentlyContinue
    if ($aliasy) {
        $aliasy | Format-Table Name, Definition -AutoSize | Out-Host
    } else {
        Write-Host '(žádné aliasy np/ct neexistují)' -ForegroundColor Yellow
    }
}

function Remove-MojeAliasy {
    foreach ($n in $nazvy) {
        if (Test-Path "Alias:$n") {
            Remove-Alias -Name $n -Scope Global -Force
        }
    }
}

# --- 1. Vytvoření aliasů ---------------------------------------------------
Remove-MojeAliasy
New-Alias -Name np -Value notepad.exe -Description 'Poznámkový blok' -Scope Global
New-Alias -Name ct -Value control.exe -Description 'Ovládací panely' -Scope Global
Show-Aliasy 'Vytvořené aliasy'

# --- 2. Záloha do JSON a XML -----------------------------------------------
# JSON: ukládáme jen podstatné vlastnosti (celý AliasInfo obsahuje i odkazy
#       na moduly apod., které se do JSON serializovat nehodí)
Get-Alias -Name $nazvy |
    Select-Object Name, Definition, Description |
    ConvertTo-Json |
    Set-Content -Path $jsonSoubor -Encoding utf8

# XML: Export-Clixml serializuje objekty AliasInfo do CLIXML
Get-Alias -Name $nazvy | Export-Clixml -Path $xmlSoubor

Write-Host "`nZáloha JSON: $jsonSoubor" -ForegroundColor Green
Write-Host "Záloha XML : $xmlSoubor"  -ForegroundColor Green

# --- 3. Smazání a obnova z JSON --------------------------------------------
Remove-MojeAliasy
Show-Aliasy 'Po smazání'

Get-Content -Path $jsonSoubor -Raw |
    ConvertFrom-Json |
    ForEach-Object {
        New-Alias -Name $_.Name -Value $_.Definition -Description $_.Description -Scope Global
    }
Show-Aliasy 'Obnoveno z JSON'

# --- 4. Smazání a obnova z XML ---------------------------------------------
Remove-MojeAliasy
Show-Aliasy 'Po smazání'

Import-Clixml -Path $xmlSoubor |
    ForEach-Object {
        New-Alias -Name $_.Name -Value $_.Definition -Description $_.Description -Scope Global
    }
Show-Aliasy 'Obnoveno z XML'
