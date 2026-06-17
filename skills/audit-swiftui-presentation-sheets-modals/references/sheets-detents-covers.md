# Reference — Sheets, Detents, Covers & Popovers (psm-01 … psm-05)

The five iOS presentation defects that make a modal read as a stale, pre-iOS-16 take-over: a **detent-less
`.sheet`** locked full-height, a **detented sheet with no grab handle**, a **`.fullScreenCover` used for a
trivial dialog**, a **`.popover` with no compact adaptation** that collapses to a full-screen cover on
iPhone, and a **mis-applied presentation background / interaction**. All five are under-used by the
iOS-trained corpus because pre-iOS-16 SwiftUI had exactly one sheet shape. These are *flag-only* defects (the
correct fix is a modality/detent judgment). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** backed by a real iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK · Swift 6.2.

---

## psm-01 — content-rich `.sheet` with no `.presentationDetents` (warning, flag-only)

Since iOS 16, a `.sheet` can resize to user-chosen detents so the content behind stays visible and the sheet
can be a partial card. A content-rich `.sheet` (a list, a form, a detail card) that carries **no
`presentationDetents`** is locked at the pre-iOS-16 full height — a heavy modal that covers everything.

```swift
// ❌ WRONG — locked full-height; the pre-iOS-16 modal, reads as stale on iOS 16+
.sheet(isPresented: $showDetail) {
    TaskDetailView(task: task)      // a scrollable detail card — no detents
}
```
```swift
// ✅ CORRECT — resizable medium/large detent so the user can peek the content behind
.sheet(isPresented: $showDetail) {
    TaskDetailView(task: task)
        .presentationDetents([.medium, .large])   // iOS 16.0+
        .presentationDragIndicator(.visible)      // iOS 16.0+ — grab handle (psm-02)
}
```

**Grounded in the corpus.** `swiftui-ctx lookup presentationDetents --platform ios --json` (run 2026-06-16)
returns `introduced_ios: 16.0`, `deprecated: false`, consensus shape `(_)` **96%** — every real use passes a
detent set. Its `recommended` iOS example is `.presentationDetents([.large])` in `3lvis/SwiftSync`:
`https://github.com/3lvis/SwiftSync/blob/375a0d6eeca24cd18619a071b95586d8750e1e85/Demo/Demo/Features/TaskForm/TaskFormSheet.swift#L74`
(2,543 stars, `min_ios: 17`). The `sheet-detents` recipe describes "a bottom sheet with height detents
(.medium, .large, or custom fraction/height)." `co_occurs_with`: `presentationBackgroundInteraction`,
`presentationContentInteraction`, `presentationSizing`. In FIX, put the `.presentationDetents([...])` chain in
`## Correct` and that permalink (+ the Sosumi `doc:`) in `## Source`.

> **Judge before flagging.** A `.sheet` is *not* always content-rich — a small one-button confirmation or a
> `ShareLink`-style action sheet may intentionally stay full-height. psm-01 LOCATES every `.sheet`; you decide
> whether its body is content that wants a partial/resizable detent.

## psm-02 — detented sheet with no `.presentationDragIndicator(.visible)` (advisory, flag-only)

A resizable/dismissible bottom sheet wants the grab-handle affordance. A `.sheet` that carries
`.presentationDetents` but no `.presentationDragIndicator(.visible)` hides the cue that the sheet can be
dragged/resized.

```swift
// ❌ WRONG — detented but no visible grab handle; the resize affordance is hidden
.presentationDetents([.medium, .large])
// ✅ CORRECT — the grab handle signals "drag to resize / swipe to dismiss"
.presentationDetents([.medium, .large])
.presentationDragIndicator(.visible)        // iOS 16.0+
```

`swiftui-ctx lookup presentationDragIndicator --platform ios --json` returns `introduced_ios: 16.0`,
consensus shape `(_)` **100%**. Recommended example
`.presentationDragIndicator(.hidden)` in `mainframecomputer/fullmoon-ios`:
`https://github.com/mainframecomputer/fullmoon-ios/blob/cbc3c8206921afaa7fc4fe3dcdf790a18843226f/fullmoon/ContentView.swift#L66`
— note `.hidden` is a deliberate choice; the defect is *no* indicator on a sheet the user is meant to resize.

## psm-03 — `.fullScreenCover` for a trivial dismissible dialog (warning, flag-only)

`.fullScreenCover` blocks swipe-to-dismiss and covers the entire screen — correct for immersive / no-dismiss
flows (onboarding, camera capture, an interruptive sign-in). Wrapping a small confirmation, picker, or
settings dialog in it is the wrong modality; a `.sheet` (dismissible by swipe-down, resizable with detents) is
the iOS idiom.

```swift
// ❌ WRONG — a one-button confirmation forced into a full-screen, non-dismissible cover
.fullScreenCover(isPresented: $showConfirm) {
    ConfirmDeleteView()             // trivial dialog; user can't swipe to dismiss
}
```
```swift
// ✅ CORRECT — a dismissible sheet with a small detent is the idiom for a dialog
.sheet(isPresented: $showConfirm) {
    ConfirmDeleteView()
        .presentationDetents([.height(220)])   // iOS 16.0+ custom detent
}
```

