#!/bin/bash
#
# make-screenshots.sh – App-Store-Screenshots (Deutsch) fuer owncloud.online
#
# Erzeugt per XCUITest je 6 Motive fuer
#   iPhone 6,9 Zoll (iPhone 17 Pro Max, 1320x2868) -> doc/appstore/screenshots/iphone-6.9/
#   iPad 13 Zoll    (iPad Pro 13 Zoll M5, 2064x2752) -> doc/appstore/screenshots/ipad-13/
#
# Voraussetzungen:
#   - Xcode mit iOS-Simulator-Runtime
#   - Demo-Konto im Schluesselbund: security add-generic-password -U -s testoo.bw.tech -a demo -w <Passwort>
#   - Demo-Inhalt auf dem Server (Ordner Dokumente, Fotos, Projekte/Website-Relaunch mit
#     oeffentlichem Link, Projektplan 2027.pdf im Stammordner)
#
# Aufruf:  tools/appstore/screenshots/make-screenshots.sh [--skip-build] [--only iphone|ipad]
#
# Umgebung (optional): OCO_SERVER (Standard https://testoo.bw.tech), OCO_USER (Standard demo)
#
# Die Motive vermeiden bewusst Onboarding und Seitenleiste (dort steht das Logo).
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HERE="$ROOT/tools/appstore/screenshots"
WORK="${TMPDIR:-/tmp}/oco-screenshots"
DD_APP="$ROOT/build/DerivedData"
DD_TEST="$WORK/dd-tests"
APP="$DD_APP/Build/Products/Debug-iphonesimulator/ownCloud.app"
BUNDLE_ID="owncloud.online.bw.tech"
TEAM="A7VZ8HFNR4"
SERVER="${OCO_SERVER:-https://testoo.bw.tech}"
USER_NAME="${OCO_USER:-demo}"
SKIP_BUILD=0
ONLY=""

while [ $# -gt 0 ]; do
	case "$1" in
		--skip-build) SKIP_BUILD=1 ;;
		--only) ONLY="$2"; shift ;;
		-h|--help) sed -n 2,22p "$0"; exit 0 ;;
		*) echo "Unbekannte Option: $1" >&2; exit 2 ;;
	esac
	shift
done

