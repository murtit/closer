# Changelog

Alle relevanten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

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
