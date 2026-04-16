# 🥷 Super Ninja AI — Task: ownCloud iOS App für owncloud.online (PHP 8.4) anpassen

## 📋 Aufgabenübersicht

Dieses Repository soll die offizielle ownCloud iOS App (`owncloud/ios-app`) vollständig enthalten und auf **owncloud.online** (PHP 8.4, Custom Backend) ausgerichtet werden.

---

## 🎯 Ziel

1. Den kompletten Quellcode von [`owncloud/ios-app`](https://github.com/owncloud/ios-app) in **dieses Repository** (`GrossLukas/IOS-App`) übertragen.
2. Die App vollständig kompatibel machen mit dem Backend [`BWTECH-github/owncloud.online`](https://github.com/BWTECH-github/owncloud.online) — eine **ownCloud-Instanz mit PHP 8.4**, die eigene Konfigurationen, Anpassungen und ggf. Custom-APIs enthält.

---

## 🔧 Schritt 1 — Quellcode übertragen (Fork-Migration)

Da das Repo `GrossLukas/IOS-App` aktuell **leer** ist, muss der gesamte Quellcode von `owncloud/ios-app` hereingezogen werden.

```bash
# 1. Upstream hinzufügen
git remote add upstream https://github.com/owncloud/ios-app.git

# 2. Upstream-Inhalte holen
git fetch upstream

# 3. Alle Branches und Tags holen
git fetch upstream --tags

# 4. Main-Branch mit Upstream synchronisieren
git checkout main
git merge upstream/master --allow-unrelated-histories

# 5. Submodule initialisieren (ios-sdk ist ein Git-Submodule)
git submodule update --init --recursive

# 6. Pushen
git push origin main --tags
```

> ⚠️ **Wichtig:** Das Repo `owncloud/ios-app` verwendet ein **Git Submodule** für das iOS SDK (`ios-sdk` → `https://github.com/owncloud/ios-sdk`). Dieses Submodule muss ebenfalls initialisiert und gepusht werden.

---

## 🔍 Schritt 2 — Backend-Analyse (`owncloud.online`)

Analysiere das Backend-Repo [`BWTECH-github/owncloud.online`](https://github.com/BWTECH-github/owncloud.online) auf folgende Punkte:

| Bereich | Was prüfen? |
|---|---|
| PHP 8.4 Kompatibilität | Gibt es Custom-APIs, geänderte Endpunkte oder neue Response-Formate? |
| Konfiguration | `config.php` — welche Server-URL, welche Apps/Plugins sind aktiv? |
| Authentifizierung | Wird OAuth2, Basic Auth oder LDAP genutzt? Welche App-Passwords sind erlaubt? |
| Custom Apps | Sind eigene ownCloud-Apps installiert, die neue API-Routen bereitstellen? |
| WebDAV | Gibt es Abweichungen beim WebDAV-Endpunkt (`/remote.php/webdav` vs. `/remote.php/dav`)? |
| Capabilities API | Gibt es Anpassungen an `/ocs/v1.php/cloud/capabilities`? |
| Theming | Gibt es Custom-Branding (App-Name, Icon, Farben)? |

---

## 🛠 Schritt 3 — iOS App anpassen

### 3.1 Server-URL & Branding

**Datei:** `ownCloud/Constants/OCConstants.swift` oder vergleichbar

- Standard-Server-URL auf `https://owncloud.online` setzen (als Vorausfüllung im Onboarding)
- App-Name ggf. anpassen (falls Custom-Branding gewünscht)
- Bundle-ID prüfen: `com.owncloud.ios-app` → ggf. eigene Bundle-ID setzen

### 3.2 OAuth2 / Authentifizierung

**Prüfen:** Welche Auth-Methoden sind auf `owncloud.online` aktiv?

- Falls OAuth2: `OCAuthenticationMethodOAuth2` konfigurieren — Client-ID & Secret aus dem ownCloud-Backend eintragen
- Falls App-Passwords aktiv: Sicherstellen, dass `OCAuthenticationMethodBasicAuth` weiterhin unterstützt wird
- Datei: `ownCloud/Server List/OCServerListTableViewController.swift` und verwandte Auth-Klassen

### 3.3 API-Endpunkte & Capabilities

Die iOS App nutzt die **OCS API** und **WebDAV**. Bei PHP 8.4 und Custom-Backend prüfen:

- `/ocs/v2.php/apps/files_sharing/api/v1/shares` — Sharing API
- `/remote.php/dav/files/{user}` — WebDAV-Endpunkt
- `/ocs/v1.php/cloud/capabilities` — Capabilities-Response

Falls das `owncloud.online`-Backend geänderte Responses liefert, müssen die entsprechenden Parser-Klassen im iOS SDK (`ios-sdk`) angepasst werden.

### 3.4 Zertifikate & TLS

- Sicherstellen, dass das SSL-Zertifikat von `owncloud.online` korrekt akzeptiert wird
- Certificate Pinning ggf. aktivieren/deaktivieren

### 3.5 PHP 8.4 spezifische Kompatibilität

PHP 8.4 enthält Breaking Changes gegenüber älteren PHP-Versionen. Folgende Bereiche in der App prüfen:

- JSON-Parsing: Sicherstellen, dass alle API-Responses korrekt geparst werden (PHP 8.4 kann bei bestimmten Datentypen andere JSON-Ausgaben produzieren)
- Error-Handling: PHP 8.4 kann bei Fehlern anders formatierte Error-Responses zurückgeben
- Deprecated-Features: Prüfen ob das Backend Endpoints geändert hat, die früher als deprecated markiert waren

---

## 📁 Schritt 4 — Build & Konfiguration

### Xcode-Konfiguration

- Xcode-Version: aus `.xcode-version` lesen (aktuell im Upstream-Repo definiert)
- Signing: Eigenes Apple Developer Team & Provisioning Profile eintragen
- Bundle-ID: Anpassen auf eigene Bundle-ID (falls Custom-Distribution gewünscht)

### Fastlane (optional)

Das Repo enthält eine `fastlane/`-Konfiguration für automatisierte Builds:
```bash
bundle install
bundle exec fastlane ios beta
```

### Abhängigkeiten

- Das iOS SDK wird als **Git Submodule** eingebunden (`ios-sdk/`)
- Nach dem Clonen immer: `git submodule update --init --recursive`

---

## ✅ Akzeptanzkriterien

Die Aufgabe gilt als erledigt, wenn:

- [ ] Das Repository `GrossLukas/IOS-App` den vollständigen Quellcode von `owncloud/ios-app` enthält
- [ ] Das Git Submodule `ios-sdk` korrekt eingebunden ist
- [ ] Die App baut fehlerfrei in Xcode (kein Kompilierungsfehler)
- [ ] Login mit einem Account auf `owncloud.online` (PHP 8.4 Backend) funktioniert
- [ ] Datei-Browse, Upload und Download funktionieren korrekt gegen das `owncloud.online`-Backend
- [ ] Sharing-Funktionen funktionieren (falls im Backend aktiv)
- [ ] Keine HTTP-Fehler wegen geänderter API-Endpunkte (alle Capabilities korrekt gelesen)
- [ ] App läuft auf iOS 15+ (Mindest-Deployment-Target aus Upstream übernehmen)

---

## 📚 Referenzen

| Resource | Link |
|---|---|
| Upstream iOS App | https://github.com/owncloud/ios-app |
| iOS SDK (Submodule) | https://github.com/owncloud/ios-sdk |
| Backend (owncloud.online) | https://github.com/BWTECH-github/owncloud.online |
| Dieses Repo | https://github.com/GrossLukas/IOS-App |
| ownCloud iOS App Docs | https://doc.owncloud.com/ios-app/ |
| ownCloud OCS API Docs | https://doc.owncloud.com/server/latest/developer_manual/core/apis/ocs-share-api.html |

---

## 🗒 Hinweise für Super Ninja AI

- Das Backend-Repo `BWTECH-github/owncloud.online` zuerst analysieren, um zu verstehen welche PHP 8.4-spezifischen Anpassungen gemacht wurden
- Danach gezielt die betroffenen Swift-Klassen im iOS App Repo anpassen
- Änderungen in separaten Feature-Branches commiten und Pull Requests gegen `main` erstellen
- Beim iOS SDK (`ios-sdk`) möglichst keine Änderungen direkt — stattdessen Submodule auf einen eigenen Fork zeigen lassen, falls Änderungen am SDK nötig sind

---

*Erstellt: April 2026 | Repo-Owner: GrossLukas*
