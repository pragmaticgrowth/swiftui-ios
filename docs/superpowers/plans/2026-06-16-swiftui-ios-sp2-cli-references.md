# swiftui-ios — SP2: CLI + references retarget (plan)

> **For agentic workers:** REQUIRED SUB-SKILL: subagent-driven-development. Steps use `- [ ]`.

**Design source:** Continuation of the approved program (see `docs/superpowers/specs/2026-06-16-swiftui-ios-data-foundation-design.md` §1 decomposition + blueprint). SP1 (data foundation) is complete; the iOS catalog at `/Users/serkan/swiftui-ios/catalog` carries `min_ios` / `introduced_ios` / `min_ios_inferred` / per-bridge `platform`. SP2 makes the **CLI** read those keys + actively filter by iOS, and retargets the macOS-bound **reference docs**. No new behavior beyond what SP1's catalog already provides — this is a faithfulness/retarget pass.

**Goal:** `swiftui-ctx` is fully iOS-correct (defaults to iOS, filters examples to iOS/cross-platform, surfaces iOS floors, routes to iOS bridge recipes), and the shared reference docs reflect iOS floors/gating.

## Global Constraints
- Repo: `/Users/serkan/swiftui-ios`. macOS repo untouched.
- The catalog keys are already iOS: `provenance.platform ∈ {ios,macos,cross_platform}`, `provenance.min_ios`, `availability.introduced_ios`, `by_repo.min_ios_inferred`, `bridges[].platform ∈ {uikit,appkit}`. The CLI must read THESE (it currently reads the old `*_macos` keys → shows null).
- `--platform` semantics for an iOS plugin: default **`ios`**; values `ios` (→ ios + cross_platform examples), `macos`, `cross` (→ cross_platform only), `any` (no filter). Fall back to all examples when a platform filter yields none (preserve existing macOS-branch fallback behavior).
- iOS floor 17; iPad within `ios`. Don't change ranking/catalog — CLI + docs only.
- Bump `plugin.json` version on user-facing change (→ `0.2.0`).

---

### Task 1: CLI iOS retarget (`SwiftUICtx.swift` + `Shards.swift`)

**Files:** `swiftui-scan/Sources/swiftui-ctx/SwiftUICtx.swift`, `swiftui-scan/Sources/swiftui-ctx/Shards.swift`

**Interfaces produced:** `swiftui-ctx lookup <api> --platform ios` returns only ios/cross_platform examples + the iOS floor; `bridges` defaults to UIKit framing; all surfaced floor/version fields read the iOS catalog keys.

The exact edit map (verified line numbers):

