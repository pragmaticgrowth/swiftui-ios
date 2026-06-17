Here's a self-contained handoff prompt. Copy everything in the block below into a fresh session.

````text
ultracode

# Continue the swiftui-ios plugin transformation — Sub-projects 3 & 4

You are picking up a multi-session project: porting the macOS "grounded SwiftUI" Claude-Code plugin into a sibling **iOS** plugin, using the same methodology. Sub-projects 1 (data foundation) and 2 (CLI + references) are DONE. Your job is **SP3 (the iOS audit suite)** then **SP4 (write/scaffold skills, commands, hook, agent, eval, README/manifest body)**.

## FIRST: load context (do this before anything else)
Read these, in order — they hold the full design, the exact decisions, and the per-task history:
1. `/Users/serkan/claude-swiftui-plugin/docs/superpowers/specs/2026-06-16-swiftui-ios-data-foundation-design.md` — program decomposition, locked decisions, the transformation blueprint.
2. `/Users/serkan/claude-swiftui-plugin/docs/superpowers/plans/2026-06-16-swiftui-ios-data-foundation.md` and `…/2026-06-16-swiftui-ios-sp2-cli-references.md` — how SP1/SP2 were built.
3. `cat "$(git -C /Users/serkan/claude-swiftui-plugin rev-parse --git-path sdd)/progress.md"` — the durable progress ledger (every task's commit + deferred Minor findings). The planning docs live on branch `swiftui-ios-transform` in the macOS repo.
4. The project memory `swiftui-ios-transform` (auto-loaded) for the one-paragraph status.

## The two repos
- `/Users/serkan/claude-swiftui-plugin` — the **macOS** reference plugin. DO NOT modify it. It is your reference for the engine, the lint architecture, and the original (macOS) audit skills you are retargeting. Planning docs + SDD ledger live here on branch `swiftui-ios-transform`.
- `/Users/serkan/swiftui-ios` — the **iOS plugin** you are building (a separate git repo). Currently v0.2.0, HEAD `9952877`. ALL implementation goes here.

## Locked decisions (do not relitigate)
Separate `swiftui-ios` plugin (not a flag); iOS-17 deployment floor; iPad modeled WITHIN `ios` via recorded idiom signals; engine copied verbatim, only seams change.

## What's already done
- **SP1:** scanner emits per-file `platform` (`uikit`/`appkit`/`cross`/`neutral`) + `uikit_bridge`/`appkit_bridge` decl kinds; pipeline retargeted to iOS; full harvest built a **319-app iOS SwiftUI catalog** at `/Users/serkan/swiftui-ios/catalog` (platforms ios:229/cross:85/macos:5). SwiftUI-presence floor enforced at stage 5.
- **SP2:** `swiftui-ctx` is iOS-correct — defaults to `--platform ios`, filters to ios/cross_platform, surfaces iOS floors, routes to `uiview-bridge`. References: `floors-master.md` is now a generated iOS floor table (3361 symbols/22 floors), `ios-gating.md` replaces `macos-arm-gating.md`.

## Catalog/CLI facts you need
- CLI: `B=/Users/serkan/swiftui-ios/swiftui-scan/.build/release/swiftui-ctx`; `export SWIFTUI_CTX_CATALOG=/Users/serkan/swiftui-ios/catalog`. Commands: `lookup <api>`, `examples <api>`, `recipe <name>`, `recipes`, `bridges`, `deprecated [<api>]`, `conformances <proto>`, `rankings <dim>`, `insights <section>`, `stats`, `doctor`, all with `--json`/`--platform ios|macos|cross|any`.
- Catalog keys (iOS): `provenance.platform`, `provenance.min_ios`, `availability.introduced_ios` (lookup surfaces it at `result.introduced_ios`, NOT under `result.availability`), `by_repo[].min_ios_inferred`, `by_repo[].ipad_idioms`, `bridges[].platform ∈ {uikit,appkit}`.
- `sdk_catalog.json` has `introduced_ios` floors for 3361 symbols incl. WidgetKit/ActivityKit/AppIntents.

## Lint engine (how every audit skill works — study one before authoring)
Reference skill with a complete lint/: `/Users/serkan/claude-swiftui-plugin/skills/audit-swiftui-controls-forms/` (has `lint/grep-tells.tsv`, `lint/ast-grep/*.yml`, `references/`, `SKILL.md`). Engine runner: `scripts/swiftui-lint.sh`; `scripts/audit-scan.py`; gate `scripts/audit-gate.sh`; self-test `scripts/audit-selftest.sh` with fixtures. Two tiers: ripgrep `grep-tells.tsv` (works everywhere) + ast-grep structural `.yml` (optional). Shared truth docs in `references/_shared/`: `finding-schema.md`, `fix-safety-protocol.md`, `lint-architecture.md`, `hallucination-blacklist.md`, `floors-master.md` (iOS), `ios-gating.md`, `cross-ref-graph.md` (still macOS — retarget in SP3), `sosumi-reference.md`, `swiftui-ctx-reference.md`. Each skill follows LOCATE→VERIFY→REPORT→FIX (the lint *locates* candidates; the skill *judges* against swiftui-ctx evidence + sosumi docs). **`ast-grep` is NOT installed on this machine** — your iOS rules must not REQUIRE it; the grep tier must stand alone.

IMPORTANT: the macOS audit skills were copied into `/Users/serkan/swiftui-ios/skills/` by the SP1 scaffold and are NOT yet retargeted. SP3 replaces/retargets them. Treat them as starting material, not finished iOS skills.

## SP3 scope — the iOS audit suite (~29 skills + orchestrator)
Per the blueprint's remapping:
- **UNIVERSAL (10, copy ~verbatim; only swap floors to iOS via `floors-master.md`/`ios-gating.md`):** state-observation, concurrency-safety, swiftdata, async-data, typography-text, localization, api-currency, view-performance, drawing-canvas, previews.
- **RETARGET (11, concept holds, rules/examples/floors change):** charts, animation-motion, accessibility, availability-gating, controls-forms (Form is grouped-by-DEFAULT on iOS — opposite of macOS; wheel picker is native, not a fail), layout-and-tables (size-classes/ViewThatFits, List primary), appearance-color, navigation-toolbars→**adaptive-navigation** (NavigationStack primary, NavigationSplitView iPad-only, `.topBarLeading` correct), document-model→**app-file-handling** (UIDocumentPicker), sandbox-files→**document-picker-permissions**, appkit-overuse→**uikit-overuse**.
- **NET-NEW (8, no macOS precedent):** `audit-swiftui-uikit-interop` (UIViewRepresentable/UIViewControllerRepresentable makeUIView/updateUIView/Coordinator/makeCoordinator, UIHostingController, becomeFirstResponder), `audit-swiftui-ios-idiomaticness` (TabView/NavigationStack fit, sheet modality, no `.onHover` except iPad pointer, size-class score), `audit-swiftui-adaptive-layout` (horizontalSizeClass/verticalSizeClass, ViewThatFits, containerRelativeFrame, NavigationSplitView, supportsMultipleWindows), `audit-swiftui-safe-area-keyboard` (safeAreaInset, ignoresSafeArea(.keyboard), scrollDismissesKeyboard, Dynamic Island/notch), `audit-swiftui-app-lifecycle-background` (scenePhase, backgroundTask, BGTaskScheduler, @SceneStorage), `audit-swiftui-presentation-sheets-modals` (sheet, presentationDetents, presentationDragIndicator, fullScreenCover, popover, presentationBackground), `audit-swiftui-haptics` (sensoryFeedback iOS 17, UIImpactFeedbackGenerator), `audit-swiftui-widgets-live-activities` (WidgetKit Widget/TimelineProvider/AppIntentConfiguration, interactive Button(intent:)/Toggle(isOn:intent:), ActivityKit ActivityAttributes/ActivityConfiguration/DynamicIsland, ControlWidget/ControlWidgetButton/ControlWidgetToggle) and `audit-swiftui-app-intents` (AppIntent/AppShortcutsProvider/OpenIntent/@Parameter/perform) and `audit-swiftui-privacy-permissions` (PrivacyInfo.xcprivacy/NSPrivacyAccessedAPITypes, Info.plist usage strings like NSCameraUsageDescription, UIBackgroundModes, ATTrackingManager, onOpenURL/universal links, UNUserNotificationCenter requestAuthorization, StoreKit 2) and `audit-swiftui-dynamic-type` (text styles, dynamicTypeSize limits, ScaledMetric). Also retarget `liquid-glass` for iOS 26 (glassEffect, GlassEffectContainer, .regular/.clear/.interactive, buttonStyle(.glass), glassEffectID + namespace, navigation-layer-only), and `touch-gestures` (TapGesture/LongPressGesture/DragGesture/MagnifyGesture/RotateGesture, swipeActions, refreshable, contextMenu) replacing pointer-gestures.
- **DROP (macOS-only):** appkit-interop (→uikit-interop), macos-nativeness (→ios-idiomaticness), scenes-windows (→app-lifecycle-background + adaptive-navigation), menus-commands (→context-menus), state-restoration (→app-lifecycle-background).
- **Orchestrator:** `audit-ios-swiftui-full` (replaces `audit-macos-swiftui-full`); wave order: guards → state/data → navigation → adaptive-layout/safe-area → presentation/modality → touch-gestures → boundary (uikit-interop/uikit-overuse/ios-idiomaticness) → platform-surface (widgets/app-intents/privacy). Also retarget `cross-ref-graph.md` to iOS seams and the deferred ledger item (re-floor `hallucination-blacklist.md` cell values to iOS).
Validate every skill with the `audit-selftest.sh` mechanism (iOS fixtures with known violations + `.expect`).

## SP4 scope
`build-ios-swiftui` + `ios-app-patterns` skills (tab app, NavigationStack master-detail, sheet/detents flow, uiview-bridge, widget, onboarding); the 4 commands (`/swiftui` `/swiftui-review` `/swiftui-audit` `/swiftui-settings` — model-first, no allowed-tools, no $ARGUMENTS); deprecation hook's iOS `deprecated-names.txt` (regenerate via the catalog); reviewer agent `swiftui-ios-reviewer`; iOS eval tasks (`eval/tasks.jsonl` + seeds); finish the README body (skills table → iOS skills, pipeline → awesome-ios, caveats → iOS-first) + final manifest. Bump `plugin.json` on every user-facing change.

## Methodology — follow the same rigor used in SP1/SP2
1. Each sub-project: `superpowers:brainstorming` (you may skip re-deciding settled points — the blueprint settles them — but write a lean spec) → `superpowers:writing-plans` → `superpowers:subagent-driven-development`.
2. Per task: generate a brief with `bash "<superpowers>/skills/subagent-driven-development/scripts/task-brief" <PLAN> <N>`, dispatch a fresh implementer subagent (cheap model for transcription/mechanical, opus for the orchestrator + cross-cutting/risky), then `bash "…/scripts/review-package" BASE HEAD` and dispatch a task reviewer. Fix Critical/Important, re-review. Record Minors in the ledger. End with a final whole-branch review on opus.
3. **Reviewer gotcha (cost me a false-positive last time):** the subagent cwd defaults to the macOS repo `/Users/serkan/claude-swiftui-plugin`. When reviewing iOS work, give ABSOLUTE paths and explicitly tell the reviewer the impl repo is `/Users/serkan/swiftui-ios` (e.g. tell it to `git -C /Users/serkan/swiftui-ios …`), or it will check the wrong repo and report nonsense.
4. Track progress in the SDD ledger as you go; it's your recovery map across compaction.
5. SP3 is large (~29 skills) — pace it by domain (orchestrator + a couple net-new high-value skills first: uikit-interop, adaptive-layout, presentation-sheets, ios-idiomaticness), validate the lint/self-test loop on those, then fan out the rest. Don't promise all 29 in one shot; ship in reviewed batches.

Start by reading the context artifacts above, confirm the SP1/SP2 state with `$B doctor`, then brainstorm/spec SP3 and begin. Build in `/Users/serkan/swiftui-ios` only.
````

A few notes on using it:
- The leading `ultracode` opts the new session into multi-agent orchestration (the workflow/subagent fan-out). Drop that word if you'd rather it work single-threaded.
- It's deliberately self-contained but also points at the committed spec/plans + the `.git/sdd/progress.md` ledger + the project memory, so the fresh session can verify everything rather than trust the prompt.
- The biggest landmines from this session are baked in: the reviewer-wrong-repo trap, `ast-grep` not being installed, and `introduced_ios` living at `result.introduced_ios`.