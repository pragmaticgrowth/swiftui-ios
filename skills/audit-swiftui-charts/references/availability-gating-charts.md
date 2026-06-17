# Reference — Charts Availability Gating (charts-08 / charts-09)

Swift Charts spans three iOS floors, and AI mis-floors the newer symbols in both directions. The floor
*values* are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read,
never restate them here. This file is the **gating logic** for the Charts domain. The iOS-arm rule and the
wrong-arm (macOS) failure mode are in `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.

---

## The three Charts floors (confirm each in floors-master)

| Floor | Symbols | Gate at the iOS 17 project floor? |
|---|---|---|
| **iOS 16** | `Chart`, `BarMark`, `LineMark`, `PointMark`, `AreaMark`, `RuleMark`, `RectangleMark`, `AxisMarks`, `.chartXAxis`/`.chartYAxis`/`.chartLegend`, `.foregroundStyle(by:)` | No — below floor |
| **iOS 17** | `SectorMark`, `.chartXSelection`/`.chartYSelection`/`.chartAngleSelection`, `.chartScrollableAxes`/`.chartScrollPosition`/`.chartXVisibleDomain` | **No — AT the floor** (a gate on these is the over-gating defect) |
| **iOS 18** | `LinePlot`, `AreaPlot`, `BarPlot`, `PointPlot`, `SectorPlot`, `RectanglePlot`, `RulePlot` (vectorized function/series plots) | **Yes — above the floor** |

**This is the iOS inversion of the macOS skill.** On the Mac the lower deployment floor meant `SectorMark`
and selection routinely needed a gate. On iOS the project floor is **17**, and `SectorMark` /
the `chart*Selection` family are **iOS 17** — *exactly at the floor*. They need **no gate**, and any
`#available(iOS …)` wrapper around them is the **over-gating** defect (charts-08, direction 2). Only the
**iOS 18 vectorized plots** sit above the floor and genuinely need a gate.

Two AI failure shapes — **charts-08 fires for both**:

1. **Under-gated.** An iOS-18 symbol (`LinePlot`, `AreaPlot`, the vectorized plot family) used **ungated**
   under the iOS 17 deployment target → compile/availability error. The model assumed "Charts = iOS 16".
2. **Over-gated.** The mirror mistake: `SectorMark` or `.chartXSelection` wrapped in `#available(iOS 18, *)`
   (or any gate) when it is actually **iOS 17 = at the floor**, or `LinePlot` wrapped in `#available(iOS 26, *)`
   when it is iOS 18. The chart is needlessly unavailable on whole OS versions. Over-gating is a real
   defect — flag it and cite the corrected floor.

```swift
// ✅ correctly gated to the REAL floor (LinePlot = iOS 18, above the iOS 17 floor)
if #available(iOS 18, *) {
    Chart { LinePlot(data, x: .value("t", \.time), y: .value("v", \.value)) }
} else {
    // pre-18 fallback (e.g. one LineMark per point, iOS 16)
    Chart(data) { LineMark(x: .value("t", $0.time), y: .value("v", $0.value)) }
}

// ✅ NO gate needed — SectorMark is iOS 17 = the project floor
Chart(slices) { SectorMark(angle: .value("Share", $0.share)) }
```

**ORIENT is load-bearing.** charts-08 only fires when the symbol's floor is **above** the project's
`IPHONEOS_DEPLOYMENT_TARGET`. With the iOS 17 floor, that means only the iOS-18 vectorized plots. If the
floor is ≥ the symbol's introduction, no gate is needed and an existing gate is the over-gating defect.
Always confirm the floor via `swiftui-ctx lookup <api> --platform ios --json` (`introduced_ios`) **and**
Sosumi before asserting either direction.

---

## charts-09 — wrong-arm gate

An `#available(macOS …, *)` (or `#if os(macOS)`) gate around a Charts symbol in an **iOS** target: the
macOS arm never runs on iPhone/iPad, so the chart is unreachable and the iOS path is silently empty. The
lower macOS Charts floors (where `SectorMark`/selection and `LinePlot` each land one major version below
their iOS counterparts) are why the model writes a `#available(macOS …, *)` gate — it ported a macOS gate
verbatim instead of converting to the iOS arm.

```swift
// ❌ wrong arm (charts-09) — never true on iPhone/iPad
if #available(macOS 14, *) { Chart(slices) { SectorMark(...) } }
// ✅ on iOS, SectorMark is iOS 17 = the project floor → no gate at all
Chart(slices) { SectorMark(...) }
// ✅ when a gate IS warranted (iOS-18 symbol), gate the iOS arm
if #available(iOS 18, *) { Chart { LinePlot(...) } }
```

**Detection.** The tier-2 ast-grep rule `charts-09-wrong-arm-gate.yml` matches an `#available(macOS …)`
whose body **contains** a `Chart`/`BarMark`/`LineMark`/`SectorMark`/`PointMark` — the gate-scope
containment grep can't express. `fix_mode: auto`: rewrite the platform arm to `iOS` at the correct floor
(per ios-gating + floors-master), or drop the gate entirely when the symbol is ≤ iOS 17.

---

## Sources

- Apple — availability annotations on the Swift Charts symbol pages, fetched via Sosumi (access
  2026-06-16): `https://developer.apple.com/documentation/charts/sectormark`,
  `/documentation/swiftui/view/chartxselection(value:)`, `/documentation/charts/lineplot`.
- Apple — "Availability condition" (`#available`) in *The Swift Programming Language* / SwiftUI platform
  gating, via Sosumi.
- Practice corpus — `swiftui-ctx lookup SectorMark`/`chartXSelection`/`LinePlot --platform ios --json`
  `introduced_ios` values (17, 17, 18 respectively) confirming the floors against shipping iOS code.
