#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Get Graph User
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "User ID or UPN" }

# Optional parameters:
# @raycast.icon 👤

# Documentation:
# @raycast.description Fetch MS Graph user info by ID or UPN
# @raycast.author Esteban Vincent

USER_ID="$1"

ENV_FILE="$HOME/Raycast/envs/get_graph_user.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env not found at $ENV_FILE"
  exit 1
fi

set -o allexport
# shellcheck source=/dev/null
source "$ENV_FILE"
set +o allexport

for var in AZURE_TENANT_ID AZURE_CLIENT_ID AZURE_CLIENT_SECRET; do
  if [[ -z "${!var}" ]]; then
    echo "❌ Missing $var in .env"
    exit 1
  fi
done

TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
  -d "client_id=${AZURE_CLIENT_ID}" \
  --data-urlencode "client_secret=${AZURE_CLIENT_SECRET}" \
  -d "scope=https://graph.microsoft.com/.default" \
  -d "grant_type=client_credentials")

TOKEN_HTTP_STATUS=$(echo "$TOKEN_RESPONSE" | tail -n1)
TOKEN_BODY=$(echo "$TOKEN_RESPONSE" | sed '$d')

if [[ "$TOKEN_HTTP_STATUS" != "200" ]]; then
  TOKEN_ERROR=$(echo "$TOKEN_BODY" | jq -r '.error_description // .error // "unknown error"')
  echo "❌ Token request failed (HTTP $TOKEN_HTTP_STATUS): $TOKEN_ERROR"
  exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_BODY" | jq -r '.access_token // empty')
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "❌ No access_token in response: $TOKEN_BODY"
  exit 1
fi

ENCODED_USER_ID=$(printf '%s' "$USER_ID" | jq -Rr '@uri')
USER_URL="https://graph.microsoft.com/v1.0/users/${ENCODED_USER_ID}?\$select=mail"
CURL_ERR_FILE=$(mktemp)
USER_RESPONSE=$(curl -s -S -w "\n%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -X GET "$USER_URL" 2>"$CURL_ERR_FILE")
CURL_EXIT=$?

USER_HTTP_STATUS=$(echo "$USER_RESPONSE" | tail -n1)
USER_BODY=$(echo "$USER_RESPONSE" | sed '$d')

if [[ $CURL_EXIT -ne 0 || "$USER_HTTP_STATUS" == "000" ]]; then
  CURL_ERR=$(cat "$CURL_ERR_FILE")
  rm -f "$CURL_ERR_FILE"
  echo "❌ Graph API curl failed (exit $CURL_EXIT): $CURL_ERR"
  exit 1
fi
rm -f "$CURL_ERR_FILE"

if [[ "$USER_HTTP_STATUS" == "404" ]]; then
  echo "⚠️ User not found: $USER_ID"
  exit 0
fi

if [[ "$USER_HTTP_STATUS" != "200" ]]; then
  GRAPH_ERROR=$(echo "$USER_BODY" | jq -r '.error.message // "unknown error"')
  GRAPH_CODE=$(echo "$USER_BODY" | jq -r '.error.code // "unknown"')
  echo "❌ Graph API failed (HTTP $USER_HTTP_STATUS) [$GRAPH_CODE]: $GRAPH_ERROR"
  exit 1
fi

MAIL=$(echo "$USER_BODY" | jq -r '.mail // .userPrincipalName // "N/A"')

echo "$MAIL"
