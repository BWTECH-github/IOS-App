//
//  OCOScreenshotsUITests.swift
//  owncloud.online – App-Store-Screenshots und UI-Pruefung
//
//  Wird von tools/appstore/screenshots/make-screenshots.sh gestartet
//  (xcodebuild test, Umgebungsvariablen mit Praefix TEST_RUNNER_).
//
//  testDrive:       fuehrt eine Aktionsliste aus OCO_ACTIONS aus (";;"-getrennt),
//                   z. B. "launch;;tap:Einstellungen;;shot:settings".
//  testAppStore:    feste Motivfolge fuer die App-Store-Screenshots.
//
//  Umgebung: OCO_OUT (Zielordner), OCO_BUNDLE, OCO_SERVER, OCO_USER, OCO_PASS.
//

import XCTest

final class OCOScreenshotsUITests: XCTestCase {
	let env = ProcessInfo.processInfo.environment
	var out: String { env["OCO_OUT"] ?? NSTemporaryDirectory() }
	var app = XCUIApplication(bundleIdentifier: ProcessInfo.processInfo.environment["OCO_BUNDLE"] ?? "owncloud.online.bw.tech")
	var step = 0

	override func setUp() {
		continueAfterFailure = false
		try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
	}

	// MARK: - Helpers
	var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

