# Reference — Interactivity & Large-Series Scale (charts-07 / charts-10)

How a chart responds to the pointer (charts-07) and how it handles thousands of data points (charts-10).

---

## charts-07 — hand-rolled selection instead of `.chartXSelection`

**The floor that matters on iOS: `.chartXSelection` / `.chartYSelection` / `.chartAngleSelection` are
iOS 17 — exactly the project floor, so they are unconditionally available and need NO gate.** Many
codebases predate them and hand-roll selection with an `.onTapGesture` or a `DragGesture` plus manual
coordinate→data math via a `chartProxy`/`GeometryReader`. That math is fragile (ignores axis scale, plot
insets, scrolling). At the iOS 17 floor, always prefer the declarative modifier.

```swift
// ❌ hand-rolled hit-testing (charts-07)
.chartOverlay { proxy in
    Rectangle().fill(.clear).contentShape(Rectangle())
        .onTapGesture { loc in /* manual proxy.value(atX:) math */ }
}
// ✅ declarative selection (iOS 17, at the project floor — no gate)
@State private var selectedDay: Date?
Chart(data) { row in
    BarMark(x: .value("Day", row.day), y: .value("Total", row.total))
}
.chartXSelection(value: $selectedDay)
```

**Also iOS 17+ (at the floor):** `.chartGesture(_:)` — `func chartGesture((ChartProxy) -> some Gesture) -> some View`
provides a declarative gesture API backed by a `ChartProxy` without the manual `chartOverlay`/coordinate
math. Prefer it when `.chartXSelection` doesn't cover the gesture shape needed.

**Detection.** Tier-1 flags `.onTapGesture`/`DragGesture`/`.gesture(` — READ to confirm it's chart
hit-testing (not an unrelated gesture). `flag-only`. The selection modifiers are iOS 17 = at the floor, so
they are always available — there is no gating excuse for the hand-rolled path here (unlike on the Mac's
lower deployment floor).
If you see a `#available(iOS 17, *)` wrapper around them, that is the over-gating defect (charts-08).

---

## charts-10 — large series not vectorized / scrollable

Emitting thousands of individual `BarMark`/`LineMark` from one array (one mark per point) is slow — every
point is a separate plottable. Two scale fixes:

- **iOS 18+ (above the iOS 17 floor → gate):** `LinePlot`, `AreaPlot`, `BarPlot`, `PointPlot`, `SectorPlot`,
  `RectanglePlot`, `RulePlot` are **vectorized** — one plot for the whole function/series instead of N
  marks. Prefer them for dense continuous data, but wrap in `#available(iOS 18, *)` (they are above the
  floor).
- **iOS 17 (at the floor — no gate):** `.chartScrollableAxes(.horizontal)` + `.chartXVisibleDomain(length:)`
  windows a long series so only the visible slice renders; pair with downsampling for very large arrays.

```swift
// ✅ vectorized (iOS 18 — gate above the iOS 17 floor)
if #available(iOS 18, *) {
    Chart { LinePlot(data, x: .value("t", \.time), y: .value("v", \.value)) }
}
// ✅ windowed scroll (iOS 17, at the floor — no gate)
Chart(data) { LineMark(x: .value("t", $0.time), y: .value("v", $0.value)) }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: 3600)
```

**Seam.** charts-10 owns the *charts-specific* scale fix; general render-cost analysis (`.drawingGroup()`,
diffing, body re-evaluation) is **`audit-swiftui-view-performance`** — `cross_ref` it. Advisory: only flag
when the series is genuinely large (hundreds–thousands of marks). Confirm `LinePlot`'s iOS 18 floor via
`swiftui-ctx lookup LinePlot --platform ios --json` before recommending it under the iOS 17 target.

---

## Sources

- Apple — fetched via Sosumi (access 2026-06-16):
  `https://developer.apple.com/documentation/swiftui/view/chartxselection(value:)` (iOS 17.0+),
  `/documentation/swiftui/view/chartscrollableaxes(_:)` (iOS 17.0+),
  `/documentation/charts/lineplot` (iOS 18.0+),
  `https://developer.apple.com/documentation/swiftui/view/chartgesture(_:)` (iOS 17.0+).
- WWDC23 — "Explore pie charts and interactivity in Swift Charts" (`/videos/play/wwdc2023/10037`);
  WWDC24 — "Swift Charts: Vectorized and function plots" (`/videos/play/wwdc2024/10155`), via Sosumi.
- Practice corpus — `swiftui-ctx lookup LinePlot --platform ios --json` (`introduced_ios: 18`) confirms
  the vectorized-plot floor; `chartScrollableAxes`/`chartScrollPosition` are documented iOS-17 modifiers
  not yet dense in the iOS corpus (confirm the floor via Sosumi before recommending under a lower target).
