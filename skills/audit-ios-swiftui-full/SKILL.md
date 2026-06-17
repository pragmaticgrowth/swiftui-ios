---
name: audit-ios-swiftui-full
description: Orchestrates a FULL iOS SwiftUI audit by routing one finished or in-progress codebase through the toolkit's 34 domain audit skills in a dependency-sensible wave order, then consolidates every per-skill finding into one swiftui-audits/_SUMMARY.md dashboard headlined by the ios-idiomaticness 0-100 idiom score, with severity and per-skill rollups. Use when the user says "audit my iOS app", "full SwiftUI review", "is this iPhone app native", "is this iPad app idiomatic", "pre-ship iOS check", "run all the SwiftUI audits", or asks for an end-to-end pass rather than one domain. Also use to gate a release (the per-skill hard-fail tally). AUDIT-ONLY, iOS-only, SwiftUI-only. This is a META skill: it sequences and aggregates the 34 owners; it contains NO domain rules or fixes of its own. Not for a single domain (route to that audit-swiftui-* skill), not for UIKit-only apps, not for writing UI from scratch, not for HIG snapshot review.
---

# Audit iOS SwiftUI — Full (orchestrator)

**AUDIT-ONLY · iOS-only · SwiftUI-only · META.** This skill runs an *entire* iOS-SwiftUI audit: it
**scans the codebase to steer to only the relevant domain skills**, runs them as **dependency-ordered
waves of parallel subagents** (each reading its scoped files and taking findings to disk), then rolls
every finding up into a single dashboard headlined by the **ios-idiomaticness** 0-100 idiom score. It
owns **scan-steering, sequence, parallelism, aggregation, and the fix-safety ordering** — nothing else.
Every rule, floor, and fix lives in the 34 owners and the shared `references/_shared/` files; this
orchestrator **points in, never restates**. iPad is modeled within iOS (size-class branches, sidebar,
pointer) — there is no separate iPadOS sweep. iOS-17 deployment floor unless the project's target says
otherwise.

