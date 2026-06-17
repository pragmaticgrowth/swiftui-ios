#!/usr/bin/env bash
# swiftui-capture.sh — the toolkit's visual CAPTURE harness (the pixel analogue of swiftui-lint.sh).
#
# Builds an iOS app, boots the Simulator, navigates its screens, and screenshots them across
# appearance/Dynamic-Type variants — producing the evidence the `audit-swiftui-design-review` skill
# critiques against the HIG/Liquid-Glass knowledge base. It CAPTURES only; it never judges.
#
# App-agnostic for the crawl path (no code added to the target). Degrades gracefully: if Xcode/Simulator
# is unavailable, no project is found, or the build fails, it writes capture.json {status:"unavailable"}
# and exits 0 so the reviewer can fall back to code-only — it NEVER fakes coverage.
#
# Usage:
#   bash scripts/swiftui-capture.sh <project-dir> [--out DIR] [--device NAME]
#                                   [--variants minimal|full] [--no-idb] [--previews]
#   <project-dir>   dir containing a .xcworkspace or .xcodeproj (default ".")
#   --out DIR       output dir (default <project-dir>/swiftui-design)
#   --device NAME   simulator device name (default: a booted device, else first available iPhone)
#   --variants      minimal = light+dark @ large (default); full = adds an AX Dynamic Type size  [Task 7]
#   --no-idb        skip the idb accessibility-tree crawl (deep-links + manifest only)             [Task 8]
#   --previews      also snapshot #Previews via EmergeTools/SnapshotPreviews                       [Task 9]
#
# Output: <out>/capture.json  (index: status, project, device, screens[], failures[])
#         <out>/screens/<screen>__<appearance>__<type>.png
# Exit: 0 on success OR clean degradation; 69 only if jq is missing (cannot emit a report).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---- args ----
PROJECT=""; OUT=""; DEVICE=""; VARIANTS="minimal"; NO_IDB=0; PREVIEWS=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)      OUT="$2"; shift 2;;
    --device)   DEVICE="$2"; shift 2;;
    --variants) VARIANTS="$2"; shift 2;;
    --no-idb)   NO_IDB=1; shift;;
    --previews) PREVIEWS=1; shift;;
    -h|--help)  sed -n '2,30p' "$0"; exit 0;;
    -*)         echo "swiftui-capture: unknown flag $1" >&2; shift;;
    *)          [ -z "$PROJECT" ] && PROJECT="$1"; shift;;
  esac
done
PROJECT="${PROJECT:-.}"
OUT="${OUT:-$PROJECT/swiftui-design}"
mkdir -p "$OUT/screens"

# jq is required even to emit the report.
command -v jq >/dev/null 2>&1 || { echo "swiftui-capture: jq is required (brew install jq)." >&2; exit 69; }

# ---- degradation helper: write capture.json {status:"unavailable"} and exit 0 ----
emit_unavailable() {
  jq -n --arg p "$PROJECT" --arg r "$1" \
    '{tool:"swiftui-capture", role:"visual-capture", status:"unavailable", reason:$r, project:$p, screens:[], failures:[$r]}' \
    > "$OUT/capture.json"
  echo "swiftui-capture: unavailable — $1 (falling back to code-only)" >&2
  exit 0
}

command -v xcodebuild >/dev/null 2>&1 || emit_unavailable "xcodebuild not found"
command -v xcrun       >/dev/null 2>&1 || emit_unavailable "xcrun not found"

# ---- locate the Xcode container (real .xcworkspace wins; ignore the one inside .xcodeproj) ----
WS="$(find "$PROJECT" -maxdepth 2 -name '*.xcworkspace' -not -path '*.xcodeproj/*' -not -path '*/.*' 2>/dev/null | head -1)"
PROJ="$(find "$PROJECT" -maxdepth 2 -name '*.xcodeproj' -not -path '*/.*' 2>/dev/null | head -1)"
if [ -n "$WS" ]; then CONTAINER=(-workspace "$WS"); CONTAINER_PATH="$WS"
elif [ -n "$PROJ" ]; then CONTAINER=(-project "$PROJ"); CONTAINER_PATH="$PROJ"
else emit_unavailable "no .xcworkspace/.xcodeproj under $PROJECT"; fi

# ---- pick a scheme (first listed) ----
LIST_JSON="$(xcodebuild -list -json "${CONTAINER[@]}" 2>/dev/null)"
SCHEME="$(printf '%s' "$LIST_JSON" | jq -r '(.workspace.schemes // .project.schemes // [])[0] // empty')"
[ -z "$SCHEME" ] && emit_unavailable "no scheme found in $CONTAINER_PATH"

