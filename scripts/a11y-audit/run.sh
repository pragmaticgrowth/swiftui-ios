#!/usr/bin/env bash
# run.sh — optional deterministic accessibility-audit runner for the design layer.
#
# If the target project's UI test target already calls `performAccessibilityAudit` (e.g. via
# DesignA11yAuditTemplate.swift), this builds-and-runs that test on a simulator and emits
# <out>/a11y-audit.json {status:"ok"|"test-failed", ...}. Otherwise it emits {status:"not-wired"}
# with how-to and exits 0 — it is OPTIONAL and never blocks the design review (the static dr-* tells
# in audit-swiftui-design-review are the always-on deterministic tier).
#
# Usage: bash scripts/a11y-audit/run.sh <project-dir> [--out DIR] [--device NAME]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT=""; OUT=""; DEVICE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2;;
    --device) DEVICE="$2"; shift 2;;
    -h|--help) sed -n '2,12p' "$0"; exit 0;;
    *) [ -z "$PROJECT" ] && PROJECT="$1"; shift;;
  esac
done
PROJECT="${PROJECT:-.}"; OUT="${OUT:-$PROJECT/swiftui-design}"
mkdir -p "$OUT"
command -v jq >/dev/null 2>&1 || { echo "a11y-audit: jq required." >&2; exit 69; }

emit() {  # $1=status $2=detail
  jq -n --arg p "$PROJECT" --arg s "$1" --arg d "$2" \
    '{tool:"a11y-audit", role:"deterministic-accessibility", status:$s, detail:$d, project:$p, findings:[]}' \
    > "$OUT/a11y-audit.json"
  echo "a11y-audit: $1 — $2" >&2
}

not_wired() {
  emit "not-wired" "No performAccessibilityAudit test found. Copy $SCRIPT_DIR/DesignA11yAuditTemplate.swift into your UI test target, then re-run. (Optional — the static dr-* tells run regardless.)"
  exit 0
}

command -v xcodebuild >/dev/null 2>&1 || { emit "unavailable" "xcodebuild not found"; exit 0; }

# Is an accessibility audit actually wired into the project?
grep -rqs 'performAccessibilityAudit' --include='*.swift' "$PROJECT" 2>/dev/null || not_wired

# Locate container + a testable scheme.
WS="$(find "$PROJECT" -maxdepth 2 -name '*.xcworkspace' -not -path '*.xcodeproj/*' -not -path '*/.*' 2>/dev/null | head -1)"
PROJ="$(find "$PROJECT" -maxdepth 2 -name '*.xcodeproj' -not -path '*/.*' 2>/dev/null | head -1)"
if [ -n "$WS" ]; then CONTAINER=(-workspace "$WS"); elif [ -n "$PROJ" ]; then CONTAINER=(-project "$PROJ"); else emit "unavailable" "no Xcode container"; exit 0; fi
SCHEME="$(xcodebuild -list -json "${CONTAINER[@]}" 2>/dev/null | jq -r '(.workspace.schemes // .project.schemes // [])[0] // empty')"
[ -z "$SCHEME" ] && { emit "unavailable" "no scheme"; exit 0; }

# Pick a simulator (booted, else by name, else first iPhone).
UDID="$(xcrun simctl list devices available --json 2>/dev/null | python3 -c '
import json,sys
want=sys.argv[1] if len(sys.argv)>1 else ""
flat=[x for v in json.load(sys.stdin).get("devices",{}).values() for x in v]
print((want and next((x["udid"] for x in flat if x.get("name")==want),"")) or
      next((x["udid"] for x in flat if x.get("state")=="Booted"),"") or
      next((x["udid"] for x in flat if "iPhone" in x.get("name","")),""))' "$DEVICE")"
[ -z "$UDID" ] && { emit "unavailable" "no simulator"; exit 0; }

if xcodebuild test "${CONTAINER[@]}" -scheme "$SCHEME" \
     -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$OUT/build" \
     -resultBundlePath "$OUT/a11y.xcresult" >"$OUT/a11y-audit.log" 2>&1; then
  emit "ok" "Accessibility audit passed (no issues) — see $OUT/a11y.xcresult"
else
  emit "test-failed" "Accessibility audit reported issues — open $OUT/a11y.xcresult for per-element screenshots, or $OUT/a11y-audit.log"
fi
exit 0