If the user wants only one domain ("audit my Liquid Glass", "check my sheets", "is my UIKit bridge
right"), do **not** run the full sweep — invoke that single `audit-swiftui-*` skill directly. Use the
routing table below to map a symptom or file-signal to the right subset.

## The evidence model (every skill, same three moves)

Each of the 34 skills, and therefore this orchestrator, runs the same governed pipeline:

1. **LOCATE** — the one shared hybrid lint runner
   (`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill <skill> --dir <sources> --json -`)
   greps tier-1 tells + (optional) ast-grep tier-2 structural rules and emits unified JSON. It **only
   locates**; a hit is never a finding. Engine + JSON shape:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
2. **VERIFY** — the agent READS each located file in full, then corroborates with **Sosumi** (the
   Apple spec: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`) and **swiftui-ctx** (the
   shipping-corpus practice: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`).
   Report a finding only at 100% certainty; iOS floors come from
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`, never from memory.
3. **FIX** — governed by `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`
   (clean-tree gate, findings-first, `fix_mode: auto` only, one commit per finding, never weaken a check).

The orchestrator's job is to run these 34 pipelines in the right order and merge their output.

## Run order (and why)

The order is **dependency-sensible**, not alphabetical. Cross-cutting guards run first so later domain
work never lands on a symbol that is about to be renamed or gated; the boundary/scoring skills run last
because they read the whole picture. Detection for a wave is parallel-safe (findings-only); **fixes are
applied serially in this same order** per the fix-safety protocol (§FIX below). All 34 domain skills
appear in **exactly one** wave.

| Wave | Skills (run in this order) | Why here |
|---|---|---|
| **0 · Guards (cross-cutting, sequential)** | `audit-swiftui-api-currency` → `audit-swiftui-availability-gating` → `audit-swiftui-concurrency-safety` | Mechanical-rename + iOS-version gating + isolation guards. They rewrite/flag symbols every other domain depends on (`NavigationView`→`NavigationStack`, `@available(iOS …)`, `@MainActor`), so they must settle first (fix-safety §5). |
| **1 · State, data & files** | `audit-swiftui-state-observation` → `audit-swiftui-swiftdata` → `audit-swiftui-async-data` → `audit-swiftui-app-lifecycle-background` → `audit-swiftui-app-file-handling` → `audit-swiftui-document-picker-permissions` | Where the model lives and how it loads/persists/restores across `scenePhase`, and how documents are imported with security-scoped consent — UI correctness depends on it. |
| **2 · Navigation** | `audit-swiftui-adaptive-navigation` | The `NavigationStack`/`NavigationSplitView` shell + `.toolbar` placement is the skeleton later layout/presentation hang off. |
| **3 · Adaptive layout & safe area** | `audit-swiftui-adaptive-layout` → `audit-swiftui-safe-area-keyboard` → `audit-swiftui-layout-and-tables` | Size-class adaptation and safe-area/keyboard insets frame the content region before content fills it (`Table` collapse, `ViewThatFits`, keyboard avoidance). |
| **4 · Presentation & modality** | `audit-swiftui-presentation-sheets-modals` | Sheets/detents/`fullScreenCover`/`popover` adapt to the navigation + safe-area frame already settled above. |
| **5 · Touch** | `audit-swiftui-touch-gestures` | Gesture/swipe/`contextMenu`/`refreshable` layer sits on top of the resolved layout + presentation surfaces. |
| **6 · Content & chrome** | `audit-swiftui-controls-forms` → `audit-swiftui-charts` → `audit-swiftui-drawing-canvas` → `audit-swiftui-animation-motion` → `audit-swiftui-liquid-glass` → `audit-swiftui-typography-text` → `audit-swiftui-dynamic-type` → `audit-swiftui-appearance-color` → `audit-swiftui-accessibility` → `audit-swiftui-localization` → `audit-swiftui-haptics` → `audit-swiftui-previews` → `audit-swiftui-view-performance` | Controls, charts, drawing, motion, glass, type, Dynamic Type, color, a11y, loc, haptics, previews, then render cost (`view-performance` reads over-rendering after state settles). Each owns its own gating in depth (guards already caught the misses). |
| **7 · Boundary & scoring** | `audit-swiftui-uikit-interop` → `audit-swiftui-uikit-overuse` → `audit-swiftui-ios-idiomaticness` | The UIKit seam (HOW the bridge is built ↔ WHETHER it should exist) and the 0-100 iOS-idiom meta-score read the full codebase + the prior findings; **`ios-idiomaticness` re-scores last** for a before/after delta. |
| **8 · Platform surfaces** | `audit-swiftui-widgets-live-activities` → `audit-swiftui-app-intents` → `audit-swiftui-privacy-permissions` | WidgetKit/ActivityKit, App Intents/Shortcuts, and the privacy-manifest/usage-string surface read the whole app + its `Info.plist`/`.xcprivacy`; they sit outside the main view tree, so they audit last. |

34 skills total. The seam-ownership that decides who keeps a finding when two waves hit the same
`file:line` is the single source `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` — the
**same** file each skill's `cross_ref` emission reads, so the dedup pass and the skills cannot drift.

> **`ios-idiomaticness` is the headline.** It is the iOS analogue of macOS-nativeness: a pure
> **meta-scorer** with NO domain rules — it produces the 0-100 idiom score + per-category breakdown,
> routes every idiom smell to the owner, and re-scores **last** so the dashboard headlines a single
> before/after number.

## Routing table (situation / file-signal → which skills)

The STEER scan (workflow step 2) auto-selects the relevant subset; this table is the manual override and the iOS signal→skill mapping behind it:

| Situation / file-signal | Run these |
|---|---|
| "feels like an iPad app blown up on iPhone" / "doesn't feel native" / rate the iOS-ness | `ios-idiomaticness` (it scores + routes to the owners) |
| glass / `glassEffect` / `GlassEffectContainer` / `buttonStyle(.glass)` / iOS 26 chrome | `liquid-glass`, then `availability-gating`, `appearance-color` |
| deprecation warnings / `NavigationView` / `.foregroundColor` / `UIScreen.main` | `api-currency` (guard), then the named owner |
| `UIViewRepresentable`/`UIViewControllerRepresentable`/`UIHostingController`/`makeCoordinator` | `uikit-interop` (how), `uikit-overuse` (whether), `concurrency-safety` |
| `UIScreen.main`/`UIApplication.shared`/`UIPasteboard`/`UIDevice` — UIKit where SwiftUI has a native answer | `uikit-overuse` (whether), `uikit-interop` (how) |
| `@Observable` / `@State` won't update / over-render | `state-observation`, `view-performance` |
| `@Model` / `@Query` / SwiftData crash | `swiftdata`, `concurrency-safety` |
| `.task`/`async`/data races / `Sendable` / `AsyncImage` | `async-data`, `concurrency-safety` |
| `scenePhase`/`backgroundTask`/`BGTaskScheduler`/`onOpenURL`/`@SceneStorage` | `app-lifecycle-background`, `async-data`, `swiftdata` |
| `NavigationStack`/`NavigationSplitView`/`.toolbar`/`.topBarLeading`/`navigationBarTitleDisplayMode` | `adaptive-navigation`, `adaptive-layout` |
| `horizontalSizeClass`/`verticalSizeClass`/`ViewThatFits`/`containerRelativeFrame` | `adaptive-layout`, `layout-and-tables`, `adaptive-navigation` |
| `Table(`/`List`/`Grid`/control density (multi-column collapse on iPhone) | `layout-and-tables`, `adaptive-layout`, `controls-forms` |
| `.sheet`/`presentationDetents`/`presentationDragIndicator`/`fullScreenCover`/`.popover` | `presentation-sheets-modals`, `adaptive-navigation`, `safe-area-keyboard` |
| `safeAreaInset`/`ignoresSafeArea(.keyboard)`/`scrollDismissesKeyboard`/notch/Dynamic Island insets | `safe-area-keyboard`, `presentation-sheets-modals` |
| `Form`/`TextField`/`Picker`/`keyboardType`/`textInputAutocapitalization`/`submitLabel`/`@FocusState` | `controls-forms`, `localization` |
| gestures / `swipeActions` / `contextMenu` / `refreshable` / `onHover` (iPad-pointer only) | `touch-gestures`, `accessibility`, `api-currency` |
| `.sensoryFeedback`/`UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator` | `haptics`, `accessibility` |
| `Chart`/`Canvas`/custom drawing | `charts`, `drawing-canvas`, `accessibility` |
| VoiceOver / Dynamic Type / `.system(size:)` fixed type / contrast | `accessibility`, `dynamic-type`, `typography-text`, `appearance-color` |
| `String(localized:)` / catalogs / RTL | `localization`, `typography-text` |
| `#Preview` / preview crashes | `previews`, `swiftdata`, `state-observation` |
| `DocumentGroup`/`FileDocument`/`fileImporter`/`fileExporter`/`UIDocumentPicker`/`UTType` | `app-file-handling`, `document-picker-permissions`, `uikit-interop` |
| security-scoped URLs / `startAccessingSecurityScopedResource` / bookmark persistence / PHPicker | `document-picker-permissions`, `privacy-permissions` |
| `WidgetKit`/`TimelineProvider`/`ActivityKit`/`DynamicIsland`/`ControlWidget`/Live Activity | `widgets-live-activities`, `app-intents`, `privacy-permissions` |
| `AppIntent`/`AppShortcutsProvider`/`OpenIntent`/`@Parameter`/Siri-Shortcuts surface | `app-intents`, `widgets-live-activities` |
| `Info.plist` usage string / `NSCameraUsageDescription` / `PrivacyInfo.xcprivacy` / `ATTrackingManager` / `UNUserNotificationCenter` / `UIBackgroundModes` / StoreKit 2 | `privacy-permissions`, `app-lifecycle-background` |

`tree`/`find` the sources first, read the **deployment target** (`IPHONEOS_DEPLOYMENT_TARGET` or
`Package.swift` `platforms:`) once — it is load-bearing for every gating rule — and pass it down. Also
note the **target idiom** (iPhone-only vs Universal/iPad): it decides whether `.onHover`/pointer and
unconditional `NavigationSplitView`/`Table` are smells (`ios-idiomaticness`, `adaptive-layout`).

## The orchestration workflow (execute verbatim)

1. **ORIENT (once).** `tree`/`find` the SwiftUI sources; record the deployment-target floor
   (`IPHONEOS_DEPLOYMENT_TARGET` / `Package.swift` `platforms:`) and the target idiom (iPhone-only vs
   Universal). Confirm the git tree state (clean vs dirty) — it decides whether fixes may run
   (fix-safety §1).
2. **STEER (scan → only the relevant skills).** Run
   `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/audit-scan.py <sources> --json swiftui-audits/_scan.json`.
   It returns `relevant_skills` — the 8 always-on cross-cutting skills (`api-currency`,
   `availability-gating`, `state-observation`, `view-performance`, `accessibility`, `typography-text`,
   `appearance-color`, `ios-idiomaticness`) plus every conditional domain whose presence signal actually
   appears in the code — and `detail[].files`, the exact files each skill must read. **Skills whose
   domain is absent are skipped, never run** (no `import WidgetKit`/`ActivityAttributes` → no
   `widgets-live-activities` subagent; no `glassEffect` → no `liquid-glass` subagent; no
   `UIViewRepresentable` → no `uikit-interop` subagent). Intersect `relevant_skills` with the wave order
   above to get each wave's skill list and **drop empty waves**. (An explicit user include/exclude
   overrides the scan.)
3. **DISPATCH (wave by wave, parallel subagents).** For each non-empty wave **in order**, spawn **one
   subagent per relevant skill in that wave, in parallel** — the filesystem is their only shared channel
   (no subagent sees another's notes except through the files on disk). Each subagent's self-contained
   brief: *invoke the `audit-swiftui-<skill>` skill; read ONLY that skill's `detail.files` from the scan;
   run LOCATE→VERIFY→REPORT; write findings to `swiftui-audits/<domain>/<context>/NN-slug.md` + the
   per-skill `swiftui-audits/<domain>/_index.md` (the `ios-idiomaticness` index carries
   `kind: nativeness-dashboard`); return a one-line `hard/warn/adv` tally.* The orchestrator never writes
   into a domain folder. **Barrier:** wait for the whole wave to land on disk before starting the next —
   later waves read earlier findings for the seam pass and `ios-idiomaticness` reads them all. Detection
   is parallel-safe (findings-only, disjoint domain folders); **fixes are serial** (step 6).
4. **DEDUP (seam pass).** For any two findings on the same `file:line`, apply
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` §1: the **primary** keeps a top-level
   finding; the **sibling** is flipped to `status: duplicate-of <primary rule_id>` (kept on disk, excluded
   from the master table). `keep-both` rows stay, cross-linked. (Key iOS seams: `uikit-overuse`
   WHETHER↔`uikit-interop` HOW; `adaptive-layout` size-class↔`layout-and-tables` arrangement;
   `presentation-sheets-modals`↔`safe-area-keyboard`; `touch-gestures`↔`accessibility`; `dynamic-type`↔
   `typography-text` — all owned by the graph, not restated here.)
5. **AGGREGATE.** Write the single top-level dashboard `swiftui-audits/_SUMMARY.md` (layout below),
   headlined by the `ios-idiomaticness` score.
6. **FIX (optional, only when asked + clean tree).** Apply fixes **serially in wave order**, guards
   first, one conventional commit per finding citing its `rule_id`, `fix_mode: auto` only, never weaken a
   check — `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`. Re-run `ios-idiomaticness`
   last for the before/after score delta.
7. **DOUBLE-CHECK.** Re-run the LOCATE lint on each fixed file to confirm the tell no longer matches;
   record it in each finding's `## Fix applied?`. Recompute the rollups so `_SUMMARY.md` reflects the
   committed state.

## The consolidated dashboard — `swiftui-audits/_SUMMARY.md`

This is the toolkit's **one top-level index/dashboard** (the shared finding-schema names it `_SUMMARY.md`;
treat it as the project-root audit index). The orchestrator is its sole author. It contains the headline
score, three rollups, and a master table:

- **iOS-idiomaticness score (headline)** — the `ios-idiomaticness` 0-100 idiom score + its per-category
  breakdown, surfaced at the very top as the single metric a reader scans for. After a FIX pass, show the
  before/after delta.
- **Rollup by severity** — total `hard-fail` / `warning` / `advisory` across all skills (the pre-ship
  signal: any `hard-fail` blocks).
- **Rollup by skill** — one row per skill run: `domain · hard · warn · adv · score?(ios-idiomaticness
  only) · link to its _index.md`. Domains the STEER scan marked absent are listed as `n/a — not present`
  so coverage is explicit (audited-and-clean vs not-applicable are never conflated).
- **Master finding table** — every non-duplicate finding (`rule_id · severity · domain · file:line · api
  · status`), sorted severity-desc then domain. `status: duplicate-of …` rows are omitted (they remain on
  disk for the audit trail).

Two runs over the same code produce a structurally identical `swiftui-audits/` tree and an equivalent
`_SUMMARY.md` — determinism is a hard requirement.

## Pre-ship gate (CI)

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/audit-gate.sh <target-dir>` loops the shared lint runner over the
audit skills, tallies hard/warn/adv per skill + total, prints a summary to stderr and a combined JSON to
stdout, and **exits 2 if any audited skill reports a hard finding** (else 0). It is **STEER-gated** by the
same `audit-scan.py` relevance scan this orchestrator uses: domains whose presence signal is absent are
marked `n/a — not present` (not run, not counted), so a project that doesn't use a domain never hard-fails
CI on that domain's broad LOCATE nets (e.g. a SwiftData-free repo won't block on `swiftdata` sd-01/sd-09).
Pass `--all` (or `--no-steer`) to force every skill regardless of presence. A non-zero exit means a
human-driven full audit (this skill) is required before shipping; it does not replace the VERIFY/READ step.

## Boundaries (stay in lane)

- This skill **never contains domain rules or fixes** — if you find yourself describing how to fix a
  `glassEffect`, a missing `updateUIView`, or a detent-less `.sheet`, stop and invoke the owner skill.
- It does not touch `references/_shared/` or any sibling skill's `references/`/`lint/` — it consumes them.
- UIKit-only apps, HIG snapshot review, and from-scratch UI are out of scope (route to `build-ios-swiftui`
  / the HIG review skill respectively).

## Reference routing (all shared — point in, never restate)

| Shared file | Open when |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | step DEDUP — seam ownership (who keeps a colliding finding) + the iOS `cross_ref` graph |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the byte-identical finding format (`introduced_ios`) + the `_SUMMARY.md` contract every skill inherits |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | step FIX — the 8-point protocol + the guards-first cross-skill order |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md` | step LOCATE — the shared runner's engine, JSON/SARIF shape, ast-grep degradation rails |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | any floor/availability value (the reconciled iOS truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | any iOS-version gating question (`@available(iOS NN,*)` / `#available` miss) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | any invented-name question (a confabulated API like `.glassBackground`, `@FocusedDocument`) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | step VERIFY — the Apple-doc spec fetch protocol |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | step VERIFY — the shipping-corpus practice CLI (consensus shape + permalinked example; `--platform ios`) |

The 34 domain owners are invoked as skills (by the slugs in the run-order table), not read as files.

## Sources

Internal orchestration over the toolkit's 34 iOS audit skills; the run order derives from the cross-skill
fix-safety ordering and the iOS seam graph in `references/_shared/`. Cites no external API directly —
every floor, signature, and spec is owned by a domain skill or a `_shared/` file referenced above via
`${CLAUDE_PLUGIN_ROOT}`.
