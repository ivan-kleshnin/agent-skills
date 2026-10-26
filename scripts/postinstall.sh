#!/usr/bin/env bash
#
# Post-install fix for the shared checklists.
#
# `npx skills add` copies only `skills/<name>/`, so the `../../references/<file>.md`
# links inside each SKILL.md have no target once installed. This script symlinks
# the repo-root `references/` directory next to every `skills/` directory it
# finds, which is where those paths land:
#
#   <base>/.agents/skills/<name>/SKILL.md  ->  <base>/.agents/references/<file>.md
#
# It looks in the current directory and in $HOME, so project and global installs
# are both covered. The links point at this checkout, so `git pull` updates the
# checklists without reinstalling.

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
refs="$repo_root/references"

if [[ ! -d "$refs" ]]; then
  echo "no references/ in $repo_root" >&2
  exit 1
fi

linked=0
while IFS= read -r skills_dir; do
  [[ -d "$skills_dir" ]] || continue
  [[ -n "$(ls -A "$skills_dir" 2>/dev/null)" ]] || continue

  parent="$(dirname "$skills_dir")"
  [[ "$parent" == "$repo_root" ]] && continue

  target="$parent/references"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "skip $target: exists, not a symlink" >&2
    continue
  fi

  ln -sfn "$refs" "$target"
  echo "linked $target"
  linked=$((linked + 1))
done < <(printf '%s\n' "$PWD"/.[!.]*/skills "$PWD"/*/skills "$HOME"/.[!.]*/skills "$HOME"/*/skills | sort -u)

echo "linked $linked director$([[ "$linked" -eq 1 ]] && echo y || echo ies)"
