# App-Store-Screenshots

`make-screenshots.sh` baut die App für den Simulator (signiert mit Team 4545KLA52K,
damit die App-Group-Entitlements greifen; Build-Flags aus `Branding.plist`), richtet
je einen Simulator ein (Deutsch, hell, Statusleiste 9:41 mit vollen Balken und vollem
Akku) und erzeugt per XCUITest sechs Motive:

| Datei | Motiv |
| --- | --- |
| `01-dateien.png` | Dateiliste im Stammordner |
| `02-fotos.png` | Ordner „Fotos“ als Bild-Kacheln |
| `03-vorschau.png` | PDF-Vorschau „Projektplan 2027.pdf“ |
| `04-teilen.png` | Freigabe-Dialog mit öffentlichem Link |
| `05-suche.png` | Suche nach „Projekt“ |
| `06-aktionen.png` | Aktionen zu einer Datei |

Ablage: `doc/appstore/screenshots/iphone-6.9/` (iPhone 17 Pro Max, 1320×2868) und
`doc/appstore/screenshots/ipad-13/` (iPad Pro 13 Zoll M5, 2064×2752).

```sh
tools/appstore/screenshots/make-screenshots.sh            # alles
tools/appstore/screenshots/make-screenshots.sh --skip-build --only ipad
```

Konto: `demo` auf https://testoo.bw.tech (fiktiver Name „Anna Berger“), Passwort im
Schlüsselbund (`security find-generic-password -s testoo.bw.tech -a demo -w`).
Der Demo-Inhalt (Ordner Dokumente, Fotos, Projekte, Team, Rechnungen 2026,
`Projektplan 2027.pdf`, öffentlicher Link „Kundenlink“ auf `Projekte/Website-Relaunch`)
liegt auf dem Server. Bilder und PDFs sind generiert, kein Fremdmaterial.

Onboarding, Kontenliste und Seitenleiste fehlen absichtlich: Dort steht das Logo, das
noch ersetzt wird. Nach dem Logo-Tausch die Motive in `testAppStore`
(`OCOScreenshotsUITests.swift`) ergänzen und das Skript erneut ausführen.

`testDrive` führt eine frei wählbare Aktionsliste aus (`OCO_ACTIONS`, z. B.
`launch;;tap:Fotos;;shot:fotos`) und eignet sich für UI-Prüfungen.