`SwiftUICtx.swift`
- `:5,:14` header/abstract "1,857 production macOS apps" → "shipping iOS & iPadOS apps".
- `:49` `var platform: String = "macos"` → `= "ios"`; help `"macos|any"` → `"ios|macos|cross|any"`.
- `:82-85` `examplesFiltered`: generalize the macos-only branch to:
```swift
    switch platform {
    case "ios":
        let ios = exs.filter { ["ios","cross_platform"].contains($0.dict("provenance").s("platform") ?? "") }
        if !ios.isEmpty { exs = ios }
    case "cross":
        let cx = exs.filter { ($0.dict("provenance").s("platform")) == "cross_platform" }
        if !cx.isEmpty { exs = cx }
    case "macos":
        let mac = exs.filter { ($0.dict("provenance").s("platform")) == "macos" }
        if !mac.isEmpty { exs = mac }
    default: break   // "any" → no platform filter
    }
```
- `:103` `exampleBrief`: `"min_macos": p.s("min_macos")` → `"min_ios": p.s("min_ios")`.
- `:134-135,:141` lookup NS/UI redirect: prefer `uiview-bridge`. If api starts with `UI` and `cat.recipe("uiview-bridge") != nil` → NextAction `recipe uiview-bridge` ("wrap a UIKit view in SwiftUI"); keep an `nsview-bridge` fallback only if that recipe exists (it won't in the iOS catalog). Update the human message to "UIKit" wording.
- `:184` lookup result `"introduced_macos": av.s("introduced_macos")` → `"introduced_ios": av.s("introduced_ios")`.
- `:209` `" · macOS \(iv)+"` reading `av.s("introduced_macos")` → `" · iOS \(iv)+"` reading `av.s("introduced_ios")`.
- `:256` note `" (macOS only; pass --platform any for iOS/library examples.)"` → `" (iOS/iPadOS; pass --platform macos|cross|any to widen.)"` and gate on `common.platform == "ios"`.
- `:389` stats: `"min macOS: \(p.s("min_macos_inferred"))"` → `"min iOS: \(p.s("min_ios_inferred"))"`.

`Shards.swift`
- `:12` abstract "NSViewRepresentable & friends" → "UIKit/AppKit bridges in production (UIViewRepresentable & friends)".
- `:14` filter help "NSViewRepresentable…" → "UIViewRepresentable…".
- `:36` `recipe nsview-bridge` → `recipe uiview-bridge`.
- `:141` `"min_macos": r.s("min_macos")` → `"min_ios": r.s("min_ios")`.
- `:153,:164` `"macOS \(min_macos)"` → `"iOS \(r["min_ios"])"` (read the `min_ios` key).
- Optionally surface each bridge's `platform` (uikit/appkit) in the `bridges` example dict (read `b.s("platform")`).

- [ ] **Step 1:** Apply the SwiftUICtx.swift edits above.
- [ ] **Step 2:** Apply the Shards.swift edits above.
- [ ] **Step 3:** Build: `( cd swiftui-scan && swift build -c release --product swiftui-ctx )` → green.
- [ ] **Step 4:** Smoke (catalog is at `./catalog`):
```bash
B=swiftui-scan/.build/release/swiftui-ctx; export SWIFTUI_CTX_CATALOG=catalog
$B lookup TabView --json | python3 -c 'import sys,json;d=json.load(sys.stdin);r=d["result"];print("platform-default ok:",d["ok"]);print("intro_ios:",r.get("availability",{}).get("introduced_ios") if isinstance(r.get("availability"),dict) else None)'
$B lookup NavigationStack --platform ios --json | python3 -c 'import sys,json;d=json.load(sys.stdin);print("ios examples:",len(d["result"].get("examples",[])) if d["ok"] else d.get("error"))'
$B bridges --json | python3 -c 'import sys,json;d=json.load(sys.stdin);print("bridges ok:",d["ok"])'
```
Expected: default platform now ios; `introduced_ios` non-null for NavigationStack (iOS 16); bridges ok.
- [ ] **Step 5:** Commit: `feat(cli): iOS platform filtering + read iOS catalog keys (min_ios/introduced_ios) + uiview-bridge routing`

---

### Task 2: Reference docs retarget (`references/_shared/`)

**Files:** Create `references/_shared/ios-gating.md`; Create `scripts/gen_floors.py`; Modify `references/_shared/floors-master.md`, `hallucination-blacklist.md`, `swiftui-ctx-reference.md`, `CLI.md`; Delete `references/_shared/macos-arm-gating.md`.

- [ ] **Step 1:** Read `references/_shared/floors-master.md`, `macos-arm-gating.md`, `hallucination-blacklist.md`, `swiftui-ctx-reference.md` to learn their structure/consumers.
- [ ] **Step 2:** `scripts/gen_floors.py` — emit an iOS floor table into `floors-master.md` from `sdk_catalog.json` availability:
```python
#!/usr/bin/env python3
"""Generate the iOS floor table in references/_shared/floors-master.md from sdk_catalog.json introduced_ios."""
import json, os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
av=json.load(open(os.path.join(ROOT,"sdk_catalog.json"))).get("availability",{})
rows=sorted(((n,d["introduced_ios"]) for n,d in av.items() if d.get("introduced_ios")),
            key=lambda x:(tuple(int(p) for p in x[1].split(".")), x[0]))
# group by floor; write a concise reference (floor -> notable APIs), capped per floor
from collections import defaultdict
byfloor=defaultdict(list)
for n,v in rows: byfloor[v].append(n)
lines=["# iOS availability floors (generated from sdk_catalog.json `introduced_ios`)","",
       "> Min-iOS each SwiftUI symbol became available. Verify anything marked verify-SDK in Xcode.",""]
for floor in sorted(byfloor, key=lambda v:tuple(int(p) for p in v.split("."))):
    apis=sorted(byfloor[floor])
    lines.append(f"## iOS {floor}+  ({len(apis)} symbols)")
    lines.append(", ".join(f"`{a}`" for a in apis[:60]) + ("" if len(apis)<=60 else f", … (+{len(apis)-60} more)"))
    lines.append("")
open(os.path.join(ROOT,"references","_shared","floors-master.md"),"w").write("\n".join(lines))
print(f"floors-master.md: {len(rows)} symbols across {len(byfloor)} iOS floors")
```
Run it: `python3 scripts/gen_floors.py`.
- [ ] **Step 3:** Author `references/_shared/ios-gating.md` (replaces `macos-arm-gating.md`): iOS deployment-target gating — `@available(iOS 17, *)` / `#available`, idiom checks (`horizontalSizeClass`, `UIDevice.current.userInterfaceIdiom`), and the iOS-17-floor policy. Then `git rm references/_shared/macos-arm-gating.md`. Grep the repo for references to `macos-arm-gating` and repoint them to `ios-gating` (skills don't exist yet, but RUN.md/READMEs/other refs might link it).
- [ ] **Step 4:** `hallucination-blacklist.md` — keep the platform-neutral invented-name guards; ensure NS*-bridge-on-iOS entries note "use UIViewRepresentable on iOS"; add any iOS-invented-name guards you know (e.g. APIs that don't exist). Light touch — don't fabricate.
- [ ] **Step 5:** `swiftui-ctx-reference.md` + `CLI.md` — replace "1,857 production macOS apps" / macOS counts with the iOS corpus numbers (319 repos, iOS SDK floor 17) and the `--platform ios|macos|cross|any` semantics.
- [ ] **Step 6:** Commit: `docs(references): iOS floors (generated) + ios-gating + iOS corpus numbers`

---

### Task 3: Version bump + verify

**Files:** `.claude-plugin/plugin.json`

- [ ] **Step 1:** `plugin.json` version `0.1.0` → `0.2.0`.
- [ ] **Step 2:** Full verify:
```bash
B=swiftui-scan/.build/release/swiftui-ctx; export SWIFTUI_CTX_CATALOG=catalog
$B doctor
$B lookup sensoryFeedback --json | python3 -c 'import sys,json;d=json.load(sys.stdin);print("intro_ios:",d["result"].get("availability",{}).get("introduced_ios"))'  # expect 17.0
$B recipe uiview-bridge --json | python3 -c 'import sys,json;print("uiview-bridge ok:",json.load(sys.stdin)["ok"])'
python3 swiftui-scan/fixtures/check.py >/dev/null && echo "scanner fixtures green"
```
- [ ] **Step 3:** Commit: `chore(release): swiftui-ios 0.2.0 — iOS-correct CLI + references`

## Self-Review
- Coverage: every residual `*_macos` CLI key (SwiftUICtx 103/184/209/256/389, Shards 141/153/164) is repointed; platform filtering added; bridge routing → uiview-bridge; references retargeted; version bumped.
- Placeholders: none — exact line edits + runnable smoke probes given.
- Type consistency: CLI reads `min_ios`/`introduced_ios`/`min_ios_inferred`/`platform` — the exact keys SP1 writes.
