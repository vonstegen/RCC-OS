# RCC-OS LaTeX Documentation Layer

This directory contains the **typeset documentation layer** of the
lab. It is the canonical PDF surface for archival documents that
need to be shared outside the repository (e.g. with reviewers,
collaborators, or in published work).

The Markdown surface in [`../docs/`](../docs/) is the living
documentation. Both surfaces are kept in sync; the Markdown is
authoritative, and the LaTeX sources are derived snapshots at the
points recorded in [`../docs/MILESTONES.md`](../docs/MILESTONES.md).

## Layout

```text
latex/
├── Makefile              # top-level driver
├── latexmkrc             # latexmk configuration
├── main.tex              # master document (one PDF)
├── preamble.tex          # packages, macros, typographic setup
├── classes/
│   └── rccos.cls         # lab document class
├── sections/             # body content per document type
│   ├── 00-frontmatter.tex
│   ├── 01-goal.tex
│   ├── 02-milestones.tex
│   ├── 03-architecture.tex
│   ├── 04-design.tex
│   ├── 05-decisions.tex
│   ├── 06-research.tex
│   ├── 07-tests.tex
│   ├── 08-deadlines.tex
│   └── 99-backmatter.tex
├── figures/              # PDF/PNG/SVG figures
├── refs/                 # .bib files (BibLaTeX)
└── build/                # build artifacts (gitignored)
```

## Build

The lab uses **`pdflatex` via `latexmk`**, with `biber` for
references. The toolchain is TeX Live (`texlive-latex-extra`,
`texlive-fonts-recommended`, `texlive-fonts-extra`, `texlive-science`,
`texlive-publishers`).

```bash
make            # build the master PDF
make clean      # remove build artifacts
make distclean  # remove build artifacts AND the final PDF
make watch      # rebuild on file change
make spelling   # run ltex for prose spell/lint
```

The CI workflow [`../.github/workflows/latex-build.yml`](../.github/workflows/latex-build.yml)
runs `make` and uploads the resulting PDF as a workflow artifact.

## Section conventions

Each file in `sections/` is a chapter-level unit. New documents
should:

1. Add a new `NN-short-name.tex` file in `sections/`.
2. Add a `\input{sections/NN-short-name}` line to `main.tex` in the
   correct order.
3. Update the table of contents in `sections/00-frontmatter.tex`
   if the document is a first-class deliverable.
4. Update the `latex/README.md` section list if you want the build
   tooling to track it.

## Syncing with `docs/`

Markdown is the source of truth. When you update `docs/`:

- Re-author the corresponding `sections/*.tex` file.
- Do not edit the LaTeX without updating the Markdown.
- For small changes, edit both in the same commit.
- For large changes, land the Markdown first, then land the LaTeX
  in a follow-up commit that references the first.

This is a deliberate bias toward the living documentation.
