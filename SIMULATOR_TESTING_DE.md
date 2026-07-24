# ownCloud Online iOS im Simulator testen

Für den **iOS-Simulator ist kein bezahlter Apple-Developer-Account und keine
Signierung nötig** — nur ein Mac mit dem kostenlosen Xcode aus dem Mac App
Store. (Der Developer-Account wird erst für TestFlight/Geräte-Builds
gebraucht.)

## Schritte

```bash
git clone https://github.com/BWTECH-github/IOS-App.git
cd IOS-App
git submodule update --init --recursive
```

Der Submodule-Schritt ist **zwingend** — er lädt das ownCloud-iOS-SDK, ohne
das das Projekt nicht baut.

Dann:

1. `ownCloud.xcodeproj` in Xcode öffnen (Doppelklick genügt).
2. Oben in der Toolbar das Schema **ownCloud** und einen iPhone-Simulator
   wählen (z. B. „iPhone 16").
3. **⌘R** — die App baut und startet im Simulator, ohne Signierung.

Falls Xcode beim ersten Build nach einem Team fragt: Das betrifft nur
Geräte-Builds; für den Simulator kann unter *Signing & Capabilities* das
kostenlose persönliche Team gewählt oder die Meldung ignoriert werden.

## Mit dem Server verbinden

- Beim Einrichten des Kontos die URL der eigenen (Test-)Instanz eingeben
  (vorbelegt ist `https://owncloud.online`).
- Anmeldung mit Benutzername + **App-Passwort** (Weboberfläche →
  Einstellungen → Sicherheit → App-Passwörter).
- Läuft der Test-Server lokal auf dem Mac, funktioniert im Simulator
  `http://localhost:PORT` direkt (der Simulator teilt das Netzwerk des Macs).

## Hinweise

- Diese App-Generation (12.x) ist laut `KNOWN_ISSUES.md` eine
  **Alpha** — zum Ansehen und für internes Testen geeignet, noch nicht für
  Kunden.
- `.xcode-version` (26.2) ist die CI-Referenz; lokal funktioniert die
  aktuelle Xcode-Version aus dem App Store für Simulator-Builds.
- TestFlight-Verteilung an externe Tester folgt nach Einrichtung des
  Apple-Developer-Accounts (Team-ID im `Fastfile` ersetzen, Bundle-IDs
  registrieren, App-Store-Connect-API-Key als Secret hinterlegen).
