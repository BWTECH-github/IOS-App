# App-Store-Angaben: ownCloud.online (iOS)

Alle Angaben stammen aus dem Code dieses Repositorys (Stand des Commits) und von https://owncloud.online.
Längenbegrenzungen von App Store Connect stehen in Klammern.

## Allgemein

| Feld | Wert |
|---|---|
| Bundle-ID | `online.owncloud.ios-app` |
| SKU (Vorschlag) | `owncloud-online-ios` |
| Primäre Sprache | Deutsch |
| Kategorie | Produktivität (primär), Business (sekundär) |
| Preis | Kostenlos. Die App enthält keine In-App-Käufe (`build.flags = DISABLE_APPSTORE_LICENSING`) |
| Support-URL | https://owncloud.online/de/kontakt/ (en: https://owncloud.online/contact/) |
| Marketing-URL | https://owncloud.online/ |
| Datenschutz-URL | https://owncloud.online/de/datenschutzrichtlinie/ (en: https://owncloud.online/privacy-policy/). Die englische Seite ist auch in der App hinterlegt (`branding.url-privacy`) |
| Nutzungsbedingungen | Apple-Standard-EULA oder https://owncloud.online/terms/ (in der App hinterlegt) |
| Copyright | 2026 BW-Tech GmbH |
| Support-E-Mail (laut Website) | support@owncloudonline.com |

## Deutsch

**Name** (30): `ownCloud.online` (15 Zeichen)

**Untertitel** (30): `Sicherer Cloud-Speicher` (23)

**Werbetext** (170):
> Ihre Dateien aus ownCloud.online immer dabei: ansehen, hochladen, teilen und offline verfügbar machen. Gespeichert ausschließlich in Rechenzentren in Deutschland.

**Beschreibung** (4000):

> Mit der App ownCloud.online greifen Sie auf Ihrem iPhone und iPad auf Ihre Dateien in ownCloud.online zu, der Cloud der BW-Tech GmbH. Ihre Daten liegen ausschließlich auf deutscher Infrastruktur, im eigenen Rechenzentrum der BW-Tech GmbH in Frankfurt am Main, und unterliegen der DSGVO.
>
> DATEIEN
> • Ordner und Dateien durchsuchen, sortieren und als Liste oder Raster anzeigen
> • Fotos, Videos, PDFs und viele weitere Dateitypen direkt in der App ansehen
> • Dateien und Ordner anlegen, umbenennen, kopieren, verschieben und löschen
> • Favoriten und zuletzt verwendete Dateien
> • Dateien offline verfügbar machen
>
> HOCHLADEN
> • Dateien, Fotos und Videos hochladen
> • Automatischer Upload neuer Fotos und Videos aus der Mediathek
> • Dokumente mit der Kamera scannen und als Datei speichern
>
> TEILEN UND ZUSAMMENARBEITEN
> • Dateien und Ordner mit anderen Benutzern teilen
> • Öffentliche Links erstellen und verwalten
>
> INTEGRATION IN iOS
> • Dateien-App: ownCloud.online erscheint als Speicherort in der Dateien-App
> • Teilen-Erweiterung: Inhalte aus anderen Apps direkt in ownCloud.online speichern
> • Kurzbefehle-Aktionen
> • Fotos und PDFs mit Markierungen versehen
>
> SICHERHEIT
> • Verschlüsselte Übertragung (HTTPS)
> • App-Sperre mit Code sowie Face ID oder Touch ID
>
> Für die Nutzung brauchen Sie ein ownCloud.online-Konto. Sie haben noch keins? Unter owncloud.online/try können Sie einen kostenlosen Testzugang anfordern.

**Keywords** (100): `Cloud,Speicher,Dateien,Upload,Foto,Backup,DSGVO,Datenschutz,Deutschland,Sync,Teilen,ownCloud` (92)

## English

**Name** (30): `ownCloud.online`

**Subtitle** (30): `Secure cloud storage` (20)

**Promotional text** (170):
> Take your ownCloud.online files with you: view, upload, share and make them available offline. Stored exclusively in data centres in Germany.

**Description** (4000):

> The ownCloud.online app gives you access to your files in ownCloud.online, the cloud operated by BW-Tech GmbH, on your iPhone and iPad. Your data is stored exclusively on German infrastructure, in BW-Tech GmbH's own data centre in Frankfurt am Main, and is subject to the GDPR.
>
> FILES
> • Browse and sort folders and files, in list or grid view
> • View photos, videos, PDFs and many other file types right in the app
> • Create, rename, copy, move and delete files and folders
> • Favorites and recently used files
> • Make files available offline
>
> UPLOAD
> • Upload files, photos and videos
> • Automatic upload of new photos and videos from your library
> • Scan documents with the camera and save them as files
>
> SHARE AND COLLABORATE
> • Share files and folders with other users
> • Create and manage public links
>
> iOS INTEGRATION
> • Files app: ownCloud.online appears as a location in the Files app
> • Share extension: save content from other apps directly to ownCloud.online
> • Shortcuts actions
> • Mark up photos and PDFs
>
> SECURITY
> • Encrypted transfer (HTTPS)
> • App lock with passcode and Face ID or Touch ID
>
> You need an ownCloud.online account to use the app. Don't have one yet? Request a free trial account at owncloud.online/try.

**Keywords** (100): `cloud,storage,files,upload,photo,backup,GDPR,privacy,Germany,sync,share,ownCloud` (80)

## Altersfreigabe (Fragebogen)

Alle Inhaltsfragen (Gewalt, sexuelle Inhalte, Nacktheit, Glücksspiel, Drogen/Alkohol/Tabak, Horror, Schimpfwörter, medizinische Informationen, Wettbewerbe) → **Keine**.

