#!/bin/bash
#
# release.sh - App-Store-Build der iOS-App ownCloud.online (BW-TECH GmbH)
#
# Ablauf: xcodebuild archive (Release, generic/platform=iOS, automatische Signierung)
#         -> xcodebuild -exportArchive (app-store-connect, Team 4545KLA52K)
#         -> Pruefung des IPA (Signatur, Entitlements, Profile, Versionen)
#
# Hochgeladen wird NUR mit --upload. Ohne den Schalter entsteht ausschliesslich ein lokales IPA.
#
# Aufruf:
#   tools/appstore/release.sh --build 303            # Archiv + IPA, kein Upload
#   tools/appstore/release.sh --build 303 --upload   # Archiv + Upload zu App Store Connect
#   tools/appstore/release.sh --verify build/appstore/303/export/ownCloud.ipa
#
# Optionen:
#   --build N          Build-Nummer (CFBundleVersion). Muss pro Upload steigen. Pflicht bei --upload.
#   --upload           Nach dem Archivieren direkt zu App Store Connect hochladen (destination upload).
#   --export-only      Kein neues Archiv, vorhandenes Archiv aus --output exportieren.
#   --output DIR       Ausgabeverzeichnis (Standard: build/appstore/<build>).
#   --verify IPA       Nur ein vorhandenes IPA pruefen.
#
# Optional fuer Upload ohne in Xcode angemeldetes Konto (App Store Connect API-Key):
#   ASC_KEY_PATH=/pfad/AuthKey_XXXX.p8 ASC_KEY_ID=XXXX ASC_ISSUER_ID=uuid
#
set -euo pipefail

TEAM_ID="4545KLA52K"
APP_BUNDLE_ID="online.owncloud.ios-app"
APP_GROUP="group.online.owncloud.ios-app"
SCHEME="ownCloud"
CONFIGURATION="Release"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="$ROOT/ownCloud.xcodeproj"
BRANDING_PLIST="$ROOT/ownCloud/Resources/Theming/Branding.plist"
EXPORT_OPTIONS_TEMPLATE="$ROOT/tools/appstore/ExportOptions.plist"

BUILD_NUMBER=""
UPLOAD=0
EXPORT_ONLY=0
OUTPUT=""
VERIFY_ONLY=""

die() { echo "FEHLER: $*" >&2; exit 1; }
info() { echo "==> $*"; }

while [ $# -gt 0 ]; do
	case "$1" in
		--build) BUILD_NUMBER="${2:-}"; shift 2 ;;
		--upload) UPLOAD=1; shift ;;
		--export-only) EXPORT_ONLY=1; shift ;;
		--output) OUTPUT="${2:-}"; shift 2 ;;
		--verify) VERIFY_ONLY="${2:-}"; shift 2 ;;
		-h|--help) sed -n '2,26p' "$0"; exit 0 ;;
		*) die "Unbekannte Option: $1 (siehe --help)" ;;
	esac
done

plist_get() { /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true; }
# Array-Eintraege eines Plists kommagetrennt ausgeben
plist_list() { /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null | sed -e "s/^ *//" -e "s/ *$//" | grep -v -e "^Array {$" -e "^}$" -e "^$" | paste -sd, - || true; }

