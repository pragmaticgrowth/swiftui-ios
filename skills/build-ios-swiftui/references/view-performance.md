# View Rendering Performance (iOS)

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain.** SwiftUI re-renders are driven by
view *identity* and dependency tracking; the anti-patterns below force needless `body` re-evaluation or
view recreation. They bite on iOS where scrolling lists, gesture-driven transitions, and older devices
make wasted `body` work visible as dropped frames. Every example compiles on an iOS target.

## The rendering anti-patterns

### 1. Building a `DateFormatter` (or other heavyweight) inside `body`
`body` runs on every dependency change — allocating a formatter each time is wasteful.
```swift
// ❌ WRONG — new DateFormatter every render
var body: some View {
    Text(DateFormatter().string(from: date))
}
// ✅ CORRECT — hoist it (static let), or use Text(date, format:)
private static let df: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; return f }()
var body: some View { Text(Self.df.string(from: date)) }      // or: Text(date, format: .dateTime.month().day())
```

### 2. `.id(UUID())` — forces full recreation every render
A fresh id every evaluation throws away the view's identity and state.
```swift
// ❌ WRONG — new identity each render → recreated, state lost, no diffing
RowView(item: item).id(UUID())
// ✅ CORRECT — stable identity tied to the data
RowView(item: item).id(item.id)
```

### 3. `AnyView` — erases the type SwiftUI needs to diff
Type-erasure defeats structural diffing; the subtree can't be compared across renders.
```swift
// ❌ WRONG
func cell() -> AnyView { AnyView(Text("hi")) }
// ✅ CORRECT — @ViewBuilder keeps the concrete type
@ViewBuilder func cell() -> some View { Text("hi") }
```

### 4. Passing closures as child view props
A closure stored in a child can't be value-compared, so the child can't be skipped on re-render.
Prefer letting the child read shared `@Observable`/`@Environment` state. The canonical fix when the
child must keep the closure is to make the child `Equatable` (or wrap it in `EquatableView`) so SwiftUI
compares the *other* props and skips re-render — keeping the closure stable alone is not enough.

### 5. `GeometryReader` overuse
`GeometryReader` greedily takes all offered space and re-lays-out its subtree on every size change
(every rotation, split-view resize on iPad, or keyboard-driven safe-area change). Reach for layout (`Layout`, `.frame`, `.alignmentGuide`,
container relative frames) first; use `GeometryReader` only when you truly need the measured size.

### 6. Real logic in `View.init`
A view's `init` runs every time its parent re-evaluates `body` — heavy work there runs constantly.
Keep `init` trivial; move work into `.task`, `@Observable` model methods, or cached/`static` state.

### 7. Filtering/sorting *inside* `ForEach`
```swift
// ❌ WRONG — filter+sort recomputed every render, inside the view tree
ForEach(items.filter { $0.isActive }.sorted { $0.name < $1.name }) { … }
// ✅ CORRECT — compute upstream (model / @Query(sort:) / a cached derived array)
ForEach(activeSortedItems) { … }        // model exposes the derived collection
```

### 8. Storing high-frequency-updating values in `@Environment`
`@Environment` fans out widely: every view that reads a given key is re-checked when that value
changes. Putting a fast-changing value there — a timer tick, a drag/scroll geometry, anything updating
many times a second — re-evaluates the whole subtree of subscribers on every tick (WWDC25 session 306
warns against exactly this). Keep such values in a narrowly-scoped `@State`/`@Observable` read only by
the views that need them; reserve `@Environment` for slow-changing, broadly-shared configuration.

## SwiftUI `List` / `Table` performance ceiling (iOS)
On iOS, **`List` is the primary collection**. Practitioner testing on **iOS 26** shows a plain `List`
of ~10,000 items now scrolls smoothly (≈50k still usable), so the old "a few hundred rows" ceiling no
longer holds for plain `List` there. The cost reappears with **heavy per-row content** — many subviews,
inline images decoded in `body`, `AnyView` cells. For a `List`/`ForEach`, give rows a stable `id` and
keep cell bodies cheap. `Table` (iPad / regular width) has known large-dataset issues (FB13639482, filed
Feb 2024 against iOS 17.3); no Apple-published fix milestone is confirmed — measure on your target.

