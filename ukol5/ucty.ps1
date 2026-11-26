# Úloha 5c: Nepoužité a uzamčené účty – Get-LocalUser vs. CIM
#
# Nepoužitý účet = nikdo se k němu nikdy nepřihlásil.
#
#   Get-LocalUser   ... vlastnost LastLogon (prázdná = nikdy), ale NEMÁ
#                       informaci o uzamčení účtu.
#   CIM             ... Win32_UserAccount má vlastnost Lockout, ale NEMÁ
#                       čas přihlášení; ten je ve Win32_NetworkLoginProfile
#                       (LastLogon), takže je potřeba spojit dvě třídy.

# =========================================================================
#  1) Řešení pomocí Get-LocalUser (modul Microsoft.PowerShell.LocalAccounts)
# =========================================================================
$casCmdlet = Measure-Command {
    $lokalni = Get-LocalUser

    $nepouziteCmdlet = $lokalni | Where-Object { -not $_.LastLogon }

    # Get-LocalUser uzamčení neumí – pomůžeme si rozhraním ADSI (WinNT://)
    $uzamceneCmdlet = $lokalni | Where-Object {
        ([ADSI]"WinNT://$env:COMPUTERNAME/$($_.Name),user").IsAccountLocked
    }
}

Write-Host '=== Get-LocalUser: nepoužité účty ===' -ForegroundColor Cyan
$nepouziteCmdlet | Format-Table Name, Enabled, LastLogon, Description -AutoSize | Out-Host

Write-Host '=== Get-LocalUser (+ADSI): uzamčené účty ===' -ForegroundColor Cyan
if ($uzamceneCmdlet) { $uzamceneCmdlet | Format-Table Name, Enabled -AutoSize | Out-Host }
else { Write-Host '(žádné)' }

# =========================================================================
#  2) Řešení pomocí CIM
# =========================================================================
$casCim = Measure-Command {
    # LocalAccount = TRUE – v doméně by se jinak vypisovaly všechny doménové účty
    $ucty = Get-CimInstance -ClassName Win32_UserAccount -Filter 'LocalAccount = TRUE'

    # Profily, ke kterým už někdo přihlásil (Name ve tvaru POCITAC\uzivatel)
    $prihlaseni = Get-CimInstance -ClassName Win32_NetworkLoginProfile |
        Where-Object { $_.LastLogon } |
        ForEach-Object { $_.Name.ToLower() }

    $nepouziteCim = $ucty | Where-Object { $prihlaseni -notcontains $_.Caption.ToLower() }
    $uzamceneCim  = $ucty | Where-Object Lockout
}

Write-Host "`n=== CIM: nepoužité účty ===" -ForegroundColor Cyan
$nepouziteCim | Format-Table Name, Disabled, Lockout, Description -AutoSize | Out-Host

Write-Host '=== CIM: uzamčené účty ===' -ForegroundColor Cyan
if ($uzamceneCim) { $uzamceneCim | Format-Table Name, Disabled, Lockout -AutoSize | Out-Host }
else { Write-Host '(žádné)' }

# =========================================================================
#  3) Porovnání
# =========================================================================
Write-Host "`n=== Porovnání výsledků ===" -ForegroundColor Cyan

function Compare-Seznam {
    param([string]$Co, $A, $B)

    $rozdil = Compare-Object -ReferenceObject @($A | ForEach-Object Name) `
                             -DifferenceObject @($B | ForEach-Object Name)
    if ($rozdil) {
        Write-Host "${Co}: výsledky se liší" -ForegroundColor Yellow
        $rozdil | Select-Object @{ N = 'Účet'; E = { $_.InputObject } },
            @{ N = 'Jen v'; E = { if ($_.SideIndicator -eq '<=') { 'Get-LocalUser' } else { 'CIM' } } } |
            Format-Table -AutoSize | Out-Host
    } else {
        Write-Host "${Co}: oba přístupy vrátily stejné účty" -ForegroundColor Green
    }
}

Compare-Seznam 'Nepoužité účty' $nepouziteCmdlet $nepouziteCim
Compare-Seznam 'Uzamčené účty'  $uzamceneCmdlet  $uzamceneCim

[PSCustomObject]@{ Řešení = 'Get-LocalUser (+ADSI)'; 'Čas (ms)' = [int]$casCmdlet.TotalMilliseconds },
[PSCustomObject]@{ Řešení = 'CIM';                   'Čas (ms)' = [int]$casCim.TotalMilliseconds } |
    Format-Table -AutoSize | Out-Host

# =========================================================================
#  Doménové účty (jen pokud je k dispozici modul ActiveDirectory – RSAT)
# =========================================================================
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory

    Write-Host '=== AD: nepoužité účty ===' -ForegroundColor Cyan
    Get-ADUser -Filter * -Properties lastLogonTimestamp |
        Where-Object { -not $_.lastLogonTimestamp } |
        Format-Table Name, SamAccountName, Enabled -AutoSize | Out-Host

    Write-Host '=== AD: uzamčené účty ===' -ForegroundColor Cyan
    Search-ADAccount -LockedOut | Format-Table Name, SamAccountName -AutoSize | Out-Host
}
