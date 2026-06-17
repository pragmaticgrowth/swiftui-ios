# Reference — Text Styles, ScaledMetric, Type-Size Caps & Fit (dt-01 … dt-05)

The five iOS Dynamic Type defects that break **Larger Text** accessibility: a **fixed point size** on body
text, the **value-init form** of the same, a **hard-coded spacing/icon dimension** that should scale with
type, a **type-size cap** that locks out accessibility users, and a **one-line label with no fit factor** that
clips at large sizes. All five are over-produced by the iOS-trained corpus because design specs hand the model
literal point sizes, and a number reads as "the right size." These are *flag-only* defects (the correct fix is
a text-style / scale judgment). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** backed by a real iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK · Swift 6.2.

---

## dt-01 — `.font(.system(size: N))` on body/title text (warning, flag-only)

A Dynamic-Type text style (`.body`, `.headline`, `.title`, `.caption`…) scales automatically with the user's
Larger Text setting. `.font(.system(size: 17))` is **frozen** — it ignores the setting entirely, so the text
stays one size while everything around it grows.

```swift
// ❌ WRONG — frozen 17pt body text; ignores Larger Text, fails Dynamic Type
Text(task.title)
    .font(.system(size: 17))
```
```swift
// ✅ CORRECT — a text style scales with the user's content-size category
Text(task.title)
    .font(.body)              // iOS 13.0+ — scales automatically
```

**Grounded in the corpus.** `swiftui-ctx lookup font --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 13.0`, `deprecated: false`, consensus shape `(_)` **100%**. The text-style path is the
overwhelmingly dominant idiom for body/title text.

> **Judge before flagging.** `.system(size:)` is *legitimate* for a non-text glyph, a fixed-geometry badge, or
> a value deliberately pinned for pixel layout. dt-01 LOCATES every `.font(.system(size:))`; you decide whether
> the target is genuine running text that must honor Dynamic Type. cross_ref `typography-text` for the
> font-craft angle (custom face, weight, design).

## dt-02 — `Font.system(size: N)` constructor for text (warning, flag-only)

The value-init form of the same defect: a `Font` built with an explicit size and assigned to text. Same frozen
result as dt-01 — it never scales.

```swift
// ❌ WRONG — a Font value pinned at 20pt; assigned to a heading that should scale
let titleFont = Font.system(size: 20, weight: .semibold)
Text(section.title).font(titleFont)
```
```swift
// ✅ CORRECT — a scaling text style (with weight if needed)
Text(section.title).font(.title3.weight(.semibold))   // iOS 13.0+
```

`swiftui-ctx lookup system --platform ios --json` returns `introduced_ios: 13.0`. The fix is the same text
style as dt-01; cross_ref `typography-text` when the weight/design choice is the real question.

## dt-03 — hard-coded spacing/icon size with no `@ScaledMetric` (advisory, flag-only)

When text scales but the gaps and icons beside it stay frozen, the layout rhythm breaks — a 44pt icon next to
text that has doubled in size reads as tiny. `@ScaledMetric` makes a number grow *with* the text.

```swift
// ❌ WRONG — icon frame and padding frozen while the label scales
HStack {
    Image(systemName: "star.fill").frame(width: 44, height: 44)
    Text(item.name).font(.body)
}
.padding(16)
```
```swift
// ✅ CORRECT — the metric scales relative to a text style
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 44
// …
Image(systemName: "star.fill").frame(width: iconSize, height: iconSize)
```

**Grounded in the corpus.** `swiftui-ctx lookup ScaledMetric --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 14.0`, `deprecated: false`, consensus shape `(relativeTo: .body)` **35%** (the leading
shape; the rest are other `relativeTo:` styles — every real use pins the metric to a text style). Its
`recommended` iOS example is `@ScaledMetric(relativeTo: .body)` in `fxm90/GradientProgressBar`:
`https://github.com/fxm90/GradientProgressBar/blob/cca0ea7fcd15fc30833332ca2e8ec735677ca479/Example/GradientProgressBarExample/Scenes/SwiftUIExample/SwiftUIExampleView.swift#L46`
(541 stars, `min_ios: 18`). In FIX, put the `@ScaledMetric(relativeTo: …)` declaration in `## Correct` and
that permalink (+ the Sosumi `doc:`) in `## Source`.

> **Judge before flagging.** Not every hard-coded `.frame`/`.padding` is a defect — a fixed container width, a
> separator height, or a non-text decoration may stay frozen. dt-03 LOCATES every literal dimension; you decide
> whether it is *spacing/icon geometry tied to text* that should scale. cross_ref `adaptive-layout` /
> `layout-and-tables` when the real remedy is a reflow or a scaled row height, not a `@ScaledMetric`.

## dt-04 — `.dynamicTypeSize(.<small size>)` cap that locks out large-text users (warning, flag-only)

