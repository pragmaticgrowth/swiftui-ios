# Shared Reference — Cross-Ref Graph & Seam-Ownership Verdicts

The single source for cross-skill seams: the directed `cross_ref` graph (which skill names
which sibling, and why) plus the seam-ownership verdicts that decide, when two skills detect the same
`file:line`, who keeps the primary finding and who is demoted to a `cross_ref`. **Both** the
orchestrator's dedup pass **and** each skill's `cross_ref` emission derive from this one file, so the
two cannot drift. Do not restate seam ownership inside a skill's own `references/`.

**As of:** 2026-06-07. Slugs below are the `audit-swiftui-<suffix>` skills (suffix shown). iOS-17
deployment floor; iPad is modeled within `ios`.

---

## 1. Seam-ownership resolution table (who is primary on a collision)

When the same site is detected by two domains, the **primary** keeps a top-level finding; the
**sibling** is demoted (`status: duplicate-of <primary rule_id>`, excluded from `_SUMMARY.md`'s master
table, kept on disk). `keep-both` = an intentional double-detection; both stay, cross-linked.

| Collision site | Primary (kept) | Sibling (demoted → cross_ref) | Rule |
|---|---|---|---|
| `Task` in `.onAppear` capturing non-Sendable state | `async-data` (lifecycle fix) | `concurrency-safety` (isolation angle) | async-data owns lifecycle; concurrency only if an isolation hazard is present. |
| `.foregroundColor(_:)` deprecated | `api-currency` (the flag) | `appearance-color` (positive craft) | currency owns the deprecation flag; appearance owns the replacement craft. |
| `Text + Text` (`+`) deprecated | `api-currency` (the flag) | `typography-text` (`AttributedString` craft) | currency flags; typography owns positive craft. |
| `Font.system(_:design:)` deprecated | `api-currency` (the flag) | `typography-text` (craft) | same three-way split. |
| `MagnificationGesture` / `RotationGesture` deprecated → `MagnifyGesture`/`RotateGesture` | `api-currency` (the flag) | `touch-gestures` (replacement mechanics) | currency flags; touch-gestures owns the mechanics. |
| `NavigationView` deprecated → `NavigationStack` | `api-currency` (the flag) | `adaptive-navigation` (structural migration) | currency flags; nav owns the structural fix. |
| glass gating (`#available(iOS 26`) | `liquid-glass` (deep glass gating) | `availability-gating` (blanket net) | liquid-glass owns glass gating in depth; gating is the catch-all. |
| any domain's missed gate | the domain skill (owns its gating in depth) | `availability-gating` (blanket net) | each domain owns its gating; availability-gating catches the misses. |
| `controlSize` sizing axis | `layout-and-tables` | `controls-forms` (only inside a `Table`/inspector) | sizing axis = layout; style variants = controls-forms. |
| `.buttonStyle`/`.pickerStyle` density | `controls-forms` | `layout-and-tables` (only inside a `Table`/inspector) | style variants = controls-forms. |
| `Table` with no size-class handling (collapses on iPhone) | `layout-and-tables` (multi-column structure) | `adaptive-layout` (size-class companion note) | structure = layout; size-class adaptation = adaptive-layout. |
| fixed `.frame(width:)` for full-screen content | `adaptive-layout` (size-class / `containerRelativeFrame`) | `layout-and-tables` (arrangement companion) | adaptive concern = adaptive-layout; raw arrangement = layout. |
| unconditional `NavigationSplitView` on compact width | `adaptive-navigation` (structural nav) | `adaptive-layout` (size-class companion note) | nav structure = adaptive-navigation; size-class gating = adaptive-layout. |
| full-height `.sheet` with no `presentationDetents` | `presentation-sheets-modals` (detent design) | `adaptive-navigation` (modality-vs-push companion) | detents = presentation; "should it push instead" = nav. |
| keyboard avoidance inside a presented `.sheet` | `safe-area-keyboard` (keyboard inset) | `presentation-sheets-modals` (detent interaction note) | keyboard = safe-area-keyboard; detent sizing = presentation. |
| SwiftData off-context `@Model` mutation | `swiftdata` (prescribes `@ModelActor`) | `concurrency-safety` (flags + routes) | concurrency flags the race; swiftdata prescribes the fix shape. |
| `loadTransferable` Sendable race | `concurrency-safety` (isolation) | `document-picker-permissions` (consent/bookmark) | sendable correctness = concurrency; file consent = document-picker-permissions. |
| `fileImporter`/`UIDocumentPickerViewController` consent | `document-picker-permissions` (security-scoped URL + bookmark) | `app-file-handling` (`FileDocument`/`DocumentGroup` companion) | consent/bookmark = picker-permissions; `FileDocument`/`DocumentGroup` shape = app-file-handling. |
| any UIKit bridge | `uikit-overuse` (WHETHER it should exist) | `uikit-interop` (HOW it's implemented) | bidirectional handshake; overuse=whether, interop=how. |
| `UIViewRepresentable` for a label/button SwiftUI already covers | `uikit-overuse` (whether to bridge at all) | `uikit-interop` (make/update/Coordinator correctness if kept) | whether = overuse; mechanics = interop. |
| save-on-background (`scenePhase` → SwiftData save) | `app-lifecycle-background` (scenePhase wiring) | `swiftdata` (save/context companion) | lifecycle trigger = app-lifecycle-background; save shape = swiftdata. |
| `onOpenURL`/`onContinueUserActivity` lifecycle | `app-lifecycle-background` (scene-event lifecycle) | `async-data` (load-on-open companion) | scene event = app-lifecycle-background; the load = async-data. |
| interactive `Button(intent:)` / `Toggle(isOn:_,intent:)` in a widget | `widgets-live-activities` (widget interactivity) | `app-intents` (intent definition companion) | placement = widgets; the `AppIntent` itself = app-intents. |
| privacy-API use surfaced inside a widget/live-activity | `widgets-live-activities` (placement) | `privacy-permissions` (manifest/usage-string) | placement = widgets; manifest correctness = privacy-permissions. |
| SwiftData preview container injection | `previews` (preview mechanics) | `swiftdata` (model design routes) | preview-construction = previews; model design = swiftdata. |
| `.drawingGroup()` perf | `drawing-canvas` (usage decision) | `view-performance` (cost measurement) | usage = drawing-canvas; cost = view-performance. |
| over-broad `@Observable` observation | `view-performance` (render cost) | `state-observation` (granularity note) | render cost = perf; state-correctness = state-observation. |
| `GeometryReader` wrapping a `Canvas` | `drawing-canvas` (feeds drawing geometry) | `layout-and-tables` (only if doing layout) | drawing geometry = drawing-canvas; layout arrangement = layout. |
| `.repeatForever` motion | `animation-motion` (UX restraint) | `view-performance` (render cost) | UX = animation; cost = perf. |
| Reduce-Motion path | `accessibility` (ignores flag entirely) | `animation-motion` (motion-specific reduced path) | "ignores flag" = a11y; "motion is wrong" = animation. |
| `@FocusState` vs `AccessibilityFocusState` | `controls-forms` (`@FocusState`, keyboard/field focus) | `accessibility` (`AccessibilityFocusState`, VoiceOver) | different wrappers; keyboard=controls, VoiceOver=a11y. |
| raw `UIImpactFeedbackGenerator` where `.sensoryFeedback` fits | `haptics` (feedback idiom) | `uikit-overuse` (whether to bridge at all) | feedback craft = haptics; "should it be SwiftUI" = uikit-overuse. |
| fixed `.system(size:)` on body text (no Dynamic Type) | `dynamic-type` (scaling) | `typography-text` (font craft companion) | scaling = dynamic-type; type craft = typography-text. |
| Dynamic-Type scaling as an a11y requirement | `dynamic-type` (text-style scaling) | `accessibility` (a11y-size companion) | scaling mechanics = dynamic-type; a11y obligation = accessibility. |
| `Chart`/`Canvas` no a11y descriptor | **keep-both** (`accessibility` + `charts`/`drawing-canvas`) | — | intentional double-detection per both plans; cross-link, don't collapse. |
| `Text(verbatim:)` / markdown rendering | `typography-text` (rendering) | `localization` (catalog angle) | type detects+renders; loc is the catalog implication. |

---

## 2. Two context-conditional tiebreakers

- **`.popover` on a compact-width target** (presentation-sheets-modals ↔ adaptive-layout): the **adaptation
  decision** ("`.popover` collapses to a sheet on iPhone — handle it") is **adaptive-layout** when the smell
  is a missing size-class branch; the **presentation API craft** (background/detent/interaction) is
  **presentation-sheets-modals**. If the site has no size-class context at all → presentation owns and
  cross_refs adaptive-layout.
- **`.contextMenu` semantics** (touch-gestures ↔ app-intents): a **long-press context menu as touch
  interaction** → **touch-gestures**; a context-menu action that should be a **Shortcuts/Siri-exposed
  `AppIntent`** → **app-intents**.

---

## 3. The cross_ref graph (one row per skill, outgoing seams)

| Skill | cross_ref targets (seam reason) |
|---|---|
| **accessibility** | controls-forms (`@FocusState`↔`AccessibilityFocusState`) · animation-motion (Reduce-Motion: motion construction theirs, "ignores flag" ours) · appearance-color (Differentiate-Without-Color / contrast) · dynamic-type (Dynamic-Type as an a11y obligation; `accessibilityShowsLargeContentViewer`) · touch-gestures (gesture targets reachable by VoiceOver / `.accessibilityAction`) · charts (chart descriptor) · drawing-canvas (Canvas a11y) · liquid-glass (Reduce Transparency) |
| **adaptive-layout** | layout-and-tables (size-class vs raw arrangement; `Table` collapse) · adaptive-navigation (`NavigationSplitView` columns gated by width) · presentation-sheets-modals (`.popover`/sheet adaptation on compact) · safe-area-keyboard (size-class affects safe-area insets) |
| **adaptive-navigation** | adaptive-layout (size-class gates `NavigationSplitView` vs `NavigationStack`) · presentation-sheets-modals (push-vs-modal decision) · controls-forms (sidebar `List` styling) · api-currency (`NavigationView` deprecation) · liquid-glass (`ToolbarSpacer`/toolbar glass era) |
| **animation-motion** | accessibility (Reduce-Motion seam) · view-performance (render cost of motion) · touch-gestures (gesture-driven animation coupling) · liquid-glass (glass morph vs generic `matchedGeometryEffect`) · drawing-canvas (`TimelineView`-as-clock theirs) |
| **api-currency** | availability-gating (floor facts; "is it gated" theirs) · appearance-color (`.foregroundColor`/`.accentColor`/`.cornerRadius` craft) · typography-text (`Text + Text`/`Font.system` craft) · adaptive-navigation (`NavigationView`/`tabItem`/inline `NavigationLink`) · state-observation (1-param `onChange`, `ObservableObject` default) · async-data (`DispatchQueue.main.async`) · touch-gestures (`MagnifyGesture`/`RotateGesture` renames) · liquid-glass (hallucinated glass names) |
| **app-file-handling** | document-picker-permissions (file IO + security-scoped bookmarks) · uikit-interop (`UIDocumentPickerViewController`/`UIDocumentInteractionController` bridge) · app-lifecycle-background (document state save on background) · api-currency (`FileDocument`/`ReferenceFileDocument` currency) |
| **app-intents** | widgets-live-activities (interactive `Button(intent:)`/`Toggle(isOn:_,intent:)` placement) · app-lifecycle-background (`OpenIntent`/deep-link surface) · privacy-permissions (intents that touch protected resources) · touch-gestures (`.contextMenu` action that should be a Shortcuts intent) |
| **app-lifecycle-background** | async-data (`scenePhase`/`onOpenURL`/`onContinueUserActivity` → load) · swiftdata (save-on-background) · app-intents (`OpenIntent`/deep-link entry) · adaptive-navigation (`NavigationPath` restoration via `@SceneStorage`) · state-observation (`@SceneStorage`/`@AppStorage` vs `@State`) |
| **appearance-color** | liquid-glass (glass materials/tint) · api-currency (`.foregroundColor`/`.accentColor` flag shared) · accessibility (Differentiate-Without-Color, WCAG ratios) · dynamic-type (color paired with scaled type) · drawing-canvas (`.cornerRadius` deprecation) |
| **async-data** | concurrency-safety (isolation of captured loading state) · state-observation (where the model lives) · swiftdata (`@Query` fetches) · app-lifecycle-background (`onOpenURL`/scenePhase-triggered loads) · controls-forms (`.redacted` on controls) |
| **availability-gating** | api-currency (floor facts) · liquid-glass (deep glass gating theirs) · state-observation, adaptive-navigation, app-lifecycle-background, widgets-live-activities, swiftdata, previews (each owns its gating in depth; this is the net) |
| **charts** | accessibility (chart descriptor) · appearance-color (per-series colors) · drawing-canvas (hand-rolled non-`Chart` drawings) · view-performance (large-dataset scrolling) |
| **concurrency-safety** | async-data (lifecycle `.task` fix) · swiftdata (`@ModelActor` fix shape) · document-picker-permissions (`Transferable` Sendable seam) · uikit-interop (Coordinator/`UIViewRepresentable` boundary) · state-observation (`@MainActor` on `@Observable`) |
| **controls-forms** | touch-gestures (tap/long-press/`swipeActions` on rows) · appearance-color (color/material crossover) · accessibility (`@FocusState`↔`AccessibilityFocusState`) · adaptive-navigation (`Form`/`List` inside navigation) |
| **document-picker-permissions** | concurrency-safety (`loadTransferable` Sendable) · app-file-handling (`fileImporter`/`DocumentGroup` shape) · privacy-permissions (Photos/Files consent + usage strings) · swiftdata (store location, app-group container) |
| **drawing-canvas** | layout-and-tables (`GeometryReader`-vs-`Layout`) · accessibility (Canvas a11y) · animation-motion (`withAnimation` timing) · charts (Canvas-drawn charts theirs) · view-performance (`.drawingGroup()` rationale) |
| **dynamic-type** | typography-text (text styles vs fixed `.system(size:)`; `@ScaledMetric`) · accessibility (Dynamic-Type as an a11y obligation) · adaptive-layout (large type forces reflow / `ViewThatFits`) · layout-and-tables (scaled rows/spacing) |
| **haptics** | uikit-overuse (raw `UIImpactFeedbackGenerator` where `.sensoryFeedback` fits) · accessibility (haptic as non-visual feedback channel) · touch-gestures (gesture-triggered feedback) |
| **ios-idiomaticness** | adaptive-navigation · adaptive-layout · presentation-sheets-modals · touch-gestures · controls-forms · layout-and-tables · uikit-overuse · haptics · dynamic-type · liquid-glass (META-scorer: each idiom smell — `TabView`/`NavigationStack` fit, sheet modality, `.onHover` misuse on iPhone, size-class coverage, `.wheel`-vs-context fit — is routed to its owner; this row carries no domain rules) |
| **layout-and-tables** | view-performance (large-`List`/`Table` ceiling) · adaptive-layout (size-class vs arrangement; `Table` collapse on iPhone) · controls-forms (control styling/density) · adaptive-navigation (`NavigationSplitView` columns theirs) · dynamic-type (scaled row heights) |
| **liquid-glass** | appearance-color (materials, Dark-Mode contrast) · availability-gating (blanket sweep; iOS 26 floor) · animation-motion (glass morph vs generic) · adaptive-navigation (navigation-layer-only glass placement) |
| **localization** | typography-text (`AttributedString` styling vs loc init) · async-data (date/number `FormatStyle`) · previews (`\.locale`/`\.layoutDirection`) · api-currency (broad deprecated sweep) · layout-and-tables (RTL mirroring) |
| **presentation-sheets-modals** | adaptive-navigation (modal-vs-push decision) · adaptive-layout (`.popover`/sheet adaptation on compact) · safe-area-keyboard (keyboard avoidance inside a sheet) · appearance-color (`presentationBackground` material) |
| **previews** | swiftdata (SwiftData model design) · state-observation (`@Observable` sample factory) · app-lifecycle-background (`@SceneStorage`/environment wiring) · api-currency (macro modernity) |
| **privacy-permissions** | document-picker-permissions (Photos/Files consent + usage strings) · app-intents (intents touching protected resources) · widgets-live-activities (widget data sources needing a manifest) · async-data (`ATTrackingManager`/`UNUserNotificationCenter` request flow) |
| **safe-area-keyboard** | presentation-sheets-modals (keyboard avoidance inside a sheet) · adaptive-layout (safe-area insets shift by size class / Dynamic Island) · layout-and-tables (`safeAreaInset`-bar vs layout) · controls-forms (`.scrollDismissesKeyboard` on a form) |
| **state-observation** | swiftdata (`@Query`) · concurrency-safety (`@Observable` isolation) · view-performance (over-broad observation) · previews (preview injection) · async-data (`onChange` lifecycle) · app-lifecycle-background (`@SceneStorage`/`@AppStorage` vs `@State`) |
| **swiftdata** | concurrency-safety (`@ModelActor`/Sendable depth) · previews (preview-construction mechanics) · document-picker-permissions (store location + app-group container) · app-lifecycle-background (save-on-background) |
| **touch-gestures** | controls-forms (tap/long-press/`swipeActions` on controls) · accessibility (gestures reachable by VoiceOver; `.accessibilityAction`) · api-currency (`MagnifyGesture`/`RotateGesture` renames) · animation-motion (gesture-driven animation) · app-intents (`.contextMenu` action → Shortcuts intent) · haptics (gesture-triggered feedback) · appearance-color (color/material crossover) |
| **typography-text** | localization (string externalization, `String(localized:)`) · api-currency (`Text + Text`/`Font.system` flag) · dynamic-type (text styles vs fixed sizes; `@ScaledMetric`) · accessibility (Dynamic-Type as a11y) · uikit-interop (rich-text `UITextView` bridge) |
| **uikit-interop** | uikit-overuse (HOW↔WHETHER; every finding cross_refs) · concurrency-safety (`@Sendable`/`@MainActor` race at the bridge) · appearance-color (`UIVisualEffectView` material decision) · app-file-handling (`UIDocumentPickerViewController` bridge) |
| **uikit-overuse** | uikit-interop (the HOW for justified bridges) · document-picker-permissions (`UIDocumentPickerViewController`/`UIImagePickerController` over-bridging) · liquid-glass (`UIVisualEffectView` vs `glassEffect`) · appearance-color (`UIVisualEffectView` vibrancy) · view-performance (`UITableView`/`UICollectionView` ceiling) · haptics (raw `UIImpactFeedbackGenerator` vs `.sensoryFeedback`) |
| **view-performance** | state-observation (over-broad observation) · layout-and-tables (`List`/`Table` structure) · animation-motion (animation cost) · liquid-glass (glass API correctness) · uikit-interop (`UITableView`/`UITextView` render cost) |
| **widgets-live-activities** | app-intents (interactive `Button(intent:)`/`Toggle(isOn:_,intent:)`; widget configuration intent) · privacy-permissions (widget data sources needing a manifest) · availability-gating (`ControlWidget` iOS 18 / `ActivityKit` floors) · appearance-color (`AccessoryWidgetBackground`/tint) |

**Total: 34 domain skills** (every `audit-swiftui-*` has a row).

> `@FocusedDocument` is **not** a real Apple symbol — use a custom `FocusedValues` key (see
> `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`).

---

## 4. Reciprocity & valid-slug notes

- A `cross_ref` MUST name one of the valid `audit-swiftui-<suffix>` slugs. There is **no**
  `audit-swiftui-version-hallucination` and **no** `audit-swiftui-state-and-data-flow` — the
  availability sweep is `audit-swiftui-availability-gating`; the state skill is
  `audit-swiftui-state-observation`. There is also **no** macOS-era slug: the nativeness meta-scorer is
  `audit-swiftui-ios-idiomaticness` (not `macos-nativeness`); the UIKit pair is
  `audit-swiftui-uikit-overuse` (WHETHER) + `audit-swiftui-uikit-interop` (HOW), never `appkit-*`; the
  nav skill is `audit-swiftui-adaptive-navigation` (not `navigation-toolbars`); gestures are
  `audit-swiftui-touch-gestures` (not `pointer-gestures`); files are
  `audit-swiftui-app-file-handling` + `audit-swiftui-document-picker-permissions` (not
  `document-model`/`sandbox-files`).
- Seams are **directional by design**: `A → B` means "A's finding may overlap B's domain," and reciprocity
  is common but not required (a downstream domain need not point back). Roughly half the seams are
  one-directional; that is expected, not a gap. When a new reciprocal seam is genuinely useful, add the
  one-line note to the owning skill's row — no structural change.
- `ios-idiomaticness` is **outgoing-only by design**: it is the meta-scorer that routes every idiom smell
  to its domain owner and contains no rules of its own, so no skill cross_refs *back* to it.

---

## Sources

Internal seam graph derived from the 34 iOS skills' own boundary/seam declarations; cites no external API.
Floor facts, the finding schema, and the Apple-doc fetch path live in sibling `_shared/` files.
