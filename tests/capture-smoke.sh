#!/usr/bin/env bash
# Smoke: the degradation path must emit a valid capture.json with status=unavailable when given a
# directory that has no buildable Xcode project. This is testable with no simulator dependency.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$ROOT/scripts/swiftui-capture.sh" "$TMP" --out "$TMP/out" >/dev/null 2>&1
if jq -e '.status=="unavailable"' "$TMP/out/capture.json" >/dev/null 2>&1; then
  echo "capture-smoke: degradation OK ✓"
else
  echo "capture-smoke: FAIL — expected status=unavailable"; exit 1
fi
