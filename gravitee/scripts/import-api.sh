#!/usr/bin/env bash
# Importe une definition d'API dans Gravitee APIM via le Management API.
# Usage : ./import-api.sh ../apis/astreintes-api.json

set -euo pipefail

MGMT_API="${GRAVITEE_MGMT_API:-http://localhost:8083}"
ORG="${GRAVITEE_ORG:-DEFAULT}"
ENV="${GRAVITEE_ENV:-DEFAULT}"
USER="${GRAVITEE_USER:-admin}"
PASSWORD="${GRAVITEE_PASSWORD:-admin}"

API_FILE="${1:?Chemin du fichier de definition API requis}"

if [[ ! -f "$API_FILE" ]]; then
  echo "Fichier introuvable : $API_FILE" >&2
  exit 1
fi

echo "=> Import de $API_FILE vers $MGMT_API ($ORG/$ENV)"

WRAPPED=$(mktemp)
trap 'rm -f "$WRAPPED"' EXIT
{ printf '{"apiExport":'; cat "$API_FILE"; printf '}'; } > "$WRAPPED"

curl -fsS -X POST \
  -u "$USER:$PASSWORD" \
  -H "Content-Type: application/json" \
  --data-binary "@$WRAPPED" \
  "$MGMT_API/management/v2/organizations/$ORG/environments/$ENV/apis/_import/definition" \
  | tee /tmp/gravitee-import.json

echo
echo "=> API importee. A activer manuellement dans la console (http://localhost:8084) : Deploy + Start."