# ---- pick a simulator UDID: --device by name, else a booted device, else first available iPhone ----
DEV_JSON="$(xcrun simctl list devices available --json 2>/dev/null)"
pick_udid() {
  printf '%s' "$DEV_JSON" | python3 -c '
import json,sys
want=sys.argv[1] if len(sys.argv)>1 else ""
d=json.load(sys.stdin).get("devices",{})
flat=[x for v in d.values() for x in v]
def by_name(n): return next((x["udid"] for x in flat if x.get("name")==n), "")
if want:
    print(by_name(want)); raise SystemExit
boot=next((x["udid"] for x in flat if x.get("state")=="Booted"), "")
if boot: print(boot); raise SystemExit
print(next((x["udid"] for x in flat if "iPhone" in x.get("name","")), ""))
' "$1"
}
UDID="$(pick_udid "$DEVICE")"
[ -z "$UDID" ] && emit_unavailable "no usable iOS simulator (device='${DEVICE:-auto}')"

echo "swiftui-capture: scheme=$SCHEME device=$UDID out=$OUT" >&2

# ---- build for the simulator ----
if ! xcodebuild build "${CONTAINER[@]}" -scheme "$SCHEME" -configuration Debug \
      -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$OUT/build" \
      CODE_SIGNING_ALLOWED=NO >"$OUT/build.log" 2>&1; then
  emit_unavailable "build-failed (see $OUT/build.log)"
fi

# ---- locate the built .app + bundle id ----
APP="$(find "$OUT/build/Build/Products" -maxdepth 2 -name '*.app' 2>/dev/null | head -1)"
[ -z "$APP" ] && emit_unavailable "built .app not found under $OUT/build/Build/Products"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null)"
[ -z "$BUNDLE_ID" ] && emit_unavailable "could not read CFBundleIdentifier from $APP"

# ---- boot (idempotent) + install ----
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP" >/dev/null 2>&1 || emit_unavailable "install failed"

# ---- clean status bar (9:41 / full bars) + grant permissions so dialogs don't block shots ----
xcrun simctl status_bar "$UDID" override --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
xcrun simctl privacy "$UDID" grant all "$BUNDLE_ID" >/dev/null 2>&1 || true

# ---- variant axes: appearance × Dynamic Type ----
APPEARANCES=(light dark)
if [ "$VARIANTS" = "full" ]; then
  SIZES=("large:large" "accessibility-extra-extra-extra-large:axxxl")
else
  SIZES=("large:large")
fi

# ---- idb availability (the app-agnostic accessibility-tree driver) ----
IDB=""
if [ "$NO_IDB" -eq 0 ] && command -v idb >/dev/null 2>&1; then IDB="idb"; fi
COVERAGE_NOTES=()

ax_json() { if [ -n "$IDB" ]; then idb ui describe-all --udid "$UDID" --json 2>/dev/null || printf '[]'; else printf '[]'; fi; }

# wait until the AX tree stops changing (no mid-animation smears); sleep fallback without idb.
wait_for_idle() {
  if [ -z "$IDB" ]; then sleep 1; return; fi
  local prev="" cur i=0
  while [ "$i" -lt 15 ]; do
    cur="$(ax_json | shasum | cut -d' ' -f1)"
    [ "$cur" = "$prev" ] && [ -n "$cur" ] && return
    prev="$cur"; i=$((i+1)); sleep 0.4
  done
}

# echo "x y" tap center for a label in the CURRENT AX tree (robust to layout shifts), or empty.
center_of() {
  ax_json | python3 -c '
import json,sys
label=sys.argv[1]; raw=sys.stdin.read().strip() or "[]"
try: els=json.loads(raw)
except Exception: els=[]
TAP={"Button","Link","Cell","TabBar"}
for e in els:
    if e.get("AXLabel")==label and e.get("enabled",True) and (e.get("type") in TAP or e.get("role")=="AXButton"):
        fr=e.get("frame",{})
        cx=fr.get("x",0)+fr.get("width",0)/2
        cy=fr.get("y",0)+fr.get("height",0)/2
        print("%d %d" % (cx,cy)); break
' "$1"
}

# reach a screen from a freshly-relaunched (home) state: deep-link, OR tap one label (breadth-1).
replay_nav() {  # $1=deeplink  $2=single tap label
  local dl="$1" lbl="$2" xy
  if [ -n "$dl" ]; then xcrun simctl openurl "$UDID" "$dl" >/dev/null 2>&1; sleep 1; wait_for_idle; return; fi
  [ -z "$lbl" ] && return
  xy="$(center_of "$lbl")"
  if [ -z "$xy" ]; then COVERAGE_NOTES+=("tap target not found: $lbl"); return; fi
  [ -n "$IDB" ] && idb ui tap --udid "$UDID" $xy >/dev/null 2>&1
  sleep 1            # let the transition BEGIN before polling for idle (wait_for_idle alone is too eager)
  wait_for_idle
}

# shoot a screen across the matrix; re-navigate after each relaunch (UIKit reads appearance/type at start).
CAPTURED=()
shoot_screen() {  # $1=name $2=deeplink $3=tap-label
  local name="$1" dl="$2" tap="$3" ap sz cat lbl
  for ap in "${APPEARANCES[@]}"; do
    xcrun simctl ui "$UDID" appearance "$ap" >/dev/null 2>&1 || true
    for sz in "${SIZES[@]}"; do
      cat="${sz%%:*}"; lbl="${sz##*:}"
      xcrun simctl ui "$UDID" content_size "$cat" >/dev/null 2>&1 || true
      xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
      wait_for_idle
      replay_nav "$dl" "$tap"
      if xcrun simctl io "$UDID" screenshot "$OUT/screens/${name}__${ap}__${lbl}.png" >/dev/null 2>&1; then
        CAPTURED+=("${name}__${ap}__${lbl}")
      fi
    done
  done
}

