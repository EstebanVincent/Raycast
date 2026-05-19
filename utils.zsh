#!/bin/zsh
# Helper: source this file, then call load_env
# Usage: source "$HOME/Raycast/utils/load_env.sh"
#        load_env VAR1 VAR2 VAR3 || exit 1
# Side-effect: sets LOADED_ENV_FILE to the resolved path

load_env() {
  local caller
  caller="$(basename "${funcfiletrace[1]%:*}" .zsh)"
  LOADED_ENV_FILE="$HOME/Raycast/envs/${caller}.env"

  if [[ ! -f "$LOADED_ENV_FILE" ]]; then
    echo "❌ .env not found at $LOADED_ENV_FILE"
    return 1
  fi

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    # Strip optional leading 'export '
    line="${line#export }"
    key="${line%%=*}"
    value="${line#*=}"
    # Strip surrounding quotes (preserves all chars inside, including $)
    if [[ "$value" == \"*\" ]]; then
      value="${value#\"}"
      value="${value%\"}"
    elif [[ "$value" == "'"*"'" ]]; then
      value="${value#"'"}"
      value="${value%"'"}"
    fi
    export "$key=$value"
  done < "$LOADED_ENV_FILE"

  for var in "$@"; do
    if [[ -z "${(P)var}" ]]; then
      echo "❌ Missing $var in .env"
      return 1
    fi
  done
}