Rule of thumb on iOS 26: a plain `List` handles many thousands of simple rows fine. For a very large or
interaction-dense grid where SwiftUI `List`/`Table` janks, bridge `UICollectionView` (a compositional /
list layout) via `UIViewRepresentable` — but only after a measurement shows the SwiftUI path is the
bottleneck (→ `uikit-interop.md`).
```swift
// ❌ WRONG — heavy custom cells decoding images in body → janky scrolling
List(items) { item in HeavyCell(item: item) }   // image decode + many subviews per row
// ✅ CORRECT — cheap rows, stable ids, async-decoded thumbnails
List(items) { item in Row(item: item) }          // small body; thumbnails via AsyncImage / a cache
// for 10k+ interaction-dense grids only, after measuring:
struct DataGrid: UIViewRepresentable { /* wrap UICollectionView, reload in updateUIView */ }
```

## Liquid Glass performance on older devices
Liquid Glass is GPU-shader-bound; overlapping glass layers compound cost on **older iPhones/iPads**.
Prefer ONE `GlassEffectContainer` over many sibling `glassEffect()` calls, and avoid glass on
high-frequency-updating content (a scrolling list, an animating chart). Profile on your lowest-spec
supported device and gate selectively only if a measurement shows a problem — the `#available(iOS 26, *)`
fallback to `.regularMaterial` is the right lever, not a device-model `#if`.
```swift
// ✅ CORRECT — one container groups sibling glass; the GPU composites them together
GlassEffectContainer {
    badge.glassEffect(.regular.interactive(), in: .capsule)
    label.glassEffect(.regular, in: .capsule)
}
// ✅ CORRECT — fall back below the floor (and on measured slow paths) to a cheaper material
if #available(iOS 26.0, *) { content.glassEffect() } else { content.background(.regularMaterial) }
```

## Detection tells
- `DateFormatter(` / `NumberFormatter(` / `JSONDecoder(` literal inside a `body` or computed-view prop.
- `.id(UUID())` / `.id(UUID().uuidString)`.
- `AnyView(` in view code.
- `GeometryReader` wrapping a whole screen/large subtree.
- `.filter`/`.sorted`/`.map` directly inside a `ForEach(...)` argument.
- Non-trivial statements inside a `View`'s `init`.
- A fast-changing value (timer/geometry) pushed through an `@Environment` key read by many views.

## Profiling tools
- **`Self._printChanges()`** — drop it as the first line of `body`; it prints which dependency caused
  that `body` to re-evaluate (`@self`, a specific property, or `@identity`). Zero setup, no Instruments;
  the fastest way to find *why* a view re-renders. Remove before shipping.
- **SwiftUI Instrument (Instruments 26)** — the new SwiftUI track plus its **Cause & Effect graph**
  attributes update cost to the state change that triggered it; the canonical iOS-26 tool for finding
  expensive `body` work and excessive updates. See WWDC25 session 306.

## Sources
- WWDC21 "Demystify SwiftUI" (session 10022) — identity, lifetime, dependencies (the diffing model):
  https://developer.apple.com/videos/play/wwdc2021/10022/
- WWDC23 "Demystify SwiftUI performance" (session 10160) — update cost, expensive `body` work:
  https://developer.apple.com/videos/play/wwdc2023/10160/
- WWDC25 "Optimize SwiftUI performance with Instruments" (session 306) — the new SwiftUI Instrument in
  Instruments 26 and its Cause & Effect graph; also the `@Environment` high-frequency fan-out warning:
  https://developer.apple.com/videos/play/wwdc2025/306/
- Apple — `Text(_:format:)` and `Layout`: https://developer.apple.com/documentation/swiftui/text · https://developer.apple.com/documentation/swiftui/layout
- SwiftUI `Table` large-dataset bug: FB13639482 (filed Feb 2024, iOS 17.3). No fix milestone is
  confirmed in Apple release notes — **measure the row threshold against your own build.**
- Community practitioner reports (r/SwiftUI, iOS SwiftUI performance write-ups) for the iOS 26
  plain-`List` headroom (~10k smooth, ~50k usable) and the `List`/`Table`-vs-`UICollectionView` ceiling — treat the
  numbers as guidance and profile your build.
