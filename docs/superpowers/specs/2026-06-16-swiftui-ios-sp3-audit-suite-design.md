# swiftui-ios — SP3: the iOS audit suite (design spec)

**Date:** 2026-06-16
**Status:** Draft — pending user review
**Author:** Claude (continuation of the approved iOS-transform program)
**Design source:** `docs/superpowers/specs/2026-06-16-swiftui-ios-data-foundation-design.md` §1 decomposition (SP3 = "Audit suite"). SP1 (data) + SP2 (CLI + references) are complete; `swiftui-ios` is at v0.2.0, HEAD `a7c1c55`.

---

## 1. Context & goal

The macOS plugin ships a **lint-engine-backed audit suite**: 28 domain `audit-swiftui-*` skills + one `audit-macos-swiftui-full` orchestrator, all driven by one shared hybrid lint runner and a set of shared truth docs in `references/_shared/`. SP1 copied these skills verbatim into `/Users/serkan/swiftui-ios/skills/` — they are **un-retargeted macOS skills** sitting in the iOS repo. SP3 replaces that copy with a real **iOS** audit suite.

**Goal:** a complete iOS audit suite — every domain skill is iOS-correct (iOS-17 floors, UIKit seam, touch idioms, iOS-only frameworks), the orchestrator is `audit-ios-swiftui-full`, the lint wiring (`audit-signals.tsv`, fixtures) and shared truth docs are retargeted to iOS, and the self-test loop is green.

**Success criteria (all must hold):**

1. `/Users/serkan/swiftui-ios/skills/` contains the **iOS roster** (below): no macOS-only skill (`appkit-interop`, `macos-nativeness`, `scenes-windows`, `menus-commands`, `state-restoration`, `appkit-overuse`, `pointer-gestures`, `navigation-toolbars`, `document-model`, `sandbox-files`, `audit-macos-swiftui-full`) remains; each is renamed/retargeted or dropped per §3.
2. `scripts/audit-signals.tsv` lists the **iOS** skill slugs with iOS presence signals; `scripts/audit-scan.py` + `scripts/audit-gate.sh` comments name the iOS orchestrator/count.
3. Every retargeted/new skill carries iOS floors (read from `references/_shared/floors-master.md`, already iOS) and routes to `ios-gating.md` (not the deleted `macos-arm-gating.md`).
4. `references/_shared/cross-ref-graph.md` describes **iOS seams** (UIKit interop, touch-gesture↔a11y, size-class↔adaptive-layout, sheet/detents↔presentation); `finding-schema.md` uses `introduced_ios`; the deferred ledger item (re-floor `hallucination-blacklist.md` cell values to iOS) is closed.
5. `bash scripts/audit-selftest.sh` is **green** against iOS fixtures (every net-new skill + every heavily-rule-changed retarget has a `tests/fixtures/<domain>.swift` + `.expect`).
6. `bash scripts/audit-gate.sh <iOS-fixture-dir>` runs all iOS skills with no crash and a sane hard/warn/adv tally; `audit-ios-swiftui-full` STEER (`audit-scan.py`) selects the right iOS subset on a sample iOS project.
7. The grep tier (`lint/grep-tells.tsv`) **stands alone** — no skill *requires* ast-grep (it is not installed on this machine); ast-grep `.yml` rules, where present, are optional structural enhancers that degrade with a notice.

**Out of scope (→ SP4):** `build-ios-swiftui`, `ios-app-patterns`, `swiftui-examples`/`swiftui-modernize` retarget, the 4 commands, the deprecation hook's `deprecated-names.txt`, the `swiftui-ios-reviewer` agent, eval tasks, README body, final manifest. `macos-swiftui-lint.sh` belongs to the *build* skill (SP4), not the audit engine — untouched here.

---

## 2. Architecture — what is reused vs. changed

My investigation confirms the engine is **platform-neutral and reusable verbatim** (locked decision: "engine copied verbatim, only seams change"):

