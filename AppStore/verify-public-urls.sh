#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
metadata="$root/Metadata/en-GB"
errors=0

for field in privacy_url support_url; do
  url=$(tr -d '\n' < "$metadata/$field.txt")
  status=$(curl -L -sS -o /dev/null -w '%{http_code}' "$url" || true)

  if [ "$status" = "200" ]; then
    printf 'PASS: %s returns HTTP 200: %s\n' "$field" "$url"
  else
    printf 'FAIL: %s returns HTTP %s: %s\n' "$field" "$status" "$url"
    errors=$((errors + 1))
  fi
done

if [ "$errors" -ne 0 ]; then
  printf '\n%d public URL check(s) failed. Publish the privacy and support pages before submission.\n' "$errors"
  exit 1
fi

printf '\nAll public App Store URLs are live.\n'
