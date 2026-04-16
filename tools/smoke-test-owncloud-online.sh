#!/usr/bin/env bash
set -euo pipefail
URL="${OC_URL:-https://owncloud.online}"
USER="${OC_USER:-}"
PASS="${OC_PASS:-}"
AUTH=()
[[ -n "$USER" && -n "$PASS" ]] && AUTH=(-u "$USER:$PASS")

fail=0
check() {
  local name=$1 code=$2 expected=$3
  if [[ "$code" =~ ^($expected)$ ]]; then echo "✅ $name ($code)"; else echo "❌ $name ($code, expected $expected)"; fail=1; fi
}

echo "Testing $URL"
C=$(curl -s -o /dev/null -w "%{http_code}" "$URL/status.php")
check "status.php" "$C" "200"
C=$(curl -s -o /dev/null -w "%{http_code}" -H "OCS-APIRequest: true" "${AUTH[@]}" "$URL/ocs/v2.php/cloud/capabilities?format=json")
check "capabilities" "$C" "200|401"
if [[ -n "$USER" ]]; then
  C=$(curl -s -o /dev/null -w "%{http_code}" -X PROPFIND -H "Depth: 1" "${AUTH[@]}" "$URL/remote.php/dav/files/$USER/")
  check "PROPFIND root" "$C" "207"
  C=$(curl -s -o /dev/null -w "%{http_code}" -H "OCS-APIRequest: true" "${AUTH[@]}" "$URL/ocs/v2.php/cloud/user?format=json")
  check "user info" "$C" "200"
fi
exit $fail
