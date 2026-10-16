# Closer

**Closer** ist eine iOS-App, die dir hilft, soziale Kontakte bewusst zu pflegen und die Menschen, die dir wichtig sind, näher bei dir zu halten. Du erfasst Personen (direkt aus deinen Kontakten) und planst pro Person Erinnerungen, damit Beziehungen im Alltag nicht untergehen: Blumen für die Partnerin und eine Erinnerung vor eurem Jahrestag, ein Anruf beim Grossvater oder endlich das Treffen mit dem Studienkollegen.

| | |
|---|---|
| Plattform | iOS / iPadOS 26.5+ |
| Sprache | Swift 5 (Swift 6 Concurrency-Features aktiv), SwiftUI, Observation |
| Tooling | Xcode 26.6+ |
| Bundle ID | `ch.murtit.closer.app` |
| Version | siehe [`CHANGELOG.md`](CHANGELOG.md) |

## Schnellstart

```bash
git clone git@github.com:murtit/closer.git
cd closer
open Closer.xcodeproj
```

Scheme **Closer** wählen, Simulator auswählen, `⌘R` zum Starten, `⌘U` für die Tests.

Für ein echtes Gerät wird ein Apple-Developer-Team benötigt (Target › *Signing & Capabilities*). Es sind keine Umgebungsvariablen, API-Keys oder Abhängigkeiten von Drittanbietern nötig. Die KI-Ideen laufen nur auf Geräten mit Apple Intelligence (iPhone 15 Pro und neuer); im Simulator nur, wenn der Mac Apple Intelligence unterstützt und es eingeschaltet ist.

Tests über die Kommandozeile:

```bash
xcodebuild test -project Closer.xcodeproj -scheme Closer \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

### Screenshots & UI-Tests

`CloserUITests/ScreenshotTests.swift` startet die App mit dem Argument `-demo-data` (feste Beispielpersonen, nur Debug-Builds) und hält die Hauptscreens im Light und Dark Mode fest. In der CI werden die Bilder bei jedem Pull Request exportiert (`scripts/export-screenshots.py`), als Artefakt *Screenshots* hochgeladen und per `scripts/publish-screenshots.sh` als PR-Kommentar gezeigt. Die Bilddateien liegen dafür im Branch `ci-screenshots` unter `pr-<Nummer>/`.

Lokal: in Xcode `⌘U` oder nur die UI-Tests mit `-only-testing:CloserUITests`. Die Screenshots stehen danach im Report Navigator beim jeweiligen Test. Die Demo-Daten lassen sich auch von Hand ansehen: Scheme › *Run* › *Arguments* › `-demo-data` hinzufügen. Mit `-demo-appearance dark` bzw. `light` lässt sich das Erscheinungsbild zusätzlich erzwingen.

## Projektstruktur

```
closer/
├── Closer/                     # App-Target (Xcode-synchronisierter Ordner)
│   ├── App/                    # Einstiegspunkt (@main) und Root-Navigation
│   ├── Core/
│   │   ├── Demo/               # Beispieldaten für UI-Tests und Screenshots (nur Debug)
│   │   ├── Models/             # Domänenmodelle (Person, Relationship, Reminder), UI-unabhängig
│   │   └── Services/           # Persistenz, Benachrichtigungen, Kontakt-Import
│   ├── DesignSystem/           # Farb-Palette (Light/Dark), wiederverwendbare Komponenten
│   ├── Features/               # Ein Ordner pro Feature (View + ViewModel)
│   │   ├── Home/
│   │   │   └── Components/     # Feature-spezifische Unter-Views
│   │   ├── Ideas/              # KI-Ideen (Apple Intelligence) und Karte mit Orten
│   │   │   └── Components/
│   │   ├── Partner/            # Jahrestag und Partner-Karte
│   │   │   └── Components/
│   │   └── People/
│   │       └── Components/
│   └── Resources/              # Asset-Kataloge, Benachrichtigungstöne (Sounds/, generiert)
├── CloserTests/                # Unit-Tests (Swift Testing), spiegelt die App-Struktur
├── CloserUITests/              # UI- und Screenshot-Tests (XCTest)
├── Closer.xcodeproj/           # Xcode-Projekt inkl. geteiltem Scheme
├── design/app-icon/            # App-Icon als SVG (generiert, nicht von Hand bearbeiten)
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
- Es gibt höchstens eine:n Partner:in (`PeopleViewModel.canBePartner`). Ihr bzw. sein Jahrestag (`Anniversary`) erzeugt jährliche Erinnerungen für den Tag selbst und jeden Vorlauf (Standard: 14 und 3 Tage), mit festen IDs, damit sie beim Ändern sauber ersetzt werden. Sie werden nicht unter den eigenen Erinnerungen gespeichert, sondern bei Bedarf abgeleitet (`Person.allReminders()`).
- Pro Person lässt sich ein Benachrichtigungston wählen (`NotificationSound`, gespeichert in `Person.notificationSound`; fehlt der Wert, spielt der iOS-Standardton). Alle Erinnerungen dieser Person, auch die des Jahrestags, werden mit diesem Ton geplant.
- **Ideen** für Dates, Geschenke und Unternehmungen schreibt Apples On-Device-Sprachmodell (*Foundation Models*, Apple Intelligence): kostenlos, ohne API-Key und ohne dass Eingaben das iPhone verlassen. `FoundationModelIdeaGenerator` erzeugt mit `@Generable`-Typen strukturierte Ideen (Emoji, Titel, Beschreibung, Suchbegriff für Apple Karten), `IdeaPrompt` baut den Prompt aus Beziehung, Budget, Hinweis und Jahrestag. Auf iPhones ohne Apple Intelligence (`IdeaAvailability.unsupported`) ist die Funktion ganz ausgeblendet; ist Apple Intelligence nur ausgeschaltet oder das Modell noch nicht geladen, zeigt Closer einen Hinweis. Die Verfügbarkeit wird bei jedem Wechsel in den Vordergrund neu gelesen.
- Zu jeder Idee zeigt eine **Apple-Karte** (MapKit) passende Orte in der Nähe: `MKLocalSearch` sucht den Suchbegriff der Idee rund um den Standort (`LocationProvider`, Berechtigung „Beim Verwenden der App“), ohne Standort rund um Zürich bzw. den Kartenausschnitt. Ein Tipp auf einen Ort öffnet Apples Ortskarte mit Öffnungszeiten und Route. Modell, Ortssuche und Standort stecken in `IdeaServices` und werden per `.environment(_:)` injiziert; mit `-demo-data` liefern `DemoIdeaGenerator` und `DemoPlaceSearch` feste Ergebnisse.
- Neue Features bekommen einen eigenen Ordner unter `Features/`. Geteilte Modelle gehören nach `Core/`, geteilte UI-Bausteine nach `DesignSystem/`.

