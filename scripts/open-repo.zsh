#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Repo in Finder
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "repo name" }

# Optional parameters:
# @raycast.icon 📁
# @raycast.description Fuzzy search repos and open best match in Finder (configure roots in open-repo.env)

# Documentation:
# @raycast.author Esteban Vincent

# shellcheck source=/dev/null
source "$HOME/Raycast/utils.zsh"

load_env || exit 1

# Collect REPO_ROOT_1, REPO_ROOT_2, … into an array
roots=()
i=1
while true; do
  varname="REPO_ROOT_$i"
  val="${(P)varname}"
  [[ -z "$val" ]] && break
  roots+=("$val")
  (( i++ ))
done

if [[ ${#roots[@]} -eq 0 ]]; then
  echo "❌ No REPO_ROOT_* defined in open-repo.env"
  exit 1
fi

selected=$(
  find "${roots[@]}" \
    -mindepth 1 -maxdepth "${REPO_DEPTH:-3}" -type d 2>/dev/null \
  | fzf --filter="$1" \
  | head -1
)

if [[ -z "$selected" ]]; then
  echo "No match for '$1'"
  exit 1
fi

open "$selected"
echo "Opened: ${selected##*/}"