`swiftui-ctx recipe fullscreen-cover-flow --json` describes the *legitimate* use: "Full-screen modal cover
(no drag-to-dismiss; typical for onboarding or immersive flows)" with the real exemplar
`https://github.com/FluidGroup/Brightroom/blob/442b873eeddc6c930e5bc209facb62a6548169c7/Dev/Sources/SwiftUIDemo/RenderingDemoView.swift#L271`.
`swiftui-ctx lookup fullScreenCover --platform ios` returns `introduced_ios: 14.0`. The flag is for a cover
whose content is *not* immersive — judge the wrapped view.

## psm-04 — `.popover` with no `.presentationCompactAdaptation` (warning, flag-only)

On iPhone (compact horizontal size class) a `.popover` with no adaptation silently becomes an opaque
full-screen cover — almost never the intent, and it hides the anchor context the popover idiom provides.

```swift
// ❌ WRONG — on iPhone this collapses to a full-screen cover, not a popover
.popover(isPresented: $showInfo) {
    InfoCard()                      // no compact adaptation
}
```
```swift
// ✅ CORRECT — keep the popover presentation on compact width (or pick .sheet deliberately)
.popover(isPresented: $showInfo) {
    InfoCard()
        .presentationCompactAdaptation(.popover)   // iOS 16.4+
}
```

`swiftui-ctx lookup presentationCompactAdaptation --platform ios` returns `introduced_ios: 16.4`;
`swiftui-ctx lookup popover --platform ios` returns `introduced_ios: 13.0`. Choose `.popover` to keep the
popover, `.sheet` to adapt to a sheet, or `.none` per the design — this is a judgment, hence flag-only.

## psm-05 — mis-applied `presentationBackground` / `presentationContentInteraction` (advisory, flag-only)

`presentationBackground(.clear)` (iOS 16.4) makes the sheet's own background transparent — only correct when
there is a visible material/blur layer behind it; otherwise the sheet reads as broken. And
`presentationContentInteraction(.scrolls)` (iOS 16.4) governs whether a drag scrolls the content or resizes
the sheet — a no-op on a sheet with no `presentationDetents`.

```swift
// ❌ WRONG — clear background with nothing behind it; sheet content floats on the app
.presentationBackground(.clear)
// ❌ WRONG — content-interaction on a non-detented sheet is a no-op
.sheet(isPresented: $show) { Body() }
    .presentationContentInteraction(.scrolls)   // no detents → nothing to resize
```
```swift
// ✅ CORRECT — clear background over a deliberate material; interaction with detents
.presentationBackground(.thinMaterial)          // iOS 16.4+
.presentationDetents([.medium, .large])
.presentationContentInteraction(.scrolls)       // iOS 16.4+ — now meaningful
```

`swiftui-ctx lookup presentationBackground --platform ios` returns `introduced_ios: 16.4`, consensus `(_)`
**98%**; `swiftui-ctx lookup presentationContentInteraction --platform ios` returns `introduced_ios: 16.4`,
consensus `(_)` **100%**.

---

## The canonical detented-sheet exemplar

```swift
.sheet(isPresented: $isPresented) {
    SheetContentView()
        .presentationDetents([.medium, .large])      // iOS 16.0+
        .presentationDragIndicator(.visible)         // iOS 16.0+
        .presentationBackground(.regularMaterial)    // iOS 16.4+ (optional)
}
```

This is the `sheet-detents` recipe shape, exemplar
`https://github.com/3lvis/SwiftSync/blob/375a0d6eeca24cd18619a071b95586d8750e1e85/Demo/Demo/Features/TaskForm/TaskFormSheet.swift#L74`.
At the iOS-17 deployment floor every modifier above is available unconditionally — no `#available` gate per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.

## Seams (cross_ref, don't double-own)

- A `TextField` inside a presented sheet covered by the keyboard → `audit-swiftui-safe-area-keyboard`
  (`.scrollDismissesKeyboard`, `ignoresSafeArea(.keyboard)`). cross_ref it from psm-01.
- "This flow should be a `NavigationStack` push, not a modal at all" → `audit-swiftui-adaptive-navigation`.
  cross_ref it from psm-03.
- The presented content branching on `horizontalSizeClass` for its own arrangement →
  `audit-swiftui-adaptive-layout`. cross_ref it from psm-04. (The popover *adaptation* is mine.)

## Sources

- Practice corpus: `swiftui-ctx lookup <api> --platform ios --json`, `swiftui-ctx recipe sheet-detents`,
  `swiftui-ctx recipe fullscreen-cover-flow` (run 2026-06-16). Contract:
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- Floors: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (the reconciled truth).
- Apple docs fetched via `https://sosumi.ai/...` per `references/source-directory.md` (access 2026-06-16).
- GitHub permalinks above are the swiftui-ctx `recommended`/recipe exemplars (pinned commit SHAs).