| Frage | Antwort | Grund |
|---|---|---|
| Uneingeschränkter Webzugang | Nein | Die App öffnet nur feste Seiten von owncloud.online (FAQ, Datenschutz, AGB, Kontakt) und keinen frei bedienbaren Browser |
| Nutzergenerierte Inhalte / Chat | Nein | Private Dateiablage des eigenen Kontos. Es gibt keinen öffentlichen Feed, keinen Chat und keine Kommentare |
| Glücksspiel / Lootboxen | Nein | |
| Erwartete Einstufung | 4+ | |

## App-Datenschutz (App Store Connect → App-Datenschutz)

**Tracking:** Nein. Die App enthält kein Werbe-, Analyse- oder Tracking-SDK und keine IDFA-Nutzung.
Eingebundene Pakete: OpenSSL, PLCrashReporter, PocketSVG, Down und SHA3IUF. Im Privacy-Manifest steht `NSPrivacyTracking = false`.

**Werden Daten erhoben?** Ja. Die App überträgt Daten an den ownCloud.online-Server, den die BW-Tech GmbH betreibt:

| Datentyp (Apple) | Erhoben | Mit Identität verknüpft | Tracking | Zweck |
|---|---|---|---|---|
| Nutzerinhalte → Fotos oder Videos | Ja (Upload, automatischer Upload) | Ja | Nein | App-Funktionalität |
| Nutzerinhalte → Andere Nutzerinhalte (Dateien, Scans) | Ja | Ja | Nein | App-Funktionalität |
| Kennungen → Nutzer-ID (Anmeldename des Kontos) | Ja (Anmeldung) | Ja | Nein | App-Funktionalität |

**Nicht erhoben:**
- Analysedaten: Es gibt kein Analytics-SDK.
- Absturzdaten: PLCrashReporter speichert Absturzberichte nur im lokalen App-Log (`AppDelegate.setupAndHandleCrashReports`). Nichts wird automatisch gesendet. Ein Log verlässt das Gerät nur, wenn die Nutzerin oder der Nutzer es selbst teilt.
- Standort: Der Hintergrund-Standort (optional, „Automatischer Upload“) weckt die App nur für Uploads auf, und es werden keine Standortdaten übertragen. Hochgeladene Fotos können wie das Original EXIF-Ortsdaten enthalten. Das gehört zum Nutzerinhalt „Fotos“.
- Kontakte, Gesundheit, Finanzen, Browserverlauf, Suchverlauf (Suchanfragen gehen nur an den eigenen Server, um Ergebnisse zu liefern), Käufe: keine.

Required-Reason-APIs (aus App, Extensions und SDK ermittelt, im Manifest deklariert):

| Kategorie | Grund | Verwendung |
|---|---|---|
| UserDefaults | CA92.1, 1C8F.1, AC6B.1 | App-Einstellungen, gemeinsame App-Group-Defaults (`OCAppIdentity`), MDM-Konfiguration |
| FileTimestamp | C617.1, 3B52.1, DDA9.1 | Dateien im App-Container/App-Group (Logs, Vault), vom Nutzer gewählte Dateien beim Import (`OCItem+OCFileURLMetadata`), Anzeige von Log-Daten |
| DiskSpace | E174.1, 85F4.1 | Speicherfreigabe bei wenig Platz (`OCItemPolicyProcessorDownloadExpiration`), Anzeige des freien Speichers (`BookmarkInfoViewController`) |
| SystemBootTime | 35F9.1 | Zeitmessung für die App-Sperre (`AppLockManager`) |

## Exportkonformität

`ITSAppUsesNonExemptEncryption = NO` (Info.plist). In App Store Connect wird dadurch nicht mehr nachgefragt.

Begründung aus dem Code:
- Transportverschlüsselung ausschließlich über HTTPS/TLS von iOS (`NSURLSession`).
- Datenschutz auf dem Gerät über iOS-Funktionen: Data Protection (`NSFileProtectionCompleteUntilFirstUserAuthentication`) und Schlüsselbund.
- OpenSSL (Paket `krzyzanowskim/OpenSSL`) wird nur zum Lesen und Prüfen von X.509-Zertifikaten genutzt (`ios-sdk/ownCloudUI/Certificate Metadata`). Die Prüfung der App-Store-Quittung (PKCS7, `OCLicenseAppStoreReceipt`) ist mit `DISABLE_APPSTORE_LICENSING` aus dem Build entfernt. Beides sind Authentifizierung bzw. Integritätsprüfung.
- Hashes (SHA1/SHA256/SHA3, MD5) dienen nur Prüfsummen und Integrität.
- Keine eigene oder proprietäre Verschlüsselung und keine Verschlüsselung von Nutzerdaten mit eigenen Algorithmen. Ende-zu-Ende-Verschlüsselung erfolgt serverseitig bzw. im Browser, nicht in der App.

Diese Nutzung fällt unter die Ausnahmen (Authentifizierung, Integrität, Verschlüsselung durch das Betriebssystem). Eine Jahres-Selbstklassifizierung (BIS) ist dafür nicht nötig. Die Entscheidung trägt das Unternehmen. Im Zweifel die Fragen in App Store Connect mit „Nur Verschlüsselung, die in iOS enthalten ist oder unter die Ausnahmen fällt“ beantworten.

## Review-Notizen (Vorschlag)

> This app is the client for ownCloud.online, a hosted file storage service operated by BW-Tech GmbH (Germany). A demo account is provided below.
> Background location (UIBackgroundModes "location") is optional and used only when the user enables "Auto Upload" with location-based background triggering: significant location changes wake the app to upload new photos and videos. No location data is collected or transmitted.
> The app contains no in-app purchases.
>
> Demo account: <Server-URL> / <Benutzer> / <Passwort>
