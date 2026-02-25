#!/usr/bin/env bash
set -euo pipefail

SRC=/tmp/certs
DST=/tmp/certsfinal
PASS="${PASS:-ChangeIt123!}"
OUT="$DST/truststore_final.jks"
BASE="$SRC/base-truststore.jks"

mkdir -p "$DST"
cp -L "$SRC"/*.pem "$DST"/

if [[ -f "$BASE" ]]; then
  keytool -importkeystore -noprompt \
    -srckeystore "$BASE" -srcstorepass "$PASS" \
    -destkeystore "$OUT"  -deststorepass "$PASS"
else
  first="$(ls "$DST"/*.pem | head -n 1)"
  keytool -importcert -noprompt -alias "init" -file "$first" \
    -keystore "$OUT" -storepass "$PASS"
fi

for pem in "$DST"/*.pem; do
  a="$(basename "$pem" .pem | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
  keytool -importcert -noprompt -alias "$a" -file "$pem" \
    -keystore "$OUT" -storepass "$PASS" || true
done

keytool -list -keystore "$OUT" -storepass "$PASS"