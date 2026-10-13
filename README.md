# Closer

**Closer** ist eine iOS-App, die dir hilft, soziale Kontakte bewusst zu pflegen und die Menschen, die dir wichtig sind, näher bei dir zu halten. Du erfasst Personen (direkt aus deinen Kontakten) und planst pro Person Erinnerungen, damit Beziehungen im Alltag nicht untergehen: Blumen für die Partnerin, ein Anruf beim Grossvater oder endlich das Treffen mit dem Studienkollegen.

| | |
|---|---|
| Plattform | iOS / iPadOS 26.5+ |
| Sprache | Swift 5 (Swift 6 Concurrency-Features aktiv), SwiftUI, Observation |
| Tooling | Xcode 26.6+ |
| Bundle ID | `ch.murtit.closer` |
| Version | siehe [`CHANGELOG.md`](CHANGELOG.md) |

## Schnellstart

```bash
git clone git@github.com:murtit/closer.git
cd closer
open Closer.xcodeproj
```

Scheme **Closer** wählen, Simulator auswählen, `⌘R` zum Starten, `⌘U` für die Tests.

Für ein echtes Gerät wird ein Apple-Developer-Team benötigt (Target › *Signing & Capabilities*). Es sind keine Umgebungsvariablen, API-Keys oder Abhängigkeiten von Drittanbietern nötig.

Tests über die Kommandozeile:

```bash
xcodebuild test -project Closer.xcodeproj -scheme Closer \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

### Screenshots & UI-Tests

`CloserUITests/ScreenshotTests.swift` startet die App mit dem Argument `-demo-data` (feste Beispielpersonen, nur Debug-Builds) und hält die Hauptscreens im Light und Dark Mode fest. In der CI werden die Bilder bei jedem Pull Request exportiert (`scripts/export-screenshots.py`), als Artefakt *Screenshots* hochgeladen und per `scripts/publish-screenshots.sh` als PR-Kommentar gezeigt. Die Bilddateien liegen dafür im Branch `ci-screenshots` unter `pr-<Nummer>/`.

Lokal: in Xcode `⌘U` oder nur die UI-Tests mit `-only-testing:CloserUITests`. Die Screenshots stehen danach im Report Navigator beim jeweiligen Test. Die Demo-Daten lassen sich auch von Hand ansehen: Scheme › *Run* › *Arguments* › `-demo-data` hinzufügen.

## Projektstruktur

```
closer/
├── Closer/                     # App-Target (Xcode-synchronisierter Ordner)
│   ├── App/                    # Einstiegspunkt (@main) und Root-Navigation
│   ├── Core/
│   │   ├── Demo/               # Beispieldaten für UI-Tests und Screenshots (nur Debug)
│   │   ├── Models/             # Domänenmodelle (Person, Relationship, Reminder), UI-unabhängig
│   │   └── Services/           # Persistenz, Benachrichtigungen, Kontakt-Import
│   ├── DesignSystem/           # Farben, Typografie, wiederverwendbare Komponenten
│   ├── Features/               # Ein Ordner pro Feature (View + ViewModel)
│   │   ├── Home/
│   │   │   └── Components/     # Feature-spezifische Unter-Views
│   │   └── People/
│   │       └── Components/
│   └── Resources/              # Asset-Kataloge, Lokalisierung
├── CloserTests/                # Unit-Tests (Swift Testing), spiegelt die App-Struktur
├── CloserUITests/              # UI- und Screenshot-Tests (XCTest)
├── Closer.xcodeproj/           # Xcode-Projekt inkl. geteiltem Scheme
├── docs/                       # Entwickler-Dokumentation (Releases, Konventionen)
├── scripts/                    # Hilfsskripte (z. B. Versionierung)
└── .github/                    # CI, PR- und Issue-Vorlagen, CODEOWNERS
```

Das Projekt nutzt **File-System-Synchronized Groups** (Xcode 16+): Neue Dateien in `Closer/`, `CloserTests/` oder `CloserUITests/` werden automatisch ins jeweilige Target aufgenommen. Es muss nichts manuell im Projekt-Navigator registriert werden.

### Architektur

- **MVVM** mit SwiftUI und `@Observable`-ViewModels.
- ViewModels werden per `.environment(_:)` injiziert. Abhängigkeiten wie `PeopleStore`, `NotificationScheduling` oder `UserDefaults` kommen über den Initializer, damit sie in Tests ersetzt werden können.
- Personen samt Erinnerungen und Fotos liegen als JSON in *Application Support* (`people.json`).
- Kontakte werden über `CNContactPickerViewController` gewählt. Der Picker läuft ausserhalb der App, deshalb braucht Closer weder die Kontakte-Berechtigung noch `NSContactsUsageDescription`.
- Erinnerungen sind lokale Benachrichtigungen (`UNCalendarNotificationTrigger`), eine pro Erinnerung. iOS erlaubt maximal 64 geplante Benachrichtigungen pro App.
- Neue Features bekommen einen eigenen Ordner unter `Features/`. Geteilte Modelle gehören nach `Core/`, geteilte UI-Bausteine nach `DesignSystem/`.

## Versionierung & Releases

Closer folgt [Semantic Versioning](https://semver.org/lang/de/) und führt ein [Changelog](CHANGELOG.md) im Format *Keep a Changelog*.

- **`MARKETING_VERSION`** (`CFBundleShortVersionString`) = SemVer, z. B. `0.1.0`
- **`CURRENT_PROJECT_VERSION`** (`CFBundleVersion`) = fortlaufende Build-Nummer, steigt mit jedem TestFlight-Upload

Details zum Release-Ablauf: [`docs/RELEASING.md`](docs/RELEASING.md).

## Mitwirken

Branching-Modell, Commit-Konventionen und Review-Prozess: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Lizenz

Proprietär. © murtit. Alle Rechte vorbehalten.
