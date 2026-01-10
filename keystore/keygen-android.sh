#!/usr/bin/env bash
set -euo pipefail

ORIG_STTY="$(stty -g)"
cleanup() {
  stty "$ORIG_STTY"
}
trap cleanup EXIT INT TERM

printf "Key alias name [fnf-se]: "
IFS= read -r ALIAS
ALIAS="${ALIAS:-fnf-se}"

while true; do
  echo "Keystore password:"
  stty -echo -icanon erase undef
  IFS= read -r STOREPASS
  stty "$ORIG_STTY"
  echo

  echo "Confirm keystore password:"
  stty -echo -icanon erase undef
  IFS= read -r STOREPASS_CONFIRM
  stty "$ORIG_STTY"
  echo

  if [[ -z "$STOREPASS" ]]; then
    echo "Password cannot be empty."
    continue
  fi

  if (( ${#STOREPASS} < 6 )); then
    echo "Password must be at least 6 characters long."
    continue
  fi

  if [[ "$STOREPASS" != "$STOREPASS_CONFIRM" ]]; then
    echo "Passwords do not match."
    continue
  fi

  break
done

printf "Your full name (CN) [Unknown]: "
IFS= read -r CN
CN="${CN:-Unknown}"

printf "Organizational unit (OU) [Unknown]: "
IFS= read -r OU
OU="${OU:-Unknown}"

printf "Organization (O) [Unknown]: "
IFS= read -r O
O="${O:-Unknown}"

printf "City or locality (L) [Unknown]: "
IFS= read -r L
L="${L:-Unknown}"

printf "State or province (ST) [Unknown]: "
IFS= read -r ST
ST="${ST:-Unknown}"

printf "Country code (2 letters) [US]: "
IFS= read -r C
C="${C:-US}"

echo "Generating keystore..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORE_PATH="$SCRIPT_DIR/android/key.keystore"
OUTPUT_JSON="$SCRIPT_DIR/android/keystore.json"

keytool -genkeypair \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 4096 \
  -validity 36500 \
  -storepass "$STOREPASS" \
  -keypass "$STOREPASS" \
  -dname "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C" \
  -v

cat > "$OUTPUT_JSON" <<EOF
{
  "alias": "$ALIAS",
  "storepass": "$STOREPASS",
  "keypass": "$STOREPASS"
}
EOF

echo "Keystore generated at: $KEYSTORE_PATH"
echo "Keystore info saved at: $OUTPUT_JSON"
