#!/usr/bin/env bash
set -euo pipefail

base_branch="develop"

usage() {
  cat <<'EOF'
Usage:
  list_review_ranges.sh [--base develop]

Outputs (tab separated):
  index    from_sha    to_sha    from_short    to_short    subject
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_branch="${2:-}"
      shift 2
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

merge_base="$(git merge-base "$base_branch" HEAD)"

commits=()
while IFS= read -r commit; do
  commits+=("$commit")
done < <(git rev-list --reverse "${merge_base}..HEAD")

if [[ "${#commits[@]}" -eq 0 ]]; then
  echo "No commits found after merge-base with ${base_branch}" >&2
  exit 2
fi

prev="$merge_base"
index=1
for commit in "${commits[@]}"; do
  from_short="$(git rev-parse --short=8 "$prev")"
  to_short="$(git rev-parse --short=8 "$commit")"
  subject="$(git log -1 --format=%s "$commit")"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$index" "$prev" "$commit" "$from_short" "$to_short" "$subject"
  prev="$commit"
  index=$((index + 1))
done
