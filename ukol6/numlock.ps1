# Úloha 6b: Je NumLock zapnutý před přihlášením uživatele? Pokud ne, zapnout.
#
# Stav kláves na přihlašovací obrazovce určuje hodnota
#   HKEY_USERS\.DEFAULT\Control Panel\Keyboard\InitialKeyboardIndicators
# Je to bitová maska: 1 = CapsLock, 2 = NumLock, 4 = ScrollLock.
# Ve Windows 10/11 bývá navíc nastaven bit 0x80000000 (2147483648),
# proto se testuje jen bit 2 a ostatní bity se zachovají.
#
# PowerShell nemá pro HKEY_USERS výchozí jednotku – vytvoříme si ji
# pomocí Registry provideru (New-PSDrive). Změna vyžaduje práva správce.

[CmdletBinding(SupportsShouldProcess)]
param()

$NUMLOCK = 2

if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}

$cesta  = 'HKU:\.DEFAULT\Control Panel\Keyboard'
$nazev  = 'InitialKeyboardIndicators'

function Get-Indikatory {
    param([string]$Cesta)
    $text = (Get-ItemProperty -Path $Cesta -Name $nazev -ErrorAction SilentlyContinue).$nazev
    if ($null -eq $text) { return [uint32]0 }
    return [uint32]$text
}

$hodnota = Get-Indikatory $cesta
$zapnuto = ($hodnota -band $NUMLOCK) -ne 0

Write-Host ("Před přihlášením (.DEFAULT): {0} = {1} (0x{1:X8})" -f $nazev, $hodnota)

# Pro informaci i aktuální uživatel – platí po jeho přihlášení
$uzivatel = Get-Indikatory 'HKCU:\Control Panel\Keyboard'
Write-Host ("Aktuální uživatel (HKCU):     {0} = {1} (0x{1:X8})" -f $nazev, $uzivatel)

if ($zapnuto) {
    Write-Host 'NumLock je před přihlášením ZAPNUTÝ, není co měnit.' -ForegroundColor Green
    return
}

Write-Host 'NumLock je před přihlášením VYPNUTÝ.' -ForegroundColor Yellow

$nova = $hodnota -bor $NUMLOCK
if ($PSCmdlet.ShouldProcess("$cesta\$nazev", "Nastavit na $nova")) {
    # Hodnota je v registru uložena jako řetězec (REG_SZ)
    Set-ItemProperty -Path $cesta -Name $nazev -Value ([string]$nova) -Type String

    $kontrola = Get-Indikatory $cesta
    Write-Host ("NumLock zapnut: {0} = {1} (0x{1:X8})" -f $nazev, $kontrola) -ForegroundColor Green
    Write-Host 'Projeví se po odhlášení / restartu. Pokud ne, vypněte "Rychlé spuštění" (Fast Startup).'
}
