# taylorpy

Vyukovy material pro seminar IVT, 3. rocnik gymnazia.

**Tema:** Vypocet goniometrickych funkci a odmocniny pomoci
zakladnich operaci (+, -, *, /).

## Co je v projektu

| Soubor | Popis |
|---|---|
| `dokument/dokument.pdf` | Vyukovy text pro samostudium |
| `prezentace/prezentace.pdf` | Beamer prezentace (15 snimku) |
| `zadani/zadani.pdf` | Tisknutelne zadani domaci prace |
| `python/taylor.py` | Implementace funkci (bez zavislosti) |
| `python/grafy.py` | Vizualizace pro dokument (numpy, matplotlib) |

## Spusteni

### Windows

```powershell
# Generovani obrazku (jednou pred kompilaci)
.\Build.ps1 python

# Kompilace vsech PDF
.\Build.ps1

# Jen jeden dokument
.\Build.ps1 dokument
.\Build.ps1 prezentace
.\Build.ps1 zadani

# Uklid pomocnych souboru
.\Build.ps1 -Clean
.\Build.ps1 -DistClean
```

### Linux / macOS

```bash
make python   # generovani obrazku
make          # vsechny PDF
make dokument
make prezentace
make zadani
make clean
make distclean
```

### Python demo (bez LaTeX)

```bash
python3 python/taylor.py    # tabulka chyb v terminalu
```

## Pozadavky

- **LaTeX:** MiKTeX nebo TeX Live (XeLaTeX + latexmk)
- **Python:** 3.8+ (taylor.py bez zavislosti; grafy.py vyzaduje numpy, matplotlib)

Instalace Python zavislosti (jednorazove; Build.ps1 to dela automaticky):

```bash
pip install -r requirements.txt
```
