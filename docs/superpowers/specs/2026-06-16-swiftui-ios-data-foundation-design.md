# swiftui-ios — Sub-project 1: iOS data foundation (design spec)

**Date:** 2026-06-16
**Status:** Approved (design) — pending written-spec review
**Author:** Claude (brainstormed with Serkan)
**Source plugin:** `claude-swiftui-plugin` (macOS, v1.0.2)

---

## 1. Program context

We are transforming the macOS "grounded SwiftUI" plugin into an iOS equivalent **using the same methodology**: harvest real shipping apps → parse with SwiftSyntax → build a queryable, quality-ranked catalog → wrap in the `swiftui-ctx` CLI → layer audit/write/scaffold skills + a deprecation hook on top.

### Locked decisions (from brainstorming)

| Decision | Choice |
|---|---|
| **Topology** | A **separate `swiftui-ios` plugin** (sibling repo), distinct catalog + distinct skill names. The macOS plugin is untouched. |
| **iOS floor** | **iOS 17** — clean `@Observable` / SwiftData / `sensoryFeedback` / NavigationStack story; parity with the macOS-14 corpus. |
| **iPad scope** | **iPhone + iPad adaptive arm** — size-class / idiom awareness (`NavigationSplitView`, `ViewThatFits`, multi-window) modeled within `ios`, not as a separate platform. |
| **Catalog/release** | **Run the full `awesome-ios` harvest before release** — ship on a real iOS corpus, not the demoted iOS slice already in the macOS catalog. |

### Decomposition (4 sequential sub-projects, each its own spec → plan → build)

1. **iOS data foundation** ← *this spec* — fork to `swiftui-ios`, retarget scanner + pipeline, build iOS SDK floors, run the full harvest → real iOS `catalog/`.
2. **CLI + references retarget** — `swiftui-ctx` iOS defaults/recipes, multi-platform floors / gating / cross-ref reference docs.
3. **Audit suite** — 10 universal + 11 retargeted + 8 net-new domains; `audit-ios-swiftui-full` orchestrator; lint rule files + fixtures + selftest.
4. **Write/scaffold skills + commands + hook + agent + eval + manifest/README.**

This spec covers **only Sub-project 1**. The output of Sub-project 1 — a populated, platform-classified iOS `catalog/` plus a platform-aware scanner — is the contract every later sub-project consumes.

---

## 2. Goal & success criteria

**Goal:** Stand up the `swiftui-ios` plugin skeleton and produce a real, quality-ranked iOS SwiftUI catalog by running the full pipeline against `awesome-ios`, targeting iOS 17, with iPhone + iPad adaptive classification.

**Success criteria (all must hold):**

1. `swiftui-scan` emits a `platform` field on every `FileResult` and `Decl`, and distinguishes `uikit_bridge` from `appkit_bridge`.
2. The pipeline (`00`→`08`) runs end-to-end against the iOS seed and produces `catalog/` whose `index.json` reports an `sdk` label matching the **installed** iOS SDK (e.g. `iOS 26.x`) with a **target floor of iOS 17**, and a non-trivial `repos_analyzed` count (target: several hundred gated iOS SwiftUI repos; exact yield validated after the pilot).
3. Every repo profile carries a 4-way `platform` classification (`ios` / `macos` / `cross_platform` / `library`) and a `min_ios_inferred`.
4. iOS-only frameworks resolve in the SDK catalog: `swiftui-ctx lookup ActivityAttributes`, `lookup ControlWidget`, `lookup AppIntent` return SDK hits (not "not found").
5. `swiftui-ctx lookup TabView --platform ios` and `lookup presentationDetents --platform ios` return real iOS examples with GitHub permalinks.
6. Scanner regression fixtures pass, including new iOS assertions.

**Explicitly NOT in scope here** (deferred): CLI default-platform flip + iOS recipes (SP2), audit skills (SP3), write/scaffold skills, commands, hook, agent, eval, README/manifest polish (SP4). Sub-project 1 builds the *data + parser*; it may leave the CLI defaulting to `macos` and simply prove iOS data is queryable via `--platform ios`.

---

## 3. Architecture overview

