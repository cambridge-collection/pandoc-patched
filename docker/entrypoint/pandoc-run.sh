#!/usr/bin/env bash
set -euo pipefail

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

split_and_expand() {
  local start="$1"
  local candidate=""
  local i before

  if (( start >= ${#tokens[@]} )); then
    split_result=("${working_matches[@]}")
    return 0
  fi

  for (( i=start; i<${#tokens[@]}; i++ )); do
    if [[ -z "$candidate" ]]; then
      candidate="${tokens[i]}"
    else
      candidate+=" ${tokens[i]}"
    fi

    if compgen -G "$candidate" > /dev/null; then
      before=${#working_matches[@]}
      while IFS=$'\n' read -r match; do
        working_matches+=("$match")
      done < <(compgen -G "$candidate")

      if split_and_expand $((i + 1)); then
        return 0
      fi

      working_matches=("${working_matches[@]:0:$before}")
    fi
  done

  return 1
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
tokens=()
for pattern in "${inputs[@]}"; do
  matches=()

  if compgen -G "$pattern" > /dev/null; then
    while IFS=$'\n' read -r match; do
      matches+=("$match")
    done < <(compgen -G "$pattern")
  else
    tokens=()
    read -r -a tokens <<< "$pattern"

    if [[ ${#tokens[@]} -gt 1 ]]; then
      working_matches=()
      split_result=()
      if split_and_expand 0; then
        matches=("${split_result[@]}")
      else
        echo "No files match pattern: $pattern" >&2
        exit 1
      fi
    else
      echo "No files match pattern: $pattern" >&2
      exit 1
    fi
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
