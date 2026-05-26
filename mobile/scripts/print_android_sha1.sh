#!/usr/bin/env bash
# Prints SHA-1/SHA-256 for Google Cloud → Android OAuth client.
# Package name must be: com.zerohunger.zero_hunger

set -euo pipefail

KEYSTORE="${ANDROID_DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Debug keystore not found: $KEYSTORE" >&2
  echo "Build the app once in Android Studio, or create the keystore." >&2
  exit 1
fi

echo "Package name: com.zerohunger.zero_hunger"
echo "Keystore: $KEYSTORE"
echo ""
keytool -list -v \
  -keystore "$KEYSTORE" \
  -alias androiddebugkey \
  -storepass android \
  -keypass android \
  | grep -E 'SHA1:|SHA256:'

echo ""
echo "Paste SHA-1 into Google Cloud → Credentials → OAuth client → Android."
