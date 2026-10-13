# Release-Prozess

## Versionsschema

| Feld | Xcode-Setting | Info.plist | Beispiel |
|---|---|---|---|
| Version (SemVer) | `MARKETING_VERSION` | `CFBundleShortVersionString` | `0.2.0` |
| Build | `CURRENT_PROJECT_VERSION` | `CFBundleVersion` | `7` |

- **MAJOR**: inkompatible Änderungen (z. B. Datenformat ohne Migration).
- **MINOR**: neue Funktionen, rückwärtskompatibel.
- **PATCH**: Fehlerbehebungen.
- Die Build-Nummer steigt mit jedem Upload zu App Store Connect und wird nie zurückgesetzt.

Beide Werte werden für alle Targets gemeinsam gepflegt, am einfachsten mit dem Skript:

```bash
scripts/bump-version.sh 0.2.0      # Version setzen, Build +1
scripts/bump-version.sh --build    # nur Build +1 (z. B. zusätzlicher TestFlight-Build)
```

## Ablauf

1. Release-Branch `release/x.y.z` von `main` erstellen.
2. `scripts/bump-version.sh x.y.z` ausführen.
3. In `CHANGELOG.md` den Abschnitt *Unreleased* in `## [x.y.z] - JJJJ-MM-TT` umbenennen und die Vergleichslinks unten anpassen.
4. PR `chore(release): x.y.z` öffnen, Review, mergen.
5. Auf `main` taggen und pushen:
   ```bash
   git tag -a vx.y.z -m "Closer x.y.z"
   git push origin vx.y.z
   ```
6. In Xcode archivieren (*Product › Archive*) und zu App Store Connect hochladen.
7. Optional: GitHub Release aus dem Tag mit dem Changelog-Abschnitt als Beschreibung erstellen.