PASS="$(security find-generic-password -s "${SERVER#https://}" -a "$USER_NAME" -w 2>/dev/null || true)"
[ -n "$PASS" ] || { echo "Kein Passwort fuer $USER_NAME im Schluesselbund (Dienst ${SERVER#https://})." >&2; exit 1; }

mkdir -p "$WORK"
# Neueste iOS-Runtime, die den Geraetetyp unterstuetzt: runtime_for <Geraetetyp>
runtime_for() {
	xcrun simctl list runtimes -j | python3 -I -c 'import json,sys; t=sys.argv[1]; r=[x for x in json.load(sys.stdin)["runtimes"] if x["platform"]=="iOS" and x["isAvailable"] and any(d["identifier"]==t for d in x.get("supportedDeviceTypes",[]))]; print(sorted(r,key=lambda x:[int(v) for v in x["version"].split(".")])[-1]["identifier"])' "$1"
}

# Simulator anlegen bzw. wiederverwenden: device <Name> <Geraetetyp>
device() {
	local udid RUNTIME
	RUNTIME="$(runtime_for "$2")"
	udid="$(xcrun simctl list devices -j | python3 -I -c 'import json,sys; n=sys.argv[1]; r=sys.argv[2]; d=json.load(sys.stdin)["devices"].get(r,[]); print(next((x["udid"] for x in d if x["name"]==n and x["isAvailable"]),""))' "$1" "$RUNTIME")"
	[ -n "$udid" ] || udid="$(xcrun simctl create "$1" "$2" "$RUNTIME")"
	echo "$udid"
}

prepare() { # prepare <udid> <iphone|ipad>
	local d="$1"
	xcrun simctl boot "$d" 2>/dev/null || true
	xcrun simctl bootstatus "$d" >/dev/null
	xcrun simctl spawn "$d" defaults write "Apple Global Domain" AppleLanguages -array de-DE
	xcrun simctl spawn "$d" defaults write "Apple Global Domain" AppleLocale -string de_DE
	# Deutsches 24-Stunden-Format auf allen Geraeten (keine 12-Stunden-Erzwingung, sonst "Heute, 4:34 PM")
	xcrun simctl spawn "$d" defaults delete "Apple Global Domain" AppleICUForce12HourTime 2>/dev/null || true
	xcrun simctl spawn "$d" defaults delete "Apple Global Domain" AppleICUForce24HourTime 2>/dev/null || true
	# Sprache/Uhrformat greifen erst nach Neustart
	xcrun simctl shutdown "$d"; xcrun simctl boot "$d"; xcrun simctl bootstatus "$d" >/dev/null
	xcrun simctl ui "$d" appearance light
	xcrun simctl status_bar "$d" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
		--cellularMode active --cellularBars 4 --operatorName "" --batteryState discharging --batteryLevel 100
	xcrun simctl uninstall "$d" "$BUNDLE_ID" 2>/dev/null || true
	xcrun simctl install "$d" "$APP"
}

run_shots() { # run_shots <udid> <zielordner>
	local d="$1" target="$2" out="$WORK/out-$(basename "$2")"
	rm -rf "$out"; mkdir -p "$out"
	local attempt
	for attempt in 1 2 3; do
		if (cd "$HERE" && TEST_RUNNER_OCO_OUT="$out" TEST_RUNNER_OCO_SERVER="$SERVER" TEST_RUNNER_OCO_USER="$USER_NAME" TEST_RUNNER_OCO_PASS="$PASS" \
			xcodebuild test-without-building -project OCOScreenshots.xcodeproj -scheme OCOScreenshotsUITests \
			-only-testing:OCOScreenshotsUITests/OCOScreenshotsUITests/testAppStore \
			-destination "platform=iOS Simulator,id=$d" -derivedDataPath "$DD_TEST" > "$out/xcodebuild.log" 2>&1); then
			break
		fi
		grep -E "error:|failed" "$out/xcodebuild.log" | head -5 >&2
		# Haeufigster Grund: "Timed out waiting for AX loaded notification" direkt nach dem Booten
		[ "$attempt" = 3 ] && { echo "Screenshot-Lauf fehlgeschlagen, Log: $out/xcodebuild.log" >&2; exit 1; }
		echo "Wiederhole Lauf ..." >&2
	done
	mkdir -p "$target"
	rm -f "$target"/*.png
	cp "$out"/0*.png "$target"/
	for f in "$target"/*.png; do echo "$(basename "$f"): $(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{printf "%s ", $2}')"; done
}

if [ "$SKIP_BUILD" = 0 ]; then
	echo "== App bauen (Simulator, signiert mit Team $TEAM)"
	# Build-Flags wie release.sh/Fastfile aus dem Branding (z. B. DISABLE_APPSTORE_LICENSING: keine "PRO"-Hinweise)
	BUILD_FLAGS="$(/usr/libexec/PlistBuddy -c "Print :build.flags" "$ROOT/ownCloud/Resources/Theming/Branding.plist" 2>/dev/null || true)"
	rm -rf "$APP" # sonst fehlen bei inkrementellen Builds die Branding-Assets
	xcodebuild build -project "$ROOT/ownCloud.xcodeproj" -scheme ownCloud -configuration Debug \
		-destination "generic/platform=iOS Simulator" -derivedDataPath "$DD_APP" \
		-allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" APP_BUILD_FLAGS="$BUILD_FLAGS" > "$WORK/build-app.log" 2>&1 \
		|| { grep -E " error:" "$WORK/build-app.log" | head -10 >&2; exit 1; }
fi
[ -d "$APP" ] || { echo "App fehlt: $APP" >&2; exit 1; }

echo "== UI-Tests bauen"
(cd "$HERE" && xcodebuild build-for-testing -project OCOScreenshots.xcodeproj -scheme OCOScreenshotsUITests \
	-destination "generic/platform=iOS Simulator" -derivedDataPath "$DD_TEST" > "$WORK/build-tests.log" 2>&1) \
	|| { grep -E " error:" "$WORK/build-tests.log" | head -10 >&2; exit 1; }

if [ -z "$ONLY" ] || [ "$ONLY" = iphone ]; then
	echo "== iPhone 6,9 Zoll"
	PHONE="$(device OCO-Shots-iPhone17ProMax com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max)"
	prepare "$PHONE" iphone
	run_shots "$PHONE" "$ROOT/doc/appstore/screenshots/iphone-6.9"
fi

if [ -z "$ONLY" ] || [ "$ONLY" = ipad ]; then
	echo "== iPad 13 Zoll"
	IPAD="$(device OCO-Shots-iPadPro13 com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB)"
	prepare "$IPAD" ipad
	run_shots "$IPAD" "$ROOT/doc/appstore/screenshots/ipad-13"
fi

echo "Fertig. Bilder pruefen: kein Logo/kein 'ownCloud' im Bild, Statusleiste 09:41, 24-Stunden-Format."
