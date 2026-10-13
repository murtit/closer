#!/usr/bin/env python3
"""Exports the screenshots attached by the UI tests from an .xcresult bundle.

Usage: scripts/export-screenshots.py <TestResults.xcresult> <output-dir>

Each screenshot is saved as `<attachment name>.png` (e.g. `01-heute-light.png`). Prints the
number of exported files; exits with 0 even if there are none, so a failed UI test run still
leaves the job's real error visible.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    result_bundle, output_dir = sys.argv[1], sys.argv[2]
    if not os.path.isdir(result_bundle):
        print(f"{result_bundle} not found, nothing to export")
        return 0

    os.makedirs(output_dir, exist_ok=True)
    with tempfile.TemporaryDirectory() as raw_dir:
        subprocess.run(
            ["xcrun", "xcresulttool", "export", "attachments",
             "--path", result_bundle, "--output-path", raw_dir],
            check=True,
        )
        with open(os.path.join(raw_dir, "manifest.json")) as f:
            manifest = json.load(f)

        count = 0
        for test in manifest:
            for attachment in test.get("attachments", []):
                exported = attachment["exportedFileName"]
                if not exported.lower().endswith(".png"):
                    continue
                # xcresulttool appends "_<index>_<UUID>" to the attachment name.
                stem = os.path.splitext(attachment.get("suggestedHumanReadableName", exported))[0]
                name = re.sub(r"_\d+_[0-9A-Fa-f-]{36}$", "", stem)
                name = re.sub(r"[^A-Za-z0-9._-]", "-", name)
                shutil.copy(os.path.join(raw_dir, exported), os.path.join(output_dir, f"{name}.png"))
                count += 1

    print(f"Exported {count} screenshot(s) to {output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
