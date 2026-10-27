#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Get Public IPv4
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌐

# Documentation:
# @raycast.author Esteban Vincent

PUBLIC_IP=$(curl -s -4 --max-time 10 https://api.ipify.org)
echo -n "$PUBLIC_IP" | pbcopy
echo "Copied to clipboard! ✅"
