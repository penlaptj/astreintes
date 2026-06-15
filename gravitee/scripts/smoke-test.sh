#!/usr/bin/env bash
# Test rapide : verifie que la passerelle Gravitee proxie bien l'app astreintes.
set -euo pipefail

GW="${GRAVITEE_GATEWAY:-http://localhost:8082}"
PATH_PREFIX="${GRAVITEE_PATH:-/astreintes}"

echo "=> GET $GW$PATH_PREFIX/"
curl -i -s "$GW$PATH_PREFIX/" | head -n 20

echo
echo "=> Verification du rate limit (envoi rapide de 5 requetes)"
for i in {1..5}; do
  curl -s -o /dev/null -w "req $i -> HTTP %{http_code} | X-RateLimit-Remaining: %header{X-RateLimit-Remaining}\n" \
    "$GW$PATH_PREFIX/"
done

echo
echo "=> Headers ajoutes par Gravitee visibles cote backend uniquement (X-Forwarded-Through, X-Request-Id)."
