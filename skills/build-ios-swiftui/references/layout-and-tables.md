# Layout, Adaptive Sizing & Tables (iOS)

> **iOS-only.** On iOS the canvas is **not** one fixed size — an iPhone rotates, an iPad splits and
> resizes in Stage Manager/Split View, and the keyboard and Dynamic Type reshape the content region.
> The layout job is to **adapt** (size classes, `ViewThatFits`, container-relative frames, safe-area /
> keyboard insets), not to hard-code points. `List` is the **primary** iOS collection; `Table`
> (multi-column, sortable) is an **iPad / regular-width** tool that collapses to a single column on
> compact-width iPhone, so reach for it only there. macOS appears only as a ❌ contrast.

The training corpus is full of one-shot iPhone-portrait views, so AI (a) **hard-codes absolute
`CGFloat` widths** instead of adapting to the proposed size, (b) reaches for `GeometryReader` to measure
when a layout container would do, (c) ignores the `horizontalSizeClass` branch that an iPad needs, and
(d) drops a multi-field `HStack` into a `List` row where the data wants real columns. The result
compiles and looks right in iPhone-portrait preview — then breaks in landscape, on iPad, or with large
Dynamic Type.

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain.** Cross-checked against `references/api-currency.md`.
Every code block compiles on an iOS target; macOS-only APIs appear *only* as ❌ contrast.

---

## The five mistakes

### 1. Hard-coded absolute sizes instead of adapting to the proposed size

A fixed `.frame(width: 350)` looks right on the device it was written for and wrong everywhere else —
clipped on a small iPhone, marooned on an iPad. Size **relative to the container** with
`containerRelativeFrame(_:)` (iOS 17.0+), or let the layout flex with `maxWidth: .infinity` + padding.

```swift
// ❌ WRONG — absolute width; clips on small phones, looks lost on iPad
CardView().frame(width: 350)
```
```swift
// ✅ CORRECT — size relative to the container, or flex to available width
CardView().containerRelativeFrame(.horizontal) { width, _ in width * 0.9 }   // iOS 17+
CardView().frame(maxWidth: .infinity).padding(.horizontal)                   // simplest flex
```

### 2. Single-column `List` where structured rows want a `Table` (iPad / regular width)

On iPad (regular width) structured, multi-field rows belong in a `Table` — real columns, headers,
**multi-column sorting via headers**, selection for free. A hand-rolled `HStack`-in-`List` has none of
that. Drive sorting with a `sortOrder:` binding to `[KeyPathComparator]`; columns built with `value:`
become sortable automatically. On compact-width iPhone a `Table` renders as a single column, so keep a
`List` path for compact and switch on `horizontalSizeClass`.

```swift
// ❌ WRONG — HStack-in-List fakes columns; no headers, no sort
List(people) { person in
    HStack { Text(person.name); Spacer(); Text("\(person.age)") }
}
```
```swift
// ✅ CORRECT — Table + TableColumn + sortOrder on iPad/regular; List on compact iPhone
@Environment(\.horizontalSizeClass) private var hSize
@State private var people: [Person] = Person.sample
@State private var sortOrder = [KeyPathComparator(\Person.name)]

var body: some View {
    if hSize == .regular {                              // iPad / regular width
        Table(people, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name)          // value: => sortable header
            TableColumn("Age", value: \.age) { Text("\($0.age)") }
        }
        .onChange(of: sortOrder) { _, newOrder in people.sort(using: newOrder) }
    } else {                                            // compact iPhone
        List(people) { person in PersonRow(person: person) }
    }
}
```

### 3. No size-class branch → an iPad app that's an enlarged iPhone

iOS has **two horizontal size classes** (`.compact` iPhone-portrait, `.regular` iPad / iPhone-landscape
on large phones). A layout that never reads `horizontalSizeClass` ships the same single-column stack on
both — the #1 "this iPad app is just a blown-up iPhone" smell. Branch the *layout*, not just the font.

```swift
// ❌ WRONG — same VStack everywhere; wastes the iPad's width
var body: some View { VStack { Sidebar(); Detail() } }
```
```swift
// ✅ CORRECT — adapt the structure to the width
@Environment(\.horizontalSizeClass) private var hSize
var body: some View {
    if hSize == .regular {
        HStack { Sidebar().frame(width: 320); Detail() }   // side-by-side on iPad
    } else {
        NavigationStack { Sidebar() }                      // drill-down on iPhone
    }
}
```
> Navigation-shell adaptation (`NavigationStack` vs a gated `NavigationSplitView`) is owned by
> `adaptive-navigation.md`; this rule is about the *content* layout inside a screen.

