# PowerShell 2026

Rozcestník řešení úloh z PowerShellu.

| # | Zadání | Řešení |
|---|--------|--------|
| 1 | OWASP Juice Shop – Vánoční speciál 2014 + kupón 50 % (říjen 2026) | [ukol1.md](ukol1.md), [screenshots/](screenshots/) |
| 2 | Paleta 16 barev přednastavených v terminálu | [uloha2.ps1](uloha2.ps1) |
| 3 | Aliasy `np` (notepad.exe) a `ct` (control.exe) – záloha a obnova přes JSON a XML | [ukol3/aliasy.ps1](ukol3/aliasy.ps1) (zálohy: [JSON](ukol3/aliasy.json), [XML](ukol3/aliasy.xml)) |
| 4 | Palindrom; statistiky textu (znaky, samohlásky, slova) | [ukol4/palindrom.ps1](ukol4/palindrom.ps1), [ukol4/text-statistiky.ps1](ukol4/text-statistiky.ps1) |
| 5 | CIM: tiskárny a umístění faxu, přejmenování disku C:, nepoužité a uzamčené účty | [ukol5/](ukol5/) – viz [ukol5/README.md](ukol5/README.md) |
| 6 | Providery: seznam nainstalovaného softwaru bez WMI/CIM (4 zdroje, bez duplicit); NumLock před přihlášením | [ukol6/](ukol6/) – viz [ukol6/README.md](ukol6/README.md) |

> Podrobnosti k úlohám 4–6 jsou v README v jednotlivých složkách.

## Požadavky

- PowerShell 7+ (`pwsh`)
- Windows (úloha 2 – barvy terminálu; úloha 3 – `notepad.exe`, `control.exe`; úloha 5 – CIM/WMI, práva správce; úloha 6 – registr, Appx, práva správce pro NumLock)

## Spuštění skriptů

```powershell
pwsh -File ./uloha2.ps1

pwsh -File ./ukol3/aliasy.ps1

pwsh -File ./ukol4/palindrom.ps1
pwsh -File ./ukol4/palindrom.ps1 "Jelenovi pivo nelej"

pwsh -File ./ukol4/text-statistiky.ps1 "Kobyla má malý bok"
pwsh -File ./ukol4/text-statistiky.ps1

pwsh -File ./ukol5/ucty.ps1   # další skripty viz ukol5/README.md

pwsh -File ./ukol6/software.ps1
pwsh -File ./ukol6/numlock.ps1
```

Bez argumentů se skripty spouštějí interaktivně (text zadáte v terminálu).
