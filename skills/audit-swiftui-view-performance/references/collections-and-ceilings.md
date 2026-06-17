# Reference — Collection cost & dataset ceilings (vperf-07, vperf-10, vperf-11)

Lists and grids are where per-render work multiplies by row count. Compute derived collections **once,
upstream**; iterate **lazily**; and respect the iOS `List`/`LazyVStack` large-collection ceiling. The
✅ lazy-container shape below is grounded in `swiftui-ctx` (a real iOS example, permalinked).

**As of 2026-06-07 · iOS 26 (Tahoe) · Swift 6.2 toolchain.**

---

## vperf-07 — filtering / sorting *inside* `ForEach`

A `.filter`/`.sorted`/`.map` written directly in the `ForEach(...)` argument is recomputed on **every
render**, inside the view tree — the worst place for it.

```swift
// ❌ WRONG — filter+sort recomputed every render, inside the view tree
ForEach(items.filter { $0.isActive }.sorted { $0.name < $1.name }) { … }
// ✅ CORRECT — compute upstream (model / @Query(sort:) / a cached derived array)
ForEach(activeSortedItems) { … }        // the model exposes the derived collection, computed once
```

Home the derived collection in an `@Observable` model property, a `@Query(sort:)` for SwiftData, or a
value cached when the inputs change — never recomputed per render. Same principle as vperf-06 (no work in
the hot path).

## vperf-11 — a large `ForEach` not inside a lazy container (eager build)

A `ForEach` placed directly in a `VStack`/`HStack`/`ScrollView`-without-lazy builds **all** its rows
eagerly. For a large collection, wrap it in a lazy container so only on-screen rows materialize. The
canonical iOS shape (consensus `LazyVStack(spacing:)` 52%, from `swiftui-ctx lookup LazyVStack --platform ios`):

```swift
// ❌ WRONG — eager: a plain VStack builds every row up front
ScrollView { VStack { ForEach(items) { row($0) } } }
// ✅ CORRECT — LazyVStack materializes only visible rows (or List, which is lazy by default)
ScrollView { LazyVStack(spacing: 0) { ForEach(items) { row($0) } } }
```

This ✅ is a real, permalinked iOS example (the `recommended` for `LazyVStack`):
`backnotprop/rig` — `ScrollView { LazyVStack(spacing: 0) { ForEach(items) { … } } }`
(https://github.com/backnotprop/rig/blob/a01d168fd8abd566f884537fa60f254a1556f71f/Rig/Views/ReferencesPanel.swift#L302).
READ to confirm the collection is genuinely large — a handful of rows in a plain `VStack` is **fine**;
don't flag a 3-item stack. `LazyVStack` is iOS 14.0+ (`floors-master.md`), so no gating concern for the iOS 17 deployment floor.

## vperf-10 — `List`/`LazyVStack` large-dataset ceiling (measurement-bound)

SwiftUI `List` and `LazyVStack` handle large collections well on iOS but can stall under extreme
dataset sizes with **heavy/editable cells**. Practitioner testing on **iOS 26** shows a plain `List`
of ~10,000 simple rows scrolls smoothly (~50k still usable), so the old "few-hundred-row" ceiling no
longer holds for plain `List`. **Measure on your target** — cell complexity is the key variable.

```swift
// ❌ RISK — List with 50k+ rows + complex editable cells → janky scrolling on older iPhone hardware
List(tensOfThousandsOfRows) { item in HeavyEditableRow(item: item) }
// ✅ CORRECT (for that scale) — virtualize via UICollectionView bridge for extreme interaction-dense grids
struct DataGrid: UIViewRepresentable { /* wrap UICollectionView with diffable data source */ }
```

Carry this **advisory** with `source: verify against Xcode 26 SDK` — never assert a fixed row threshold
as fact. The **column-structure / layout** of a `Table` is `audit-swiftui-layout-and-tables`'s turf,
and the `UICollectionView` **bridge implementation** is `audit-swiftui-uikit-interop`'s — `cross_ref` both;
this skill owns only the **dataset-size cost ceiling that justifies the bridge.**

---

## Sources

- WWDC23 "Demystify SwiftUI performance" (session 10160) — `List`/`ForEach` update cost:
  https://developer.apple.com/videos/play/wwdc2023/10160/ (accessed 2026-06-07).
- Apple — `LazyVStack`: https://developer.apple.com/documentation/swiftui/lazyvstack ·
  `List`: https://developer.apple.com/documentation/swiftui/list (fetch via Sosumi; accessed 2026-06-07).
- Community practitioner reports (r/SwiftUI; iOS SwiftUI performance write-ups) for the iOS 26
  plain-`List` headroom (~10k smooth, ~50k usable) — treat the numbers as guidance and profile your
  build (accessed 2026-06-07).
