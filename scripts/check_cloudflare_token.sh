#!/usr/bin/env bash
set -euo pipefail

# Verifica que el token de Cloudflare usado por Traefik sea valido.
# Variables opcionales:
#   TOKEN_FILE=/home/mloco/kronos-server/traefik/cf_api_token.txt

TOKEN_FILE="${TOKEN_FILE:-/home/mloco/kronos-server/traefik/cf_api_token.txt}"

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "TOKEN_FILE_MISSING:$TOKEN_FILE"
  exit 2
fi

token="$(tr -d '\r\n' < "$TOKEN_FILE")"
if [[ -z "$token" ]]; then
  echo "TOKEN_EMPTY:$TOKEN_FILE"
  exit 2
fi

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

http_code="$(curl -sS -o "$tmp_json" -w '%{http_code}' \
  -H "Authorization: Bearer $token" \
  -H 'Content-Type: application/json' \
  'https://api.cloudflare.com/client/v4/user/tokens/verify')"

if [[ "$http_code" != "200" ]]; then
  echo "INVALID_HTTP:$http_code"
  exit 1
fi

if python3 - "$tmp_json" <<'PY'
import json
import sys

path = sys.argv[1]
obj = json.load(open(path, "r", encoding="utf-8"))
if obj.get("success") is True:
    print("TOKEN_OK")
    raise SystemExit(0)

errors = obj.get("errors") or []
codes = ",".join(str(e.get("code", "")) for e in errors if e)
messages = " | ".join((e.get("message", "") or "").replace("\n", " ") for e in errors if e)
print(f"TOKEN_INVALID:{codes}:{messages}")
raise SystemExit(1)
PY
then
  exit 0
fi

exit 1
