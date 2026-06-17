# swiftui-ios — SP3: iOS audit suite (implementation plan)

> **For agentic workers / workflow agents:** this plan is the per-skill brief source. Each skill-authoring
> agent reads its row here + the spec + the macOS reference skill it adapts + the canonical template
> (`/Users/serkan/claude-swiftui-plugin/skills/audit-swiftui-controls-forms/`). REQUIRED SUB-SKILL: subagent-driven-development.

**Design source:** `docs/superpowers/specs/2026-06-16-swiftui-ios-sp3-audit-suite-design.md`.
**Impl repo:** `/Users/serkan/swiftui-ios` (separate git repo). macOS repo `/Users/serkan/claude-swiftui-plugin` = read-only reference. Both: macOS reference skills under `skills/audit-swiftui-*`; iOS work under `/Users/serkan/swiftui-ios/skills/`.

## Global constraints (every agent obeys)
- **iOS-only · SwiftUI-only · AUDIT-ONLY.** iOS-17 deployment floor; iPad modeled within `ios`.
- Floors are read from `references/_shared/floors-master.md` (already iOS, 3361 symbols/22 floors) — **never asserted from memory**. Gating routes to `references/_shared/ios-gating.md` (NOT the deleted `macos-arm-gating.md`).
- Ground every ✅ shape + floor in **swiftui-ctx**: `B=/Users/serkan/swiftui-ios/swiftui-scan/.build/release/swiftui-ctx; export SWIFTUI_CTX_CATALOG=/Users/serkan/swiftui-ios/catalog`. `introduced_ios` surfaces at `result.introduced_ios` (NOT under `result.availability`). Use `--platform ios`. A `lookup` exit 3 corroborates a hallucination / no-iOS-arm symbol.
- **grep tier stands alone** (`lint/grep-tells.tsv`, mandatory, self-test-validated). ast-grep `.yml` optional, never required by selftest (ast-grep NOT installed). Thin `scripts/<x>-lint.sh` pointer = adapt `audit-swiftui-controls-forms/scripts/cf-lint.sh`, just swap the `--skill` slug.
- Skill shape = the `audit-swiftui-controls-forms` template exactly: SKILL.md (frontmatter rich-trigger `description` + AUDIT-ONLY header + seam note + judgment rules + defect index table + real-API table + LOCATE→READ→DETECT→VERIFY→REPORT→FIX→DOUBLE-CHECK workflow + confidence gating + output contract + context-folder starter table + reference routing + detection accelerator). Finding schema is byte-identical (`references/_shared/finding-schema.md`); body sections become `## Why it's wrong on iOS`.
- **Agents do NOT git commit** — they only write files into disjoint paths (own skill dir + own `tests/fixtures/<domain>.{swift,expect}`). The orchestrator commits each batch.
- **Reviewer-wrong-repo trap:** reviews use absolute paths + `git -C /Users/serkan/swiftui-ios`.

---

## Phase 0 — Scaffolding (orchestrator, deterministic, one commit)
In `/Users/serkan/swiftui-ios`:
- `git rm -r` dropped macOS-only skills: `audit-swiftui-appkit-interop`, `audit-swiftui-macos-nativeness`, `audit-swiftui-scenes-windows`, `audit-swiftui-menus-commands`, `audit-swiftui-state-restoration`, `audit-macos-swiftui-full`.
- `git mv` renames (keep macOS files as editing base): `navigation-toolbars`→`adaptive-navigation`, `pointer-gestures`→`touch-gestures`, `document-model`→`app-file-handling`, `sandbox-files`→`document-picker-permissions`, `appkit-overuse`→`uikit-overuse`. Also `git mv tests/fixtures/navigation-toolbars.{swift,expect} adaptive-navigation.{swift,expect}`.
- `mkdir` net-new skill dirs (+ `lint/`, `references/`, `scripts/`): `uikit-interop`, `ios-idiomaticness`, `adaptive-layout`, `safe-area-keyboard`, `app-lifecycle-background`, `presentation-sheets-modals`, `haptics`, `widgets-live-activities`, `app-intents`, `privacy-permissions`, `dynamic-type`, and orchestrator `audit-ios-swiftui-full`.
- Write the complete iOS `scripts/audit-signals.tsv` (all 34 slugs + iOS signals; `always` = the 8 cross-cutting: api-currency, availability-gating, state-observation, view-performance, accessibility, typography-text, appearance-color, ios-idiomaticness; rest `cond`).
- Retarget `scripts/audit-scan.py` + `scripts/audit-gate.sh` comments ("28"→"34", "audit-macos-swiftui-full"→"audit-ios-swiftui-full").

---

