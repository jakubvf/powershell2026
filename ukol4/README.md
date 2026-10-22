# Úloha 4 – Palindrom a statistiky textu

Dva samostatné PowerShell skripty. Oba umí pracovat s textem z příkazového
řádku i interaktivně.

## `palindrom.ps1` – ověření palindromu

Palindrom se porovnává po normalizaci: malá písmena, **bez diakritiky**,
bez mezer a interpunkce (proto projde i „Kobyla má malý bok“, kde se liší
`y` a `ý`).

```powershell
pwsh -File ./palindrom.ps1                      # testovací příklady
pwsh -File ./palindrom.ps1 "Jelenovi pivo nelej" # vlastní text
```

Testovací příklady: *Jelenovi pivo nelej*, *Kobyla má malý bok*,
*Kupředu udeř puk*, *Dal kopat Ota poklad* – všechny vyjde `[ANO]`.

## `text-statistiky.ps1` – statistiky textu

Vypíše počet znaků s mezerami i bez mezer, počet samohlásek (včetně
českých s diakritikou) a počet slov.

```powershell
pwsh -File ./text-statistiky.ps1 "Kobyla má malý bok"
pwsh -File ./text-statistiky.ps1                # interaktivní režim
```

Ukázka:

```
Text: Kobyla má malý bok
  Znaků s mezerami : 18
  Znaků bez mezer  : 15
  Samohlásek       : 7
  Slov             : 4
```
