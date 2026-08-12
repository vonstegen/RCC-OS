# Top-level Makefile for the RCC-OS LaTeX documentation layer.
# Build with `make`. Use `make help` for available targets.

LATEXMK ?= latexmk
BIBER   ?= biber
PDFLATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error -file-line-error

DOC       := main
SOURCES   := $(wildcard sections/*.tex) preamble.tex
BUILDDIR  := build
PDF       := $(BUILDDIR)/$(DOC).pdf

.PHONY: all clean distclean help spelling watch

all: $(PDF)

$(PDF): $(SOURCES) | $(BUILDDIR)
	$(LATEXMK) -pdf -pdflatex="pdflatex $(PDFLATEX_FLAGS)" $(DOC)
	mkdir -p $(BUILDDIR)
	mv $(DOC).pdf $(PDF) 2>/dev/null || true
	mv $(DOC).aux $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).bcf $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).bbl $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).fls $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).fdb_latexmk $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).log $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).out $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).run.xml $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).toc $(BUILDDIR)/ 2>/dev/null || true
	mv $(DOC).synctex.gz $(BUILDDIR)/ 2>/dev/null || true

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)

distclean: clean
	rm -f $(DOC).pdf

watch:
	$(LATEXMK) -pdf -pvc -pdflatex="pdflatex $(PDFLATEX_FLAGS)" $(DOC)

spelling:
	@command -v ltex >/dev/null 2>&1 || { echo "ltex not installed; see https://valentjn.github.io/ltex/."; exit 0; }
	ltex

help:
	@echo "make            - build $(PDF)"
	@echo "make clean      - remove build artifacts"
	@echo "make distclean  - also remove the final PDF"
	@echo "make watch      - rebuild on file change"
	@echo "make spelling   - run ltex prose lint"
