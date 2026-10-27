#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Add My IP to Eloquentia UAT Firewalls
# @raycast.mode fullOutput
# @raycast.argument1 { "type": "text", "placeholder": "IPv4 (default: my IP)", "optional": true }

# Optional parameters:
# @raycast.icon 🔥
# @raycast.packageName Azure

# Documentation:
# @raycast.description Add current public IPv4 to Storage, Cosmos Mongo vCore, Document Intelligence and Key Vault firewalls (Eloquentia UAT)
# @raycast.author Esteban Vincent

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

TENANT="lpl.onmicrosoft.com"
SUBSCRIPTION="501a539e-6753-4fc2-9041-7a7985eed35f"
RESOURCE_GROUP="rg-eloquentia-we1-uat"
STORAGE_ACCOUNT="sastdelqtwe1uat"
MONGO_CLUSTER="cosmosdb-mongo-elqt-we1-uat"
COGNITIVE_ACCOUNT="csdi-eloquentia-we1-uat"
KEY_VAULT="kv-elqt-we1-uat"
MONGO_API_VERSION="2024-07-01"

if ! az account show --subscription "$SUBSCRIPTION" >/dev/null 2>&1; then
  echo "🔑 Not logged in, opening browser for az login..."
  # Disable the interactive subscription picker (no TTY under Raycast)
  if ! AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$TENANT" -o none; then
    echo "❌ az login failed"
    exit 1
  fi
  if ! az account show --subscription "$SUBSCRIPTION" >/dev/null 2>&1; then
    echo "❌ Logged in, but no access to subscription $SUBSCRIPTION"
    exit 1
  fi
  echo
fi

if [[ -n "$1" ]]; then
  IP="${1// /}"
  IP_SOURCE="Provided IP"
else
  # Firewalls only accept IPv4, so use the IPv4-only endpoint
  IP=$(curl -s -4 --max-time 10 https://api.ipify.org)
  IP_SOURCE="Public IP"
fi
if [[ ! "$IP" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] \
  || (( match[1] > 255 || match[2] > 255 || match[3] > 255 || match[4] > 255 )); then
  echo "❌ Invalid IPv4: '$IP'"
  exit 1
fi
echo "🌐 $IP_SOURCE: $IP"
echo

FAILED=0

echo "📦 Storage account: $STORAGE_ACCOUNT"
EXISTING=$(az storage account network-rule list \
  --subscription "$SUBSCRIPTION" -g "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" \
  --query "length(ipRules[?ipAddressOrRange=='$IP'])" -o tsv 2>&1)
if [[ "$EXISTING" == "0" ]]; then
  if az storage account network-rule add \
    --subscription "$SUBSCRIPTION" -g "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" \
    --ip-address "$IP" -o none; then
    echo "   ✅ Added"
  else
    echo "   ❌ Failed"; FAILED=1
  fi
elif [[ "$EXISTING" =~ ^[0-9]+$ ]]; then
  echo "   ✅ Already present"
else
  echo "   ❌ $EXISTING"; FAILED=1
fi

echo "🍃 Cosmos DB Mongo cluster: $MONGO_CLUSTER"
RULE_NAME="ClientIP-${IP//./-}"
MONGO_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.DocumentDB/mongoClusters/${MONGO_CLUSTER}/firewallRules/${RULE_NAME}?api-version=${MONGO_API_VERSION}"
if az rest --method put --url "$MONGO_URL" \
  --body "{\"properties\":{\"startIpAddress\":\"$IP\",\"endIpAddress\":\"$IP\"}}" -o none; then
  echo "   ✅ Rule '$RULE_NAME' created/updated (applies asynchronously)"
else
  echo "   ❌ Failed"; FAILED=1
fi

echo "🧠 Document Intelligence: $COGNITIVE_ACCOUNT"
EXISTING=$(az cognitiveservices account network-rule list \
  --subscription "$SUBSCRIPTION" -g "$RESOURCE_GROUP" -n "$COGNITIVE_ACCOUNT" \
  --query "length(ipRules[?value=='$IP' || value=='$IP/32'])" -o tsv 2>&1)
if [[ "$EXISTING" == "0" ]]; then
  if az cognitiveservices account network-rule add \
    --subscription "$SUBSCRIPTION" -g "$RESOURCE_GROUP" -n "$COGNITIVE_ACCOUNT" \
    --ip-address "$IP" -o none; then
    echo "   ✅ Added"
  else
    echo "   ❌ Failed"; FAILED=1
  fi
elif [[ "$EXISTING" =~ ^[0-9]+$ ]]; then
  echo "   ✅ Already present"
else
  echo "   ❌ $EXISTING"; FAILED=1
fi

echo "🔐 Key Vault: $KEY_VAULT"
EXISTING=$(az keyvault network-rule list \
  --subscription "$SUBSCRIPTION" -g "$RESOURCE_GROUP" -n "$KEY_VAULT" \
  --query "length(ipRules[?value=='$IP' || value=='$IP/32'])" -o tsv 2>&1)
if [[ "$EXISTING" == "0" ]]; then
  if az keyvault network-rule add \
    --subscription "$SUBSCRIPTION" -g "$RESOURCE_GROUP" -n "$KEY_VAULT" \
    --ip-address "$IP/32" -o none; then
    echo "   ✅ Added"
  else
    echo "   ❌ Failed"; FAILED=1
  fi
elif [[ "$EXISTING" =~ ^[0-9]+$ ]]; then
  echo "   ✅ Already present"
else
  echo "   ❌ $EXISTING"; FAILED=1
fi

echo
if (( FAILED )); then
  echo "⚠️ Some firewalls were not updated"
  exit 1
fi
echo "🎉 $IP allowed on all 4 resources"
