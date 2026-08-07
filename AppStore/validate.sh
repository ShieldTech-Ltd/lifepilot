#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
metadata="$root/Metadata/en-GB"
errors=0

fail() {
  printf 'FAIL: %s\n' "$1"
  errors=$((errors + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

check_chars() {
  file=$1
  limit=$2
  label=$3
  count=$(tr -d '\n' < "$file" | wc -m | tr -d ' ')
  if [ "$count" -le "$limit" ]; then
    pass "$label is $count/$limit characters"
  else
    fail "$label is $count/$limit characters"
  fi
}

check_bytes() {
  file=$1
  limit=$2
  label=$3
  count=$(tr -d '\n' < "$file" | wc -c | tr -d ' ')
  if [ "$count" -le "$limit" ]; then
    pass "$label is $count/$limit UTF-8 bytes"
  else
    fail "$label is $count/$limit UTF-8 bytes"
  fi
}

check_chars "$metadata/name.txt" 30 "App name"
check_chars "$metadata/subtitle.txt" 30 "Subtitle"
check_chars "$metadata/promotional_text.txt" 170 "Promotional text"
check_chars "$metadata/description.txt" 4000 "Description"
check_bytes "$metadata/keywords.txt" 100 "Keywords"

em_dash=$(printf '\342\200\224')
if grep -R -n "$em_dash" "$root" >/dev/null 2>&1; then
  fail "App Store package contains an em dash"
else
  pass "App Store package contains no em dashes"
fi

check_images() {
  directory=$1
  width=$2
  height=$3
  label=$4
  count=0

  for image in "$directory"/*.jpg; do
    [ -f "$image" ] || continue
    count=$((count + 1))
    actual_width=$(sips -g pixelWidth "$image" | awk '/pixelWidth/ {print $2}')
    actual_height=$(sips -g pixelHeight "$image" | awk '/pixelHeight/ {print $2}')
    alpha=$(sips -g hasAlpha "$image" | awk '/hasAlpha/ {print $2}')

    if [ "$actual_width" = "$width" ] && [ "$actual_height" = "$height" ] && [ "$alpha" = "no" ]; then
      pass "$(basename "$image") is ${width}x${height} without alpha"
    else
      fail "$(basename "$image") is ${actual_width}x${actual_height}, alpha=$alpha; expected ${width}x${height}, alpha=no"
    fi
  done

  if [ "$count" -ge 1 ] && [ "$count" -le 10 ]; then
    pass "$label has $count screenshots"
  else
    fail "$label has $count screenshots; expected 1 to 10"
  fi
}

check_images "$root/Screenshots/en-GB/iPhone-6.9" 1320 2868 "iPhone 6.9-inch set"
check_images "$root/Screenshots/en-GB/iPad-13" 2064 2752 "iPad 13-inch set"

if [ "$errors" -ne 0 ]; then
  printf '\n%d validation check(s) failed.\n' "$errors"
  exit 1
fi

printf '\nAll local App Store package checks passed.\n'