### Design & App-Icon

Die Farben stammen aus dem App-Icon: Tannengrün `#10231F`, Koralle `#F5A58C` und Creme-Rosé `#F8F3E9`. `Closer/DesignSystem/Palette.swift` leitet daraus semantische Tokens mit je einer Light- und Dark-Variante ab (`background`, `surface`, `accent`, …). Im Dark Mode sind Flächen neutral fast schwarz, Tannengrün ist dort nur Akzent. Hell, Dunkel oder „Automatisch“ wählt man in der App unter *Einstellungen* (`AppearancePreference`, gespeichert in `UserDefaults`). Views verwenden nur diese Tokens (`Color.closerAccent`, `.closerSurface`, …), nie feste Farbwerte, damit beide Modi stimmig bleiben. `PaletteTests` prüft den Kontrast jedes Text/Hintergrund-Paars nach WCAG AA.

Das Icon wird aus seiner Geometrie erzeugt, nicht von Hand gezeichnet:

```bash
scripts/generate-app-icon.py          # SVGs in design/app-icon/ und PNGs im Asset-Katalog neu erzeugen
scripts/generate-app-icon.py --check  # prüft, ob die eingecheckten Dateien aktuell sind (läuft in der CI)
```

### Benachrichtigungstöne

Apps dürfen die Klingel- und Hinweistöne des iPhones nicht verwenden. Für Benachrichtigungen spielt iOS nur den Standardton oder Töne, die mit der App ausgeliefert werden (`UNNotificationSound(named:)`, `.wav`/`.aiff`/`.caf`, höchstens 30 Sekunden). Closer bringt deshalb eigene Töne mit: Nähe, Funke, Tropfen, Morgen und Gruss. Sie werden wie das Icon aus Code erzeugt (ein paar Noten, glockenartig synthetisiert), nicht von Hand eingespielt:

```bash
scripts/generate-notification-sounds.py          # Closer/Resources/Sounds/*.wav neu erzeugen
scripts/generate-notification-sounds.py --check  # prüft, ob die eingecheckten Töne aktuell sind (läuft in der CI)
```

Zusätzlich kann man **eigene Töne** aus der Dateien-App hinzufügen (z. B. MP3, M4A, WAV, AIFF). `SoundFileConverter` wandelt sie in 16-bit-PCM-CAF um und kürzt sie auf 29,5 Sekunden mit kurzem Ausblenden; `SoundLibrary` legt sie unter `Library/Sounds/<UUID>.caf` ab, dem einzigen Ordner ausserhalb des Bundles, in dem iOS Benachrichtigungstöne sucht. Die Namen stehen daneben in `custom-sounds.json`. Eigene Töne gelten für alle Personen; wird einer gelöscht, fallen die betroffenen Personen auf „Standard“ zurück.

Einen Closer-Ton ändern oder ergänzen: Funktion im Skript anpassen bzw. hinzufügen und in `FILES` eintragen, Skript ausführen, dann den Fall in `NotificationSound` ergänzen (Dateiname `closer-<rawValue>.wav`). `SoundPreviewPlayerTests` prüft, dass jeder angebotene Ton im Bundle liegt und das Format stimmt.

## Versionierung & Releases

Closer folgt [Semantic Versioning](https://semver.org/lang/de/) und führt ein [Changelog](CHANGELOG.md) im Format *Keep a Changelog*.

- **`MARKETING_VERSION`** (`CFBundleShortVersionString`) = SemVer, z. B. `0.1.0`
- **`CURRENT_PROJECT_VERSION`** (`CFBundleVersion`) = fortlaufende Build-Nummer, steigt mit jedem TestFlight-Upload

Details zum Release-Ablauf: [`docs/RELEASING.md`](docs/RELEASING.md).

## Mitwirken

Branching-Modell, Commit-Konventionen und Review-Prozess: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Lizenz

Proprietär. © murtit. Alle Rechte vorbehalten.