| Artifact | Verdict |
|---|---|
| `scripts/swiftui-lint.sh` (295 lines) | **Verbatim.** Zero macOS hardcoding. Tier-1 grep + tier-2 ast-grep + parse probe + JSON/SARIF + graceful ast-grep degradation. |
| `scripts/audit-gate.sh` | **Comment-only.** Auto-discovers skills by globbing `skills/audit-swiftui-*` with a `lint/` dir — picks up the iOS roster automatically. Header says "28"/"audit-macos-swiftui-full"; retarget the prose. |
| `scripts/audit-scan.py` | **Comment-only.** Signal-driven; logic platform-neutral. Header says "28"/"audit-macos-swiftui-full"; retarget the prose. |
| `scripts/audit-selftest.sh` | **Verbatim.** Keys on `tests/fixtures/<domain>.swift`+`.expect` → `audit-swiftui-<domain>`. New iOS domains just need fixtures. |
| `scripts/audit-signals.tsv` | **Full rewrite.** Currently identical to macOS (macOS slugs + signals). The single biggest wiring change. |
| `references/_shared/lint-architecture.md` | **Verbatim** (0 macOS hits). |
| `references/_shared/finding-schema.md` | **Light** (`introduced_macos`→`introduced_ios`; domain-folder names). |
| `references/_shared/fix-safety-protocol.md` | **Light** (2 hits — wording). |
| `references/_shared/sosumi-reference.md` | **Light** (Apple-doc path examples → iOS-relevant). |
| `references/_shared/cross-ref-graph.md` | **Retarget** (116 lines, iOS seams — see §4). |
| `references/_shared/hallucination-blacklist.md` | **Re-floor** cell values to iOS (closes the SP2-deferred ledger item). |
| `references/_shared/floors-master.md`, `ios-gating.md`, `swiftui-ctx-reference.md` | Already iOS (SP2). No change. |

**Each domain skill keeps the same shape** (the `audit-swiftui-controls-forms` template): `SKILL.md` (frontmatter + AUDIT-ONLY header + seam note + judgment rules + defect index + the real-API table + the LOCATE→READ→DETECT→VERIFY→REPORT→FIX→DOUBLE-CHECK workflow + confidence gating + output contract + reference routing + detection accelerator), `lint/grep-tells.tsv` (tier-1, mandatory, self-test-validated), `lint/ast-grep/*.yml` (tier-2, optional), `references/*.md`, `scripts/<x>-lint.sh` (thin pointer to the shared runner).

---

## 3. The iOS audit roster (final)

The handoff's "~29 skills" **undercounts** — iOS adds genuinely new domains (widgets, app-intents, privacy, haptics, dynamic-type, safe-area, adaptive-layout, lifecycle, presentation, uikit-interop, ios-idiomaticness). The real roster is **34 domain skills + 1 orchestrator = 35**.

**UNIVERSAL — 10 (copy ~verbatim; swap floors macOS→iOS via the already-iOS `floors-master.md`/`ios-gating.md`, fix macOS prose):**
`state-observation`, `concurrency-safety`, `swiftdata`, `async-data`, `typography-text`, `localization`, `api-currency`, `view-performance`, `drawing-canvas`, `previews`.

**RETARGET — 13 (concept holds; rules/examples/floors change):**
`charts`, `animation-motion`, `accessibility`, `availability-gating`, `controls-forms` (Form is grouped-**by-default** on iOS — opposite of macOS; `.wheel` picker is **native**, not a fail), `layout-and-tables` (size-classes/`ViewThatFits`; `List` primary, `Table` is iPad/Mac), `appearance-color`, `liquid-glass` (iOS 26 — `glassEffect`/`GlassEffectContainer`/`.glass` button/`glassEffectID`+namespace, navigation-layer-only), `touch-gestures` (replaces `pointer-gestures` — `TapGesture`/`LongPressGesture`/`DragGesture`/`MagnifyGesture`/`RotateGesture`, `swipeActions`, `refreshable`, `contextMenu`), `navigation-toolbars`→**`adaptive-navigation`** (`NavigationStack` primary, `NavigationSplitView` iPad-only, `.topBarLeading`), `document-model`→**`app-file-handling`** (`UIDocumentPicker`/`fileImporter`), `sandbox-files`→**`document-picker-permissions`**, `appkit-overuse`→**`uikit-overuse`**.

