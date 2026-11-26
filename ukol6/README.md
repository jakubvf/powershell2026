# Úloha 6 – PowerShell providery

| Skript | Úkol |
|--------|------|
| [`software.ps1`](software.ps1) | Seznam nainstalovaného softwaru ze 4 zdrojů (bez WMI/CIM), bez duplicit |
| [`numlock.ps1`](numlock.ps1) | NumLock před přihlášením – zjištění a zapnutí |

```powershell
pwsh -File ./software.ps1
pwsh -File ./software.ps1 -CsvSoubor software.csv   # i export do CSV
pwsh -File ./numlock.ps1 -WhatIf                     # jen zjistí stav
pwsh -File ./numlock.ps1                             # zapne (jako správce)
```

## Nainstalovaný software

| # | Zdroj | Provider / příkaz | Co poskytuje |
|---|-------|-------------------|--------------|
| 1 | `…\CurrentVersion\Uninstall` v `HKLM` (64bit), `HKLM\…\WOW6432Node` (32bit) a `HKCU` (jen pro uživatele) | **Registry** (`Get-ChildItem`, `Get-ItemProperty`) | název, verze, vydavatel, datum instalace, umístění, velikost, příkaz k odinstalaci |
| 2 | `HKLM:\SOFTWARE\Classes\Installer\Products`, `HKCU:\…\Installer\Products` | **Registry** | MSI produkty Windows Installeru (verze zakódovaná v DWORD) |
| 3 | Aplikace z Microsoft Store | `Get-AppxPackage` | název balíčku, verze, vydavatel, architektura, umístění |
| 4 | Zástupci `.lnk` v nabídce Start (všichni uživatelé + aktuální) | **FileSystem** (`Get-ChildItem`) + `VersionInfo` cílového `.exe` | produkt, verze, firma, složka programu |

**Odstranění duplicit** probíhá ve dvou krocích:

1. Záznamy z registru (1, 2) se slučují podle **přesného** názvu (bez ohledu
   na velikost písmen a interpunkci). Různé verze nebo architektury, například
   *VC++ x86* a *x64* nebo *Python 3.11* a *3.12*, tak zůstanou samostatně.
2. Appx a zástupci ze Start menu mají jiné názvy (bez verze, bez `(x64)`).
   Proto se k záznamům z kroku 1 přiřazují podle **volného** klíče, ze kterého
   se odstraní verze a architektura. Co se nepřiřadí, přidá se jako nová položka.

Při sloučení se u každé vlastnosti vezme první vyplněná hodnota (přednost má
Uninstall). Ve sloupci `Zdroje` je vidět, kde všude byl software nalezen.

## NumLock před přihlášením

Stav kláves na přihlašovací obrazovce určuje hodnota
`HKEY_USERS\.DEFAULT\Control Panel\Keyboard\InitialKeyboardIndicators`,
což je bitová maska (1 = CapsLock, **2 = NumLock**, 4 = ScrollLock). Windows 10/11
k ní často přidávají bit `0x80000000`, proto se testuje jen bit 2 a zbytek
hodnoty zůstane zachovaný (např. `2147483648` → `2147483650`).

Pro `HKEY_USERS` PowerShell nemá výchozí jednotku, takže si ji skript vytvoří
přes Registry provider:

```powershell
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
Get-ItemProperty 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name InitialKeyboardIndicators
Set-ItemProperty 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name InitialKeyboardIndicators -Value '2147483650'
```

Změna se projeví po odhlášení nebo restartu. Pokud ne, je potřeba vypnout
*Rychlé spuštění* (Fast Startup), které obnovuje stav z hibernace.
