#!/usr/bin/env bash
set -euo pipefail

# Ejecuta el chequeo de certificados y envia correo solo si hay WARN/EXPIRED/FAIL.
# Variables opcionales:
#   ALERT_EMAIL=kronos00bot@gmail.com
#   ALERT_FROM=kronos00bot@gmail.com
#   WARN_DAYS=30
#   SMTP_CONFIG=/home/mloco/kronos-server/.secrets/ssmtp-gmail.conf

BASE_DIR="/home/mloco/kronos-server"
CHECK_SCRIPT="$BASE_DIR/scripts/check_traefik_certs.sh"
ALERT_EMAIL="${ALERT_EMAIL:-kronos00bot@gmail.com}"
ALERT_FROM="${ALERT_FROM:-kronos00bot@gmail.com}"
WARN_DAYS="${WARN_DAYS:-30}"
ALERT_LOG="${ALERT_LOG:-$BASE_DIR/traefik-cert-alerts.log}"
SMTP_CONFIG="${SMTP_CONFIG:-$BASE_DIR/.secrets/ssmtp-gmail.conf}"

if [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "ERROR: no existe o no es ejecutable: $CHECK_SCRIPT" >&2
  exit 2
fi

TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

set +e
WARN_DAYS="$WARN_DAYS" BASE_DIR="$BASE_DIR" ACME_FILE="$BASE_DIR/traefik/data/acme.json" "$CHECK_SCRIPT" >"$TMP_OUT" 2>&1
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  exit 0
fi

subject="[KRONOS][TLS] Alerta de certificados Traefik en $(hostname -s)"
alert_body="$({
  echo "Se detectaron problemas de certificados en Traefik."
  echo
  echo "Host: $(hostname -f 2>/dev/null || hostname)"
  echo "Fecha: $(date -Is)"
  echo "WARN_DAYS: $WARN_DAYS"
  echo "Exit code: $rc"
  echo
  echo "Resultado:"
  cat "$TMP_OUT"
})"

send_with_ssmtp() {
  if [[ ! -x /usr/sbin/ssmtp ]]; then
    return 1
  fi
  if [[ ! -f "$SMTP_CONFIG" ]]; then
    return 1
  fi

  {
    echo "To: $ALERT_EMAIL"
    echo "From: $ALERT_FROM"
    echo "Subject: $subject"
    echo
    printf '%s\n' "$alert_body"
  } | /usr/sbin/ssmtp -C "$SMTP_CONFIG" "$ALERT_EMAIL"
}

if ! send_with_ssmtp && ! printf '%s\n' "$alert_body" | mail -s "$subject" "$ALERT_EMAIL"; then
  {
    echo "[$(date -Is)] ERROR enviando correo a $ALERT_EMAIL"
    echo "$alert_body"
    echo
  } >> "$ALERT_LOG"
fi

exit $rc