### 4. `GeometryReader` to measure when a layout container would do

`GeometryReader` greedily takes all offered space and re-lays-out its subtree on every size change
(rotation, iPad resize, keyboard). For "split the width" / "size to the container," reach for
`ViewThatFits`, `containerRelativeFrame`, `Grid`, or a custom `Layout` first — use `GeometryReader` only
when you genuinely need the measured size for drawing.

```swift
// ❌ WRONG — GeometryReader to pick a layout that fits
GeometryReader { geo in
    if geo.size.width > 500 { WideRow() } else { NarrowRow() }
}
```
```swift
// ✅ CORRECT — ViewThatFits picks the first child that fits the proposed size (iOS 16+)
ViewThatFits(in: .horizontal) {
    WideRow()        // tried first; used if it fits
    NarrowRow()      // fallback
}
```

### 5. `fixedSize()` / `layoutPriority` confusion when content truncates

Wrapping a whole subtree in `.fixedSize()` to "stop truncation" forces the view to its ideal size in
*both* axes and can blow past the screen, defeating the adaptive layout. The targeted fix for "which
view gives up space first" is `layoutPriority`; to stop a single label wrapping without freezing height,
use single-axis `fixedSize(horizontal:vertical:)`.

```swift
// ❌ WRONG — blanket both-axis fixedSize on a container; ignores proposed size, overflows
HStack { Text(longTitle); Spacer(); Text(subtitle) }.fixedSize()
```
```swift
// ✅ CORRECT — layoutPriority decides who keeps space; single-axis fixedSize stops wrap only
HStack {
    Text(longTitle).layoutPriority(1)          // this Text keeps its space
    Spacer()
    Text(subtitle)                             // this one truncates first
}
Text(label).fixedSize(horizontal: false, vertical: true)   // stop wrap, keep flexible height
```

---

## iOS-specific notes

- **Adapt, don't hard-code.** iOS reshapes constantly — rotation, iPad multitasking, keyboard,
  Dynamic Type. Reach for `containerRelativeFrame(_:)` (iOS 17.0+), `ViewThatFits` (iOS 16.0+), `Grid`
  (iOS 16.0+), and `horizontalSizeClass` branches before absolute `CGFloat`s.
- **Safe area & keyboard are layout, not decoration.** Content must respect the safe area and move out
  from under the keyboard. The keyboard-avoidance / safe-area inset rules are their own domain —
  cross-ref the audit suite's `safe-area-keyboard` concern; never hard-code a status-bar/home-indicator
  height.
- **`List` is the iOS primary; `Table` is iPad/regular-width.** Multi-column sortable tables shine on
  iPad (iOS 16.0+) and collapse to a single column on compact-width iPhone. A `TableColumn` built with
  `value:` is sortable; one built with only a content closure is not.
- **Variable column count → `TableColumnForEach`** (iOS 17.0+). When the number of columns is known only
  at runtime, use `TableColumnForEach` (the `ForEach` equivalent for `TableColumn`); mix it with static
  columns. Still an iPad/regular-width tool.
- **Sorting is one wiring.** `sortOrder: $binding` to `[KeyPathComparator]` + `.onChange(of: sortOrder)
  { _, new in data.sort(using: new) }`. SwiftUI draws the sort indicator and cycles ascending →
  descending automatically.
- **Scale to UIKit at extreme size/interaction.** SwiftUI `List`/`Table` render fine for typical data,
  but for a very large or interaction-dense grid bridge `UICollectionView` (compositional / list layout)
  via `UIViewRepresentable` — only after a measurement shows SwiftUI is the bottleneck (→
  `uikit-interop.md`, `view-performance.md`).

---

## Detection tells

Grep-able signals that catch these in review:

- **`.frame(width:` / `.frame(height:` with an absolute number on a content view** (not a fixed icon)
  → hard-coded size that won't adapt (mistake 1).
- **`List(` wrapping rows that are `HStack { Text … Spacer() Text … }` of a struct's fields**, in an app
  that also runs on iPad → should be a `Table` on regular width (mistake 2).
- **A whole app with no `horizontalSizeClass` / `UIDevice.userInterfaceIdiom` read anywhere** → no iPad
  adaptation (mistake 3).
