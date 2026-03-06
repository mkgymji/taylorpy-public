#Requires -Version 5.1
<#
.SYNOPSIS
    taylorpy - kompilace PDF a generovani obrazku na Windows.

.DESCRIPTION
    Zkompiluje vyukovy dokument, Beamer prezentaci a zadani
    pomoci latexmk + XeLaTeX.
    Volitelne spusti Python skript pro generovani obrazku.
    Ekvivalent Makefile pro Windows 10/11.

    Vyzaduje MiKTeX nebo TeX Live pro Windows:
      MiKTeX:   winget install MiKTeX.MiKTeX
                nebo https://miktex.org/download
      TeX Live: https://tug.org/texlive/windows.html

    Poznamka pro MiKTeX: pri prvnim sestaveni se balicky
    stahuji automaticky (potreba internet a chvili trpelivosti).

    Python (numpy + matplotlib) je potreba pro generovani obrazku.
    Pred prvni kompilaci dokumentu spust:  .\Build.ps1 python

.PARAMETER Target
    Co zkompilovat / provest (vychozi: all).
    Platne hodnoty: all, dokument, prezentace, zadani, python

.PARAMETER Clean
    Smaze pomocne soubory (zachova PDF a obrazky).

.PARAMETER DistClean
    Smaze vse vcetne PDF a vygenerovanych obrazku (python/output/).

.EXAMPLE
    .\Build.ps1                  # zkompiluje vsechny PDF dokumenty
    .\Build.ps1 dokument         # jen vyukovy text
    .\Build.ps1 prezentace       # jen Beamer prezentace
    .\Build.ps1 zadani           # jen zadani domaci prace
    .\Build.ps1 python           # jen generovani obrazku
    .\Build.ps1 -Clean           # smaze pomocne soubory, zachova PDF
    .\Build.ps1 -DistClean       # smaze vse vcetne PDF a obrazku
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("all", "dokument", "prezentace", "zadani", "python")]
    [string]$Target = "all",

    [switch]$Clean,
    [switch]$DistClean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# UTF-8 vystup (aby fungovala cestina v terminalu)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# Koren projektu (adresar tohoto skriptu)
$Root = $PSScriptRoot

# Pokud perl neni v PATH, zkus ho najit v instalaci Git for Windows.
# latexmk je Perl skript -- bez perlu MiKTeX odmitne spustit latexmk.exe.
if (-not (Get-Command perl -ErrorAction SilentlyContinue)) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        # git.exe byva v <GitRoot>\cmd\ nebo <GitRoot>\bin\, perl v <GitRoot>\usr\bin\
        $gitRoot = Split-Path (Split-Path $git.Source -Parent) -Parent
        $perlDir = Join-Path $gitRoot "usr\bin"
        if (Test-Path (Join-Path $perlDir "perl.exe")) {
            $env:PATH = "$perlDir;$env:PATH"
            Write-Host "[info] Perl pridan z Git for Windows: $perlDir" -ForegroundColor DarkGray
        }
    }
}

# =============================================================
# Definice cilu -- koresponduje s Makefile
# =============================================================
$TargetMap = [ordered]@{
    "all"        = @("dokument\dokument.tex", "prezentace\prezentace.tex", "zadani\zadani.tex")
    "dokument"   = @("dokument\dokument.tex")
    "prezentace" = @("prezentace\prezentace.tex")
    "zadani"     = @("zadani\zadani.tex")
    "python"     = @()   # resi se zvlast nize
}