	/// Bildschirmfoto inkl. Statusleiste (Originalaufloesung des Geraets).
	func shot(_ name: String, numbered: Bool = true) {
		waitForIdle()
		var base = "\(out)/\(name)"
		if numbered { step += 1; base = "\(out)/\(String(format: "%02d", step))-\(name)" }
		try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: base + ".png"))
	}

	/// Vor dem Foto warten, bis keine Aktivitaetsanzeige (Ladekreisel) mehr sichtbar ist (max. 15 s).
	func waitForIdle(timeout: TimeInterval = 15) {
		let deadline = Date().addingTimeInterval(timeout)
		while Date() < deadline, app.activityIndicators.allElementsBoundByIndex.contains(where: { $0.exists && $0.isHittable }) {
			Thread.sleep(forTimeInterval: 0.5)
		}
	}

	func dump(_ name: String) {
		shot(name)
		try? app.debugDescription.write(toFile: "\(out)/\(String(format: "%02d", step))-\(name).txt", atomically: true, encoding: .utf8)
	}

	func find(_ label: String, type: XCUIElement.ElementType = .any) -> XCUIElement? {
		let exact = app.descendants(matching: type).matching(NSPredicate(format: "label == %@ OR identifier == %@", label, label))
		for i in 0..<min(exact.count, 20) { let e = exact.element(boundBy: i); if e.exists && e.isHittable { return e } }
		let fuzzy = app.descendants(matching: type).matching(NSPredicate(format: "label BEGINSWITH[c] %@", label))
		for i in 0..<min(fuzzy.count, 20) { let e = fuzzy.element(boundBy: i); if e.exists && e.isHittable { return e } }
		return nil
	}

	@discardableResult
	func wait(_ label: String, timeout: TimeInterval = 30, type: XCUIElement.ElementType = .any) -> XCUIElement? {
		let deadline = Date().addingTimeInterval(timeout)
		var e = find(label, type: type)
		while e == nil && Date() < deadline {
			Thread.sleep(forTimeInterval: 0.5)
			dismissPrompts() // z. B. "Passwort sichern?" verdeckt das Ziel
			e = find(label, type: type)
		}
		return e
	}

	func tap(_ label: String, timeout: TimeInterval = 20, type: XCUIElement.ElementType = .any) {
		guard let e = wait(label, timeout: timeout, type: type) else {
			dump("NOTFOUND-\(label.prefix(24))")
			XCTFail("Element nicht gefunden: \(label)")
			return
		}
		e.tap()
	}

	func enterText(field index: Int, secure: Bool = false, _ value: String) {
		let f = (secure ? app.secureTextFields : app.textFields).element(boundBy: index)
		XCTAssertTrue(f.waitForExistence(timeout: 20), "Feld \(index)")
		f.tap()
		if let cur = f.value as? String, !cur.isEmpty, cur != f.placeholderValue {
			f.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: cur.count + 2))
		}
		f.typeText(value)
	}

	func settle(_ seconds: TimeInterval = 1.5) { Thread.sleep(forTimeInterval: seconds) }

	/// Zurueck navigieren, bis eine Zelle mit diesem Label sichtbar ist
	func back(until label: String) {
		for _ in 0..<4 {
			if find(label, type: .cell) != nil { return }
			back(); settle(2)
		}
		XCTAssertNotNil(find(label, type: .cell), "Zurueck zu \(label) fehlgeschlagen")
	}

	/// Zurueck-Knopf der obersten Navigationsleiste
	func back() {
		let b = app.navigationBars.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR identifier == %@", "Zurück", "Einstellungen", "BackButton")).firstMatch
		if b.exists && b.isHittable { b.tap() } else { app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap() }
	}

	// MARK: - App-Store-Motive
	/// Systemabfrage "Passwort sichern?" bzw. andere Hinweise wegtippen
	func dismissPrompts(wait seconds: TimeInterval = 0) {
		let deadline = Date().addingTimeInterval(seconds)
		repeat {
			for label in ["Später", "Not Now", "Jetzt nicht"] {
				let e = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
				if e.exists && e.isHittable { e.tap(); settle(1); return }
			}
			if seconds > 0 { settle(0.5) }
		} while Date() < deadline
	}

	func loginIfNeeded() {
		if wait("Einrichtung starten", timeout: 6) != nil {
			tap("Einrichtung starten")
			enterText(field: 0, env["OCO_SERVER"] ?? "https://testoo.bw.tech")
			tap("Fortfahren", type: .button)
			openLoginPage()
			signIn(user: env["OCO_USER"] ?? "demo")
			dismissPrompts(wait: 10)
			tap("Fertig", type: .button)
			dismissPrompts(wait: 5)
		}
		// Kontenliste -> erstes Konto oeffnen
		if let account = wait("Konto ", timeout: 8, type: .cell) { account.tap() }
		dismissPrompts()
		XCTAssertNotNil(wait("Fotos", timeout: 40), "Dateiliste nicht geladen")
	}

	/// Auf dem iPad die Seitenleiste (enthaelt das Logo) ausblenden
	func hideSidebarOnPad() {
		guard isPad else { return }
		let sidebarItem = app.cells.matching(NSPredicate(format: "label == %@", "Favoriten")).firstMatch
		if sidebarItem.exists && sidebarItem.isHittable {
			let toggles = app.buttons.matching(NSPredicate(format: "label == %@", "Seitenleiste ein-/ausblenden"))
			for i in 0..<toggles.count where toggles.element(boundBy: i).isHittable { toggles.element(boundBy: i).tap(); break }
			settle()
		}
	}

	/// Eintrag der Seitenleiste oeffnen (iPhone und iPad): Seitenleiste bei Bedarf einblenden, Eintrag waehlen,
	/// danach wieder ausblenden, falls sie noch sichtbar ist
	func openSidebarItem(_ label: String) {
		if find(label, type: .cell) == nil { toggleSidebar() }
		tap(label, type: .cell)
		settle(2)
		if find(label, type: .cell) != nil { toggleSidebar() }
	}

	func toggleSidebar() {
		let toggles = app.buttons.matching(NSPredicate(format: "label == %@", "Seitenleiste ein-/ausblenden"))
		for i in 0..<toggles.count where toggles.element(boundBy: i).isHittable { toggles.element(boundBy: i).tap(); break }
		settle()
	}

	func setLayout(_ name: String) {
		tap("Layout ändern")
		tap(name, type: .button)
		settle(2)
	}

	func testAppStore() throws {
		app.launch()
		loginIfNeeded()
		hideSidebarOnPad()
		setLayout("Liste")
		settle(3)
		shot("01-dateien", numbered: false)

		// Fotos als Bild-Kacheln
		tap("Fotos", type: .cell)
		settle(2)
		setLayout("Bild-Kacheln")
		settle(4)
		shot("02-fotos", numbered: false)
		setLayout("Liste")
		back(until: "Projektplan 2027")

		// PDF-Vorschau
		tap("Projektplan 2027", type: .cell)
		settle(8)
		shot("03-vorschau", numbered: false)
		back(until: "Projekte")
		hideSidebarOnPad()

		// Favoriten (ohne Server-Adresse im Bild, anders als ein Freigabe-Link)
		openSidebarItem("Favoriten")
		settle(3)
		shot("04-favoriten", numbered: false)
		openSidebarItem("Dateien")
		XCTAssertNotNil(wait("Projektplan 2027", timeout: 20, type: .cell), "Dateiliste nach den Favoriten nicht geladen")

		// Suche
		tap("client.search")
		settle(1)
		app.typeText("Projekt")
		settle(5)
		app.typeText("\n")
		settle(2)
		shot("05-suche", numbered: false)
		if find("Abbrechen", type: .button) != nil { tap("Abbrechen", type: .button) }
		settle(2)

		// Aktionen zu einer Datei
		tap("Mehr zu Projektplan 2027.pdf")
		settle(2)
		shot("06-aktionen", numbered: false)
		app.swipeDown(); settle(1.5)
		if find("Abbrechen", type: .button) != nil { tap("Abbrechen", type: .button) }
	}

	// MARK: - Web-Anmeldung (OAuth2)
	var loginPage: XCUIApplication { XCUIApplication(bundleIdentifier: "com.apple.SafariViewService") }

	/// Vom Schritt "Anmelden" bis zur geladenen Anmeldeseite des Servers
	func openLoginPage() {
		XCTAssertNotNil(wait("Anmeldeseite öffnen", timeout: 30, type: .button), "Keine Web-Anmeldung angeboten")
		dump("web-anmelden")
		tap("Anmeldeseite öffnen", type: .button)

		// Systemabfrage der Anmeldesitzung: "... moechte ... zum Anmelden verwenden"
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		let confirm = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["Fortfahren", "Weiter", "Continue"])).firstMatch
		XCTAssertTrue(confirm.waitForExistence(timeout: 20), "Systemabfrage fehlt")
		shot("web-systemabfrage")
		confirm.tap()

		XCTAssertTrue(loginPage.webViews.firstMatch.waitForExistence(timeout: 30), "Anmeldeseite fehlt")
		settle(6)
		shot("web-seite")
		try? loginPage.debugDescription.write(toFile: "\(out)/web-seite.txt", atomically: true, encoding: .utf8)
	}

	/// Anmeldung auf der Seite und Zustimmung, danach ist die App wieder vorn
	func signIn(user: String) {
		let web = loginPage
		let userField = web.textFields.firstMatch
		XCTAssertTrue(userField.waitForExistence(timeout: 20), "Feld Benutzername fehlt")
		userField.tap()
		// Tippen auf ein zweites Feld einer Webseite gibt ihm keinen Tastaturfokus: mit Tabulator weiter
		userField.typeText(user + "\t")
		settle(1)
		web.secureTextFields.firstMatch.typeText((env["OCO_PASS"] ?? "") + "\n")

		let authorize = web.buttons["Autorisieren"]
		XCTAssertTrue(authorize.waitForExistence(timeout: 30), "Zustimmungsseite fehlt")
		shot("web-zustimmung")
		authorize.tap()
	}

	/// Anmeldung ueber die Anmeldeseite des Servers. Ohne OCO_USER endet der Test auf der Anmeldeseite,
	/// z. B. bei Servern mit fremdem Anmeldedienst (Azure), fuer den es hier keine Zugangsdaten gibt.
	func testWebLogin() throws {
		app.launch()
		if wait("Einrichtung starten", timeout: 8) != nil { tap("Einrichtung starten") }
		enterText(field: 0, env["OCO_SERVER"] ?? "https://testoo.bw.tech")
		tap("Fortfahren", type: .button)
		openLoginPage()
		guard let user = env["OCO_USER"], !user.isEmpty else { return }
		signIn(user: user)

		XCTAssertNotNil(wait("Fertig", timeout: 40, type: .button), "Anmeldung nicht abgeschlossen")
		shot("web-fertig")
		tap("Fertig", type: .button)
		dismissPrompts(wait: 5)
		if let account = wait("Konto ", timeout: 8, type: .cell) { account.tap() }
		dismissPrompts()
		// Dateizeilen tragen den Namen ohne Endung, deshalb ein Ordner
		XCTAssertNotNil(wait(env["OCO_EXPECT"] ?? "Dokumente", timeout: 40), "Dateiliste nicht geladen")
		shot("web-dateien")
	}

	// MARK: - Generischer Treiber
	func testDrive() throws {
		continueAfterFailure = true
		let actions = (env["OCO_ACTIONS"] ?? "dump:start").components(separatedBy: ";;")
		for a in actions where !a.isEmpty {
			let parts = a.split(separator: ":", maxSplits: 1).map(String.init)
			let cmd = parts[0], arg = parts.count > 1 ? parts[1] : ""
			switch cmd {
				case "launch": app.terminate(); app.launch()
				case "activate": app.activate()
				case "terminate": app.terminate()
				case "wait": settle(Double(arg) ?? 2)
				case "waitfor": wait(arg, timeout: 40)
				case "tap": tap(arg)
				case "tapbutton": tap(arg, type: .button)
				case "tapcell": tap(arg, type: .cell)
				case "tapopt": find(arg)?.tap()
				case "tapnth":
					// tapnth:<label>#<index> – n-tes Element mit diesem Label
					let kv = arg.components(separatedBy: "#")
					let q = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", kv[0]))
					q.element(boundBy: Int(kv[1]) ?? 0).tap()
				case "longpress":
					if let e = wait(arg) { e.press(forDuration: 1.2) } else { XCTFail("nicht gefunden: \(arg)") }
				case "field", "secure":
					// field:<index>=<Wert oder $ENV>
					let kv = arg.split(separator: "=", maxSplits: 1).map(String.init)
					var value = kv.count > 1 ? kv[1] : ""
					if value.hasPrefix("$") { value = env[String(value.dropFirst())] ?? "" }
					enterText(field: Int(kv[0]) ?? 0, secure: cmd == "secure", value)
				case "typetext": app.typeText(arg)
				case "back": back()
				case "enter": app.typeText("\n")
				case "swipeup": app.swipeUp()
				case "swipedown": app.swipeDown()
				case "swipeleft": (find(arg) ?? app).swipeLeft()
				case "home": XCUIDevice.shared.press(.home)
				case "portrait": XCUIDevice.shared.orientation = .portrait
				case "landscape": XCUIDevice.shared.orientation = .landscapeLeft
				case "shot": shot(arg)
				case "rawshot":
					// ohne auf das Ende der Ladeanzeige zu warten, um Zwischenzustaende festzuhalten
					try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(out)/\(arg).png"))
				case "dump": dump(arg)
				default: XCTFail("unbekannte Aktion \(cmd)")
			}
		}
	}
}