**NET-NEW — 11 (no macOS precedent):**
`uikit-interop` (`UIViewRepresentable`/`UIViewControllerRepresentable` make/update/Coordinator/`makeCoordinator`, `UIHostingController`, `becomeFirstResponder`), `ios-idiomaticness` (TabView/NavigationStack fit, sheet modality, no `.onHover` except iPad pointer, size-class score — the iOS analogue of `macos-nativeness`, the meta scorer), `adaptive-layout` (`horizontalSizeClass`/`verticalSizeClass`, `ViewThatFits`, `containerRelativeFrame`, `NavigationSplitView`, `supportsMultipleWindows`), `safe-area-keyboard` (`safeAreaInset`, `ignoresSafeArea(.keyboard)`, `scrollDismissesKeyboard`, Dynamic Island/notch), `app-lifecycle-background` (`scenePhase`, `backgroundTask`, `BGTaskScheduler`, `@SceneStorage` — absorbs macOS `scenes-windows`+`state-restoration`), `presentation-sheets-modals` (`sheet`, `presentationDetents`, `presentationDragIndicator`, `fullScreenCover`, `popover`, `presentationBackground`), `haptics` (`sensoryFeedback` iOS 17, `UIImpactFeedbackGenerator`), `widgets-live-activities` (WidgetKit `Widget`/`TimelineProvider`/`AppIntentConfiguration`, interactive `Button(intent:)`/`Toggle(isOn:intent:)`, ActivityKit `ActivityAttributes`/`ActivityConfiguration`/`DynamicIsland`, `ControlWidget`/`ControlWidgetButton`/`ControlWidgetToggle`), `app-intents` (`AppIntent`/`AppShortcutsProvider`/`OpenIntent`/`@Parameter`/`perform`), `privacy-permissions` (`PrivacyInfo.xcprivacy`/`NSPrivacyAccessedAPITypes`, Info.plist usage strings e.g. `NSCameraUsageDescription`, `UIBackgroundModes`, `ATTrackingManager`, `onOpenURL`/universal links, `UNUserNotificationCenter.requestAuthorization`, StoreKit 2), `dynamic-type` (text styles, `dynamicTypeSize` limits, `ScaledMetric`).

**DROP — 5 (concerns folded into net-new, no standalone iOS skill):** `appkit-interop`→`uikit-interop`; `macos-nativeness`→`ios-idiomaticness`; `scenes-windows`→`app-lifecycle-background`+`adaptive-navigation`; `menus-commands`→folded into `touch-gestures` (`contextMenu`) + `app-intents`; `state-restoration`→`app-lifecycle-background`. `pointer-gestures`→`touch-gestures`, `navigation-toolbars`→`adaptive-navigation`, `document-model`→`app-file-handling`, `sandbox-files`→`document-picker-permissions` (renames, counted under RETARGET).

**Orchestrator:** `audit-ios-swiftui-full` (replaces `audit-macos-swiftui-full`). Wave order:
`0 guards` (api-currency → availability-gating → concurrency-safety) → `1 state/data/files` (state-observation → swiftdata → async-data → app-lifecycle-background → app-file-handling → document-picker-permissions) → `2 navigation` (adaptive-navigation) → `3 adaptive-layout/safe-area` (adaptive-layout → safe-area-keyboard → layout-and-tables) → `4 presentation/modality` (presentation-sheets-modals) → `5 touch` (touch-gestures) → `6 content/chrome` (controls-forms, charts, drawing-canvas, animation-motion, liquid-glass, typography-text, dynamic-type, appearance-color, accessibility, localization, haptics, previews, view-performance) → `7 boundary` (uikit-interop → uikit-overuse → ios-idiomaticness) → `8 platform-surface` (widgets-live-activities → app-intents → privacy-permissions). All 34 domain skills appear in exactly one wave. `ios-idiomaticness` re-scores last for the before/after delta.

---

## 4. Resolved open choices (SP3-specific, not in the blueprint)

