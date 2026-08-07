#!/bin/sh

set -eu

archive=${1:-/tmp/LifePilot-Launch.xcarchive}
allow_development=${ALLOW_DEVELOPMENT:-0}
app="$archive/Products/Applications/LifePilot.app"
app_info="$app/Info.plist"
widget="$app/PlugIns/LifePilotWidgets.appex"
share="$app/PlugIns/LifePilotShareExtension.appex"
errors=0

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  errors=$((errors + 1))
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null
}

check_value() {
  value_file=$1
  value_key=$2
  value_expected=$3
  value_label=$4
  value_actual=$(plist_value "$value_file" "$value_key" || true)

  if [ "$value_actual" = "$value_expected" ]; then
    pass "$value_label is $value_expected"
  else
    fail "$value_label is '$value_actual'; expected '$value_expected'"
  fi
}

check_file() {
  path_file=$1
  path_label=$2
  if [ -e "$path_file" ]; then
    pass "$path_label is embedded"
  else
    fail "$path_label is missing at $path_file"
  fi
}

check_privacy_manifest() {
  privacy_file=$1
  privacy_label=$2
  privacy_required_reason=$3

  check_file "$privacy_file" "$privacy_label privacy manifest"
  [ -f "$privacy_file" ] || return

  if plutil -lint "$privacy_file" >/dev/null; then
    pass "$privacy_label privacy manifest is valid"
  else
    fail "$privacy_label privacy manifest is invalid"
  fi

  privacy_tracking=$(plutil -extract NSPrivacyTracking raw -o - "$privacy_file" 2>/dev/null || true)
  privacy_collected=$(plutil -extract NSPrivacyCollectedDataTypes json -o - "$privacy_file" 2>/dev/null || true)
  privacy_accessed=$(plutil -extract NSPrivacyAccessedAPITypes json -o - "$privacy_file" 2>/dev/null || true)

  if [ "$privacy_tracking" = "false" ]; then
    pass "$privacy_label declares no tracking"
  else
    fail "$privacy_label tracking declaration is '$privacy_tracking'"
  fi

  if [ "$privacy_collected" = "[]" ]; then
    pass "$privacy_label declares no collected data"
  else
    fail "$privacy_label collected-data declaration is not empty"
  fi

  if printf '%s' "$privacy_accessed" | grep -F "$privacy_required_reason" >/dev/null; then
    pass "$privacy_label includes required-reason code $privacy_required_reason"
  else
    fail "$privacy_label is missing required-reason code $privacy_required_reason"
  fi
}

check_entitlements() {
  entitlement_bundle=$1
  entitlement_label=$2
  entitlement_output=$(codesign -d --entitlements - "$entitlement_bundle" 2>&1 || true)

  if printf '%s' "$entitlement_output" | grep -F 'group.com.ritiksah.lifepilot' >/dev/null; then
    pass "$entitlement_label has the shared App Group entitlement"
  else
    fail "$entitlement_label is missing the shared App Group entitlement"
  fi

  if printf '%s' "$entitlement_output" | grep -F '[Bool] true' >/dev/null; then
    if [ "$allow_development" = "1" ]; then
      warn "$entitlement_label has get-task-allow enabled for local development"
    else
      fail "$entitlement_label has get-task-allow enabled; an App Store build must disable it"
    fi
  else
    pass "$entitlement_label does not enable get-task-allow"
  fi
}

if [ ! -d "$archive" ]; then
  printf 'FAIL: archive not found: %s\n' "$archive"
  exit 1
fi

check_file "$app" "LifePilot app bundle"
[ -d "$app" ] || exit 1

check_value "$app_info" CFBundleIdentifier com.ritiksah.lifepilot "App bundle identifier"
check_value "$app_info" CFBundleShortVersionString 0.5.0 "Marketing version"
check_value "$app_info" CFBundleVersion 1 "Build number"
check_value "$app_info" MinimumOSVersion 17.0 "Minimum iOS version"
check_value "$app_info" ITSAppUsesNonExemptEncryption false "Non-exempt encryption declaration"
check_value "$app_info" NSSupportsLiveActivities true "Live Activities declaration"

device_family=$(plist_value "$app_info" UIDeviceFamily || true)
if printf '%s' "$device_family" | grep -F '1' >/dev/null && printf '%s' "$device_family" | grep -F '2' >/dev/null; then
  pass "Archive supports both iPhone and iPad"
else
  fail "Archive UIDeviceFamily is incomplete: $device_family"
fi

check_file "$widget" "Widget extension"
check_file "$share" "Share extension"

if [ -d "$widget" ]; then
  check_value "$widget/Info.plist" CFBundleIdentifier com.ritiksah.lifepilot.widgets "Widget bundle identifier"
  check_value "$widget/Info.plist" CFBundleShortVersionString 0.5.0 "Widget marketing version"
  check_value "$widget/Info.plist" CFBundleVersion 1 "Widget build number"
  check_value "$widget/Info.plist" NSExtension:NSExtensionPointIdentifier com.apple.widgetkit-extension "Widget extension point"
fi

if [ -d "$share" ]; then
  check_value "$share/Info.plist" CFBundleIdentifier com.ritiksah.lifepilot.share "Share bundle identifier"
  check_value "$share/Info.plist" CFBundleShortVersionString 0.5.0 "Share marketing version"
  check_value "$share/Info.plist" CFBundleVersion 1 "Share build number"
  check_value "$share/Info.plist" NSExtension:NSExtensionPointIdentifier com.apple.share-services "Share extension point"
fi

check_privacy_manifest "$app/PrivacyInfo.xcprivacy" "App" "CA92.1"
check_privacy_manifest "$widget/PrivacyInfo.xcprivacy" "Widget" "1C8F.1"
check_privacy_manifest "$share/PrivacyInfo.xcprivacy" "Share extension" "1C8F.1"

check_entitlements "$app" "App"
[ ! -d "$widget" ] || check_entitlements "$widget" "Widget"
[ ! -d "$share" ] || check_entitlements "$share" "Share extension"

identity=$(plist_value "$archive/Info.plist" ApplicationProperties:SigningIdentity || true)
case "$identity" in
  Apple\ Distribution:*)
    pass "Archive uses Apple Distribution signing"
    ;;
  Apple\ Development:*)
    if [ "$allow_development" = "1" ]; then
      warn "Archive uses Apple Development signing: $identity"
    else
      fail "Archive uses Apple Development signing; Apple Distribution is required"
    fi
    ;;
  *)
    fail "Unexpected archive signing identity: $identity"
    ;;
esac

if verify_output=$(codesign --verify --deep --strict "$app" 2>&1); then
  pass "Code signature verifies with deep strict validation"
else
  if [ "$allow_development" = "1" ]; then
    warn "Local code-signing trust validation did not pass: $verify_output"
  else
    fail "Code signature validation failed: $verify_output"
  fi
fi

if [ "$errors" -ne 0 ]; then
  printf '\n%d archive preflight check(s) failed.\n' "$errors"
  exit 1
fi

printf '\nArchive preflight passed.\n'
