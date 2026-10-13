# Closer

**Closer** ist eine iOS-App, die dir hilft, soziale Kontakte bewusst zu pflegen und die Menschen, die dir wichtig sind, näher bei dir zu halten. Kleine, wiederkehrende Gesten werden als tägliche Erinnerungen geplant, damit Beziehungen im Alltag nicht untergehen.

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

## Projektstruktur

```
closer/
├── Closer/                     # App-Target (Xcode-synchronisierter Ordner)
│   ├── App/                    # Einstiegspunkt (@main) und Root-Navigation
│   ├── Core/
│   │   └── Models/             # Domänenmodelle, UI-unabhängig
│   ├── DesignSystem/           # Farben, Typografie, wiederverwendbare Styles
│   ├── Features/               # Ein Ordner pro Feature (View + ViewModel)
│   │   ├── Home/
│   │   │   └── Components/     # Feature-spezifische Unter-Views
│   │   └── Reminders/
│   │       └── Components/
│   └── Resources/              # Asset-Kataloge, Lokalisierung
├── CloserTests/                # Unit-Tests (Swift Testing), spiegelt die App-Struktur
├── Closer.xcodeproj/           # Xcode-Projekt inkl. geteiltem Scheme
├── docs/                       # Entwickler-Dokumentation (Releases, Konventionen)
├── scripts/                    # Hilfsskripte (z. B. Versionierung)
└── .github/                    # CI, PR- und Issue-Vorlagen, CODEOWNERS
```

Das Projekt nutzt **File-System-Synchronized Groups** (Xcode 16+): Neue Dateien in `Closer/` oder `CloserTests/` werden automatisch ins jeweilige Target aufgenommen. Es muss nichts manuell im Projekt-Navigator registriert werden.

### Architektur

- **MVVM** mit SwiftUI und `@Observable`-ViewModels.
- ViewModels werden per `.environment(_:)` injiziert. Abhängigkeiten wie `UserDefaults` kommen über den Initializer, damit sie in Tests ersetzt werden können.
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
