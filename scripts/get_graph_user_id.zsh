#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Get Graph User ID
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Email or UPN" }

# Optional parameters:
# @raycast.icon 👤

# Documentation:
# @raycast.description Fetch an MS Graph user ID by email or UPN and copy it
# @raycast.author Esteban Vincent

USER_EMAIL="$1"

# shellcheck source=/dev/null
source "$HOME/Raycast/utils.zsh"
source "$HOME/Raycast/envs/get_graph_user.env"

for variable in AZURE_TENANT_ID AZURE_CLIENT_ID AZURE_CLIENT_SECRET; do
  if [[ -z "${(P)variable}" ]]; then
    echo "Missing $variable in get_graph_user.env"
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
  echo "Token request failed (HTTP $TOKEN_HTTP_STATUS): $TOKEN_ERROR"
  exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_BODY" | jq -r '.access_token // empty')
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "No access_token in response"
  exit 1
fi

ENCODED_USER_EMAIL=$(printf '%s' "$USER_EMAIL" | jq -Rr '@uri')
USER_URL="https://graph.microsoft.com/v1.0/users/${ENCODED_USER_EMAIL}?\$select=id"
USER_RESPONSE=$(curl -s -S -w "\n%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -X GET "$USER_URL")
CURL_EXIT=$?

USER_HTTP_STATUS=$(echo "$USER_RESPONSE" | tail -n1)
USER_BODY=$(echo "$USER_RESPONSE" | sed '$d')

if [[ $CURL_EXIT -ne 0 || "$USER_HTTP_STATUS" == "000" ]]; then
  echo "Graph API curl failed (exit $CURL_EXIT)"
  exit 1
fi

if [[ "$USER_HTTP_STATUS" == "404" ]]; then
  echo "User not found: $USER_EMAIL"
  exit 0
fi

if [[ "$USER_HTTP_STATUS" != "200" ]]; then
  GRAPH_ERROR=$(echo "$USER_BODY" | jq -r '.error.message // "unknown error"')
  GRAPH_CODE=$(echo "$USER_BODY" | jq -r '.error.code // "unknown"')
  echo "Graph API failed (HTTP $USER_HTTP_STATUS) [$GRAPH_CODE]: $GRAPH_ERROR"
  exit 1
fi

USER_ID=$(echo "$USER_BODY" | jq -r '.id // empty')
if [[ -z "$USER_ID" ]]; then
  echo "No user ID in response"
  exit 1
fi

printf '%s' "$USER_ID" | pbcopy
echo "Copied user ID: $USER_ID"
