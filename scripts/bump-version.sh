#!/usr/bin/env bash
# Setzt MARKETING_VERSION (SemVer) und/oder CURRENT_PROJECT_VERSION (Build) für alle Targets.
#
#   scripts/bump-version.sh 0.2.0        # Marketing-Version setzen, Build +1
#   scripts/bump-version.sh 0.2.0 42     # Marketing-Version und Build explizit setzen
#   scripts/bump-version.sh --build      # nur Build-Nummer +1
set -euo pipefail

PBXPROJ="$(cd "$(dirname "$0")/.." && pwd)/Closer.xcodeproj/project.pbxproj"
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

current_build() {
    grep -m1 -E 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" | sed -E 's/.*= ([0-9]+);/\1/'
}

set_build() {
    sed -i.bak -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $1;/g" "$PBXPROJ"
    rm -f "$PBXPROJ.bak"
}

set_marketing() {
    sed -i.bak -E "s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $1;/g" "$PBXPROJ"
    rm -f "$PBXPROJ.bak"
}

case "${1:-}" in
    "" | -h | --help)
        sed -n '2,6p' "$0"; exit 0 ;;
    --build)
        set_build $(( $(current_build) + 1 )) ;;
    *)
        [[ "$1" =~ $SEMVER_RE ]] || { echo "Ungültige Version '$1' (erwartet MAJOR.MINOR.PATCH)" >&2; exit 1; }
        set_marketing "$1"
        set_build "${2:-$(( $(current_build) + 1 ))}" ;;
esac

grep -m1 -E 'MARKETING_VERSION' "$PBXPROJ" | xargs
grep -m1 -E 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | xargs
