#!/usr/bin/env bash
set -euo pipefail

base_branch="develop"
target_commit=""

usage() {
  cat <<'EOF'
Usage:
  resolve_target_commit.sh [--base develop] [--commit <sha>]

Outputs:
  current_branch=<branch>
  merge_base=<sha>
  commit_count=<n>
  target_commit=<sha>
  parent_commit=<sha>
  diff_range=<parent>..<target>
  target_subject=<subject>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_branch="${2:-}"
      shift 2
      ;;
    --commit)
      target_commit="${2:-}"
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

if [[ -z "$base_branch" ]]; then
  echo "base branch is required" >&2
  exit 1
fi

current_branch="$(git branch --show-current)"
merge_base="$(git merge-base "$base_branch" HEAD)"

commits=()
while IFS= read -r commit; do
  commits+=("$commit")
done < <(git rev-list --reverse "${merge_base}..HEAD")

if [[ "${#commits[@]}" -eq 0 ]]; then
  echo "No commits found after merge-base with ${base_branch}" >&2
  exit 2
fi

if [[ -n "$target_commit" ]]; then
  found=0
  for commit in "${commits[@]}"; do
    if [[ "$commit" == "$target_commit" ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -ne 1 ]]; then
    echo "Specified commit is not in ${base_branch}..HEAD: ${target_commit}" >&2
    exit 3
  fi
else
  last_index=$((${#commits[@]} - 1))
  target_commit="${commits[$last_index]}"
fi

parent_commit="$(git rev-parse "${target_commit}^")"
target_subject="$(git log -1 --format=%s "$target_commit")"

printf 'current_branch=%s\n' "$current_branch"
printf 'merge_base=%s\n' "$merge_base"
printf 'commit_count=%s\n' "${#commits[@]}"
printf 'target_commit=%s\n' "$target_commit"
printf 'parent_commit=%s\n' "$parent_commit"
printf 'diff_range=%s..%s\n' "$parent_commit" "$target_commit"
printf 'target_subject=%s\n' "$target_subject"
