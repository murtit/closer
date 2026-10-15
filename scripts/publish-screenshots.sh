#!/usr/bin/env bash
# Publishes the CI screenshots of a pull request and posts (or updates) one PR comment showing them.
#
# Usage: scripts/publish-screenshots.sh <screenshot-dir>
#
# Required environment (set by .github/workflows/ci.yml):
#   GH_TOKEN      token with contents:write and pull-requests:write
#   REPO          owner/name, e.g. murtit/closer
#   PR_NUMBER     pull request number
#   HEAD_SHA      commit the screenshots were taken from
#   RUN_URL       link to the workflow run
#
# The images are committed to the orphan branch `ci-screenshots` under `pr-<number>/`, because
# PR comments cannot embed images from workflow artifacts. The comment links them by commit SHA,
# so each update shows the new images and older comment revisions keep theirs.
set -euo pipefail

SRC_DIR=${1:?screenshot directory missing}
BRANCH=ci-screenshots
MARKER='<!-- closer-ci-screenshots -->'
SHORT_SHA=${HEAD_SHA:0:7}

shopt -s nullglob
images=("$SRC_DIR"/*.png)
if [ ${#images[@]} -eq 0 ]; then
    echo "No screenshots in $SRC_DIR, nothing to publish"
    exit 0
fi

# MARK: - Commit images to the screenshot branch

tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT

# Commits the screenshots on top of the current remote branch (or a new orphan branch) and pushes.
publish_attempt() {
    work=$(mktemp -d "$tmp_root/attempt.XXXX")
    git -C "$work" init -q
    git -C "$work" config user.name "github-actions[bot]"
    git -C "$work" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git -C "$work" remote add origin "https://x-access-token:${GH_TOKEN}@github.com/${REPO}.git"

    if git -C "$work" fetch -q --depth 1 origin "$BRANCH" 2>/dev/null; then
        git -C "$work" checkout -q -B "$BRANCH" FETCH_HEAD
    else
        git -C "$work" checkout -q --orphan "$BRANCH"
        printf '# CI-Screenshots\n\nAutomatisch erzeugt von `.github/workflows/ci.yml`. Nicht manuell bearbeiten.\n' > "$work/README.md"
    fi

    rm -rf "$work/pr-$PR_NUMBER"
    mkdir -p "$work/pr-$PR_NUMBER"
    cp "${images[@]}" "$work/pr-$PR_NUMBER/"
    git -C "$work" add -A
    git -C "$work" commit -q -m "chore: screenshots for #$PR_NUMBER at $SHORT_SHA" > /dev/null || true  # unchanged images
    git -C "$work" push -q origin "HEAD:refs/heads/$BRANCH"
}

# Other PRs may push at the same time; each only touches its own folder, so retry on top of theirs.
for attempt in 1 2 3 4 5; do
    if publish_attempt; then
        break
    fi
    if [ "$attempt" -eq 5 ]; then
        echo "Could not push to $BRANCH" >&2
        exit 1
    fi
    sleep $((attempt * 2))
done
IMAGE_SHA=$(git -C "$work" rev-parse HEAD)

# MARK: - Comment

label() {
    case "$1" in
        01-heute) echo "Heute" ;;
        02-personen) echo "Personen" ;;
        03-person-hinzufuegen) echo "Person hinzufügen" ;;
        04-person) echo "Person" ;;
        05-erinnerung) echo "Erinnerung" ;;
        06-jahrestag) echo "Jahrestag" ;;
        07-benachrichtigungston) echo "Benachrichtigungston" ;;
        08-einstellungen) echo "Einstellungen" ;;
        *) echo "$1" ;;
    esac
}

url() {
    echo "https://github.com/${REPO}/blob/${IMAGE_SHA}/pr-${PR_NUMBER}/$1?raw=true"
}

body=$(mktemp)
{
    echo "$MARKER"
    echo "### 📸 Screenshots"
    echo
    echo "Aus dem iOS-Simulator mit Demo-Daten, Commit \`$SHORT_SHA\` ([Workflow-Run]($RUN_URL))."
    echo
    echo "| Screen | Light | Dark |"
    echo "|---|---|---|"
    for screen in $(for f in "${images[@]}"; do basename "$f" .png; done | sed -E 's/-(light|dark)$//' | sort -u); do
        row="| **$(label "$screen")** |"
        for mode in light dark; do
            file="$screen-$mode.png"
            if [ -f "$SRC_DIR/$file" ]; then
                row+=" <img src=\"$(url "$file")\" width=\"240\" alt=\"$(label "$screen") ($mode)\"> |"
            else
                row+=" – |"
            fi
        done
        echo "$row"
    done
} > "$body"

comment_id=$(gh api "repos/$REPO/issues/$PR_NUMBER/comments" --paginate \
    --jq ".[] | select(.user.login == \"github-actions[bot]\" and (.body | contains(\"$MARKER\"))) | .id" | head -n 1)

if [ -n "$comment_id" ]; then
    gh api -X PATCH "repos/$REPO/issues/comments/$comment_id" -F "body=@$body" > /dev/null
    echo "Updated screenshot comment $comment_id"
else
    gh api -X POST "repos/$REPO/issues/$PR_NUMBER/comments" -F "body=@$body" > /dev/null
    echo "Posted screenshot comment"
fi
