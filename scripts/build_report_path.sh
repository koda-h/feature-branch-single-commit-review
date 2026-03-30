#!/usr/bin/env bash
set -euo pipefail

branch=""
timestamp=""
reuse_latest=0

usage() {
  cat <<'EOF'
Usage:
  build_report_path.sh [--branch <branch>] [--timestamp <YYYYMMDDHHMM>] [--reuse-latest]

Outputs:
  docs/code_review/<sanitized-branch>_<timestamp>.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      branch="${2:-}"
      shift 2
      ;;
    --timestamp)
      timestamp="${2:-}"
      shift 2
      ;;
    --reuse-latest)
      reuse_latest=1
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$branch" ]]; then
  branch="$(git branch --show-current)"
fi

if [[ -z "$branch" ]]; then
  echo "Current branch could not be determined" >&2
  exit 2
fi

if [[ -z "$timestamp" ]]; then
  timestamp="$(date +%Y%m%d%H%M)"
fi

sanitized_branch="${branch//\//-}"

if [[ "$reuse_latest" -eq 1 ]]; then
  latest_report="$(find docs/code_review -maxdepth 1 -type f -name "${sanitized_branch}_*.md" 2>/dev/null | sort | tail -n 1)"
  if [[ -n "$latest_report" ]]; then
    printf '%s\n' "$latest_report"
    exit 0
  fi
fi

printf 'docs/code_review/%s_%s.md\n' "$sanitized_branch" "$timestamp"
