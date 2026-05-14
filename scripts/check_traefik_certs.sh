#!/usr/bin/env bash
set -euo pipefail

# Verifica validez y vencimiento de certificados TLS en dominios de Traefik.
# Uso:
#   ./scripts/check_traefik_certs.sh
#   ./scripts/check_traefik_certs.sh dominio1 dominio2
# Variables opcionales:
#   WARN_DAYS=30
#   ACME_FILE=./traefik/data/acme.json

WARN_DAYS="${WARN_DAYS:-30}"
ACME_FILE="${ACME_FILE:-./traefik/data/acme.json}"

python3 - "$WARN_DAYS" "$ACME_FILE" "$@" <<'PY'
import json
import socket
import ssl
import sys
from datetime import datetime, timezone
from pathlib import Path

warn_days = int(sys.argv[1])
acme_file = Path(sys.argv[2])
arg_domains = [d.strip() for d in sys.argv[3:] if d.strip()]

def domains_from_acme(path: Path):
    if not path.exists():
        return []
    try:
        obj = json.loads(path.read_text())
    except Exception:
        return []
    found = set()
    for resolver_data in obj.values():
        for cert in resolver_data.get("Certificates", []):
            dom = cert.get("domain", {})
            main = dom.get("main")
            if main:
                found.add(main)
            for san in dom.get("sans", []) or []:
                if san:
                    found.add(san)
    return sorted(found)

if arg_domains:
    domains = sorted(set(arg_domains))
else:
    domains = domains_from_acme(acme_file)

if not domains:
    print(f"ERROR: no se encontraron dominios. Revisa ACME_FILE={acme_file} o pasa dominios por argumento.")
    sys.exit(2)

print("host,status,days_left,issuer_cn,not_after")
failed = False
for host in domains:
    try:
        ctx = ssl.create_default_context()
        with socket.create_connection((host, 443), timeout=10) as sock:
            with ctx.wrap_socket(sock, server_hostname=host) as ssock:
                cert = ssock.getpeercert()

        not_after = cert.get("notAfter")
        exp = datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        days_left = int((exp - now).total_seconds() // 86400)

        issuer_cn = ""
        for item in cert.get("issuer", []):
            for k, v in item:
                if k == "commonName":
                    issuer_cn = v
                    break
            if issuer_cn:
                break

        status = "OK"
        if days_left < 0:
            status = "EXPIRED"
            failed = True
        elif days_left <= warn_days:
            status = "WARN"
            failed = True

        print(f"{host},{status},{days_left},{issuer_cn},{exp.isoformat()}")
    except Exception as e:
        failed = True
        print(f"{host},FAIL,NA,NA,{str(e).replace(',', ';')}")

sys.exit(1 if failed else 0)
PY
