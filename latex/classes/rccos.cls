% !TEX root = main.tex
% RCC-OS document class.
% Lightweight wrapper around book with the lab's typographic conventions.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rccos}[2026/08/12 RCC-OS documentation class]

\LoadClass[11pt,a4paper,oneside,openany]{book}

\RequirePackage[a4paper,margin=1in,headheight=15pt]{geometry}
\RequirePackage{parskip}
\RequirePackage[svgnames]{xcolor}
\definecolor{rccosAccent}{HTML}{1B4F8C}
\RequirePackage{titlesec}
\titleformat{\chapter}[display]
  {\color{rccosAccent}\Huge\bfseries}
  {\thechapter}{0pt}{}
\titleformat{\section}
  {\color{rccosAccent}\Large\bfseries}
  {\thesection}{0.5em}{}
\titleformat{\subsection}
  {\color{rccosAccent}\large\bfseries}
  {\thesubsection}{0.4em}{}

\RequirePackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\nouppercase{\leftmark}}
\fancyhead[R]{\RCCOS}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.4pt}

\RequirePackage{enumitem}
\setlist{topsep=2pt,itemsep=1pt,parsep=0pt}
