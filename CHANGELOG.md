# Changelog

Alle relevanten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Added
- **Eigene Benachrichtigungstöne**: In der Tonauswahl lässt sich unter *Eigene Töne* eine Audiodatei aus der Dateien-App hinzufügen (z. B. eine Sprachnachricht oder ein Lied als MP3, M4A, WAV oder AIFF). Closer kürzt sie auf unter 30 Sekunden mit sanftem Ausblenden, spielt sie zur Probe ab und wählt sie für die Person. Eigene Töne stehen bei allen Personen zur Auswahl und lassen sich per Wischen löschen; betroffene Personen erhalten dann wieder den Standardton.
- **Benachrichtigungston pro Person**: Im Formular einer Person unter *Benachrichtigungen › Ton* wählst du, welcher Ton ihre Erinnerungen ankündigt. Neben dem iOS-Standardton gibt es fünf eigene Closer-Töne (Nähe, Funke, Tropfen, Morgen, Gruss); antippen spielt sie zur Probe ab. Der Ton gilt für alle Erinnerungen der Person, auch für die des Jahrestags. Bestehende Personen behalten den Standardton.
- `scripts/generate-notification-sounds.py` erzeugt die Töne als WAV unter `Closer/Resources/Sounds/`; die CI prüft, dass die Dateien zum Skript passen.
- Screenshot-Test für die Tonauswahl.
- **Partner:in im Fokus**: Auf „Heute“ steht ganz oben eine eigene, warme Karte für deine:n Partner:in mit Foto, „Seit … Tagen zusammen“, Countdown zum nächsten Jahrestag und einer Schaltfläche für eine liebe Nachricht. Ein Tipp öffnet die Person.
- **Jahrestag**: Für die Partnerin bzw. den Partner lässt sich der Tag eintragen, an dem ihr zusammengekommen seid (beim Erfassen oder im Personen-Detail). Closer erinnert jedes Jahr am Tag selbst und standardmässig schon 2 Wochen („Zeit für ein Geschenk“) und 3 Tage vorher („Zeit, ein Date zu planen“). Vorlauf (1, 3, 7, 14 oder 30 Tage), Uhrzeit und Ein/Aus sind einstellbar. Jahrestags-Erinnerungen erscheinen auch bei den nächsten Erinnerungen.
- Erinnerungen können jetzt auch **jährlich** wiederholt werden (z. B. für Geburtstage). Am 29. Februar fällt eine jährliche Erinnerung in anderen Jahren auf den 28.
- Farb-Tokens `partner`, `partnerEnd`, `onPartner` und `partnerAccent` für die Partner-Karte, mit Kontrast-Tests.
- Screenshot-Test für das Jahrestags-Formular.
- **Personen**: Mehrere Personen mit Beziehung (Partner:in, Familie, Freunde oder eigene Bezeichnung) erfassen, bearbeiten und löschen.
- Kontakt-Import über den System-Kontaktpicker: Name, Foto, Telefonnummer (Mobilnummer bevorzugt) und E-Mail werden übernommen, ohne dass Closer Zugriff auf alle Kontakte braucht.
- Erinnerungen pro Person, einmalig, täglich, wöchentlich oder monatlich, mit Vorschlägen je Beziehung (z. B. „Blumen kaufen“ für Partner:in, „Anrufen und fragen, wie es geht“ für Familie, „Melden und etwas abmachen“ für Freunde).
- Personen-Detail mit Schnellaktionen zum Anrufen, Schreiben und Mailen.
- Startseite zeigt die nächsten anstehenden Erinnerungen über alle Personen.
- Tests für Modelle, Persistenz, Kontakt-Import und `PeopleViewModel`.
- UI-Test-Target `CloserUITests`: Screenshot-Tests gehen die Hauptscreens (Heute, Personen, Person hinzufügen, Person, Erinnerung, Jahrestag, Benachrichtigungston, Einstellungen) im Light und Dark Mode durch.
- Startargument `-demo-data` (nur Debug) startet die App mit festen Beispielpersonen in einem temporären Speicher, ohne echte Daten oder Benachrichtigungen anzufassen. `-demo-appearance light|dark` erzwingt das Erscheinungsbild.
- CI erstellt bei jedem Pull Request Screenshots im Simulator, lädt sie als Artefakt *Screenshots* hoch und zeigt sie in einem automatisch aktualisierten PR-Kommentar.
- Neues App-Icon: zwei leicht überlappende Kreise in Korallorange (`#F5A58C`) und Creme-Rosé (`#F8F3E9`) auf tiefem Tannengrün (`#10231F`), inklusive Dark- und Tinted-Variante. Quelle als SVG unter `design/app-icon/`, erzeugt mit `scripts/generate-app-icon.py`; die CI prüft, dass die PNGs zur Vorlage passen.
- **Einstellungen** (Zahnrad auf „Heute“): Erscheinungsbild „Automatisch“, „Hell“ oder „Dunkel“ direkt in der App wählen. Standard ist „Automatisch“.
- Design-System mit semantischen Farb-Tokens (`Palette`, `Color+Theme`), je mit Light- und Dark-Variante, plus `CloserMarkView` (Bildmarke des Icons). Tests prüfen Markenfarben und WCAG-Kontrast (≥ 4.5:1) aller Text/Hintergrund-Paare in beiden Modi.

