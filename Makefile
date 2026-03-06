# =============================================================
# Makefile -- taylorpy
#
# Pouziti:
#   make             -- zkompiluje vsechny PDF dokumenty
#   make all         -- stejne jako make
#   make dokument    -- pouze vyukovy text
#   make prezentace  -- pouze Beamer prezentace
#   make zadani      -- pouze zadani domaci prace
#   make python      -- spusti Python skript (vygeneruje obrazky)
#   make clean       -- smaze pomocne soubory (zachova PDF)
#   make distclean   -- smaze vse vcetne PDF a vystupnich obrazku
#   make help        -- zobrazi tuto napovedu
# =============================================================

LATEXMK      := latexmk
LATEXMK_OPTS := \
    -pdf                     \
    -interaction=nonstopmode \
    -halt-on-error           \
    -cd

PYTHON := python3

DOKUMENT   := dokument/dokument.pdf
PREZENTACE := prezentace/prezentace.pdf
ZADANI     := zadani/zadani.pdf

# =============================================================
.DEFAULT_GOAL := all

.PHONY: all dokument prezentace zadani python clean distclean help

all: $(DOKUMENT) $(PREZENTACE) $(ZADANI)
	@echo ""
	@echo "Vse zkompilovano."

dokument: $(DOKUMENT)

prezentace: $(PREZENTACE)

zadani: $(ZADANI)

# Obecne pravidlo: .tex -> .pdf
%.pdf: %.tex
	@echo "-> $(notdir $<)"
	@$(LATEXMK) $(LATEXMK_OPTS) $<

# Spusteni Python skriptu -- generuje obrazky do python/output/
python:
	@echo "-> Generuji obrazky (python/output/)..."
	@$(PYTHON) python/grafy.py

# =============================================================
# Uklid
# =============================================================
clean:
	@echo "Mazem pomocne soubory..."
	@find . ! -path "./.git/*" \( \
	    -name "*.aux"            \
	    -o -name "*.log"         \
	    -o -name "*.out"         \
	    -o -name "*.toc"         \
	    -o -name "*.bbl"         \
	    -o -name "*.blg"         \
	    -o -name "*.bcf"         \
	    -o -name "*.run.xml"     \
	    -o -name "*.fls"         \
	    -o -name "*.fdb_latexmk" \
	    -o -name "*.synctex.gz"  \
	    -o -name "*.xdv"         \
	    -o -name "*.nav"         \
	    -o -name "*.snm"         \
	    -o -name "*.vrb"         \
	\) -delete
	@echo "Hotovo."

distclean: clean
	@find . ! -path "./.git/*" -name "*.pdf" -delete
	@rm -rf python/output/
	@echo "Smazany i PDF soubory a vystupni obrazky."

# =============================================================
# Napoveda
# =============================================================
help:
	@echo ""
	@echo "taylorpy -- Makefile"
	@echo "------------------------------------------------"
	@echo "  make             zkompiluje vsechny PDF dokumenty"
	@echo "  make all         stejne jako make"
	@echo "  make dokument    pouze vyukovy text"
	@echo "  make prezentace  pouze Beamer prezentace"
	@echo "  make zadani      pouze zadani domaci prace"
	@echo "  make python      spusti Python skript (obrazky)"
	@echo "  make clean       smaze pomocne soubory (zachova PDF)"
	@echo "  make distclean   smaze vse vcetne PDF a obrazku"
	@echo "  make help        tato napoveda"
	@echo ""
	@echo "Poznamka: pred prvni kompilaci dokumentu spust 'make python'"
	@echo "aby existovaly obrazky vkladane do PDF."
	@echo ""