```
awesome-ios + open-source-ios-apps  (seed)
        │  00_harvest
        ▼
  candidates ──01_gate──► gated iOS repos (recency, swift-share, swiftui-share)
                                │
   iOS 17 SDK symbolgraph ◄─────┤  02 / 02b  (arm64-apple-ios17.0; +WidgetKit/ActivityKit/AppIntents)
   (introduced_ios floors)      │
                                ▼  04_run: clone ▸ swiftui-scan (platform-aware) ▸ delete
                          per-repo JSONL
                                │  05_catalog (iOS_SIGNALS, platform-enum, min_ios, iPad idioms)
                                ▼
                      catalog/*.json  ──06/06b discover──► more iOS repos ──► re-aggregate
                                │  07 enrich authors · 08 recipes (iOS)
                                ▼
                   swiftui-ctx  (queryable: --platform ios)
```

The **engine is reused verbatim**: SwiftParser AST walk, the clone→scan→delete loop, author-authority enrichment, JSON sharding, ranking. Only the **seed, the target triple, the signal sets, the classification, and the discovery terms** change, plus one small additive scanner change (the `platform` field + bridge de-conflation).

---

## 4. Components

### A. Repo scaffold

- New sibling repo/plugin `swiftui-ios`. Copy the platform-neutral engine verbatim: `swiftui-scan/`, `scripts/`, `references/_shared/`, `Makefile`, `bin/swiftui-ctx`, `scripts/swiftui-ctx`, `eval/` harness shell, `hooks/` wiring (rules retargeted in later sub-projects).
- New `.claude-plugin/plugin.json`: `name: "swiftui-ios"`, keywords `["swiftui","ios","ipados","swift","code-examples","audit","cli"]`, fresh description. New `marketplace.json`. Bump to `0.1.0`.
- New `README.md` framed for iOS (numbers filled in after the harvest).
- `data/` and the raw `repos/` dump are regenerated, not copied. The committed macOS `catalog/` is **not** carried over.

### B. Scanner changes (`swiftui-scan`) — additive, surgical

Confirmed seams:

- **`ScanVisitor.swift:46-54`** — `conformanceKind` maps both `NSViewRepresentable`/`NSViewControllerRepresentable` *and* `UIViewRepresentable`/`UIViewControllerRepresentable` to a single `"bridge"` kind. **Change:** NS* → `"appkit_bridge"`, UI* → `"uikit_bridge"`. (Downstream `bridges.json` consumers in `Shards.swift` updated in SP2; SP1 only changes the emitted kind string.)
- **`FileResult` / `Decl` (`ScanVisitor.swift:26-36`, `main.swift`)** — add a computed **`platform`** field: `uikit` | `appkit` | `cross` | `neutral`, derived from `imports` (`UIKit` vs `AppKit`) ∪ the signal-set overlap (see §5). Emitted once per file (and surfaced on `Decl` for bridge decls). ~50 lines; no behavior change to existing fields.
- **`Package.swift`** — add `.iOS(.v17)` to `platforms` (currently `[.macOS(.v13)]`). The package still builds the same two products.

Regression-safety: existing macOS fixtures must still pass (the `platform` field is additive; `appkit_bridge` replaces `bridge` for NS* — fixture `.expect` updated accordingly).

### C. Pipeline retarget (`scripts/00–08`)

