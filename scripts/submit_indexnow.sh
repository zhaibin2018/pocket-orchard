#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_HOST="${INDEXNOW_HOST:-zhaibin2018.github.io}"
SITE_BASE="${INDEXNOW_SITE_BASE:-https://zhaibin2018.github.io/pocket-orchard}"
KEY="${INDEXNOW_KEY:-4f2cd436378891df86bb83c994906b52}"
KEY_LOCATION="${INDEXNOW_KEY_LOCATION:-$SITE_BASE/$KEY.txt}"
SITEMAP="$ROOT/sitemap.xml"

if [[ ! -f "$SITEMAP" ]]; then
  printf 'Missing sitemap: %s\n' "$SITEMAP" >&2
  exit 1
fi

URLS=()
while IFS= read -r url; do
  URLS+=("$url")
done < <(sed -n 's:.*<loc>\(.*\)</loc>.*:\1:p' "$SITEMAP")

if (( ${#URLS[@]} == 0 )); then
  printf 'No URLs found in sitemap: %s\n' "$SITEMAP" >&2
  exit 1
fi

PAYLOAD="$(python3 - "$SITE_HOST" "$KEY" "$KEY_LOCATION" "${URLS[@]}" <<'PY'
import json
import sys

host, key, key_location, *urls = sys.argv[1:]
print(json.dumps({
    "host": host,
    "key": key,
    "keyLocation": key_location,
    "urlList": urls,
}, separators=(",", ":")))
PY
)"

printf 'Submitting %s URLs to IndexNow for %s\n' "${#URLS[@]}" "$SITE_BASE"
printf '%s\n' "${URLS[@]}"

curl -fsS \
  -H "Content-Type: application/json; charset=utf-8" \
  -X POST \
  --data "$PAYLOAD" \
  "https://api.indexnow.org/IndexNow"

printf '\nIndexNow submission accepted.\n'
