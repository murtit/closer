# Mitwirken an Closer

## Branching

Wir arbeiten mit **trunk-based development**:

- `main` ist immer releasefähig und geschützt. Änderungen kommen ausschliesslich per Pull Request.
- Feature-Branches sind kurzlebig und folgen dem Schema `<typ>/<kurzbeschreibung>`, z. B. `feat/contact-groups`, `fix/notification-time`, `chore/update-ci`.
- Releases werden mit einem Git-Tag `vMAJOR.MINOR.PATCH` auf `main` markiert (siehe [`docs/RELEASING.md`](docs/RELEASING.md)).

## Commits

Commit-Nachrichten folgen [Conventional Commits](https://www.conventionalcommits.org/de/v1.0.0/):

```
<typ>(<optionaler scope>): <kurze Beschreibung im Imperativ>
```

| Typ | Verwendung | SemVer-Auswirkung |
|---|---|---|
| `feat` | Neue Funktion | MINOR |
| `fix` | Fehlerbehebung | PATCH |
| `refactor` | Umbau ohne Verhaltensänderung | – |
| `test` | Tests | – |
| `docs` | Dokumentation | – |
| `chore` / `ci` / `build` | Tooling, CI, Projekt-Setup | – |

Breaking Changes werden mit `!` (z. B. `feat!: …`) oder einem `BREAKING CHANGE:`-Footer markiert und führen zu einem MAJOR-Release.

## Pull Requests

1. Branch von `main` erstellen.
2. Änderungen inkl. Tests umsetzen, `⌘U` muss grün sein.
3. Eintrag unter `## [Unreleased]` in `CHANGELOG.md` ergänzen.
4. PR mit der Vorlage öffnen: Zusammenfassung, Akzeptanzkriterien, Screenshots bei UI-Änderungen, manuelle Schritte.
5. CI muss grün sein und mindestens ein Review (CODEOWNERS) vorliegen.
6. Merge per **Squash & Merge**, der PR-Titel wird zur Commit-Nachricht und folgt daher ebenfalls Conventional Commits.

## Code-Konventionen

- Swift API Design Guidelines, 4 Leerzeichen Einrückung (siehe `.editorconfig`).
- Ein Typ pro Datei, Dateiname = Typname. Extensions heissen `Typ+Thema.swift`.
- Views enden auf `View`, ViewModels auf `ViewModel`.
- `// MARK: -` zur Gliederung grösserer Typen.
- Abhängigkeiten (Persistenz, Services) werden per Initializer injiziert, nicht als Singleton direkt verwendet.
- Neue Features unter `Closer/Features/<Feature>/`, passende Tests unter `CloserTests/Features/<Feature>/`.