| Stage | File:anchor | Change |
|---|---|---|
| Harvest | `00_harvest.py:8` (`RAW`) | seed → `vsouza/awesome-ios` README; add a second pass over `dkhamsing/open-source-ios-apps` (its category READMEs link repos the same way). `SELF`/`RESERVED` updated. |
| Gate | `01_gate.py` | keep recency (`CUTOFF`) + `swift_share ≥ 0.2` + `swift_bytes ≥ 3KB`; **add a SwiftUI-presence floor** (require ≥1 file importing SwiftUI) since iOS repos skew UIKit-heavy and we want SwiftUI apps. |
| SDK build | `02_build_sdk_catalog.py` + `RUN.md:24-30` | target `arm64-apple-ios17.0`; **module set adds `WidgetKit`, `ActivityKit`, `AppIntents`** alongside `SwiftUI, SwiftUICore, Observation, SwiftData, Charts`; stdlib denylist (`sg_std`) adds `UIKit` to subtract UIKit method-name collisions. Drop `NSApplicationDelegateAdaptor` from the property-wrapper set; add `UIApplicationDelegateAdaptor`. |
| Availability | `02b_availability.py` | emit `introduced_ios` / `deprecated` / `renamed` (replaces the macOS arm). This output **also seeds the iOS floor table** used by SP2's `floors-master`. |
| Aggregate | `05_catalog.py:20-22` | replace `MACOS_SIGNALS` with **`iOS_SIGNALS`** (see §5). |
| | `05_catalog.py:158-160` | platform classification becomes a **4-way enum** (see §5), not binary `macos`/`other`. |
| | `05_catalog.py:34` (`UI_IMPORTS`) | add `UIKit`; prefer the scanner-emitted `platform` field over import-only filtering. |
| | `05_catalog.py:30` (`COOC_NOISE`) | keep visionOS noise; do **not** treat iOS tokens as noise. |
| | `05_catalog.py:36-40` (`SETTINGS_RE`/`FORM_VOCAB`) | drop the `Settings` scene token (no iOS Settings scene); keep `Form`/`Section`/`Picker`/`Toggle`/etc.; route to `ios_settings.json` (a "preferences screen" pattern shard). |
| | `05_catalog.py` modernity (`~269,275`) | per-platform normalization `(min_ios - 13)/N`; remove the non-macOS ranking penalty. Capture **iPad-idiom signals** (`NavigationSplitView`, `horizontalSizeClass`, `verticalSizeClass`, `ViewThatFits`, `containerRelativeFrame`) into the repo profile to support the adaptive arm. |
| Discover | `06_discover.py:26-37` (`TERMS`) | iOS-leaning discriminators (see §5). Because iOS-exclusive tokens are weaker than macOS ones, **also run an inverted query** (SwiftUI app markers MINUS macOS terms) and merge. |
| Gate discovered | `06b_gate_discovered.py` | unchanged logic; feeds the same iOS gate. |
| Enrich | `07_enrich_authors.py` | unchanged (author authority is platform-neutral). |
| Recipes | `08_recipes.py` | iOS recipe extraction targets: `tab-bar-app`, `navigationstack-master-detail`, `sheet-detents`, `fullscreen-cover-flow`, `uiview-bridge`, `widget-scaffold`, `app-intent`, `onboarding-flow`. (Recipe *templates* authored in SP2/SP4; SP1 extracts the matching real examples.) |

### D. The harvest run (gated, environment-heavy)

Execute `00`→`08` → produces `catalog/` for the gated iOS corpus.

**Prerequisites (must confirm before running):**
- `gh` authenticated (harvest + discovery use the GitHub API; code-search is rate-limited to ~10 req/min).
- Xcode / Swift 6.3 toolchain with the **iOS 17+ SDK** installed (for `swift symbolgraph-extract -sdk $(xcrun --show-sdk-path --sdk iphoneos)` and building `swiftui-scan`).
- Disk headroom for clone→scan→delete (peak ≈ `jobs × largest shallow clone`).

**Cost:** multi-hour (cloning/scanning ~1–2k repos). The run is **resumable** (a `done`-terminated per-repo JSONL is skipped) and **disk-bounded** (streaming clone→delete), inheriting the macOS pipeline's properties.

**Sequencing within SP1:** do `02`/`02b` (SDK symbolgraph at `ios17`) **early** — it's cheap and produces the floor table that SP2 needs — then the long `04_run` harvest. Pilot with `--only`/`--limit` on a handful of known-good iOS SwiftUI repos before the full run.

### E. Testing

- Extend `swiftui-scan/fixtures/` with an iOS sample exercising: `UIViewRepresentable` + `UIViewControllerRepresentable` (→ `uikit_bridge`), `import UIKit` (→ `platform: uikit`), a cross-platform file (`#if os(iOS)`), `TabView`/`.tabItem`, `presentationDetents`, `fullScreenCover`, `@UIApplicationDelegateAdaptor`. Update `fixtures/check.py` with assertions for the new `platform` field and bridge kinds. Keep the macOS fixture green.
- Spot-check `02b` iOS floors against known introductions (`NavigationStack` = iOS 16, `@Observable`/`SwiftData`/`sensoryFeedback` = iOS 17, `presentationDetents` = iOS 16, `ContentUnavailableView` = iOS 17).
- Catalog smoke tests: `swiftui-ctx lookup TabView --platform ios`, `lookup presentationDetents --platform ios`, `lookup ActivityAttributes` all return `ok:true` with results.

---

## 5. Platform classification (detailed)

The scanner emits a per-file `platform` hint; `05_catalog.py` aggregates per-repo into the 4-way enum.

