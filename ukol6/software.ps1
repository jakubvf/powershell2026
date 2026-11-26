# Úloha 6a: Co nejpodrobnější seznam nainstalovaného softwaru – BEZ WMI/CIM
#
# Zdroje (PowerShell providery Registry a FileSystem + Appx):
#   1. Registry – klíče Uninstall (HKLM 64bit, HKLM 32bit/WOW6432Node, HKCU)
#   2. Registry – MSI databáze Windows Installeru (Installer\Products)
#   3. Appx      – aplikace z Microsoft Store (Get-AppxPackage)
#   4. FileSystem – zástupci v nabídce Start (.lnk) + verze z cílového .exe
#
# Vše se spojí do jednoho seznamu a duplicity se sloučí podle normalizovaného
# názvu – u každé položky je vidět, ve kterých zdrojích byla nalezena.

[CmdletBinding()]
param(
    # Volitelně uloží výsledek do CSV
    [string]$CsvSoubor
)

# -------------------------------------------------------------------------
# Pomocné funkce
# -------------------------------------------------------------------------

# Normalizace názvu pro hledání duplicit:
# malá písmena, bez verze, bez architektury/jazyka v závorkách, bez interpunkce
function Get-KlicNazvu {
    param([string]$Nazev)

    $n = $Nazev.ToLowerInvariant()
    $n = $n -replace '\((x64|x86|64-bit|32-bit|64bit|32bit|amd64|arm64)[^)]*\)', ''
    $n = $n -replace '\b(x64|x86|amd64|arm64|64-bit|32-bit)\b', ''
    $n = $n -replace '\bv?\d+(\.\d+)+\b', ''          # čísla verzí 1.2.3
    $n = $n -replace '[^\p{L}\p{Nd}]+', ' '
    return $n.Trim()
}

function New-Polozka {
    param($Nazev, $Verze, $Vydavatel, $Datum, $Umisteni, $VelikostMB, $Architektura, $Zdroj, $Odinstalace)

    [PSCustomObject]@{
        Nazev        = $Nazev
        Verze        = $Verze
        Vydavatel    = $Vydavatel
        Nainstalovano = $Datum
        Umisteni     = $Umisteni
        VelikostMB   = $VelikostMB
        Architektura = $Architektura
        Odinstalace  = $Odinstalace
        Zdroj        = $Zdroj
    }
}

function ConvertFrom-RegDatum {
    param([string]$Text)
    if ($Text -match '^\d{8}$') {
        return [datetime]::ParseExact($Text, 'yyyyMMdd', $null)
    }
    return $null
}

$vsechno = [System.Collections.Generic.List[object]]::new()

