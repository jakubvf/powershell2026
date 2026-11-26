# Úloha 5 – CIM rozhraní

Tři skripty, všechny používají `Get-CimInstance` / `Get-CimClass` / `Set-CimInstance`.
Změny (umístění faxu, přejmenování disku) vyžadují **spuštění jako správce**.
Oba skripty, které něco mění, podporují `-WhatIf` (jen ukáže, co by se stalo).

| Skript | Úkol |
|--------|------|
| [`tiskarny.ps1`](tiskarny.ps1) | Vlastnosti třídy `Win32_Printer`, změna umístění faxu |
| [`disk.ps1`](disk.ps1) | Název disku `C:` a přejmenování na „System“ |
| [`ucty.ps1`](ucty.ps1) | Nepoužité a uzamčené účty – `Get-LocalUser` vs. CIM |

```powershell
pwsh -File ./tiskarny.ps1 -Umisteni 'Budova A, kancelář 101'
pwsh -File ./disk.ps1 -WhatIf          # jen ukázka
pwsh -File ./disk.ps1                  # C: -> System
pwsh -File ./disk.ps1 -Disk D: -NovyNazev Data
pwsh -File ./ucty.ps1
```

## Tiskárny

Tiskárny spravuje třída **`Win32_Printer`**. Vlastnosti a metody vypíšeme takto:

```powershell
(Get-CimClass Win32_Printer).CimClassProperties
(Get-CimClass Win32_Printer).CimClassMethods      # Pause, Resume, PrintTestPage, SetDefaultPrinter …
```

Umístění faxu změníme přes zapisovatelnou vlastnost `Location`:

```powershell
Get-CimInstance Win32_Printer -Filter "Name LIKE '%Fax%'" |
    Set-CimInstance -Property @{ Location = 'Kancelář 101' }
```

> Na Windows 11 fax ve výchozím stavu chybí – je třeba doinstalovat volitelnou
> funkci *Fax a skenování ve Windows*.

## Disk C:

```powershell
Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'" | Select DeviceID, VolumeName
Get-CimInstance Win32_Volume -Filter "DriveLetter = 'C:'" |
    Set-CimInstance -Property @{ Label = 'System' }
```

## Účty – porovnání řešení

| | `Get-LocalUser` | CIM |
|---|---|---|
| Třída / příkaz | `Get-LocalUser` | `Win32_UserAccount` + `Win32_NetworkLoginProfile` |
| Poslední přihlášení | ✅ `LastLogon` přímo u účtu | ⚠️ jen ve `Win32_NetworkLoginProfile.LastLogon` – nutné spojit přes `Caption` = `Name` |
| Uzamčení účtu | ❌ chybí – nutno přes ADSI `[ADSI]"WinNT://…".IsAccountLocked` | ✅ `Win32_UserAccount.Lockout` |
| Filtrování | v PowerShellu (`Where-Object`) | na straně WMI (`-Filter 'LocalAccount = TRUE'`) |
| Vzdálené počítače | ❌ jen lokálně (nebo přes `Invoke-Command`) | ✅ `-ComputerName` / `-CimSession` |
| Doména | ❌ jen lokální účty | ⚠️ bez filtru `LocalAccount` vrací i všechny doménové účty (pomalé) |
| Čitelnost | jednoduché, typované objekty (`DateTime`, `SID`) | delší, ale obecné – stejný postup pro jakoukoli třídu |

**Shrnutí:** Pro nepoužité účty je jednodušší `Get-LocalUser` (jedna vlastnost
`LastLogon`), pro uzamčené účty naopak CIM (`Lockout`), protože `Get-LocalUser`
tuto informaci vůbec neposkytuje. CIM navíc funguje i na vzdálených počítačích.

Pro doménové účty (MO) by se použil modul `ActiveDirectory`:
`Search-ADAccount -LockedOut` a `Get-ADUser -Properties lastLogonTimestamp` –
skript je spustí automaticky, pokud je modul nainstalován (RSAT).