### Changed
- Es gibt nur noch **eine:n Partner:in**: Ist bereits jemand als Partner:in erfasst, ist die Auswahl „Partner:in“ für weitere Personen deaktiviert, und neue Personen starten mit „Familie“. Bestehende Daten mit mehreren Partner:innen bleiben erhalten; als Partner:in auf „Heute“ gilt die zuerst erfasste Person.
- App-Design auf die Farben des Icons umgestellt: Creme-Hintergrund im Light Mode, Tannengrün im Dark Mode, Akzentfarbe Terrakotta bzw. Koralle. Die Hervorhebungskarte auf „Heute“ ist tannengrün mit Bildmarke statt Rosa-Verlauf, Avatare ohne Foto zeigen Initialen auf Koralle. Listen und Formulare nutzen die neuen Hintergründe.
- Dark Mode ruhiger: Hintergründe und Listen sind ein warmes, neutrales Fast-Schwarz statt Tannengrün. Tannengrün bleibt als Akzent (Hervorhebungskarte auf „Heute“), Koralle als Akzentfarbe.
- Die globale `AccentColor` entspricht der neuen Akzentfarbe (Light/Dark).
- Der Tab „Erinnerungen“ ist durch „Personen“ ersetzt; Erinnerungen gehören jetzt immer zu einer Person.
- Daten werden als JSON-Datei in *Application Support* gespeichert statt in `UserDefaults`.
- Benachrichtigungen zeigen den Namen der Person als Titel und werden beim App-Start mit den gespeicherten Daten abgeglichen.
- Emoji-Auswahl nach `DesignSystem/Components` verschoben und um Freundschafts- und Alltags-Emojis ergänzt.

### Removed
- Rosa Farbschema (`rosePrimary`, `roseDeep`, `roseBlush`) zugunsten der neuen Palette.
- Globale „Liebesgesten“ aus 0.1.0. Bestehende Einträge können keiner Person zugeordnet werden; ihre geplanten Benachrichtigungen werden beim ersten Start entfernt.

## [0.1.0] - 2026-10-13

### Added
- Unit-Test-Target `CloserTests` (Swift Testing) mit Tests für `Reminder` und `RemindersViewModel`.
- Geteiltes Xcode-Scheme `Closer`, damit Build und Tests für alle Entwickler und die CI identisch laufen.
- GitHub-Actions-Workflow für Build und Tests auf dem iOS-Simulator.
- Projekt-Dokumentation: README, CONTRIBUTING, Release-Prozess, PR- und Issue-Vorlagen, CODEOWNERS.
- `scripts/bump-version.sh` zum Setzen von Marketing-Version und Build-Nummer.
- `.gitignore` und `.editorconfig`.

### Changed
- App von *Lovenote* (`LoveApp`) in **Closer** umbenannt: Xcode-Projekt, Target, Scheme, Modul, Produktname und Anzeigename.
- Bundle-ID von `ch.murtit.LoveApp` auf `ch.murtit.closer` geändert.
- Quellcode nach Features gegliedert (`App/`, `Core/`, `DesignSystem/`, `Features/`, `Resources/`).
- `LoveAppApp` → `CloserApp`, `ContentView` → `RootView`, `StatCard` in eigene Datei ausgelagert.
- `RemindersViewModel` erhält `UserDefaults` per Initializer (Testbarkeit).
- Versionsschema auf SemVer umgestellt (`1.0` → `0.1.0`).

### Removed
- Benutzerspezifische Xcode-Dateien (`xcuserdata`) aus dem Repository.

[Unreleased]: https://github.com/murtit/closer/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/murtit/closer/releases/tag/v0.1.0
