# Reference — Picker Style for the Data & Control Density (cf-05 · cf-07)

On iOS the **picker style must fit the data**: a few mutually-exclusive options want a segmented control, a
long list wants a pop-up menu or a pushed navigation list, and a `.wheel` is the right control for a
date/range/continuous value. A `Picker` left at the default style, or a `.wheel` forced onto a binary choice,
reads wrong. Control **density** (`controlSize`) is a finer-grained iOS-15+ knob for compact controls. Both
cf-05 and cf-07 are *advisory, flag-only* (style/density is a judgment). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** backed by a real iOS permalink, not opinion.

**As of:** 2026-06-16 · iOS 26 · Swift 6.2 · project floor iOS 17.

> **`.pickerStyle(.wheel)` is NATIVE iOS (inverted from macOS).** On macOS `.wheel` has no platform arm; on
> **iOS it is a real, shipping picker style** (`WheelPickerStyle` `introduced_ios 13.0`). Never flag it as
> platform-wrong or wrap it in `#available`. The only `.wheel` smell is **fit**: a spinning wheel for a
> 2–3-option binary choice that a `.segmented` control serves better — and even that is advisory.

---

## cf-05 — `Picker` with the wrong/default style for its data (advisory, flag-only)

The iOS picker styles map to the data:

- **`.segmented`** — 2–5 mutually-exclusive options shown inline (a horizontal segmented control).
- **`.menu`** — a pop-up button that opens a menu of options (good for a medium list, inline in a form).
- **`.navigationLink`** — pushes a selection list onto the `NavigationStack` (good for a long list inside a
  `Form`/`List`).
- **`.wheel`** — the spinning wheel, native and correct for a continuous/range value (a count, a duration).
- **`.inline`** / **`.automatic`** — the platform default inside a `List`/`Form`.

```swift
// ❌ WRONG — a 3-option choice left at the default style reads as a plain pushed row
Picker("Sort", selection: $sort) {
    Text("Name").tag(Sort.name)
    Text("Date").tag(Sort.date)
    Text("Size").tag(Sort.size)
}
```
```swift
// ✅ CORRECT — a few mutually-exclusive options → segmented control
Picker("Sort", selection: $sort) {
    Text("Name").tag(Sort.name)
    Text("Date").tag(Sort.date)
    Text("Size").tag(Sort.size)
}
.pickerStyle(.segmented)                     // 2–5 options inline (iOS 13.0+)
```

**Grounded in the corpus.** `swiftui-ctx lookup pickerStyle --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 13.0`, `deprecated: false`, consensus `(_)` **100%** — every real use passes a style. Choose
per the data: `.segmented` for a few options, `.menu` / `.navigationLink` for a long list, `.wheel` for a
continuous value. Put the chosen style in `## Correct`; it is the dev's call, not a mechanical fix.
`WheelPickerStyle` `--platform ios` returns `introduced_ios 13.0` (a real iOS control) — it is **never** a
defect by existence.

## cf-07 — compact control left at the default `controlSize` (advisory, flag-only)

`controlSize` (iOS 15.0+) tunes a control's density. In a compact context (a toolbar, a dense inspector row,
an iPad regular-width sidebar) a `.small`/`.mini` button or picker reads better than the `.regular` default; a
single prominent action wants `.large`. This is a *finer* iOS knob than the keyboard concerns above — flag only
where density is genuinely off.

```swift
// ❌ WRONG (density) — a prominent CTA left at the default control size in a tight bar
Button("Save") { save() }.buttonStyle(.borderedProminent)
```
```swift
// ✅ CORRECT — pick a density that fits the context
Button("Save") { save() }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)                     // prominent single action (iOS 15.0+)
// dense pane:
HStack { /* controls */ }.controlSize(.small)   // applies to the subtree
```

**Grounded in the corpus.** `swiftui-ctx lookup controlSize --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 15.0`, `deprecated: false`, consensus `(_)` **100%**. The iOS case list is
`.mini`/`.small`/`.regular`/`.large` (and `.extraLarge`, iOS 17.0+, which *does* render larger on iOS — unlike
macOS where it is a no-op). `.regular` is the default; dense panes want `.small`/`.mini`, a prominent action
wants `.large`. **Seam:** `controlSize` as a **layout sizing axis** (inside a `Table`/inspector arrangement) is
`audit-swiftui-layout-and-tables` — `cross_ref` it when the issue is layout sizing, not control density.

---

## iOS-specific notes

- **`Form` is grouped by default on iOS.** A missing `.formStyle(.grouped)` is **not** a defect (it is the
  macOS-only cf-01 that this skill drops). `formStyle` exists on iOS (16.0+) but the grouped look is already
  the iOS default.
- **`.pickerStyle(.wheel)` is a native iOS control** (`WheelPickerStyle` iOS 13.0+) — correct for continuous
  values, never platform-wrong. The only smell is using it for a binary choice that `.segmented` fits.
- **Density is `controlSize`** (iOS 15.0+): `.mini`/`.small` for compact contexts, `.regular` default,
  `.large` for a prominent action; `.extraLarge` (iOS 17.0+) renders larger on iOS.
- **`.buttonStyle(.glass)` / glass control styling** are Liquid Glass (iOS 26.0+) and owned by
  `audit-swiftui-liquid-glass` — note in one line and `cross_ref`, don't gate them here.

---

## Sources

- Apple — `pickerStyle(_:)`: `.segmented`/`.menu`/`.navigationLink`/`.wheel`/`.inline`/`.automatic`; iOS 13.0+:
  `https://developer.apple.com/documentation/swiftui/view/pickerstyle(_:)` (via Sosumi, accessed 2026-06-16).
- Apple — `WheelPickerStyle`: the iOS spinning wheel — a **native iOS** picker style (iOS 13.0+, NOT
  platform-wrong): `https://developer.apple.com/documentation/swiftui/wheelpickerstyle` (via Sosumi, accessed
  2026-06-16).
- Apple — `controlSize(_:)`: *"Sets the size for controls within this view."* — iOS 15.0+; `ControlSize` cases
  `.mini`/`.small`/`.regular`/`.large`/`.extraLarge` (iOS 17.0+, renders larger on iOS):
  `https://developer.apple.com/documentation/swiftui/controlsize` (via Sosumi, accessed 2026-06-16).
- Practice corpus (the ✅ permalinks / floor proof): `swiftui-ctx lookup pickerStyle --platform ios` →
  `introduced_ios 13.0`, consensus `(_)` 100%; `swiftui-ctx lookup WheelPickerStyle --platform ios` →
  `introduced_ios 13.0` (a shipping iOS control); `swiftui-ctx lookup controlSize --platform ios` →
  `introduced_ios 15.0` (1,857-repo iOS catalog, SwiftSyntax, iOS 26 SDK; accessed 2026-06-16).
