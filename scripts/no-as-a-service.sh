#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Random No
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ❌

# Documentation:
# @raycast.description Get a random rejection reason from No-as-a-Service
# @raycast.author Esteban Vincent

REASON=$(curl -s https://naas.isalman.dev/no | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
echo -n "$REASON" | pbcopy
echo "$REASON"
