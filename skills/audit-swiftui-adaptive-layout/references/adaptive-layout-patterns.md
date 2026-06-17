# Reference — Adaptive Layout Patterns (adl-01 … adl-07)

The defects that ship an iPhone-portrait layout onto the full iOS device matrix: a **hard-coded width**, a
**`UIScreen.main` layout oracle**, an **unconditional split**, a **layout that never branches on size
class**, and **manual width math** where a native adaptive primitive exists. All are *flag-only* (the fix is
a judgment call: is this full-screen content? should the split collapse? which axis to branch on?). Floors
live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** (`lookup --platform ios`) backed by a real iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK. iPad is modeled within `ios`.

---

## adl-01 — full-screen content pinned to a literal `.frame(width:)` (warning, flag-only)

A literal width that matches one iPhone (e.g. `393` = iPhone 15 points) freezes the layout to that device.
On iPad it letter-boxes inside a wide window; in landscape it clips; under Split View / Slide Over it
overflows the reduced scene. Full-screen content sizes to its **container**, not a number.

```swift
// ❌ WRONG — device-frozen; native only on the one iPhone whose width is 393
VStack {
    Text("Welcome")
    HeroContent()
}
.frame(width: 393)                       // letter-boxes on iPad, clips in landscape
```
```swift
// ✅ CORRECT — let full-screen content fill its container; constrain with maxWidth if you need a reading measure
VStack {
    Text("Welcome")
    HeroContent()
}
.frame(maxWidth: .infinity)              // fills the container on every device
// or, for a comfortable reading width that still adapts:
.frame(maxWidth: 700)
```

> **Judge before flagging.** A fixed width on a **genuinely fixed element** (a 44pt icon chip, a 1pt divider,
> a fixed-size badge) is correct. adl-01 LOCATES every literal `.frame(width: <number>)`; you decide whether
> it wraps full-screen / flexible content (defect) or a fixed atom (fine).

## adl-02 — `UIScreen.main.bounds` as a layout oracle (hard-fail, flag-only)

`UIScreen.main` is **deprecated on iOS 16+**: it has no scene context, so under Split View / Slide Over /
Stage Manager it returns the wrong rect. It is a UIKit symbol, not a SwiftUI layout API — `swiftui-ctx
lookup UIScreen` returns a "looks like a UIKit/AppKit type" note, confirming the layout answer lives in
SwiftUI, not `UIScreen`.

```swift
// ❌ WRONG — deprecated, scene-less, wrong under multitasking
Color.blue
    .frame(width: UIScreen.main.bounds.width)
```
```swift
// ✅ CORRECT — read the actual container with GeometryReader (scene-correct), or branch on size class
GeometryReader { proxy in
    Color.blue
        .frame(width: proxy.size.width)   // the real container width, multitasking-aware
}
```

**Replace, never gate.** `UIScreen.main` is a deprecation, not a low floor — wrapping it in
`#available(iOS …)` is wrong; remove it. This is a **keep-both** seam with `audit-swiftui-uikit-overuse`
(*whether the `UIScreen` bridge should exist at all*): file the layout-sizing finding here,
`cross_ref: uikit-overuse`.

## adl-03 — `NavigationSplitView` with no size-class branch (warning, flag-only)

`NavigationSplitView` (iOS 16.0; `swiftui-ctx lookup NavigationSplitView --platform ios` → consensus `{ }`
58% / `(columnVisibility:)` 42%) presents a multi-column split at **regular** width and auto-collapses to a
stack at **compact** width. Shipping it with no `horizontalSizeClass` awareness means you accept that
collapse blind — often with the wrong column visibility or a detail that can't be reached on iPhone.

```swift
// ❌ WRONG — regular-width split shipped onto compact iPhone with no thought to the collapse
NavigationSplitView {
    SidebarList()
} detail: {
    DetailView()
}
```
```swift
// ✅ CORRECT — drive column visibility from the size class, or branch to a NavigationStack on compact
@Environment(\.horizontalSizeClass) private var hSize
@State private var columnVisibility: NavigationSplitViewVisibility = .automatic

var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
        SidebarList()
    } detail: {
        DetailView()
    }
    .onChange(of: hSize) { _, new in
        columnVisibility = (new == .compact) ? .detailOnly : .automatic
    }
}
```

**Grounded in the corpus.** `swiftui-ctx lookup NavigationSplitView --platform ios` recommends a real iOS
shape in `mainframecomputer/fullmoon-ios`:
`https://github.com/mainframecomputer/fullmoon-ios/blob/cbc3c8206921afaa7fc4fe3dcdf790a18843226f/fullmoon/ContentView.swift#L25`.
The split-view's **column content, titles, and toolbar placement** belong to
`audit-swiftui-adaptive-navigation` — file the *adaptation* finding here, `cross_ref: adaptive-navigation`.

## adl-04 — layout never branches on size class (advisory, flag-only)

