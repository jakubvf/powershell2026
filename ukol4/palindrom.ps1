# Úloha: Ověření, zda je zadaný text palindrom
# Palindrom = text, který se čte stejně zepředu i zezadu (bez ohledu na
# velikost písmen, mezery a interpunkci).

param(
    [string]$Text
)

# Odstranění diakritiky (převede např. á -> a, ř -> r)
function Remove-Diakritika {
    param([string]$Vstup)

    $normalizovany = $Vstup.Normalize([Text.NormalizationForm]::FormD)
    $sb = [System.Text.StringBuilder]::new()

    foreach ($znak in $normalizovany.ToCharArray()) {
        $kategorie = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($znak)
        if ($kategorie -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($znak)
        }
    }

    return $sb.ToString().Normalize([Text.NormalizationForm]::FormC)
}

# Normalizace: malá písmena, bez diakritiky, pouze písmena a číslice
function Get-NormalizovanyText {
    param([string]$Vstup)

    $bezDiakritiky = Remove-Diakritika $Vstup
    return ($bezDiakritiky.ToLower() -replace '[^\p{L}\p{Nd}]', '')
}

function Test-Palindrom {
    param([string]$Vstup)

    $cisty = Get-NormalizovanyText $Vstup

    # Porovnání se obráceným řetězcem
    $znaky = $cisty.ToCharArray()
    [array]::Reverse($znaky)
    $obraceny = -join $znaky

    return ($cisty -eq $obraceny)
}

function Show-Vysledek {
    param([string]$Vstup)

    $cisty = Get-NormalizovanyText $Vstup
    $jePalindrom = Test-Palindrom $Vstup

    if ($jePalindrom) {
        Write-Host ("  [ANO] '{0}' je palindrom." -f $Vstup) -ForegroundColor Green
    } else {
        Write-Host ("  [NE]  '{0}' NENÍ palindrom." -f $Vstup) -ForegroundColor Red
    }
    Write-Host ("        normalizovaně: {0}" -f $cisty) -ForegroundColor DarkGray
}

# --- Pokud byl text předán parametrem, otestuj jen ten ---
if ($PSBoundParameters.ContainsKey('Text')) {
    Show-Vysledek $Text
    return
}

# --- Testovací příklady ---
$testy = @(
    'Jelenovi pivo nelej',
    'Kobyla má malý bok',
    'Kupředu udeř puk',
    'Dal kopat Ota poklad',
    'Ahoj světe'   # protipříklad
)

Write-Host '=== Testovací příklady ===' -ForegroundColor Cyan
foreach ($t in $testy) {
    Show-Vysledek $t
}

# --- Interaktivní zadání od uživatele ---
Write-Host ''
$zadany = Read-Host 'Zadejte vlastní text (Enter přeskočí)'
while (-not [string]::IsNullOrWhiteSpace($zadany)) {
    Write-Host ''
    Show-Vysledek $zadany
    Write-Host ''
    $zadany = Read-Host 'Zadejte další text (Enter ukončí)'
}

Write-Host 'Hotovo.' -ForegroundColor Cyan
