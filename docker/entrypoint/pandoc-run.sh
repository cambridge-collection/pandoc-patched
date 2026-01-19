#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar

pandoc_opts=()
inputs=()
output_override=""
target_ext=""

map_ext() {
  local fmt="$1"
  local base="${fmt%%[+-]*}"
  [[ -z "$base" ]] && base="html"

  declare -A ext_map=(
    [html]="html"
    [html5]="html"
    [html4]="html"
    [s5]="html"
    [slidy]="html"
    [slideous]="html"
    [dzslides]="html"
    [revealjs]="html"
    [markdown]="md"
    [markdown_strict]="md"
    [markdown_mmd]="md"
    [markdown_phpextra]="md"
    [markdown_github]="md"
    [commonmark]="md"
    [commonmark_x]="md"
    [gfm]="md"
    [rst]="rst"
    [mediawiki]="wiki"
    [dokuwiki]="txt"
    [zimwiki]="txt"
    [org]="org"
    [asciidoc]="adoc"
    [asciidoctor]="adoc"
    [latex]="tex"
    [beamer]="tex"
    [context]="tex"
    [pdf]="pdf"
    [rtf]="rtf"
    [odt]="odt"
    [docx]="docx"
    [pptx]="pptx"
    [opml]="opml"
    [docbook]="xml"
    [jats]="xml"
    [tei]="xml"
    [icml]="icml"
    [man]="man"
    [texinfo]="texi"
    [plain]="txt"
    [native]="native"
    [json]="json"
    [epub]="epub"
    [epub3]="epub"
  )

  if [[ -n "${ext_map[$base]:-}" ]]; then
    echo "${ext_map[$base]}"
  else
    echo "$base"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      inputs+=("$@")
      break
      ;;
    -o|--output)
      shift
      if [[ $# -eq 0 ]]; then
        echo "-o/--output requires a value" >&2
        exit 1
      fi
      output_override="$1"
      shift
      ;;
    -o=*|--output=*)
      output_override="${1#*=}"
      shift
      ;;
    -t|--to)
      pandoc_opts+=("$1")
      shift
      if [[ $# -eq 0 ]]; then
        echo "-t/--to requires a value" >&2
        exit 1
      fi
      target_ext="$1"
      pandoc_opts+=("$target_ext")
      shift
      ;;
    -t=*|--to=*)
      val="${1#*=}"
      target_ext="$val"
      # Normalize to "-t value" form.
      pandoc_opts+=("${1%%=*}" "$val")
      shift
      ;;
    -*)
      pandoc_opts+=("$1")
      shift
      ;;
    *)
      inputs+=("$1")
      shift
      ;;
  esac
done

if [[ ${#inputs[@]} -eq 0 ]]; then
  exec pandoc "${pandoc_opts[@]}"
fi

expanded_inputs=()
for pattern in "${inputs[@]}"; do
  mapfile -t matches < <(compgen -G "$pattern")
  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "No files match pattern: $pattern" >&2
    exit 1
  fi
  expanded_inputs+=("${matches[@]}")
done

inputs=("${expanded_inputs[@]}")

if [[ -n "$output_override" && ${#inputs[@]} -gt 1 ]]; then
  echo "-o/--output may only be used with a single input file" >&2
  exit 1
fi

ext="$(map_ext "${target_ext:-html}")"

for src in "${inputs[@]}"; do
  out="$output_override"
  if [[ -z "$out" ]]; then
    base="$(basename "$src")"
    base="${base%.*}"
    out="/data/${base}.${ext}"
  fi

  echo "Converting $src -> $out"
  pandoc "${pandoc_opts[@]}" "$src" -o "$out"
done
