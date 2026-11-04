# App-Store-Release (owncloud.online iOS)

Kurzanleitung für den Store-Build der App `owncloud.online.bw.tech` (Team `4545KLA52K`, BW-TECH GmbH).

## Voraussetzungen

- Xcode mit angemeldetem Apple-Konto des Teams `4545KLA52K` (Xcode → Settings → Accounts).
  Das Konto braucht die Rolle **Admin** oder **App Manager** mit Zugriff auf Zertifikate,
  damit Xcode das Zertifikat **Apple Distribution** automatisch anlegen kann
  (alternativ einmalig in Xcode → Accounts → Manage Certificates → „+“ → Apple Distribution).
- Xcode-Lizenz akzeptiert (`sudo xcodebuild -license accept`). Nach einem Xcode-Update außerdem einmal `sudo xcodebuild -runFirstLaunch`.
- Submodul ausgecheckt: `git submodule update --init`.
- Für den Upload: App-Eintrag in App Store Connect mit der Bundle-ID `owncloud.online.bw.tech`.

## Kennungen

| Target | Bundle-ID |
|---|---|
| App | `owncloud.online.bw.tech` |
| File Provider | `owncloud.online.bw.tech.FileProvider` |
| File Provider UI | `owncloud.online.bw.tech.FileProviderUI` |
| Share Extension | `owncloud.online.bw.tech.ShareExtension` |
| Action Extension | `owncloud.online.bw.tech.ActionExtension` |
| Intents | `owncloud.online.bw.tech.Intents` |

- App-Group (alle Targets): `group.owncloud.online.bw.tech`
- Keychain-Access-Group: `$(AppIdentifierPrefix)group.owncloud.online.bw.tech`
- URL-Schemes: `owncloud-online-bwtech` (App) und `owncloud-online-bwtech-auth` (Auth)
- Die Kennungen kollidieren nicht mit der App „ownCloud Online“ der ownCloud GmbH
  (`online.owncloud.ios-app`, `group.online.owncloud.ios-app`, Scheme `owncloud-online`);
  beide Apps laufen nebeneinander auf einem Gerät.
- Die automatische Signierung (`-allowProvisioningUpdates`) legt fehlende App-IDs, die App-Group
  und die App-Store-Profile im Team `4545KLA52K` selbst an.

## Versionen

| Wert | Quelle | Aktuell |
|---|---|---|
| Marketing-Version (`CFBundleShortVersionString`) | Projekt-Build-Setting `APP_SHORT_VERSION` (`ownCloud.xcodeproj`, Projekt-Ebene). App: `MARKETING_VERSION = ${APP_SHORT_VERSION}`, Extensions lesen `$(APP_SHORT_VERSION)` direkt in ihrer Info.plist | `12.7.0` |
| Build-Nummer (`CFBundleVersion`) | Projekt-Build-Setting `APP_VERSION`. App/Action-Extension: `CURRENT_PROJECT_VERSION = $(APP_VERSION)`, übrige Extensions `$(APP_VERSION)` in der Info.plist | `302` im Projekt |

Die Build-Nummer muss bei jedem Upload höher sein als die vorherige. `release.sh --build N`
setzt `APP_VERSION=N` für alle Targets, ohne das Projekt zu ändern. Wenn die Marketing-Version
geändert werden soll, `APP_SHORT_VERSION` im Projekt anpassen (eine Stelle je Konfiguration).

## Build

```sh
# Archiv + IPA (kein Upload), Ergebnis unter build/appstore/<N>/export/
tools/appstore/release.sh --build 303

# Archiv + IPA + Prüfung, danach Upload zu App Store Connect (nur mit ausdrücklichem Schalter)
tools/appstore/release.sh --build 303 --upload

# Vorhandenes IPA prüfen (Signatur, Entitlements, Profile, Versionen, Privacy-Manifeste)
tools/appstore/release.sh --verify build/appstore/303/export/ownCloud.ipa
```

Was das Skript macht:

1. `xcodebuild archive`: Schema `ownCloud`, Konfiguration Release, `generic/platform=iOS`,
   automatische Signierung, `-allowProvisioningUpdates`. Dabei werden `DEVELOPMENT_TEAM=4545KLA52K`
   (auch für die Targets im Submodul `ios-sdk`, in denen noch das ownCloud-Team steht), `APP_VERSION`
   und `APP_BUILD_FLAGS` gesetzt. `APP_BUILD_FLAGS` kommt wie beim Fastfile aus `build.flags` in `Branding.plist`;
   `DISABLE_APPSTORE_LICENSING` wird immer ergänzt (keine In-App-Käufe). Das Flag steht zusätzlich auf
   Projektebene, damit auch ein Archiv direkt aus Xcode (Product > Archive) keine Kaufangebote enthält.