A Universal layout with device-dependent arrangement and **zero** `@Environment(\.horizontalSizeClass)` /
`verticalSizeClass` reads never reacts to iPad-regular, landscape, or multitasking. The size-class
environment (`UserInterfaceSizeClass`, `.compact`/`.regular`, iOS 13.0) is the **only** correct device test
— never a model name or a width literal.

```swift
// ❌ WRONG — reads the class but the layout is identical regardless (or never reads it at all)
@Environment(\.horizontalSizeClass) private var hSize
var body: some View {
    HStack { Sidebar(); Content() }      // hSize captured, never used to branch
}
```
```swift
// ✅ CORRECT — branch the arrangement on the size class
@Environment(\.horizontalSizeClass) private var hSize
var body: some View {
    if hSize == .regular {
        HStack { Sidebar(); Content() }  // side-by-side on iPad / regular width
    } else {
        VStack { Sidebar(); Content() }  // stacked on compact iPhone
    }
}
```

## adl-05 — manual width ladder where `ViewThatFits` is the idiom (advisory, flag-only)

A `if geo.size.width > N { LayoutA } else { LayoutB }` ladder choosing between fixed layouts is exactly what
`ViewThatFits` (iOS 16.0) expresses — it picks the first child that fits, no thresholds to maintain.
`swiftui-ctx lookup ViewThatFits --platform ios` → consensus `(in)` 53% / `{ }` 48%.

```swift
// ❌ WRONG — hand-tuned threshold; brittle, re-measures, ignores Dynamic Type growth
GeometryReader { geo in
    if geo.size.width > 600 {
        HStack { Sidebar(); Content() }
    } else {
        VStack { Sidebar(); Content() }
    }
}
```
```swift
// ✅ CORRECT — ViewThatFits picks the first arrangement that fits the container
ViewThatFits {
    HStack { Sidebar(); Content() }      // tried first; used if it fits
    VStack { Sidebar(); Content() }      // fallback when the row is too wide
}
```

**Grounded in the corpus.** `swiftui-ctx lookup ViewThatFits --platform ios` recommends a real iOS use in
`Dimillian/IceCubesApp`:
`https://github.com/Dimillian/IceCubesApp/blob/9c05a720597b3ff13de2e241bf58d3fba0863c09/Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowMediaPreviewView.swift#L209`
(`co_occurs_with`: `accessibilityActions`, `accessibilityFocused` — `cross_ref: accessibility` when the two
arrangements differ for VoiceOver).

## adl-06 — fractional-of-screen width by arithmetic (advisory, flag-only)

A `width * 0.5` / `width / 2` computes a fraction of a measured width by hand. `containerRelativeFrame(_:)`
(iOS 17.0; `swiftui-ctx lookup containerRelativeFrame --platform ios` → consensus `(_)` 64%, also
`(_, count:span:spacing:alignment:)`) expresses a fraction of the **container** declaratively and adapts
when the container changes.

```swift
// ❌ WRONG — manual fraction of a measured width
GeometryReader { proxy in
    Card().frame(width: proxy.size.width / 2)
}
```
```swift
// ✅ CORRECT — a half-container width, declarative and container-aware (iOS 17.0)
Card()
    .containerRelativeFrame(.horizontal) { width, _ in width / 2 }
// or an evenly-spanned grid of cards:
Card()
    .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
```

`containerRelativeFrame` is iOS 17.0 — at the iOS-17 project floor it needs no gate. Below the floor, route
the gate via `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. Its recommended iOS example:
`https://github.com/Dimillian/IceCubesApp/blob/9c05a720597b3ff13de2e241bf58d3fba0863c09/Packages/MediaUI/Sources/MediaUI/MediaUIView.swift#L20`.

## adl-07 — `GeometryReader` only to make a width-threshold decision (warning, flag-only)

`GeometryReader` is for **real per-pixel geometry** (drawing, custom positioning). Wrapping it solely to
read `proxy.size.width` and pick compact-vs-regular is a misuse: it forces a greedy layout pass, defeats lazy
sizing, and re-runs on every change. The compact-vs-regular decision is `horizontalSizeClass`.

```swift
// ❌ WRONG — GeometryReader as a size-class proxy (greedy, re-measures)
GeometryReader { proxy in
    if proxy.size.width > 700 { WideLayout() } else { NarrowLayout() }
}
```
```swift
// ✅ CORRECT — the size class is the decision; no geometry pass needed
@Environment(\.horizontalSizeClass) private var hSize
var body: some View {
    if hSize == .regular { WideLayout() } else { NarrowLayout() }
}
```

If the threshold is a true content measure (not a device-class proxy), keep `GeometryReader` but prefer
`ViewThatFits` (adl-05) when the branches are mutually-exclusive fixed layouts.

---

## Sources

- Floors / availability: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (iOS truth).
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. All
  consensus shapes + permalinks above from `swiftui-ctx lookup <api> --platform ios --json` (run 2026-06-16).
- Apple paths fetched via `https://sosumi.ai/...` — see `references/source-directory.md` for the map and
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol.
