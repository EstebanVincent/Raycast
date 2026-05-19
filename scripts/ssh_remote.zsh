#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title SSH Remote
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Target (e.g. pi4, pi4vpn, pi5)" }

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.description SSH into any remote — prefix maps to {PREFIX}_ADDRESS and {PREFIX}_PASSWORD in ssh_remote.env

# Documentation:
# @raycast.author Esteban Vincent

# shellcheck source=/dev/null
source "$HOME/Raycast/utils.zsh"

PREFIX=$(echo "$1" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
ADDRESS_VAR="${PREFIX}_ADDRESS"
PASSWORD_VAR="${PREFIX}_PASSWORD"

load_env "$ADDRESS_VAR" "$PASSWORD_VAR" || exit 1

ADDRESS="${(P)ADDRESS_VAR}"
PASSWORD="${(P)PASSWORD_VAR}"

if [[ -n "$PASSWORD" ]]; then
  SSH_CMD="sshpass -p '${PASSWORD}' ssh ${ADDRESS}"
else
  SSH_CMD="ssh ${ADDRESS}"
fi

osascript \
  -e "tell application \"Terminal\" to do script \"${SSH_CMD}\"" \
  -e "tell application \"Terminal\" to activate"

echo "Connecting to $1 ($ADDRESS)"
