# swiftui-ios — iOS Data Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `swiftui-ios` plugin and produce a real, quality-ranked iOS SwiftUI catalog by retargeting the macOS plugin's scanner + pipeline to iOS 17 and running the full `open-source-ios-apps`/`awesome-ios` harvest.

**Architecture:** Fork the platform-neutral engine (`swiftui-scan`, `scripts/`, `references/_shared/`, CLI) into a sibling repo, make one additive scanner change (per-file `platform` field + de-conflated UIKit/AppKit bridge kinds), retarget the Python pipeline's seed/triple/signal-sets/classification/discovery, then run `00`→`08` to build `catalog/`. The CLI keeps defaulting to `macos` in SP1; iOS data is proven queryable via `--platform ios`.

**Tech Stack:** Swift 6 + SwiftSyntax 603.0.1 (scanner/CLI), Python 3 (pipeline), `gh` CLI + GitHub API (harvest/discovery), `swift symbolgraph-extract` + Xcode iOS SDK (SDK catalog), `jq`.

## Global Constraints

- **Topology:** new sibling repo `/Users/serkan/swiftui-ios` (the macOS repo `/Users/serkan/claude-swiftui-plugin` is never modified by this plan).
- **iOS floor:** deployment target `arm64-apple-ios17.0`. Modernity is normalized against iOS 17 (clean `@Observable`/SwiftData/`sensoryFeedback`/`NavigationStack` story).
- **iPad:** modeled *within* the `ios` classification via recorded idiom signals — not a separate platform arm.
- **Catalog/release:** full harvest before release; seed = `dkhamsing/open-source-ios-apps` (primary) + `vsouza/awesome-ios` apps-section (secondary) + code-search discovery.
- **Scanner changes are additive:** the `platform` field is new; only the NS* bridge-kind string changes (`bridge` → `appkit_bridge`). Existing fields and the macOS-fixture behavior (re-pointed to the new kind) stay green.
- **SwiftUI-presence** is enforced at **aggregation (stage 5)** — a repo contributing zero SwiftUI occurrences classifies as `library` — because the gate (`01`) only has GitHub API metadata, not file contents. (This satisfies the spec's "SwiftUI-presence floor" at the only stage where file contents exist.)
- DRY, YAGNI, TDD where a test cycle exists (scanner fixtures, pipeline unit checks on synthetic JSONL), frequent commits.

---

### Task 1: Scaffold the `swiftui-ios` repo

**Files:**
- Create: `/Users/serkan/swiftui-ios/` (new git repo) by copying the engine from the macOS repo, excluding generated data.
- Create: `/Users/serkan/swiftui-ios/.claude-plugin/plugin.json`
- Create: `/Users/serkan/swiftui-ios/.claude-plugin/marketplace.json`
- Create: `/Users/serkan/swiftui-ios/README.md` (skeleton; numbers filled after harvest)

**Interfaces:**
- Produces: a buildable repo whose `swiftui-scan` + `swiftui-ctx` compile identically to the macOS source (no iOS changes yet). All later tasks edit files *inside this repo*.

- [ ] **Step 1: Copy the engine, excluding generated/committed data**

```bash
SRC=/Users/serkan/claude-swiftui-plugin
DST=/Users/serkan/swiftui-ios
mkdir -p "$DST"
rsync -a --exclude '.git' --exclude 'catalog' --exclude 'data' --exclude 'repos' \
  --exclude 'sg' --exclude 'sg_std' --exclude 'sdk_catalog.json' --exclude 'symbols_all.tsv' \
  --exclude 'swiftui-ctx' --exclude '.build' --exclude 'docs' \
  "$SRC"/ "$DST"/
mkdir -p "$DST/docs/superpowers/specs" "$DST/docs/superpowers/plans"
cp "$SRC/docs/superpowers/specs/2026-06-16-swiftui-ios-data-foundation-design.md" "$DST/docs/superpowers/specs/"
cp "$SRC/docs/superpowers/plans/2026-06-16-swiftui-ios-data-foundation.md" "$DST/docs/superpowers/plans/"
```

- [ ] **Step 2: Write the new plugin manifest**

Create `/Users/serkan/swiftui-ios/.claude-plugin/plugin.json`:

```json
{
  "name": "swiftui-ios",
  "description": "Real production SwiftUI usage from shipping iOS & iPadOS apps PLUS iOS-SwiftUI skills (domain audits + write/modernize/scaffold) — backed by the swiftui-ctx CLI. Look up how an API is really used and the consensus argument shape, flag deprecated calls, scaffold whole patterns, and run domain audits (navigation, adaptive layout, presentation/sheets, UIKit interop, widgets/Live Activities, accessibility, concurrency, and more) grounded in real iOS code with GitHub permalinks. Use before writing, reviewing, modernizing, or auditing SwiftUI on iOS/iPadOS.",
  "version": "0.1.0",
  "author": { "name": "yigitkonur", "url": "https://github.com/yigitkonur" },
  "homepage": "https://github.com/yigitkonur/swiftui-ios-plugin",
  "repository": "https://github.com/yigitkonur/swiftui-ios-plugin",
  "license": "MIT",
  "keywords": ["swiftui", "ios", "ipados", "swift", "code-examples", "audit", "cli"]
}
```

Mirror the macOS repo's `marketplace.json` shape with the `swiftui-ios` name/description (read `/Users/serkan/claude-swiftui-plugin/.claude-plugin/marketplace.json` for the exact schema and copy it, swapping name/description/keywords).

- [ ] **Step 3: README skeleton**

Create `/Users/serkan/swiftui-ios/README.md` with a one-paragraph framing ("real-world SwiftUI for claude — grounded in shipping iOS apps") and a `<!-- corpus numbers filled after harvest (Task 10) -->` marker where the macOS README has its stats table.

- [ ] **Step 4: Init git + verify the engine still builds**

```bash
cd /Users/serkan/swiftui-ios && git init -q && git add -A
( cd swiftui-scan && swift build -c release --product swiftui-scan --product swiftui-ctx ) 2>&1 | tail -5
```
Expected: build succeeds (this is the unmodified macOS engine).

- [ ] **Step 5: Commit**

```bash
cd /Users/serkan/swiftui-ios && git add -A && git commit -q -m "chore: scaffold swiftui-ios from macOS plugin engine"
```

---

### Task 2: Scanner — `platform` field + UIKit/AppKit bridge de-conflation

**Files (all in `/Users/serkan/swiftui-ios`):**
- Create: `swiftui-scan/fixtures/Sample_iOS.swift`
- Modify: `swiftui-scan/fixtures/check.py` (add iOS assertions; repoint NS bridge assertion)
- Modify: `swiftui-scan/Sources/swiftui-scan/ScanVisitor.swift:46-54` (conformanceKind) + add `platformHint()`
- Modify: `swiftui-scan/Sources/swiftui-scan/main.swift:6-13,44-49` (FileResult.platform + emit)
- Modify: `swiftui-scan/Package.swift:6` (add `.iOS(.v17)`)

**Interfaces:**
- Produces: `FileResult.platform: String` ∈ {`uikit`,`appkit`,`cross`,`neutral`}; `Decl.kind` for bridges is `uikit_bridge` (UIView*) or `appkit_bridge` (NSView*) instead of `bridge`. Stage 5 (Task 6) consumes both.

- [ ] **Step 1: Write the failing iOS fixture + assertions**

Create `swiftui-scan/fixtures/Sample_iOS.swift`:

```swift
import SwiftUI
import UIKit

struct FeedView: View {
    @State private var selection: Tab = .home
    var body: some View {
        TabView(selection: $selection) {
            List { Text("row") }
                .refreshable { }
                .tabItem { Label("Home", systemImage: "house") }
        }
        .sheet(isPresented: .constant(false)) { Text("sheet") }
        .presentationDetents([.medium, .large])
    }
}

struct MapBox: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ v: UIView, context: Context) {}
}

struct PlayerVC: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ c: UIViewController, context: Context) {}
}
```

Add to `swiftui-scan/fixtures/check.py` — extend the macOS `checks` list (NS bridge assertion repointed) and add an iOS check block. Replace the line:

```python
    ("NSViewRepresentable → bridge decl",  has_decl("bridge","GraphView")),
```
with:
```python
    ("NSViewRepresentable → appkit_bridge",  has_decl("appkit_bridge","GraphView")),
    ("macOS Sample file platform=appkit",   obj.get("platform")=="appkit"),
```

After the macOS `checks`/`fails` block, append a second harness that runs the iOS fixture:

```python
ios = json.loads(subprocess.run([BIN], input=(os.path.join(HERE,"Sample_iOS.swift")+"\n").encode(),
                                 capture_output=True).stdout.decode().splitlines()[0])
iocc, idecls = ios["occurrences"], ios["decls"]
def ihas_decl(kind, name): return any(d["kind"]==kind and d["name"]==name for d in idecls)
def ihas_occ(kind, sym): return any(o["kind"]==kind and o["sym"]==sym for o in iocc)
ios_checks = [
    ("iOS file platform=uikit (import UIKit)", ios.get("platform")=="uikit"),
    ("UIViewRepresentable → uikit_bridge",     ihas_decl("uikit_bridge","MapBox")),
    ("UIViewControllerRepresentable → uikit_bridge", ihas_decl("uikit_bridge","PlayerVC")),
    ("presentationDetents modifier captured",  ihas_occ("modifier","presentationDetents")),
    ("tabItem modifier captured",              ihas_occ("modifier","tabItem")),
]
for name, ok in ios_checks: print(f"  [{'PASS' if ok else 'FAIL'}] {name}")
if any(not ok for _, ok in ios_checks):
    print(f"\n{sum(1 for _,ok in ios_checks if not ok)} iOS CHECKS FAILED"); sys.exit(1)
print(f"ALL {len(ios_checks)} iOS CHECKS PASS")
```

- [ ] **Step 2: Run the check to verify it FAILS**

```bash
cd /Users/serkan/swiftui-ios && ( cd swiftui-scan && swift build -c release --product swiftui-scan ) \
  && python3 swiftui-scan/fixtures/check.py
```
Expected: FAIL — `platform` is `None` (field doesn't exist), bridges still emit `bridge` not `*_bridge`.

- [ ] **Step 3: De-conflate bridge kinds**

In `swiftui-scan/Sources/swiftui-scan/ScanVisitor.swift`, replace lines 51-52:
```swift
        "NSViewRepresentable": "bridge", "NSViewControllerRepresentable": "bridge",
        "UIViewRepresentable": "bridge", "UIViewControllerRepresentable": "bridge",
```
with:
```swift
        "NSViewRepresentable": "appkit_bridge", "NSViewControllerRepresentable": "appkit_bridge",
        "UIViewRepresentable": "uikit_bridge", "UIViewControllerRepresentable": "uikit_bridge",
```
Update the `Decl.kind` comment (`ScanVisitor.swift:28-29`) to list `appkit_bridge | uikit_bridge` instead of `bridge`.

- [ ] **Step 4: Add `platformHint()` + signal sets to `ScanVisitor`**

In `ScanVisitor.swift`, add after the `conformanceKind`/`viewReturns` statics (around line 55):

```swift
    static let iosSignals: Set<String> = ["UIViewRepresentable","UIViewControllerRepresentable",
        "UIHostingController","UIApplicationDelegateAdaptor","fullScreenCover","presentationDetents",
        "navigationBarTitleDisplayMode","prefersLargeContent","UIScreen","UIDevice",
        "UIImpactFeedbackGenerator","ControlWidget","ActivityAttributes"]
    static let macosSignals: Set<String> = ["MenuBarExtra","Settings","NSViewRepresentable",
        "NSViewControllerRepresentable","NSHostingController","windowStyle","menuBarExtraStyle",
        "windowResizability","NSApplicationDelegateAdaptor","HSplitView","windowToolbarStyle","onExitCommand"]

    func platformHint() -> String {
        var syms = Set(occurrences.map { $0.sym })
        for d in decls { syms.formUnion(d.conforms) }
        let uikit  = imports.contains("UIKit")  || !syms.isDisjoint(with: Self.iosSignals)
        let appkit = imports.contains("AppKit") || !syms.isDisjoint(with: Self.macosSignals)
        switch (uikit, appkit) {
        case (true, true):  return "cross"
        case (true, false): return "uikit"
        case (false, true): return "appkit"
        default:            return "neutral"
        }
    }
```

- [ ] **Step 5: Add `platform` to `FileResult` and emit it**

In `swiftui-scan/Sources/swiftui-scan/main.swift`, add to the struct (after `var skipped: String?`):
```swift
    var platform: String = "neutral"
```
For the `unreadable`/`toolarge` early-emits leave the default. For the real emit (lines 44-49) add `platform: v.platformHint()`:
```swift
    emit(FileResult(path: path,
                    imports: v.imports.sorted(),
                    loc: lines.count,
                    occurrences: v.occurrences,
                    decls: v.decls,
                    skipped: nil,
                    platform: v.platformHint()))
```

- [ ] **Step 6: Add `.iOS(.v17)` to Package.swift**

`swiftui-scan/Package.swift:6`: `platforms: [.macOS(.v13)],` → `platforms: [.macOS(.v13), .iOS(.v17)],`

- [ ] **Step 7: Build + run checks (expect PASS, macOS fixture still green)**

```bash
cd /Users/serkan/swiftui-ios && ( cd swiftui-scan && swift build -c release --product swiftui-scan ) \
  && python3 swiftui-scan/fixtures/check.py
```
Expected: `ALL … CHECKS PASS` (macOS) and `ALL 5 iOS CHECKS PASS`.

- [ ] **Step 8: Commit**

```bash
cd /Users/serkan/swiftui-ios && git add -A && git commit -q -m "feat(scanner): per-file platform field + UIKit/AppKit bridge de-conflation"
```

---

### Task 3: SDK catalog at the iOS 17 target (`02` + `02b`)

**Files (in `/Users/serkan/swiftui-ios`):**
- Modify: `scripts/02_build_sdk_catalog.py:99-110` (wrappers, sdk label, modules)
- Modify: `scripts/02b_availability.py:14-16,19-29,57,84-91` (SG list, jq domain `macOS`→`iOS`, `introduced_ios`)
- Modify: `RUN.md` (the stage-2 symbolgraph commands → iOS target + extra modules)

**Interfaces:**
- Produces: `sdk_catalog.json` whose `modules` include `WidgetKit`,`ActivityKit`,`AppIntents`; `availability[name].introduced_ios`; `sdk` label contains "iOS". Stage 5 (Task 6) reads `introduced_ios`.

- [ ] **Step 1: Retarget the symbolgraph extraction in RUN.md**

Replace the macOS stage-2 block with (this is the command operators run before the harvest):

```bash
mkdir -p sg sg_std
SDK="$(xcrun --show-sdk-path --sdk iphoneos)"
for m in SwiftUI SwiftUICore Observation SwiftData Charts WidgetKit ActivityKit AppIntents; do \
  swift symbolgraph-extract -module-name $m -target arm64-apple-ios17.0 -sdk "$SDK" \
    -minimum-access-level public -emit-extension-block-symbols -output-dir sg/; done
for m in Swift Combine Foundation UIKit; do \
  swift symbolgraph-extract -module-name $m -target arm64-apple-ios17.0 -sdk "$SDK" \
    -minimum-access-level public -output-dir sg_std/; done
# flatten sg/*.symbols.json -> symbols_all.tsv ; build stdlib_method_names.json from sg_std/
python3 scripts/02_build_sdk_catalog.py
python3 scripts/02b_availability.py
```

- [ ] **Step 2: `02_build_sdk_catalog.py` — modules, label, wrappers**

- Line 110 `"modules": ["SwiftUI","SwiftUICore","Observation","SwiftData","Charts"],` → add `,"WidgetKit","ActivityKit","AppIntents"`.
- Line 109 `"sdk": "macOS 26.5 SDK",` → `"sdk": "iOS SDK (target floor iOS 17.0)",`
- Line 103 wrappers: remove `"NSApplicationDelegateAdaptor",` (keep `"UIApplicationDelegateAdaptor"`).

- [ ] **Step 3: `02b_availability.py` — iOS domain + introduced_ios**

- `SG` (lines 14-16): append the three new graphs:
```python
SG = [os.path.join(ROOT,"sg",f) for f in
      ("SwiftUI.symbols.json","SwiftUICore.symbols.json","Observation.symbols.json",
       "SwiftData.symbols.json","Charts.symbols.json",
       "WidgetKit.symbols.json","ActivityKit.symbols.json","AppIntents.symbols.json")]
```
- The `JQ` filter (line 22): `select(.domain=="macOS")` → `select(.domain=="iOS")`.
- Line 57: `rec["introduced_macos"]` → `rec["introduced_ios"]`.
- Docstring + the `REPLACEMENTS` map stay (they are cross-platform deprecations; `tabItem→Tab`, `NavigationView→NavigationStack`, `foregroundColor→foregroundStyle` are all iOS-correct).

- [ ] **Step 4: Build the iOS SDK catalog (requires Xcode iOS SDK)**

```bash
cd /Users/serkan/swiftui-ios
# (run the RUN.md stage-2 block from Step 1)
python3 -c 'import json;c=json.load(open("sdk_catalog.json"));print("sdk:",c["sdk"]);print("modules:",c["modules"]);print({k:(k in c["dimensions"]["types"]) for k in ["ActivityAttributes","ControlWidget","AppIntent"]})'
```
Expected: `sdk` contains "iOS"; modules include WidgetKit/ActivityKit/AppIntents; the three iOS-only types resolve `True`.

> If the Xcode iOS SDK is unavailable in this environment, this task is gated with Task 9/10's harvest (see Task 9 Step 0). Tasks 4–8 do not depend on a freshly built `sdk_catalog.json`.

- [ ] **Step 5: Commit**

```bash
cd /Users/serkan/swiftui-ios && git add scripts/02_build_sdk_catalog.py scripts/02b_availability.py RUN.md sdk_catalog.json 2>/dev/null; git commit -q -m "feat(sdk): build catalog at arm64-apple-ios17.0 + WidgetKit/ActivityKit/AppIntents"
```

---

### Task 4: Harvest the iOS seed (`00_harvest.py`)

**Files (in `/Users/serkan/swiftui-ios`):**
- Modify: `scripts/00_harvest.py:8-15` (seed URL(s), SELF)

**Interfaces:**
- Produces: `data/00_candidates.json` (owner/repo + categories) drawn from the iOS app list.

- [ ] **Step 1: Point the harvester at the iOS app seed**

`scripts/00_harvest.py` lines 8-15:
```python
RAW = "https://raw.githubusercontent.com/dkhamsing/open-source-ios-apps/master/README.md"
SECONDARY = "https://raw.githubusercontent.com/vsouza/awesome-ios/master/README.md"
LOCAL = "/tmp/open-source-ios-apps.md"
OUT = "data/00_candidates.json"
...
SELF = ("dkhamsing","open-source-ios-apps")
```
Add a second fetch+parse pass over `SECONDARY` (same `LINK`/`HEAD` regex), merging unique `owner/repo` and unioning categories. The `awesome-ios` list is library-heavy — tag its candidates `source: "awesome-ios"` so Task 6 can prefer app-classified repos in rankings.

- [ ] **Step 2: Run + sanity check**

```bash
cd /Users/serkan/swiftui-ios && python3 scripts/00_harvest.py && \
  python3 -c 'import json;c=json.load(open("data/00_candidates.json"));print("candidates:",len(c));print(c[0])'
```
Expected: several hundred+ candidates; each has `owner`,`repo`,`categories`.

- [ ] **Step 3: Commit**

```bash
cd /Users/serkan/swiftui-ios && git add scripts/00_harvest.py && git commit -q -m "feat(harvest): seed from open-source-ios-apps + awesome-ios"
```

> `scripts/01_gate.py` needs **no change** (CUTOFF `2024-06-07` is still ~2 years back; Swift-share rules are platform-neutral). SwiftUI-presence is enforced at stage 5 (Task 6).

---

### Task 5: iOS discovery terms (`06_discover.py`)

**Files (in `/Users/serkan/swiftui-ios`):**
- Modify: `scripts/06_discover.py:1-9` (docstring) + `:26-37` (`TERMS`)

**Interfaces:**
- Produces: `data/06_discovered.jsonl` of iOS repos found via code search.

- [ ] **Step 1: Replace the macOS-exclusive TERMS with iOS-leaning ones**

`scripts/06_discover.py` `TERMS` (lines 26-37):
```python
TERMS = [
    # Tier A — iOS-distinctive SwiftUI/iOS APIs
    "UIViewControllerRepresentable", "UIViewRepresentable", "UIApplicationDelegateAdaptor",
    "presentationDetents", "fullScreenCover", "navigationBarTitleDisplayMode",
    # Tier B — iOS extension/intent surface (no macOS analogue)
    "ControlWidget", "ControlWidgetButton", "ActivityAttributes", "ActivityConfiguration",
    "AppShortcutsProvider", "DynamicIsland",
    # Tier C — iOS interaction idioms
    "sensoryFeedback", "swipeActions", "tabViewStyle", "UIHostingController",
]
```
Update the docstring (lines 2-9) to say "iOS SwiftUI apps" and describe the inverted fallback below.

- [ ] **Step 2: Add the inverted "SwiftUI minus macOS" merge**

After the positive-term pass, add a query for broad SwiftUI app markers and subtract macOS-signal repos (reuse `06`'s existing aggregation/dedup helpers):
```python
# inverted broadening: SwiftUI apps that don't use the niche iOS tokens above
INVERTED = ['"import SwiftUI" "@main" "WindowGroup"', '"import SwiftUI" TabView NavigationStack']
MACOS_EXCLUDE = {"MenuBarExtra","NSApplicationDelegateAdaptor","windowResizability","NSHostingController"}
# run each INVERTED query via the same `gh search code` path; drop any repo whose match files
# also contain a MACOS_EXCLUDE token (cheap post-filter on the returned snippets).
```

- [ ] **Step 3: Commit** (run is part of Task 10; no standalone run here to conserve rate-limit)

```bash
cd /Users/serkan/swiftui-ios && git add scripts/06_discover.py && git commit -q -m "feat(discover): iOS-leaning code-search terms + inverted SwiftUI-minus-macOS merge"
```

---

### Task 6: Aggregation — iOS signals, 4-way platform, iOS modernity, iPad idioms (`05_catalog.py`)

**Files (in `/Users/serkan/swiftui-ios`):**
- Create: `scripts/tests/test_classify.py` (synthetic-JSONL unit check)
- Modify: `scripts/05_catalog.py` — lines `20-22` (signals), `34` (UI_IMPORTS), `38-40` (FORM_VOCAB), `42-45` (`macos_ver`→`ios_ver`), `125-160` (classification + bridge kinds + idioms), `269,275,281-283` (modernity + penalty + provenance).

**Interfaces:**
- Consumes: scanner `FileResult.platform`, `Decl.kind` ∈ {…,`uikit_bridge`,`appkit_bridge`}, and `sdk_catalog.json.availability[*].introduced_ios` (Task 3).
- Produces: per-repo `platform` ∈ {`ios`,`macos`,`cross_platform`,`library`}, `min_ios`, `ipad_idioms[]`; `bridges.json` entries carry `platform`. `repo_score` penalizes non-iOS.

- [ ] **Step 1: Write the failing classification unit test**

Create `scripts/tests/test_classify.py`:

```python
import importlib.util, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cat", os.path.join(HERE,"..","05_catalog.py"))
cat = importlib.util.module_from_spec(spec); spec.loader.exec_module(cat)

def classify(imports, syms, swiftui_occ=1, has_app=False):
    return cat.classify_platform(set(imports), set(syms), swiftui_occ, has_app)

assert classify(["UIKit"], []) == "ios"
assert classify([], ["UIViewRepresentable"]) == "ios"
assert classify(["AppKit"], []) == "macos"
assert classify(["UIKit","AppKit"], []) == "cross_platform"
assert classify([], ["MenuBarExtra"]) == "macos"
assert classify([], [], swiftui_occ=0) == "library"
assert classify([], [], swiftui_occ=5) == "ios"   # default low-confidence
print("classify_platform: ALL PASS")
```

- [ ] **Step 2: Run it — expect FAIL** (`classify_platform` doesn't exist yet)

```bash
cd /Users/serkan/swiftui-ios && python3 scripts/tests/test_classify.py
```
Expected: `AttributeError: module 'cat' has no attribute 'classify_platform'`.

- [ ] **Step 3: Signals + vocab edits**

`05_catalog.py` lines 20-22 — replace `MACOS_SIGNALS` block with both sets:
```python
# symbols that prove a repo targets a given platform
IOS_SIGNALS = {"UIViewRepresentable","UIViewControllerRepresentable","UIHostingController",
               "UIApplicationDelegateAdaptor","fullScreenCover","presentationDetents",
               "navigationBarTitleDisplayMode","prefersLargeContent","UIScreen","UIDevice",
               "UIImpactFeedbackGenerator","ControlWidget","ActivityAttributes"}
MACOS_SIGNALS = {"MenuBarExtra","Settings","NSViewRepresentable","NSViewControllerRepresentable",
                 "NSHostingController","windowStyle","menuBarExtraStyle","windowResizability",
                 "NSApplicationDelegateAdaptor","HSplitView","windowToolbarStyle","onExitCommand"}
IPAD_IDIOM_SIGNALS = {"NavigationSplitView","horizontalSizeClass","verticalSizeClass",
                      "ViewThatFits","containerRelativeFrame","supportsMultipleWindows"}
```
Line 34: `UI_IMPORTS = {"SwiftUI", "SwiftUICore", "Charts"}` → add `"UIKit"`.
Lines 38-40 `FORM_VOCAB`: remove `"Settings",` (no iOS Settings scene).

- [ ] **Step 4: `ios_ver` + `classify_platform` helper**

Rename the `macos_ver` function (lines 42-46) to `ios_ver` (same body). Add a module-level helper near it:
```python
def classify_platform(imports, syms, swiftui_occ, has_app):
    ios_pos = ("UIKit" in imports) or bool(IOS_SIGNALS & syms)
    mac_pos = ("AppKit" in imports) or bool(MACOS_SIGNALS & syms)
    if ios_pos and mac_pos: return "cross_platform"
    if ios_pos: return "ios"
    if mac_pos: return "macos"
    if swiftui_occ == 0 and not has_app: return "library"
    return "ios"   # default low-confidence (awesome-ios seed is iOS-majority)
```

- [ ] **Step 5: Wire classification + bridge kinds + idioms into the aggregation loop**

In the per-occurrence loop replace the `introduced_macos` read (lines 125-127):
```python
                    iv = ios_ver(av.get("introduced_ios","")) if av else 0.0
                    if iv > prof["max_ios"]: prof["max_ios"] = iv
```
(and initialize `prof["max_ios"]=0.0` wherever `max_macos` was initialized.)

Bridge handling (line 141): `if d["kind"] == "bridge":` → `if d["kind"].endswith("bridge"):` and add `"platform": "uikit" if d["kind"]=="uikit_bridge" else "appkit"` to the appended dict.

Classification block (lines 155-161) becomes:
```python
        repo_profile[repo] = prof
        repo_meta[repo]["min_ios"] = prof["max_ios"]
        repo_meta[repo]["deprecated"] = len(prof["deprecated"]) > 0
        syms = prof["types"] | prof["modifiers"] | prof["propertyWrappers"]
        has_app = any(d.get("kind") in ("app","scene") for d in prof.get("decls_kinds", []))
        repo_meta[repo]["platform"] = classify_platform(
            set(prof["imports"]), syms, prof.get("swiftui_occ", 0), has_app)
        repo_meta[repo]["ipad_idioms"] = sorted(IPAD_IDIOM_SIGNALS & syms)
        _write_repo_profile(repo, prof, repo_meta[repo])
```
Track `prof["swiftui_occ"]` (increment whenever a matched occurrence's source file imported SwiftUI) and `prof["decls_kinds"]` (append each decl's kind) earlier in the loop where `prof` is populated.

- [ ] **Step 6: iOS modernity + non-iOS penalty**

In `repo_score` (lines 269,275):
```python
    modern_n = min(1.0, max(0.0, (m.get("min_ios",0)-13)/13.0))   # iOS 13→0 … 26→1
```
```python
        + (0.25 if m.get("platform") not in ("ios","cross_platform") else 0.0)
```
In `_provenance` (lines 281-283): `mm = m.get("min_ios",0)` and emit `"min_ios": (...)` (rename the key).

- [ ] **Step 7: Run the unit test — expect PASS**

```bash
cd /Users/serkan/swiftui-ios && python3 scripts/tests/test_classify.py
```
Expected: `classify_platform: ALL PASS`.

- [ ] **Step 8: Commit**

```bash
cd /Users/serkan/swiftui-ios && git add scripts/05_catalog.py scripts/tests/test_classify.py && git commit -q -m "feat(aggregate): iOS signals, 4-way platform classify, iOS modernity, iPad idioms, bridge platform"
```

---

### Task 7: iOS recipe extraction targets (`08_recipes.py`)

**Files (in `/Users/serkan/swiftui-ios`):**
- Modify: `scripts/08_recipes.py` (the recipe pattern keys/signatures it mines for)

**Interfaces:**
- Produces: `catalog/recipes.json` keyed by iOS recipe names. (Recipe *templates* are authored in SP2/SP4; this task only retargets which patterns are extracted from the corpus.)

- [ ] **Step 1: Read the current recipe definitions and retarget**

Read `scripts/08_recipes.py` to find the recipe-name → signature map (macOS recipes: `menubar-app`, `settings-screen`, `nsview-bridge`, …). Replace the macOS-only entries with iOS targets, keyed by detectable signatures:
- `tab-bar-app` → repos using `TabView` + `Tab`/`.tabItem`
- `navigationstack-master-detail` → `NavigationStack` + `navigationDestination`
- `sheet-detents` → `.sheet` + `presentationDetents`
- `fullscreen-cover-flow` → `fullScreenCover`
- `uiview-bridge` → `uikit_bridge` decls
- `widget-scaffold` → `WidgetKit`/`Widget`
- `app-intent` → `AppIntent`/`AppShortcutsProvider`
Keep any platform-neutral recipes (e.g. `observable-model`) unchanged.

- [ ] **Step 2: Commit** (extraction runs in Task 10)

```bash
cd /Users/serkan/swiftui-ios && git add scripts/08_recipes.py && git commit -q -m "feat(recipes): retarget extraction to iOS patterns (tab/nav-stack/sheet/uiview-bridge/widget/app-intent)"
```

---

### Task 8: Pilot harvest + smoke test

**Files:** none modified — this validates Tasks 2–7 end-to-end on a small set.

**Interfaces:**
- Consumes: all retargeted scripts + the iOS `sdk_catalog.json` (Task 3).
- Produces: a small `catalog/` proving the wiring; confirms environment for the full run.

- [ ] **Step 0: Confirm environment**

```bash
gh auth status 2>&1 | tail -2
xcrun --show-sdk-path --sdk iphoneos 2>&1
df -h /Users/serkan | tail -1
```
Expected: `gh` logged in; an iphoneos SDK path prints; ample free disk. *If the iOS SDK is missing*, build it on a machine with Xcode and copy `sdk_catalog.json` in (Task 3 Step 4), or proceed with the macOS-built `sdk_catalog.json` for a wiring-only pilot (availability floors will be macOS until rebuilt).

- [ ] **Step 1: Pilot 00→05 on a handful of known iOS SwiftUI repos**

```bash
cd /Users/serkan/swiftui-ios
python3 scripts/00_harvest.py
python3 scripts/01_gate.py
( cd swiftui-scan && swift build -c release --product swiftui-scan )
python3 scripts/04_run.py --jobs 4 --only dkhamsing/ChouTi,pointfreeco/isowords,Dimillian/IceCubesApp
python3 scripts/05_catalog.py
```
(Adjust `--only` to repos confirmed present in `data/01_included.json`.)

- [ ] **Step 2: Smoke-test the catalog**

```bash
cd /Users/serkan/swiftui-ios
B=swiftui-scan/.build/release/swiftui-ctx
SWIFTUI_CTX_CATALOG=catalog $B lookup TabView --platform ios --json | python3 -c 'import sys,json;d=json.load(sys.stdin);print("ok",d["ok"]); print("examples",len(d.get("result",{}).get("examples",[])) if d["ok"] else d.get("error"))'
SWIFTUI_CTX_CATALOG=catalog $B lookup presentationDetents --platform ios --json | python3 -c 'import sys,json;print(json.load(sys.stdin)["ok"])'
python3 -c 'import json,glob; ps=[json.load(open(f)).get("platform") for f in glob.glob("catalog/by_repo/*.json")]; from collections import Counter; print(Counter(ps))'
```
Expected: `lookup TabView --platform ios` → `ok True` with ≥1 example; platform Counter shows `ios`/`cross_platform` repos.

- [ ] **Step 3: Commit the pilot catalog (optional checkpoint)**

```bash
cd /Users/serkan/swiftui-ios && git add catalog data && git commit -q -m "chore: pilot iOS catalog (wiring validation)"
```

---

### Task 9: Full harvest + index verification + README numbers

**Files (in `/Users/serkan/swiftui-ios`):**
- Produces: full `catalog/`; Modify: `README.md` (corpus numbers), `catalog/index.json` (verified).

**Interfaces:**
- Produces: the SP1 deliverable — a populated, platform-classified iOS catalog consumed by SP2–SP4.

- [ ] **Step 1: Run the full pipeline (background; multi-hour, resumable)**

```bash
cd /Users/serkan/swiftui-ios
python3 scripts/00_harvest.py && python3 scripts/01_gate.py
python3 scripts/04_run.py --jobs 6          # clone▸scan▸delete across all gated repos (resumable)
python3 scripts/05_catalog.py
python3 scripts/06_discover.py && python3 scripts/06b_gate_discovered.py
python3 scripts/04_run.py --jobs 6          # scan the newly discovered repos
python3 scripts/07_enrich_authors.py && python3 scripts/05_catalog.py   # re-rank with authority
python3 scripts/08_recipes.py
```

- [ ] **Step 2: Verify the index meets the success criteria**

```bash
cd /Users/serkan/swiftui-ios && python3 -c '
import json,glob;from collections import Counter
idx=json.load(open("catalog/index.json"));print("sdk:",idx.get("sdk"),"repos:",idx.get("repos_analyzed"))
ps=Counter(json.load(open(f)).get("platform") for f in glob.glob("catalog/by_repo/*.json"));print("platforms:",ps)
'
```
Expected: `sdk` contains "iOS"; `repos_analyzed` is several hundred+; platform mix is iOS-dominant.

- [ ] **Step 3: Fill README corpus numbers + commit**

Replace the `<!-- corpus numbers… -->` marker in `README.md` with the real counts from `index.json`.

```bash
cd /Users/serkan/swiftui-ios && git add -A && git commit -q -m "feat(catalog): full iOS corpus harvest + verified index + README numbers"
```

---

## Self-Review

- **Spec coverage:** §A scaffold→T1; §B scanner platform+bridge→T2; §B Package.swift→T2; §C `00`→T4, `01` (no-change, SwiftUI-presence relocated to T6)→noted in Global Constraints, `02/02b`→T3, `05`→T6, `06/06b`→T5, `07` (no-change)→T9, `08`→T7; §D harvest→T8 (pilot)+T9 (full); §E testing→T2 (fixtures), T3 Step 4 + T8 Step 2 (smoke), T6 (unit). All success criteria (1 scanner platform; 2 index sdk/repos; 3 4-way platform+min_ios; 4 iOS-only types resolve; 5 `lookup --platform ios`; 6 fixtures) map to tasks.
- **Placeholders:** none — every script edit shows the current→target code; commands have expected output.
- **Type consistency:** `platform` strings (`uikit/appkit/cross/neutral` at scanner; `ios/macos/cross_platform/library` at repo level) are used consistently; `classify_platform` signature matches its test and call site; `introduced_ios`/`min_ios`/`max_ios`/`ios_ver` renamed consistently; bridge kinds `uikit_bridge`/`appkit_bridge` consistent across scanner, fixture asserts, and `05_catalog` consumer.

**Known follow-on (SP2):** `Shards.swift` `bridges` command still filters on the old `bridge` conformance kind — re-point it to `*_bridge` and surface `platform`; CLI default-platform flip and iOS recipe *templates* are SP2 scope (not required for SP1's success criteria, which use explicit `--platform ios`).
