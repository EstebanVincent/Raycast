#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Generate Meme
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🖼️
# @raycast.argument1 { "type": "text", "placeholder": "meme query" }

# Documentation:
# @raycast.description Generate a meme via imgflip webhook and copy image to clipboard
# @raycast.author Esteban Vincent

# shellcheck source=/dev/null
source "$HOME/Raycast/utils.sh"
load_env N8N_WEBHOOK_BASE_URL N8N_WEBHOOK_IMGFLIP_API_KEY || exit 1

QUERY="$1"
TMPFILE=$(mktemp /tmp/meme_XXXXXX.jpg)

echo "⏳ Generating meme..."
RESPONSE=$(curl -s --request POST \
  --url "$N8N_WEBHOOK_BASE_URL/imgflip" \
  --header "apiKey: $N8N_WEBHOOK_IMGFLIP_API_KEY" \
  --header 'content-type: application/json' \
  --data "{\"query\": \"$QUERY\"}")

IMAGE_URL=$(echo "$RESPONSE" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')

if [ -z "$IMAGE_URL" ]; then
  echo "Failed to generate meme ❌"
  rm -f "$TMPFILE"
  exit 1
fi

curl -s -o "$TMPFILE" "$IMAGE_URL"

osascript -e "set the clipboard to (read (POSIX file \"$TMPFILE\") as JPEG picture)"

rm -f "$TMPFILE"
echo "Meme copied to clipboard! 🖼️"