**`iOS_SIGNALS`** (strong iOS-only proof): `UIViewRepresentable`, `UIViewControllerRepresentable`, `UIHostingController`, `UIApplicationDelegateAdaptor`, `fullScreenCover`, `presentationDetents`, `navigationBarTitleDisplayMode`, `tabViewStyle` (`.page`), `prefersLargeContent`, `accessibilityShowsLargeContentViewer`, `UIScreen`, `UIDevice`, `UIImpactFeedbackGenerator`, `ControlWidget`, `ActivityAttributes`.

**`MACOS_SIGNALS`** (unchanged, used to detect cross-platform): `MenuBarExtra`, `Settings`, `NSViewRepresentable`, `NSViewControllerRepresentable`, `NSHostingController`, `windowStyle`, `menuBarExtraStyle`, `windowResizability`, `NSApplicationDelegateAdaptor`, `HSplitView`, `windowToolbarStyle`, `onExitCommand`.

**`iPAD_IDIOM_SIGNALS`** (recorded, not classifying): `NavigationSplitView`, `horizontalSizeClass`, `verticalSizeClass`, `ViewThatFits`, `containerRelativeFrame`, `.onHover` (pointer-on-iPad), `supportsMultipleWindows`.

**Classification rule (per repo):**
- `import UIKit` OR `iOS_SIGNALS` overlap → **iOS-positive**.
- `import AppKit` OR `MACOS_SIGNALS` overlap → **macOS-positive**.
- both positive → `cross_platform`; only iOS-positive → `ios`; only macOS-positive → `macos`; neither, and no `app`/`scene` decl → `library`; neither but has an app entry point → default `ios` (iOS is the majority case for the `awesome-ios` seed) with a `platform_low_confidence` flag.

**Discovery `TERMS` (iOS-leaning):** `UIViewControllerRepresentable`, `UIViewRepresentable`, `UIApplicationDelegateAdaptor`, `presentationDetents`, `fullScreenCover`, `navigationBarTitleDisplayMode`, `tabViewStyle(.page)`, `ControlWidget`, `ControlWidgetButton`, `ActivityAttributes`, `ActivityConfiguration`, `AppIntent`, `AppShortcutsProvider`, `sensoryFeedback`, `refreshable`, `swipeActions` — **plus** an inverted query: SwiftUI app markers (`@main` + `App` + `WindowGroup`/`TabView`) MINUS `MACOS_SIGNALS`.

---

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| iOS corpus is noisier (UIKit-heavy, many cross-platform repos). | SwiftUI-presence gate (§C `01`); scanner `platform` field + 4-way enum; `cross_platform` is first-class, not discarded. |
| Weak iOS-exclusive discovery discriminators. | Inverted "SwiftUI minus macOS" query merged with positive terms (§5). |
| Harvest is multi-hour and needs gh+Xcode+disk. | Gated, resumable, disk-bounded; pilot with `--limit`; do cheap `02/02b` first. Confirm prerequisites before the long run. |
| iPad idioms blur the `ios` classification. | Model iPad *within* `ios` via recorded idiom signals (not a separate platform), per locked decision. |
| Scanner change regresses macOS fixtures. | `platform` is additive; only NS* bridge-kind string changes; macOS fixture `.expect` updated and kept green. |

---

## 7. Resolved items (user: "do the best for us, full coverage")

1. **Harvest environment — RESOLVED.** Build A–C + E first; pilot D on a small `--limit` against a handful of known-good iOS SwiftUI repos; then run the full multi-hour harvest (resumable, can run in the background while later sub-projects' skills are authored). The build does not block on the harvest; the harvest swaps the real corpus in when it finishes. Confirm `gh` auth + iOS-17 SDK + disk at the pilot step.
2. **Seed mix — RESOLVED.** `dkhamsing/open-source-ios-apps` is **primary** (real shipping apps), `vsouza/awesome-ios` **secondary** (apps section only, since it is library-heavy), and code-search discovery (§5) broadens. Validate yield after the pilot.

## 8. Program scope note

Per the user's "full coverage transformation" directive, the program executes **all four sub-projects** (data foundation → CLI/references → audit suite → write/scaffold/commands/hook/agent/eval/manifest), not just SP1. The implementation plan sequences them; SP1's catalog contract gates the rest. The multi-hour harvest runs in the background so skill authoring (SP3/SP4) proceeds in parallel and consumes the real corpus once it lands.
