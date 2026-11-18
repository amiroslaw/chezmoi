#!/bin/bash

# Parse command line arguments
# Supported usages:
#   adoc.sh html <file.adoc>
#   adoc.sh pdf <file.adoc>
#   adoc.sh <file.adoc> html
#   adoc.sh <file.adoc> pdf
#   adoc.sh -t <html|pdf> <file.adoc>

TYPE=""
INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    html|HTML|--html)
      TYPE="html"
      shift
      ;;
    pdf|PDF|--pdf)
      TYPE="pdf"
      shift
      ;;
    -t|--type)
      TYPE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [html|pdf] <file.adoc>"
      echo "       $0 <file.adoc> [html|pdf]"
      echo "       $0 -t [html|pdf] <file.adoc>"
      exit 0
      ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
      elif [[ -z "$TYPE" ]]; then
        TYPE="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  echo "Error: No AsciiDoc file provided."
  echo "Usage: $0 [html|pdf] <file.adoc>"
  exit 1
fi

# Default to html if type is omitted
if [[ -z "$TYPE" ]]; then
  TYPE="html"
fi

TYPE=$(echo "$TYPE" | tr '[:upper:]' '[:lower:]')

# Shared document attributes & options
COMMON_OPTS=(
  -r asciidoctor-kroki
  -a source-highlighter=highlight.js
  -a source-language=java
  -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin,clojure,fennel,bash
  -a hardbreaks=true
  -a experimental=true
  -a toc=left
  -a toclevels=5
  -a icons=font@
  -a allow-uri-read=true
  -a sectanchors=true
  -a sectlinks=true
  -a table-stripes=even
  -a imagesoutdir=./img
  -a imagesdir=./img
  -a plantuml-format=svg
)

case "$TYPE" in
  html)
    # Kill previous watcher
    pkill -f "watchexec" 2>/dev/null || true

    HTML_OUT="${NOTE:+$NOTE/}preview.html"

    # # --fs-events modify 

    # asciidoctorj -o "$NOTE/preview.html" \
    nohup watchexec --poll 200ms --restart --watch "$INPUT" -- \
      asciidoctor.ruby4.0 -o "$HTML_OUT" \
        -b html5 \
        "${COMMON_OPTS[@]}" \
        "$INPUT" \
      >/dev/null 2>&1 &

    "${BROWSER:-qutebrowser}" "$HTML_OUT" &
    ;;

  pdf)
    PDF_OUT="${INPUT%.*}.pdf"

    asciidoctor.ruby4.0 -o "$PDF_OUT" \
      -b pdf \
      -r asciidoctor-pdf \
      "${COMMON_OPTS[@]}" \
      "$INPUT"
    # >/dev/null 2>&1 &
    ;;

  *)
    echo "Error: Unsupported type '$TYPE'. Please use 'html' or 'pdf'."
    exit 1
    ;;
esac

# -----------------------------------------------------------------------------
# Useful reference comments and alternative configurations preserved from:
# ascii-pdf.sh & preview-ascii.sh
# -----------------------------------------------------------------------------
#
# ls "$1" | entr -n asciidoctor -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true -a backend=html5 -a sectanchors=true -a sectlinks=true -a table-stripes=even  -a imagesoutdir=./img -a imagesdir=./img -a plantuml-format=svg "$1" &
#
# bug with asciidoctor-diagram
# ls "$1" | entr -n asciidoctor -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true -a backend=html5 -a sectanchors=true -a sectlinks=true -a table-stripes=even -r asciidoctor-diagram -a imagesoutdir=./img -a imagesdir=./img -a plantuml-format=svg "$1" &
#
# --trace debug
#
# ls "$1" | entr -n asciidoctor -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true "$1" &
#
# outdir
# outfile
# iconsdir
#
# https://docs.asciidoctor.org/asciidoc/latest/attributes/document-attributes-ref/#source-highlighting-and-formatting-attributes
#
# asciidocFX:
# allow-uri-read=true
# showtitle=true
# idprefix=true is def
# apply-data-line=true ??
# apply-image-cacher=true
# imagesdir=images
#
#
# source-highlighter=highlight.js
# * coderay
# * highlight.js
# * pygments
# * rouge
#
#
# :doctype: article
# :encoding: utf-8
# :lang: en
# :toc: left
# :numbered:
#
# watchexec --watch "$1" -- asciidoc -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true -a backend=html5 -a sectanchors=true -a sectlinks=true -a table-stripes=even  -a imagesoutdir=./img -a imagesdir=./img -a plantuml-format=svg "$1" &