# =============================================================
# Prerekvizity
# =============================================================
function Test-LatexPrerequisites {
    $missing = @()
    if (-not (Get-Command latexmk -ErrorAction SilentlyContinue)) { $missing += "latexmk" }
    if (-not (Get-Command xelatex -ErrorAction SilentlyContinue)) { $missing += "xelatex" }

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "CHYBA: Chybi programy: $($missing -join ', ')" -ForegroundColor Red
        Write-Host ""
        Write-Host "Instalace MiKTeX:   winget install MiKTeX.MiKTeX" -ForegroundColor Yellow
        Write-Host "           nebo:    https://miktex.org/download"   -ForegroundColor Yellow
        Write-Host "Instalace TeX Live: https://tug.org/texlive/windows.html" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

# =============================================================
# Kompilace jednoho .tex souboru
# =============================================================
function Invoke-Latexmk {
    param([string]$RelPath)

    $fullPath = Join-Path $Root $RelPath
    $label    = $RelPath -replace '\\', '/'

    if (-not (Test-Path $fullPath)) {
        Write-Host "  [SKIP] $label (soubor nenalezen)" -ForegroundColor DarkYellow
        return $true
    }

    Write-Host "  -> $label" -ForegroundColor Cyan

    # Spoustime z korene projektu, aby latexmk nasel .latexmkrc
    # (-cd pak prepne do adresare .tex souboru pred kompilaci)
    Push-Location $Root
    try {
        & latexmk `
            -pdf `
            "-pdflatex=xelatex %O %S" `
            -interaction=nonstopmode `
            -halt-on-error `
            -cd `
            -shell-escape `
            $fullPath
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($exitCode -ne 0) {
        Write-Host "  [CHYBA] $label" -ForegroundColor Red
        # Zobraz posledni radky .log souboru pro diagnostiku
        $logPath = [System.IO.Path]::ChangeExtension($fullPath, ".log")
        if (Test-Path $logPath) {
            Write-Host "  --- posledni radky logu ---" -ForegroundColor DarkGray
            Get-Content $logPath | Select-Object -Last 30 |
                ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
        }
        return $false
    }

    $pdfPath = [System.IO.Path]::ChangeExtension($fullPath, ".pdf")
    $pdfSize = if (Test-Path $pdfPath) {
        "{0:N0} KB" -f (([System.IO.FileInfo]$pdfPath).Length / 1KB)
    } else { "?" }

    Write-Host "  [OK] $label  ($pdfSize)" -ForegroundColor Green
    return $true
}

# =============================================================
# Virtualni prostredi (.venv) a generovani obrazku Pythonem
# =============================================================

# Vrati cestu k Python interpretu uvnitr .venv (nebo ho vytvori).
function Get-VenvPython {
    $venvDir  = Join-Path $Root ".venv"
    $venvPy   = Join-Path $venvDir "Scripts\python.exe"
    $req      = Join-Path $Root "requirements.txt"

    # Zkontroluj, ze systemovy Python existuje
    $sysPy = Get-Command python -ErrorAction SilentlyContinue
    if (-not $sysPy) { $sysPy = Get-Command python3 -ErrorAction SilentlyContinue }
    if (-not $sysPy) {
        Write-Host ""
        Write-Host "CHYBA: Python neni v PATH." -ForegroundColor Red
        Write-Host "Instalace: winget install Python.Python.3.12" -ForegroundColor Yellow
        Write-Host "      nebo: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }

    # Vytvor .venv, pokud jeste neexistuje
    if (-not (Test-Path $venvPy)) {
        Write-Host "  [venv] Vytvarim virtualni prostredi: .venv" -ForegroundColor DarkGray
        & $sysPy.Source -m venv $venvDir
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [CHYBA] Vytvoreni .venv selhalo." -ForegroundColor Red
            exit 1
        }
        Write-Host "  [venv] Virtualni prostredi vytvoreno." -ForegroundColor DarkGray
    }

    # Nainstaluj / aktualizuj balicky, kdyz requirements.txt existuje
    if (Test-Path $req) {
        Write-Host "  [venv] Instaluji balicky z requirements.txt..." -ForegroundColor DarkGray
        & $venvPy -m pip install --quiet --upgrade pip
        & $venvPy -m pip install --quiet -r $req
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [CHYBA] Instalace balicku selhala." -ForegroundColor Red
            exit 1
        }
        Write-Host "  [venv] Balicky jsou aktualni." -ForegroundColor DarkGray
    }

    return $venvPy
}

function Invoke-Python {
    $pyExe  = Get-VenvPython
    $script = Join-Path $Root "python\grafy.py"
    $outDir = Join-Path $Root "python\output"

    if (-not (Test-Path $script)) {
        Write-Host "  [SKIP] python/grafy.py (soubor nenalezen)" -ForegroundColor DarkYellow
        return $true
    }

    Write-Host "  -> python/grafy.py" -ForegroundColor Cyan
    Write-Host "     (vystup: python/output/)" -ForegroundColor DarkGray

    Push-Location $Root
    try {
        & $pyExe $script
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($exitCode -ne 0) {
        Write-Host "  [CHYBA] Python skript selhal (exit code $exitCode)" -ForegroundColor Red
        return $false
    }

    # Spocitej vygenerovane soubory
    $generated = if (Test-Path $outDir) {
        (Get-ChildItem $outDir -File).Count
    } else { 0 }

    Write-Host "  [OK] Vygenerovano $generated souboru v python/output/" -ForegroundColor Green
    return $true
}

# =============================================================
# Uklid pomocnych souboru
# =============================================================
$CleanPatterns = @(
    "*.aux", "*.log", "*.out", "*.toc",
    "*.bbl", "*.blg", "*.bcf", "*.run.xml",
    "*.fls", "*.fdb_latexmk", "*.synctex.gz",
    "*.xdv", "*.nav", "*.snm", "*.vrb",
    "*.lof", "*.lot", "*.lol", "*-SAVE-ERROR"
)

function Invoke-Clean {
    param([switch]$IncludePdf)

    Write-Host "Mazu pomocne soubory..." -ForegroundColor Yellow
    $count = 0

    foreach ($pattern in $CleanPatterns) {
        Get-ChildItem -Path $Root -Filter $pattern -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notlike "*\.git\*" } |
            ForEach-Object { Remove-Item $_.FullName -Force; $count++ }
    }

    if ($IncludePdf) {
        Write-Host "Mazu PDF soubory..." -ForegroundColor Yellow
        Get-ChildItem -Path $Root -Filter "*.pdf" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notlike "*\.git\*" } |
            ForEach-Object { Remove-Item $_.FullName -Force; $count++ }

        $outputDir = Join-Path $Root "python\output"
        if (Test-Path $outputDir) {
            Write-Host "Mazu python/output/..." -ForegroundColor Yellow
            Remove-Item $outputDir -Recurse -Force
            $count++
        }
    }

    Write-Host "Hotovo. Smazano $count souboru/adresaru." -ForegroundColor Green
}

# =============================================================
# Hlavni logika
# =============================================================

if ($DistClean) {
    Invoke-Clean -IncludePdf
    exit 0
}

if ($Clean) {
    Invoke-Clean
    exit 0
}

# Python-only target
if ($Target -eq "python") {
    Write-Host ""
    Write-Host "taylorpy -- generovani obrazku" -ForegroundColor White
    Write-Host ("-" * 44) -ForegroundColor DarkGray
    Write-Host ""
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = Invoke-Python
    $stopwatch.Stop()
    $elapsed = "{0:mm\:ss}" -f $stopwatch.Elapsed
    Write-Host ""
    Write-Host ("-" * 44) -ForegroundColor DarkGray
    if ($ok) {
        Write-Host "Hotovo  (${elapsed})" -ForegroundColor Green
    } else {
        Write-Host "Generovani selhalo  (${elapsed})" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# LaTeX targets (all / dokument / prezentace / zadani)
Test-LatexPrerequisites

$filesToBuild = $TargetMap[$Target]
$total  = $filesToBuild.Count
$ok     = 0
$failed = [System.Collections.Generic.List[string]]::new()

Write-Host ""
Write-Host "taylorpy -- sestaveni: $Target  ($total souboru)" -ForegroundColor White
Write-Host ("-" * 52) -ForegroundColor DarkGray

# Varujeme, kdyz chybi python/output/ a kompilujeme dokument nebo vse
$outputDir = Join-Path $Root "python\output"
if (-not (Test-Path $outputDir) -or (Get-ChildItem $outputDir -File -ErrorAction SilentlyContinue).Count -eq 0) {
    Write-Host ""
    Write-Host "[pozor] Adresar python/output/ je prazdny nebo neexistuje." -ForegroundColor DarkYellow
    Write-Host "        Spust nejprve: .\Build.ps1 python" -ForegroundColor DarkYellow
}

Write-Host ""

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $filesToBuild) {
    if (Invoke-Latexmk $file) {
        $ok++
    } else {
        $failed.Add($file)
    }
    Write-Host ""
}

$stopwatch.Stop()
$elapsed = "{0:mm\:ss}" -f $stopwatch.Elapsed

Write-Host ("-" * 52) -ForegroundColor DarkGray

if ($failed.Count -eq 0) {
    Write-Host "Vse zkompilovano: $ok/$total PDF  (${elapsed})" -ForegroundColor Green
} else {
    Write-Host "Zkompilovano: $ok/$total  (${elapsed})" -ForegroundColor Yellow
    Write-Host "Chyby v:" -ForegroundColor Red
    foreach ($f in $failed) {
        Write-Host "  - $($f -replace '\\', '/')" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Tip: pro diagnostiku spust konkretni soubor:" -ForegroundColor DarkYellow
    Write-Host "  latexmk -xelatex -cd -shell-escape $($failed[0])" -ForegroundColor DarkYellow
    exit 1
}