# ---------------------------------------------------------------------------
# IPA-Pruefung
# ---------------------------------------------------------------------------
verify_ipa() {
	local ipa="$1" tmp failed=0
	[ -f "$ipa" ] || die "IPA nicht gefunden: $ipa"
	tmp="$(mktemp -d)"
	ditto -x -k "$ipa" "$tmp"
	local app
	app="$(find "$tmp/Payload" -maxdepth 1 -name '*.app' | head -1)"
	[ -n "$app" ] || die "Keine .app im IPA"

	local app_short app_build
	app_short="$(plist_get "$app/Info.plist" CFBundleShortVersionString)"
	app_build="$(plist_get "$app/Info.plist" CFBundleVersion)"
	info "IPA: $ipa"
	info "App-Version $app_short ($app_build)"

	local bundles=("$app")
	while IFS= read -r b; do bundles+=("$b"); done < <(find "$app/PlugIns" -maxdepth 1 -name '*.appex' 2>/dev/null | sort)

	for b in "${bundles[@]}"; do
		local name bid short build ents prof_name prof_team prof_type get_task groups kc
		name="$(basename "$b")"
		bid="$(plist_get "$b/Info.plist" CFBundleIdentifier)"
		short="$(plist_get "$b/Info.plist" CFBundleShortVersionString)"
		build="$(plist_get "$b/Info.plist" CFBundleVersion)"
		codesign -d --entitlements - --xml "$b" > "$tmp/ents.plist" 2>/dev/null || true
		get_task="$(plist_get "$tmp/ents.plist" get-task-allow)"
		groups="$(plist_list "$tmp/ents.plist" com.apple.security.application-groups)"
		kc="$(plist_list "$tmp/ents.plist" keychain-access-groups)"
		ents="$(plutil -p "$tmp/ents.plist" 2>/dev/null | tr -d "\n" | tr -s " ")"
		if [ -f "$b/embedded.mobileprovision" ]; then
			security cms -D -i "$b/embedded.mobileprovision" > "$tmp/prof.plist" 2>/dev/null
			prof_name="$(plist_get "$tmp/prof.plist" Name)"
			prof_team="$(plist_get "$tmp/prof.plist" TeamIdentifier:0)"
			if [ "$(plist_get "$tmp/prof.plist" ProvisionedDevices)" != "" ]; then prof_type="mit Geraeteliste (KEIN App-Store-Profil)"; else prof_type="App Store"; fi
		else
			prof_name="-"; prof_team="-"; prof_type="FEHLT"
		fi
		echo "--- $name"
		echo "    Bundle-ID:   $bid"
		echo "    Version:     $short ($build)"
		echo "    Signatur:    $(codesign -dvv "$b" 2>&1 | grep -E '^Authority=' | head -1 | cut -d= -f2-)"
		echo "    Profil:      $prof_name [Team $prof_team, $prof_type]"
		echo "    App-Group:   $groups"
		echo "    Keychain:    $kc"
		echo "    get-task-allow: $get_task"
		echo "    Entitlements: $ents"

		codesign --verify --strict "$b" 2>/dev/null || { echo "    !! codesign --verify fehlgeschlagen"; failed=1; }
		[ "$short" = "$app_short" ] && [ "$build" = "$app_build" ] || { echo "    !! Version weicht von der App ab"; failed=1; }
		case "$bid" in "$APP_BUNDLE_ID"|"$APP_BUNDLE_ID".*) ;; *) echo "    !! Bundle-ID nicht unter $APP_BUNDLE_ID"; failed=1 ;; esac
		[ "$get_task" = "false" ] || [ -z "$get_task" ] || { echo "    !! get-task-allow ist gesetzt"; failed=1; }
		[[ ",$groups," == *",$APP_GROUP,"* ]] || { echo "    !! App-Group $APP_GROUP fehlt"; failed=1; }
		[[ "$kc" == *"$APP_GROUP"* ]] || { echo "    !! Keychain-Access-Group fehlt"; failed=1; }
		[ "$prof_type" = "App Store" ] && [ "$prof_team" = "$TEAM_ID" ] || { echo "    !! Profil ist kein App-Store-Profil des Teams $TEAM_ID"; failed=1; }
		[ -f "$b/PrivacyInfo.xcprivacy" ] || { echo "    !! PrivacyInfo.xcprivacy fehlt"; failed=1; }
	done

	echo "--- Frameworks"
	for f in "$app"/Frameworks/*.framework; do
		[ -e "$f" ] || continue
		local auth privacy="nein"
		auth="$(codesign -dvv "$f" 2>&1 | grep -E '^Authority=' | head -1 | cut -d= -f2-)"
		[ -f "$f/PrivacyInfo.xcprivacy" ] && privacy="ja"
		echo "    $(basename "$f"): $auth, PrivacyInfo: $privacy"
		codesign --verify --strict "$f" 2>/dev/null || { echo "    !! codesign --verify fehlgeschlagen: $f"; failed=1; }
	done

	rm -rf "$tmp"
	if [ $failed -ne 0 ]; then
		die "IPA-Pruefung mit Fehlern beendet"
	fi
	info "IPA-Pruefung erfolgreich"
}

if [ -n "$VERIFY_ONLY" ]; then
	verify_ipa "$VERIFY_ONLY"
	exit 0
fi

# ---------------------------------------------------------------------------
# Vorbereitung
# ---------------------------------------------------------------------------
[ -f "$ROOT/ios-sdk/ownCloudSDK.xcodeproj/project.pbxproj" ] || die "Submodul ios-sdk fehlt (git submodule update --init)"
xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1 || die "Xcode ist nicht einsatzbereit: $(xcrun --sdk iphoneos --show-sdk-path 2>&1 | head -1) (nach Xcode-Updates: sudo xcodebuild -license accept && sudo xcodebuild -runFirstLaunch)"

if [ -z "$BUILD_NUMBER" ]; then
	[ $UPLOAD -eq 0 ] || die "--upload braucht eine explizite, hoehere Build-Nummer (--build N)"
	BUILD_NUMBER="$(xcodebuild -project "$PROJECT" -target "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null | awk '$1=="APP_VERSION"{print $3; exit}')"
	echo "Hinweis: keine --build angegeben, verwende Build-Nummer aus dem Projekt: $BUILD_NUMBER"
fi
[[ "$BUILD_NUMBER" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || die "Ungueltige Build-Nummer: $BUILD_NUMBER"

OUTPUT="${OUTPUT:-$ROOT/build/appstore/$BUILD_NUMBER}"
ARCHIVE="$OUTPUT/ownCloud.xcarchive"
EXPORT_DIR="$OUTPUT/export"
mkdir -p "$OUTPUT"

# Build-Flags wie im Fastfile aus dem Branding lesen (z. B. DISABLE_APPSTORE_LICENSING)
BUILD_FLAGS="$(plist_get "$BRANDING_PLIST" build.flags)"
MARKETING_VERSION="$(xcodebuild -project "$PROJECT" -target "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null | awk '$1=="APP_SHORT_VERSION"{print $3; exit}')"

info "Version $MARKETING_VERSION ($BUILD_NUMBER), Team $TEAM_ID, Build-Flags: '${BUILD_FLAGS}'"
info "Git: $(git -C "$ROOT" rev-parse --short HEAD) / SDK $(git -C "$ROOT/ios-sdk" rev-parse --short HEAD)"
if [ -n "$(git -C "$ROOT" status --porcelain --untracked-files=no)" ]; then
	echo "Warnung: Arbeitskopie hat uncommittete Aenderungen."
fi

AUTH_ARGS=()
if [ -n "${ASC_KEY_PATH:-}" ]; then
	[ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] || die "ASC_KEY_PATH braucht ASC_KEY_ID und ASC_ISSUER_ID"
	AUTH_ARGS=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

# DEVELOPMENT_TEAM wird global gesetzt, damit auch die Targets des Submoduls ios-sdk
# (dort ist das Team von ownCloud eingetragen) mit dem BW-TECH-Team gebaut werden.
BUILD_SETTINGS=(
	DEVELOPMENT_TEAM="$TEAM_ID"
	CODE_SIGN_STYLE=Automatic
	APP_VERSION="$BUILD_NUMBER"
	APP_BUILD_FLAGS="$BUILD_FLAGS"
)

# ---------------------------------------------------------------------------
# Archivieren
# ---------------------------------------------------------------------------
if [ $EXPORT_ONLY -eq 0 ]; then
	info "Archiviere nach $ARCHIVE (Log: $OUTPUT/archive.log)"
	rm -rf "$ARCHIVE"
	if ! xcodebuild archive \
		-project "$PROJECT" \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-destination "generic/platform=iOS" \
		-archivePath "$ARCHIVE" \
		-derivedDataPath "$OUTPUT/DerivedData" \
		-allowProvisioningUpdates \
		${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} \
		"${BUILD_SETTINGS[@]}" > "$OUTPUT/archive.log" 2>&1; then
		grep -E 'error:|errSec|requires a provisioning|No Account|No profiles|Signing for' "$OUTPUT/archive.log" | sort -u | head -30
		die "Archivieren fehlgeschlagen (vollstaendiges Log: $OUTPUT/archive.log)"
	fi
	info "Archiv erstellt"
fi
[ -d "$ARCHIVE" ] || die "Kein Archiv unter $ARCHIVE"

# ---------------------------------------------------------------------------
# Exportieren / Hochladen
# ---------------------------------------------------------------------------
EXPORT_OPTIONS="$OUTPUT/ExportOptions.plist"
cp "$EXPORT_OPTIONS_TEMPLATE" "$EXPORT_OPTIONS"
if [ $UPLOAD -eq 1 ]; then
	/usr/libexec/PlistBuddy -c "Set :destination upload" "$EXPORT_OPTIONS"
	info "UPLOAD zu App Store Connect ist aktiviert (--upload)"
fi

info "Exportiere (Log: $OUTPUT/export.log)"
rm -rf "$EXPORT_DIR"
if ! xcodebuild -exportArchive \
	-archivePath "$ARCHIVE" \
	-exportPath "$EXPORT_DIR" \
	-exportOptionsPlist "$EXPORT_OPTIONS" \
	-allowProvisioningUpdates \
	${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} > "$OUTPUT/export.log" 2>&1; then
	grep -E 'error|Error|errSec|No signing certificate|No profiles|not permitted|role|agreement' "$OUTPUT/export.log" | sort -u | head -30
	die "Export fehlgeschlagen (vollstaendiges Log: $OUTPUT/export.log)"
fi

if [ $UPLOAD -eq 1 ]; then
	info "Upload abgeschlossen. Die Verarbeitung in App Store Connect dauert einige Minuten."
else
	IPA="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.ipa' | head -1)"
	[ -n "$IPA" ] || die "Kein IPA im Export"
	verify_ipa "$IPA"
	info "Fertig: $IPA"
fi