2. `xcodebuild -exportArchive` mit `tools/appstore/ExportOptions.plist`
   (`app-store-connect`, Team `4545KLA52K`, `signingStyle automatic`, `destination export`).
3. Prüfung des IPA (immer, auch vor einem Upload). Schlägt sie fehl, bricht das Skript ab.
4. Nur mit `--upload`: zweiter `-exportArchive` mit `destination upload` (Log `upload.log`).

Upload ohne Xcode-Konto: einen App Store Connect API-Key per Umgebung übergeben:
`ASC_KEY_PATH=…/AuthKey_XXXX.p8 ASC_KEY_ID=XXXX ASC_ISSUER_ID=… tools/appstore/release.sh --build N --upload`.

Logs: `build/appstore/<N>/archive.log`, `export.log` und (bei `--upload`) `upload.log`.

## Build-Flags (Branding.plist → `build.flags`)

- `DISABLE_APPSTORE_LICENSING`: Die In-App-Käufe der Upstream-App (Dokumentenscanner, Markup,
  Kurzbefehle, Foto-Pro-Funktionen, Pro-Abo) werden aus der App entfernt und diese Funktionen
  für alle Konten freigeschaltet (`OCLicenseBuildUnlockProvider`). Ohne das Flag würde die App
  Käufe anbieten, die es in App Store Connect für diese App nicht gibt.

Das Flag steht auf Projektebene (`APP_BUILD_FLAGS = "$(inherited) DISABLE_APPSTORE_LICENSING"`,
Debug und Release). Damit gilt es auch für Builds und Archive direkt aus Xcode (Run, Product > Archive)
und für die Unit-Tests: Die StoreKit-Tests in `LicensingTests` werden dann übersprungen.

## Store-Compliance

- **Exportkonformität:** `ITSAppUsesNonExemptEncryption = NO` in `ownCloud/Resources/Info.plist`.
  Begründung in [store-texte.md](store-texte.md#exportkonformität).
- **Privacy-Manifest:** `PrivacyInfo.xcprivacy` (Projektwurzel) liegt in der App, in allen fünf Extensions
  und in den Frameworks `ownCloudApp` und `ownCloudAppShared`. Die Build-Phase
  „Add privacy manifest to SDK frameworks“ des App-Targets kopiert es außerdem in `ownCloudSDK.framework`
  und `ownCloudUI.framework`, weil das Upstream-Submodul keins mitliefert.
- **Angaben für App Store Connect** (Datenschutz, Altersfreigabe, Texte): [store-texte.md](store-texte.md).

## Stand der Signierung (2026-11-03)

- Im Team registriert: nur die App-ID `owncloud.online.bw.tech`. Die fünf Extension-IDs und die
  App-Group `group.owncloud.online.bw.tech` legt Xcode beim ersten signierten Archiv an.
- Das Xcode-Konto `dev@bw.tech` wird seit dem Update auf Xcode 27.2 abgelehnt
  („The login details … were rejected“). Mit App-Store-Connect-API-Schlüssel (`ASC_KEY_*`) meldet
  `xcodebuild archive` „No Account for Team 4545KLA52K“. Vor `release.sh` deshalb in Xcode →
  Settings → Accounts das Team-Konto neu anmelden.

## Checkliste vor der Einreichung

- [x] Demo-Konto für das App-Review angelegt: `appreview` auf https://testoo.bw.tech, mit Beispieldateien (Dokumente, Fotos, Projekte). Nur für Apple, nicht für eigene Tests benutzen. Die App lässt nur Basic-Auth-Konten zu.
- [ ] Demo-Konto in App Store Connect unter „App-Review-Informationen“ eintragen. Das Passwort steht nicht im Repo, BW-TECH verwahrt es (Schlüsselbund des Release-Macs).
- [ ] Hinweis zum Hintergrund-Standort in die Review-Notizen übernehmen (siehe store-texte.md).
- [x] Screenshots: 6,9" iPhone und 13" iPad (neu erzeugen: `tools/appstore/screenshots/make-screenshots.sh`).
- [x] Logo und App-Icon: Entscheidung BW-TECH (2026-11-04): Das vorhandene owncloud.online-Logo (Wortmarke und
  Wolke, auch im App-Icon `ownCloud/Resources/AppIcon.icon` und `fastlane/metadata-owncloud-online/app_icon.jpg`)
  ist das eigene Logo von BW-TECH und bleibt. Falls App Review wegen Ähnlichkeit zu einer anderen App nachfragt
  (Richtlinien 4.1/5.2.1), mit den Markenrechten von BW-TECH antworten.
- [x] Kein Screenshot zeigt eine Server-Adresse: Motiv 4 sind die Favoriten statt des Freigabe-Dialogs mit Link.
- [ ] Datenschutz-URL, Support-URL, Kategorie, Altersfreigabe und App-Datenschutz-Angaben in App Store Connect eintragen.