1. **ast-grep policy — grep-first.** `ast-grep` is not installed and cannot be validated here. Every skill ships a **mandatory, self-test-validated `grep-tells.tsv`** that stands alone. ast-grep `.yml` rules are authored **only** for the few canonical structural-*absence* cases (e.g. "a `UIViewRepresentable` with no `updateUIView`", "a `sheet` with no `presentationDetents`"), clearly marked optional, and are **never** required by `audit-selftest.sh`. A skill with no genuine structural-absence case ships grep-only.
2. **Fixture coverage — every net-new skill + every heavily-rule-changed retarget.** A `tests/fixtures/<domain>.swift` (known violations) + `.expect` (rule_ids that must fire) for all 11 net-new skills and the retargets whose rules genuinely change (controls-forms, adaptive-navigation, touch-gestures, liquid-glass, uikit-overuse, app-file-handling, document-picker-permissions, accessibility, availability-gating, layout-and-tables). The 6 existing fixtures (api-currency, concurrency-safety, drawing-canvas, liquid-glass, navigation-toolbars→adaptive-navigation, state-observation) are retargeted, not deleted. Universal copy-verbatim skills inherit macOS-heritage tells; no new fixture unless a tell changed.
3. **Meta-scorer.** `ios-idiomaticness` is the `macos-nativeness` analogue (0–100 iOS-idiom score + `kind: nativeness-dashboard` index); it carries the meta-scoring logic, not domain rules.

---

## 5. Build plan — reviewed batches (SDD)

SP3 is large; per the handoff it ships in **reviewed batches**, each its own task(s) in the SDD plan, each implementer→reviewer→fix→ledger cycle. Proposed sequencing:

- **Batch A — Foundation + flagship (validates the whole loop):** retarget the wiring (`audit-signals.tsv`, scan/gate comments) + shared refs (`cross-ref-graph.md`, `finding-schema.md`, `fix-safety-protocol.md`, `sosumi-reference.md`, `hallucination-blacklist.md` re-floor) + the orchestrator `audit-ios-swiftui-full` + **4 flagship net-new skills** (`uikit-interop`, `adaptive-layout`, `presentation-sheets-modals`, `ios-idiomaticness`) with fixtures. Prove `audit-selftest.sh` + `audit-gate.sh` green end-to-end before fanning out.
- **Batch B — UNIVERSAL (10):** floor-swap + macOS-prose fix, mechanical; cheap-model implementers.
- **Batch C — RETARGET (13):** charts, animation-motion, accessibility, availability-gating, controls-forms, layout-and-tables, appearance-color, liquid-glass, touch-gestures, adaptive-navigation, app-file-handling, document-picker-permissions, uikit-overuse.
- **Batch D — remaining NET-NEW (7):** safe-area-keyboard, app-lifecycle-background, haptics, widgets-live-activities, app-intents, privacy-permissions, dynamic-type.
- **Batch E — whole-suite review + final gate:** run `audit-selftest.sh` + `audit-gate.sh` over the full roster, STEER smoke on a sample iOS project, final whole-branch review on opus, bump `plugin.json`.

Each batch: per-task brief → implementer subagent → `review-package` → reviewer subagent (**absolute paths; impl repo is `/Users/serkan/swiftui-ios`** — the reviewer-wrong-repo trap) → fix Critical/Important → record Minors in `.git/sdd/progress.md`.

---

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| ast-grep absent → structural rules untestable. | Grep tier mandatory + self-test-validated; ast-grep optional/degrading, never gates selftest (§4.1). |
| 34 skills → drift in shape/quality across a big fan-out. | One template (`audit-swiftui-controls-forms`), one shared finding-schema, one cross-ref-graph; Batch A proves the loop before fan-out; per-batch reviewer. |
| iOS inverts macOS rules (Form grouped-by-default; `.wheel` native; sidebar is iPad-only). | RETARGET skills are not mechanical — each re-derives its judgment core against iOS evidence (swiftui-ctx + Sosumi), reviewer checks the inversion. |
| Reviewer checks the wrong repo. | Every brief gives absolute paths + `git -C /Users/serkan/swiftui-ios`. |
| Inventing iOS APIs in examples. | Every ✅ shape grounded in `swiftui-ctx` consensus + a real permalink; floors from `floors-master.md`; cross-check `hallucination-blacklist.md`. |

---

## 7. Determinism / contract

Two audit runs over the same code must produce a structurally identical `swiftui-audits/` tree (the shared finding-schema guarantee). SP3 preserves this: same engine, same schema, same context-folder discipline — only the domains and their iOS rules differ.