`dynamicTypeSize` can **cap** how large text grows. A fixed cap *below* the accessibility range
(`.dynamicTypeSize(.large)`, or `...DynamicTypeSize.xxLarge`) clamps text exactly where accessibility users
need it to keep growing — defeating Dynamic Type for the people it exists for.

```swift
// ❌ WRONG — text can never exceed .large; accessibility sizes are clamped away
SomeContentView()
    .dynamicTypeSize(.large)
```
```swift
// ✅ CORRECT — allow growth, optionally bound the *extreme* at the accessibility range
SomeContentView()
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)   // iOS 15.0+ — bound an extreme, not a regression
```

`swiftui-ctx lookup dynamicTypeSize --platform ios --json` returns `introduced_ios: 15.0`, `deprecated:
false`, consensus shape `(_)` **100%**; its `recommended` iOS example is `.dynamicTypeSize(.large)` in
`Dimillian/IceCubesApp`:
`https://github.com/Dimillian/IceCubesApp/blob/9c05a720597b3ff13de2e241bf58d3fba0863c09/Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowActionsView.swift#L268`
— note even a high-quality app uses a fixed `.large` in a constrained row; the defect is a cap that clamps the
*whole screen* below accessibility sizes. A cap at the accessibility range to bound an extreme layout is
legitimate — judge the bound. `DynamicTypeSize` enum: iOS 15.0.

## dt-05 — `.lineLimit(1)` on scalable text with no `.minimumScaleFactor` (advisory, flag-only)

A single-line label whose text can grow will **truncate** at large sizes. The fit idioms are to let the text
shrink (`minimumScaleFactor`), allow tightening, or drop the one-line constraint so the label wraps.

```swift
// ❌ WRONG — one line, no shrink-to-fit; truncates "…" at large Dynamic-Type sizes
Text(account.displayName)
    .font(.headline)
    .lineLimit(1)
```
```swift
// ✅ CORRECT — allow the text to shrink to fit (or drop .lineLimit so it wraps)
Text(account.displayName)
    .font(.headline)
    .lineLimit(1)
    .minimumScaleFactor(0.7)   // iOS 13.0+ — shrink rather than truncate
```

`swiftui-ctx lookup minimumScaleFactor --platform ios --json` returns `introduced_ios: 13.0`, `deprecated:
false`. Whether to shrink or to wrap is a layout judgment — hence flag-only.

---

## The canonical scaled-layout exemplar

```swift
struct ScaledRow: View {
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 28   // iOS 14.0+
    let item: Item
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.body)                       // glyph scales with the row text
                .frame(width: iconSize, height: iconSize)
            Text(item.title)
                .font(.body)                       // iOS 13.0+ — Dynamic Type
                .lineLimit(1)
                .minimumScaleFactor(0.8)           // iOS 13.0+ — shrink before truncating
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)   // iOS 15.0+ — bound only the extreme
    }
}
```

This is the consensus scaling shape: a text style for the text, `@ScaledMetric(relativeTo: .body)` for the
icon, `minimumScaleFactor` for fit, and a cap only at the accessibility range. At the iOS-17 deployment floor
every modifier above is available unconditionally — no `#available` gate per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.

## Seams (cross_ref, don't double-own)

- The **font-craft** angle (custom face, weight, design, `AttributedString`, `Text + Text`) →
  `audit-swiftui-typography-text`. cross_ref it from dt-01/dt-02. The *scaling* (does it honor Dynamic Type) is
  mine and primary per cross-ref-graph §1.
- "**Supporting Dynamic Type is an accessibility requirement**" + `accessibilityShowsLargeContentViewer`
  (icon-only large-content HUD) → `audit-swiftui-accessibility`. cross_ref it when the framing is the a11y
  obligation, not the scaling mechanic.
- The **structural reflow** at accessibility sizes (a `ViewThatFits`, a horizontal stack that must wrap) →
  `audit-swiftui-adaptive-layout`; scaled **row heights/spacing inside a `List`/`Table`** →
  `audit-swiftui-layout-and-tables`. cross_ref from dt-03 when the remedy is a layout change, not a
  `@ScaledMetric`.

## Sources

- Practice corpus: `swiftui-ctx lookup font|system|ScaledMetric|dynamicTypeSize|minimumScaleFactor --platform
  ios --json` (run 2026-06-16). Contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- Floors: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (the reconciled truth — `@ScaledMetric`
  14.0, `dynamicTypeSize`/`DynamicTypeSize` 15.0, `font`/`minimumScaleFactor` 13.0).
- Apple docs fetched via `https://sosumi.ai/...` per `references/source-directory.md` (access 2026-06-16).
- GitHub permalinks above are the swiftui-ctx `recommended` exemplars (pinned commit SHAs).
</content>