# -------------------------------------------------------------------------
# 1) Registry: Uninstall
# -------------------------------------------------------------------------
$uninstallKlice = @(
    @{ Cesta = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';             Arch = '64-bit' }
    @{ Cesta = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; Arch = '32-bit' }
    @{ Cesta = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';             Arch = 'uživatel' }
)

foreach ($k in $uninstallKlice) {
    if (-not (Test-Path $k.Cesta)) { continue }

    Get-ChildItem -Path $k.Cesta -ErrorAction SilentlyContinue |
        Get-ItemProperty -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and -not $_.ParentKeyName } |   # bez aktualizací (KB) k produktům
        ForEach-Object {
            $vsechno.Add((New-Polozka `
                -Nazev        $_.DisplayName `
                -Verze        $_.DisplayVersion `
                -Vydavatel    $_.Publisher `
                -Datum        (ConvertFrom-RegDatum $_.InstallDate) `
                -Umisteni     $_.InstallLocation `
                -VelikostMB   $(if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1KB, 1) }) `
                -Architektura $k.Arch `
                -Odinstalace  $_.UninstallString `
                -Zdroj        'Registry-Uninstall'))
        }
}

# -------------------------------------------------------------------------
# 2) Registry: Windows Installer (MSI) produkty
# -------------------------------------------------------------------------
$msiKlice = 'HKLM:\SOFTWARE\Classes\Installer\Products',
            'HKCU:\SOFTWARE\Microsoft\Installer\Products'

foreach ($cesta in $msiKlice) {
    if (-not (Test-Path $cesta)) { continue }

    Get-ChildItem -Path $cesta -ErrorAction SilentlyContinue |
        Get-ItemProperty -ErrorAction SilentlyContinue |
        Where-Object ProductName |
        ForEach-Object {
            # Verze je uložena jako DWORD: major.minor.build (8b.8b.16b)
            $verze = $null
            if ($null -ne $_.Version) {
                $v = [uint32]$_.Version
                $verze = '{0}.{1}.{2}' -f ($v -shr 24), (($v -shr 16) -band 0xFF), ($v -band 0xFFFF)
            }
            $vsechno.Add((New-Polozka -Nazev $_.ProductName -Verze $verze -Zdroj 'Registry-MSI'))
        }
}

# -------------------------------------------------------------------------
# 3) Appx – aplikace z Microsoft Store
# -------------------------------------------------------------------------
try {
    try   { Import-Module Appx -ErrorAction Stop }
    catch { Import-Module Appx -UseWindowsPowerShell -ErrorAction Stop -WarningAction SilentlyContinue }

    Get-AppxPackage -PackageTypeFilter Main |
        Where-Object { -not $_.IsFramework -and $_.SignatureKind -ne 'System' } |
        ForEach-Object {
            # Vydavatel je ve tvaru "CN=Microsoft Corporation, O=..., ..."
            $vydavatel = if ($_.Publisher -match 'CN=([^,]+)') { $Matches[1] } else { $_.Publisher }
            $vsechno.Add((New-Polozka `
                -Nazev        $_.Name `
                -Verze        $_.Version `
                -Vydavatel    $vydavatel `
                -Umisteni     $_.InstallLocation `
                -Architektura $_.Architecture `
                -Zdroj        'Appx'))
        }
}
catch {
    Write-Warning "Appx balíčky nelze načíst: $($_.Exception.Message)"
}

# -------------------------------------------------------------------------
# 4) FileSystem – zástupci v nabídce Start
# -------------------------------------------------------------------------
$startMenu = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
             "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

# Zástupci, které nejsou samotnou aplikací
$sum = 'uninstall|odinstal|readme|read me|help|nápověda|manual|website|web site|license|licence|release notes'

$shell = New-Object -ComObject WScript.Shell

Get-ChildItem -Path $startMenu -Filter *.lnk -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.BaseName -notmatch $sum } |
    ForEach-Object {
        $cil = $shell.CreateShortcut($_.FullName).TargetPath
        if (-not $cil -or $cil -notlike '*.exe' -or -not (Test-Path -LiteralPath $cil)) { return }

        $info = (Get-Item -LiteralPath $cil).VersionInfo
        $vsechno.Add((New-Polozka `
            -Nazev     $(if ($info.ProductName) { $info.ProductName } else { $_.BaseName }) `
            -Verze     $info.ProductVersion `
            -Vydavatel $info.CompanyName `
            -Datum     (Get-Item -LiteralPath $cil).CreationTime.Date `
            -Umisteni  (Split-Path $cil) `
            -Zdroj     'StartMenu'))
    }

# -------------------------------------------------------------------------
# Spojení a odstranění duplicit
# -------------------------------------------------------------------------
# Krok 1: Záznamy z registru (Uninstall, MSI) se slučují podle PŘESNÉHO
#         názvu (bez ohledu na velikost písmen a interpunkci) – různé verze
#         nebo architektury (např. VC++ x86 a x64) tak zůstanou samostatně.
# Krok 2: Appx a zástupci ze Start menu mají názvy jiné (bez verze apod.),
#         proto se k záznamům z kroku 1 přiřadí podle VOLNÉHO klíče
#         (Get-KlicNazvu). Co se nepřiřadí, přidá se jako nová položka.
#
# Při slučování se pro každou vlastnost vezme první vyplněná hodnota –
# přednost má Registry-Uninstall (nejvíce údajů), pak MSI, Appx, StartMenu.
$poradi = @{ 'Registry-Uninstall' = 0; 'Registry-MSI' = 1; 'Appx' = 2; 'StartMenu' = 3 }
$vlastnosti = 'Nazev', 'Verze', 'Vydavatel', 'Nainstalovano', 'Umisteni', 'VelikostMB', 'Architektura', 'Odinstalace'

function Get-PresnyKlic {
    param([string]$Nazev)
    return ($Nazev.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]+', ' ').Trim()
}

function Merge-Polozky {
    param($Polozky)

    $polozky = $Polozky | Sort-Object { $poradi[$_.Zdroj] }
    $vysledek = [ordered]@{}
    foreach ($p in $vlastnosti) {
        $vysledek[$p] = $polozky.$p | Where-Object { $_ } | Select-Object -First 1
    }
    $vysledek['Zdroje'] = ($polozky.Zdroj | Select-Object -Unique) -join ', '
    return [PSCustomObject]$vysledek
}

# Krok 1
$seznam = [System.Collections.Generic.List[object]]::new()
$vsechno |
    Where-Object { $_.Zdroj -like 'Registry-*' -and (Get-PresnyKlic $_.Nazev) } |
    Group-Object { Get-PresnyKlic $_.Nazev } |
    ForEach-Object { $seznam.Add((Merge-Polozky $_.Group)) }

$index = @{}
foreach ($z in $seznam) {
    $k = Get-KlicNazvu $z.Nazev
    if (-not $index.ContainsKey($k)) { $index[$k] = [System.Collections.Generic.List[object]]::new() }
    $index[$k].Add($z)
}

# Krok 2
$vsechno |
    Where-Object { $_.Zdroj -notlike 'Registry-*' -and (Get-KlicNazvu $_.Nazev) } |
    Group-Object { Get-KlicNazvu $_.Nazev } |
    ForEach-Object {
        $nova = Merge-Polozky $_.Group

        if ($index.ContainsKey($_.Name)) {
            # Software už v seznamu je – jen doplníme zdroj a chybějící údaje
            foreach ($z in $index[$_.Name]) {
                $z.Zdroje = (($z.Zdroje -split ', ') + ($nova.Zdroje -split ', ') | Select-Object -Unique) -join ', '
                foreach ($p in $vlastnosti) {
                    if (-not $z.$p -and $nova.$p) { $z.$p = $nova.$p }
                }
            }
        }
        else {
            $seznam.Add($nova)
        }
    }

$seznam = $seznam | Sort-Object Nazev

# -------------------------------------------------------------------------
# Výstup
# -------------------------------------------------------------------------
Write-Host '=== Počet záznamů podle zdroje ===' -ForegroundColor Cyan
$vsechno | Group-Object Zdroj | Format-Table Name, Count -AutoSize | Out-Host

Write-Host ("Celkem nalezeno: {0}, po odstranění duplicit: {1}" -f $vsechno.Count, @($seznam).Count) -ForegroundColor Green

$seznam | Format-Table Nazev, Verze, Vydavatel, Nainstalovano, VelikostMB, Architektura, Zdroje -AutoSize -Wrap | Out-Host

if ($CsvSoubor) {
    $seznam | Export-Csv -Path $CsvSoubor -NoTypeInformation -Encoding utf8
    Write-Host "Uloženo do: $CsvSoubor" -ForegroundColor Green
}