# ---- navigation: manifest-driven (deterministic) else auto-explore (breadth-1) ----
MANIFEST="$OUT/screens.manifest.json"
SCREEN_NAMES=(); SCREEN_DLS=(); SCREEN_TAPS=()
if [ -f "$MANIFEST" ]; then
  while IFS=$'\t' read -r nm dl tp; do
    SCREEN_NAMES+=("$nm"); SCREEN_DLS+=("$dl"); SCREEN_TAPS+=("$tp")
  done < <(jq -r '.screens[] | [.name, (.deeplink//""), ((.tap_labels//[])[0]//"")] | @tsv' "$MANIFEST" 2>/dev/null)
  COVERAGE_NOTES+=("manifest-driven: ${#SCREEN_NAMES[@]} screen(s)")
else
  SCREEN_NAMES=(home); SCREEN_DLS=(""); SCREEN_TAPS=("")
  if [ -n "$IDB" ]; then
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    wait_for_idle
    while IFS= read -r lbl; do
      [ -z "$lbl" ] && continue
      SCREEN_NAMES+=("$(printf '%s' "$lbl" | tr ' /' '__' | tr -cd 'A-Za-z0-9_-' | cut -c1-40)")
      SCREEN_DLS+=(""); SCREEN_TAPS+=("$lbl")
    done < <(ax_json | python3 -c '
import json,sys
raw=sys.stdin.read().strip() or "[]"
try: els=json.loads(raw)
except Exception: els=[]
TAP={"Button","Link","Cell","TabBar"}
seen=set(); n=0
for e in els:
    lab=e.get("AXLabel")
    if lab and e.get("enabled",True) and (e.get("type") in TAP or e.get("role")=="AXButton") and lab not in seen:
        seen.add(lab); print(lab); n+=1
        if n>=10: break
')
    if [ "${#SCREEN_NAMES[@]}" -gt 1 ]; then
      COVERAGE_NOTES+=("auto-explored ${#SCREEN_NAMES[@]} screen(s) (breadth-1, capped at 10 + home)")
    else
      COVERAGE_NOTES+=("auto-explore found no tappable targets (auth wall? add a screens.manifest.json)")
    fi
  else
    COVERAGE_NOTES+=("idb unavailable — only home captured; install idb or add a screens.manifest.json")
  fi
fi

# shoot every screen
idx=0
while [ "$idx" -lt "${#SCREEN_NAMES[@]}" ]; do
  shoot_screen "${SCREEN_NAMES[$idx]}" "${SCREEN_DLS[$idx]}" "${SCREEN_TAPS[$idx]}"
  idx=$((idx+1))
done
[ "${#CAPTURED[@]}" -eq 0 ] && emit_unavailable "no screenshots captured"

# write a discovered manifest back (so the next run is deterministic) if none existed
if [ ! -f "$MANIFEST" ]; then
  DISC="$(mktemp)"
  k=0
  while [ "$k" -lt "${#SCREEN_NAMES[@]}" ]; do
    printf '%s\t%s\t%s\n' "${SCREEN_NAMES[$k]}" "${SCREEN_DLS[$k]}" "${SCREEN_TAPS[$k]}" >> "$DISC"
    k=$((k+1))
  done
  jq -R -s 'split("\n")|map(select(length>0))|map(split("\t"))|
    {screens: map({name:.[0], deeplink:.[1], tap_labels: (if .[2]=="" then [] else [.[2]] end)})}' \
    "$DISC" > "$MANIFEST"
  rm -f "$DISC"
fi

# ---- emit success index (group captured variants per screen) + coverage ----
SCREENS_JSON="$(printf '%s\n' "${CAPTURED[@]}" | jq -R -s '
  split("\n") | map(select(length>0)) |
  map({screen: split("__")[0], variant: (split("__")[1] + "/" + split("__")[2])}) |
  group_by(.screen) | map({name: .[0].screen, variants: map(.variant)})')"
COVERAGE_JSON="$(printf '%s\n' "${COVERAGE_NOTES[@]}" | jq -R -s 'split("\n")|map(select(length>0))')"
jq -n --arg p "$PROJECT" --arg s "$SCHEME" --arg d "$UDID" --arg app "$BUNDLE_ID" \
  --argjson screens "$SCREENS_JSON" --argjson coverage "$COVERAGE_JSON" --arg idb "${IDB:-none}" \
  '{tool:"swiftui-capture", role:"visual-capture", status:"ok",
    project:$p, scheme:$s, device:$d, bundle_id:$app, navigator:$idb,
    screens:$screens, coverage:$coverage, failures:[]}' \
  > "$OUT/capture.json"
echo "swiftui-capture: ok — ${#CAPTURED[@]} screenshot(s), ${#SCREEN_NAMES[@]} screen(s) → $OUT/screens" >&2
exit 0