## Phase A — Foundation + flagship (Batch A)
**Shared refs (1 agent each, disjoint files):**
- `cross-ref-graph.md` — full iOS retarget: 34-skill seam table + ownership verdicts. Key iOS seams: uikit-overuse(WHETHER)↔uikit-interop(HOW); touch-gestures↔accessibility(VoiceOver) & ↔api-currency(gesture renames); adaptive-layout↔layout-and-tables(size-class vs arrangement) & ↔adaptive-navigation(NavigationSplitView columns); presentation-sheets-modals↔adaptive-navigation & ↔safe-area-keyboard(keyboard avoidance in sheets); app-lifecycle-background↔async-data(scenePhase/onOpenURL) & ↔swiftdata(save-on-background); widgets-live-activities↔app-intents(interactive Button(intent:)) & ↔privacy-permissions; ios-idiomaticness routes all idiom smells to owners (the meta-scorer); dynamic-type↔typography-text & ↔accessibility; app-file-handling↔document-picker-permissions(consent).
- `finding-schema.md` — `availability:` floor → iOS floor / "iOS ABSENT" / "n/a"; "All 28"→"All 34"; `macos-nativeness`→`ios-idiomaticness` (`kind: nativeness-dashboard`→keep, it's the iOS idiom dashboard); body `## Why it's wrong on macOS`→`## Why it's wrong on iOS`; additive-field table: drop `appkit-overuse`'s `justified`→`uikit-overuse`; keep the rest.
- `fix-safety-protocol.md` + `sosumi-reference.md` — light: macOS wording→iOS; Sosumi example paths → iOS-relevant (UIKit/SwiftUI iOS docs).
- `hallucination-blacklist.md` — re-floor cell values from "(macOS NN+)" to iOS floors; add iOS-invented-name guards (don't fabricate — only well-known non-existent symbols).
**Orchestrator (1 agent):** `audit-ios-swiftui-full/SKILL.md` — adapt `audit-macos-swiftui-full/SKILL.md`: 34 skills, the §3 wave order, STEER via `audit-scan.py`, dashboard `_SUMMARY.md`, `ios-idiomaticness` headline score, gate via `audit-gate.sh`.
**Flagship skills (1 agent each, full skill + fixture):** `uikit-interop`, `adaptive-layout`, `presentation-sheets-modals`, `ios-idiomaticness` (specs in the roster below).
**Gate before fan-out:** `bash scripts/audit-selftest.sh` green for the 4 flagship fixtures; `bash scripts/audit-gate.sh tests/fixtures` runs clean.

---

## Roster (per-skill briefs). Mode: C=copy+floor-swap · R=retarget · N=net-new. Source = macOS dir to adapt (rel to macOS `skills/`).

### Batch B — UNIVERSAL (10, mode C: copy macOS sibling verbatim, swap macOS floors→iOS, fix macOS prose/examples, keep rule-id prefixes & existing fixtures)
| Skill | Source | iOS notes |
|---|---|---|
| state-observation | audit-swiftui-state-observation | `@Observable`/`@State`/`@Bindable` identical; floors iOS 17. Keep fixture; verify floors. |
| concurrency-safety | audit-swiftui-concurrency-safety | `@MainActor`/`Sendable`/actor identical; iOS floors. Keep fixture. |
| swiftdata | audit-swiftui-swiftdata | `@Model`/`@Query`/`ModelActor` iOS 17. |
| async-data | audit-swiftui-async-data | `.task`/`AsyncImage`/`refreshable` identical; iOS floors. |
| typography-text | audit-swiftui-typography-text | identical; drop macOS-only type notes; iOS floors. Cross-ref dynamic-type. |
| localization | audit-swiftui-localization | identical; iOS floors. |
| api-currency | audit-swiftui-api-currency | deprecations are cross-platform; `NavigationView`→`NavigationStack` (cross-ref adaptive-navigation, not navigation-toolbars). Keep fixture (retarget cross_ref names). |
| view-performance | audit-swiftui-view-performance | identical; drop NSTableView ceiling note; iOS floors. |
| drawing-canvas | audit-swiftui-drawing-canvas | identical; iOS floors. Keep fixture. |
| previews | audit-swiftui-previews | `#Preview`/`@Previewable` identical; iOS floors. |

### Batch C — RETARGET (13, mode R: concept holds, rules/examples/floors change; re-derive judgment core vs iOS evidence)
| Skill | Source | iOS judgment core (the inversions matter) |
|---|---|---|
| charts | audit-swiftui-charts | Charts iOS 16+; `Chart`/marks identical; iOS floors; cross-ref accessibility. |
| animation-motion | audit-swiftui-animation-motion | identical APIs; iOS floors; cross-ref accessibility(Reduce-Motion), touch-gestures. |
| accessibility | audit-swiftui-accessibility | VoiceOver/Dynamic-Type identical; **add** `accessibilityShowsLargeContentViewer`; cross-ref dynamic-type, touch-gestures. |
| availability-gating | audit-swiftui-availability-gating | `@available(iOS NN,*)`/`#available`; route to `ios-gating.md`; blanket-net for all domains. Fixture. |
| controls-forms | audit-swiftui-controls-forms | **INVERSIONS:** `Form` is grouped **by default** on iOS (no `.formStyle(.grouped)` fail); `.pickerStyle(.wheel)`/`WheelPickerStyle` is **NATIVE on iOS** (NOT a hard-fail); `.help` tooltips are macOS — drop cf-03 or repurpose. iOS control concerns: `.textFieldStyle(.roundedBorder)`, `.keyboardType`, `.textInputAutocapitalization`, `.submitLabel`, `.pickerStyle(.segmented/.menu/.navigationLink/.wheel)`, `controlSize` exists iOS 17. New fixture. |
| layout-and-tables | audit-swiftui-layout-and-tables | `List` is primary; `Table` is iPad/Mac (multi-column collapses on iPhone — flag a `Table` with no size-class handling); `ViewThatFits`; `Grid`; size-classes. cross-ref adaptive-layout. New fixture. |
| appearance-color | audit-swiftui-appearance-color | `Color`/material/`.tint` identical; iOS system colors (`Color(.systemBackground)`); dark-mode; cross-ref liquid-glass, dynamic-type. |
| liquid-glass | audit-swiftui-liquid-glass | **iOS 26**: `glassEffect`, `GlassEffectContainer`, `.regular/.clear/.interactive`, `buttonStyle(.glass)`, `glassEffectID`+namespace, navigation-layer-only. Floors iOS 26. Keep/retarget fixture. |
| touch-gestures | audit-swiftui-pointer-gestures | **REPLACES pointer-gestures.** `TapGesture`/`LongPressGesture`/`DragGesture`/`MagnifyGesture`/`RotateGesture`, `swipeActions`, `refreshable`, `contextMenu`. `.onHover`/`pointerStyle` = iPad-pointer-only (flag on iPhone-only target / cross-ref ios-idiomaticness). cross-ref accessibility, api-currency(gesture renames). New fixture. |
| adaptive-navigation | audit-swiftui-navigation-toolbars (renamed) | **NavigationStack primary**; `NavigationSplitView` is iPad/regular-width (flag unconditional split on compact); `.toolbar` `.topBarLeading`/`.topBarTrailing`/`.bottomBar`/`.navigationBarTrailing` are **CORRECT on iOS** (macOS flagged them — invert); `navigationBarTitleDisplayMode`; `NavigationView` deprecated→`NavigationStack`. **Retarget fixture** (`.topBarLeading` no longer a violation). |
| app-file-handling | audit-swiftui-document-model (renamed) | iOS `DocumentGroup`/`FileDocument` + `fileImporter`/`fileExporter` + `UIDocumentPickerViewController` bridge; UTType; iOS floors. cross-ref document-picker-permissions, uikit-interop. New fixture. |
| document-picker-permissions | audit-swiftui-sandbox-files (renamed) | iOS file access: security-scoped URLs from the document picker, `startAccessingSecurityScopedResource`/`stopAccessing…`, bookmark persistence; Photos/Files consent; **NOT** macOS sandbox entitlements/NSOpenPanel. cross-ref privacy-permissions. New fixture. |
| uikit-overuse | audit-swiftui-appkit-overuse (renamed) | **WHETHER a UIKit bridge should exist** when SwiftUI has a native answer: `UIViewRepresentable` for a label/button (use SwiftUI), `UIScreen.main` (use `GeometryReader`/size-class — deprecated in iOS 16+), `UIApplication.shared.windows`, `UIPasteboard`(use `.copyable`/`PasteButton`), `UIScreen.main.bounds`. cross-ref uikit-interop(HOW). New fixture. |

### Batch D — remaining NET-NEW (7, mode N: author fresh on the template; ground every API in swiftui-ctx + floors-master)
| Skill | Prefix | Domain core + key tells |
|---|---|---|
| safe-area-keyboard | sak | `safeAreaInset(edge:)`, `ignoresSafeArea(.keyboard)`, `.scrollDismissesKeyboard`, keyboard-avoidance, Dynamic Island / notch insets. Tell: content hard-coded to screen edges ignoring safe area; missing keyboard dismissal on scroll. New fixture. |
| app-lifecycle-background | alb | `@Environment(\.scenePhase)`, `.backgroundTask(.appRefresh)`, `BGTaskScheduler`, `@SceneStorage` restoration, `onOpenURL`/`onContinueUserActivity`. Absorbs macOS scenes-windows + state-restoration. Tell: no scenePhase handling for save; BGTaskScheduler without registration. New fixture. |
| haptics | hap | `.sensoryFeedback(_:trigger:)` (iOS 17), `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator` (prefer `sensoryFeedback`). Tell: raw `UIImpactFeedbackGenerator` where `sensoryFeedback` fits; haptic without `prepare()`. New fixture. |
| widgets-live-activities | wla | WidgetKit `Widget`/`TimelineProvider`/`AppIntentConfiguration`/`StaticConfiguration`; interactive `Button(intent:)`/`Toggle(isOn:_,intent:)` (iOS 17); ActivityKit `ActivityAttributes`/`ActivityConfiguration`/`DynamicIsland`; `ControlWidget`/`ControlWidgetButton`/`ControlWidgetToggle` (iOS 18). Tell: timeline with no reload policy; Live Activity with no DynamicIsland; deprecated `IntentConfiguration`. New fixture. |
| app-intents | ain | `AppIntent`/`AppShortcutsProvider`/`OpenIntent`/`@Parameter`/`perform()`; `AppShortcut` phrases. Tell: AppIntent without `title`; AppShortcutsProvider with no phrases; Siri/Shortcuts surface gaps. New fixture. |
| privacy-permissions | pp | `PrivacyManifest`/`PrivacyInfo.xcprivacy`/`NSPrivacyAccessedAPITypes`; Info.plist usage strings (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, etc.); `UIBackgroundModes`; `ATTrackingManager.requestTrackingAuthorization`; `UNUserNotificationCenter.requestAuthorization`; StoreKit 2. **Scans .plist/.xcprivacy too**, not just .swift. Tell: privacy-API use with no manifest/usage-string. New fixture. |
| dynamic-type | dt | `.font(.body)` text styles vs fixed `.system(size:)`; `dynamicTypeSize(...)` limits; `@ScaledMetric`; `.minimumScaleFactor`; accessibility sizes. Tell: fixed point sizes on body text; no `@ScaledMetric` for spacing tied to type. cross-ref typography-text, accessibility. New fixture. |

### Flagship (in Batch A; full briefs)
| Skill | Prefix | Domain core |
|---|---|---|
| uikit-interop | uik | `UIViewRepresentable`/`UIViewControllerRepresentable`: `makeUIView`/`updateUIView`/`makeCoordinator`/`Coordinator`; missing `updateUIView` body; `UIHostingController` (SwiftUI-in-UIKit); `becomeFirstResponder`; Coordinator retain cycles; `@Binding` not propagated in `updateUIView`. cross-ref uikit-overuse(WHETHER), concurrency-safety(@Sendable at bridge). Fixture: representable with no `updateUIView`, Coordinator missing. |
| adaptive-layout | adl | `horizontalSizeClass`/`verticalSizeClass`, `ViewThatFits`, `containerRelativeFrame`, `NavigationSplitView` (iPad), `supportsMultipleWindows`. Tell: fixed `.frame(width:)` for full-screen content; iPhone-only layout on a Universal target; no size-class branch. cross-ref adaptive-navigation, layout-and-tables. Fixture. |
| presentation-sheets-modals | psm | `.sheet`, `presentationDetents`, `presentationDragIndicator`, `.fullScreenCover`, `.popover` (iPad-adaptive), `presentationBackground`, `presentationContentInteraction`. Tell: full-height `.sheet` with no detents; `.popover` on compact with no adaptation; `fullScreenCover` where a sheet fits. cross-ref adaptive-navigation, safe-area-keyboard. Fixture. |
| ios-idiomaticness | idi | **META-scorer** (analogue of macos-nativeness): 0–100 iOS-idiom score + per-category breakdown + `kind: nativeness-dashboard` index; routes smells to owners (TabView/NavigationStack fit, sheet modality, `.onHover` misuse, size-class coverage). Contains NO domain rules — routes. Fixture optional (scorer). |

---

## Batches B–E execution
- **B/C/D:** workflow pipelines one agent per skill (disjoint dir + fixture) → review stage → fix stage. Cheap model for C-mode (mechanical), opus/sonnet for R/N (judgment). Orchestrator runs `audit-selftest.sh` after each batch, fixes failures, commits the batch, updates `.git/sdd/progress.md`.
- **E (final):** whole-suite review (parallel reviewers); `bash scripts/audit-selftest.sh` + `bash scripts/audit-gate.sh tests/fixtures` green; STEER smoke (`audit-scan.py`) on a sample iOS project; final whole-branch review on opus; bump `.claude-plugin/plugin.json` (→ 0.3.0); commit.

## Self-Review
- Coverage: all 34 skills + orchestrator + 5 shared-ref retargets + signals + scan/gate comments + fixtures accounted for; every skill maps to exactly one batch and one wave.
- Disjoint-write invariant: each agent owns one skill dir or one shared file + one fixture; audit-signals.tsv written once in Phase 0; no two agents write the same path.
- Inversions captured: Form grouped-by-default, `.wheel` native, `.topBarLeading` correct, `List`-primary, `Table`-is-iPad — all flagged in the C-rows so reviewers check them.
