# Úloha 2: Vykreslení palety 16 přednastavených barev terminálu
# Sloupce: název | název v barvě písma | název s barvou pozadí

$sirka = 18

foreach ($barva in [System.Enum]::GetValues([System.ConsoleColor])) {
    $nazev = $barva.ToString().PadRight($sirka)

    Write-Host $nazev -NoNewline
    Write-Host $nazev -ForegroundColor $barva -NoNewline
    Write-Host $nazev -BackgroundColor $barva
}