- **`GeometryReader` wrapping a layout choice** (`if geo.size.width > … `) → likely wants `ViewThatFits`
  / `containerRelativeFrame` (mistake 4).
- **`.fixedSize()` (both-axis, no arguments) applied to a *container*** → wrong tool; expect
  `layoutPriority` or single-axis `fixedSize(horizontal:vertical:)` (mistake 5).

---

## Canonical pattern

A regular-width data `Table` with the compact-width `List` fallback, to quote verbatim:

```swift
struct PeopleScreen: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var people: [Person] = Person.sample
    @State private var sortOrder = [KeyPathComparator(\Person.name)]

    var body: some View {
        Group {
            if hSize == .regular {                                   // iPad / regular width
                Table(people, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.name)               // sortable header
                    TableColumn("Age", value: \.age) { Text("\($0.age)") }
                }
                .onChange(of: sortOrder) { _, newOrder in people.sort(using: newOrder) }
            } else {                                                 // compact iPhone
                List(people) { person in
                    HStack { Text(person.name); Spacer(); Text("\(person.age)").foregroundStyle(.secondary) }
                }
            }
        }
        .navigationTitle("People")
    }
}
```

**Rules:** (1) Size **relative to the container** (`containerRelativeFrame`, `maxWidth: .infinity`),
never a hard-coded absolute width on content. (2) On iPad/regular width use `Table` + `TableColumn` (+
`sortOrder:` / `KeyPathComparator`) for structured rows; keep a `List` path for compact iPhone. (3)
Branch the *layout* on `horizontalSizeClass` so the iPad isn't a blown-up iPhone. (4) Prefer
`ViewThatFits` / a layout container over `GeometryReader` to choose a layout. (5) Reach for
`layoutPriority` / single-axis `fixedSize(horizontal:vertical:)` before a blanket `.fixedSize()`.

---

## Availability table

| API | Min iOS | Note |
|---|---|---|
| `containerRelativeFrame(_:alignment:)` | iOS 17.0+ | size relative to the nearest container instead of an absolute CGFloat |
| `ViewThatFits` | iOS 16.0+ | picks the first child that fits the proposed size |
| `Grid` / `GridRow` | iOS 16.0+ | two-dimensional aligned layout |
| `Table` / `TableColumn` | iOS 16.0+ | single-column on compact width; multi-column on iPad/regular |
| `KeyPathComparator` (Foundation; with `Table` `sortOrder:`) | iOS 16.0+ | sortable-header behavior |
| `TableColumnForEach` | iOS 17.0+ | `ForEach` equivalent for a runtime-variable number of `TableColumn`s |
| `horizontalSizeClass` / `verticalSizeClass` (env) | iOS 13.0+ | `.compact` / `.regular` adaptation |
| `fixedSize()` / `fixedSize(horizontal:vertical:)` | iOS 13.0+ | cross-platform |
| `layoutPriority(_:)` | iOS 13.0+ | cross-platform |
| `controlSize(_:)` (`ControlSize`) | iOS 15.0+ | denser controls (used far more on iPad than iPhone) |

---

## Sources

All Apple-doc availability strings were scraped 2026-06-06 and cross-checked against the iOS catalog
(`swiftui-ctx lookup … --platform ios`).

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/table | *"A container that presents rows of data arranged in one or more columns…"* — availability `iOS 16.0+` | high |
| https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:alignment:) | *"Positions this view within an invisible frame with a size relative to the nearest container."* — iOS 17.0+ | high |
| https://developer.apple.com/documentation/swiftui/viewthatfits | *"A view that adapts to the available space by providing the first child view that fits."* — iOS 16.0+ | high |
| https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass | size-class environment value — iOS 13.0+ | high |
| https://developer.apple.com/documentation/swiftui/view/controlsize(_:) | *"Sets the size for controls within this view."* — iOS 15.0+ | high |
| https://developer.apple.com/documentation/swiftui/tablecolumnforeach | *"A structure that computes columns on demand…"* — iOS 17.0+ | high |
| https://developer.apple.com/documentation/swiftui/view/layoutpriority(_:) | *"Sets the priority by which a parent layout should apportion space to this child."* — iOS 13.0+ | medium |
| https://developer.apple.com/documentation/swiftui/view/fixedsize() | *"Fixes this view at its ideal size."* — iOS 13.0+ | medium |
