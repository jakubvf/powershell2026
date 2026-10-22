# PowerShell 2026

Rozcestník řešení úloh z PowerShellu.

| # | Zadání | Řešení |
|---|--------|--------|
| 1 | OWASP Juice Shop – Vánoční speciál 2014 + kupón 50 % (říjen 2026) | [ukol1.md](ukol1.md), [screenshots/](screenshots/) |
| 2 | Paleta 16 barev přednastavených v terminálu | [uloha2.ps1](uloha2.ps1) |
| 3 | Aliasy `np` (notepad.exe) a `ct` (control.exe) – záloha a obnova přes JSON a XML | _zatím neřešeno_ |
| 4 | Ověření, zda je text palindrom | [ukol4/palindrom.ps1](ukol4/palindrom.ps1) |
| 5 | Statistiky textu (znaky, samohlásky, slova) | [ukol4/text-statistiky.ps1](ukol4/text-statistiky.ps1) |

> Úlohy 4 a 5 jsou umístěny ve složce [`ukol4/`](ukol4/) – viz [ukol4/README.md](ukol4/README.md).

## Požadavky

- PowerShell 7+ (`pwsh`)
- Windows (úloha 2 – barvy terminálu; úloha 3 – `notepad.exe`, `control.exe`)

## Spuštění skriptů

```powershell
pwsh -File ./uloha2.ps1

pwsh -File ./ukol4/palindrom.ps1
pwsh -File ./ukol4/palindrom.ps1 "Jelenovi pivo nelej"

pwsh -File ./ukol4/text-statistiky.ps1 "Kobyla má malý bok"
pwsh -File ./ukol4/text-statistiky.ps1
```

Bez argumentů se skripty spouštějí interaktivně (text zadáte v terminálu).
