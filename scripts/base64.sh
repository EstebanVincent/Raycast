#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Base64
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔡
# @raycast.argument1 { "type": "text", "placeholder": "encode | decode" }
# @raycast.argument2 { "type": "text", "placeholder": "text, file path, or blank for clipboard", "optional": true }

# Documentation:
# @raycast.description Encode or decode base64. Handles text, file paths, and images.
# @raycast.author Esteban Vincent

MODE=$(echo "$1" | tr '[:upper:]' '[:lower:]')
INPUT="$2"

if [[ "$MODE" != "encode" && "$MODE" != "decode" ]]; then
  echo "❌ Mode must be 'encode' or 'decode'"
  exit 1
fi

# ── ENCODE ────────────────────────────────────────────────────────────────────
if [[ "$MODE" == "encode" ]]; then
  if [[ -n "$INPUT" && -f "$INPUT" ]]; then
    # File path → base64
    RESULT=$(base64 -i "$INPUT")
    echo -n "$RESULT" | pbcopy
    echo "File encoded → clipboard ✅"
  elif [[ -n "$INPUT" ]]; then
    # Plain text → base64
    RESULT=$(echo -n "$INPUT" | base64)
    echo -n "$RESULT" | pbcopy
    echo "Text encoded → clipboard ✅"
  else
    # Try clipboard image first, then fall back to text
    TMPFILE=$(mktemp /tmp/b64clipboard_XXXXXX)
    osascript -e "write (the clipboard as «class PNGf») to (open for access POSIX file \"$TMPFILE\" with write permission)" 2>/dev/null
    if [[ -s "$TMPFILE" ]]; then
      RESULT=$(base64 -i "$TMPFILE")
      rm -f "$TMPFILE"
      echo -n "$RESULT" | pbcopy
      echo "Clipboard image encoded → clipboard ✅"
    else
      rm -f "$TMPFILE"
      CLIPBOARD=$(pbpaste)
      if [[ -z "$CLIPBOARD" ]]; then
        echo "❌ Clipboard is empty"
        exit 1
      fi
      RESULT=$(echo -n "$CLIPBOARD" | base64)
      echo -n "$RESULT" | pbcopy
      echo "Clipboard text encoded → clipboard ✅"
    fi
  fi

# ── DECODE ────────────────────────────────────────────────────────────────────
else
  if [[ -n "$INPUT" ]]; then
    B64="$INPUT"
  else
    B64=$(pbpaste)
  fi

  if [[ -z "$B64" ]]; then
    echo "❌ No input provided"
    exit 1
  fi

  # Decode to a temp file to inspect content
  TMPFILE=$(mktemp /tmp/b64decode_XXXXXX)
  if ! echo "$B64" | base64 -d > "$TMPFILE" 2>/dev/null; then
    rm -f "$TMPFILE"
    echo "❌ Invalid base64 input"
    exit 1
  fi

  FILETYPE=$(file --brief --mime-type "$TMPFILE")

  case "$FILETYPE" in
    image/png)
      osascript -e "set the clipboard to (read (POSIX file \"$TMPFILE\") as «class PNGf»)"
      rm -f "$TMPFILE"
      echo "PNG decoded → clipboard 🖼️"
      ;;
    image/jpeg)
      osascript -e "set the clipboard to (read (POSIX file \"$TMPFILE\") as JPEG picture)"
      rm -f "$TMPFILE"
      echo "JPEG decoded → clipboard 🖼️"
      ;;
    image/gif|image/webp|image/*)
      # For other image types, copy the file path instead
      IMGFILE="/tmp/b64_image_$(date +%s).${FILETYPE##*/}"
      mv "$TMPFILE" "$IMGFILE"
      echo -n "$IMGFILE" | pbcopy
      echo "Image (${FILETYPE##*/}) saved → $IMGFILE, path copied ✅"
      ;;
    text/*)
      DECODED=$(cat "$TMPFILE")
      rm -f "$TMPFILE"
      echo -n "$DECODED" | pbcopy
      echo "Text decoded → clipboard ✅"
      ;;
    *)
      # Unknown binary — save to file, copy path
      OUTFILE="/tmp/b64_decoded_$(date +%s).bin"
      mv "$TMPFILE" "$OUTFILE"
      echo -n "$OUTFILE" | pbcopy
      echo "Binary decoded → $OUTFILE, path copied ✅"
      ;;
  esac
fi
