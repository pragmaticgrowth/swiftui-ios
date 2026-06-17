# Reference — UIKit Control → SwiftUI Control Map (over-01, over-05)

The 1:1 native replacements. When a representable wraps one of these *for plain use*, the bridge is
**overuse** — flag it and show the SwiftUI ✅. Confirm every replacement exists at the project's floor
(iOS 17) in VERIFY (`swiftui-ctx lookup --platform ios` + Sosumi) before flagging.

**As of:** 2026-06-16 · iOS 26. All SwiftUI controls below are iOS 13+ unless noted.

---

## over-01 — the 1:1 control map

| UIKit (wrapped in a representable) | Native SwiftUI | Notes |
|---|---|---|
| `UILabel` | `Text(_:)` | the most common trivial overuse — a representable wrapping a `UILabel` for static text |
| `UIButton` | `Button(_:action:)` / `Button(role:)` | |
| `UITextField` (plain) | `TextField(_:text:)` / `SecureField` | first-responder / inputAccessoryView use may be justified — see `justified-escape-hatches.md` |
| `UISwitch` | `Toggle(_:isOn:)` | consensus shape `(_, isOn)` (67%) |
| `UISlider` | `Slider(value:in:)` | |
| `UIStepper` | `Stepper(_:value:in:)` | |
| `UIColorWell` / color picker | `ColorPicker(_:selection:)` | **iOS 14+** |
| `UIDatePicker` | `DatePicker(_:selection:)` | `.datePickerStyle(.wheel)` reproduces the classic wheel |
| `UIProgressView` / `UIActivityIndicatorView` | `ProgressView()` / `ProgressView(value:)` | indeterminate + determinate; **iOS 14+** |
| `UISegmentedControl` | `Picker(...).pickerStyle(.segmented)` | |
| `UIPickerView` | `Picker(...).pickerStyle(.wheel)` | the wheel style is NATIVE and idiomatic on iOS |
| `UIImageView` | `Image(...)` / `AsyncImage` | `AsyncImage` iOS 15+ |

**The trap:** a `UITextField` bridge is *not* automatically over-01 — it is a justified hatch when it
exists for a custom `inputView`/`inputAccessoryView`, precise first-responder / insertion-point control,
or a UIKit-only keyboard toolbar. READ the bridge: if it only sets/reads `.text` and forwards a
delegate, it is over-01; if it overrides `becomeFirstResponder` / installs an `inputAccessoryView`, it
is justified (and interop owns its HOW).

## over-05 — UIKit blur/glass → SwiftUI glass / Material

`UIVisualEffectView` (with `UIBlurEffect`/`UIVibrancyEffect`) is the **UIKit** blur surface. In a
SwiftUI view, bridging it is overuse — SwiftUI has first-class equivalents: `.glassEffect(_:in:)`,
`GlassEffectContainer`, `.buttonStyle(.glass)` (all iOS 26.0+), and for plain frosted backgrounds the
`Material` family (`.ultraThinMaterial`/`.thinMaterial`/`.regularMaterial`, iOS 15+). Flag the bridge;
the SwiftUI glass *placement/grouping* rules (navigation-layer-only, no glass-on-glass, container
grouping) are `audit-swiftui-liquid-glass` and the material/vibrancy *choice* is
`audit-swiftui-appearance-color` — cross_ref them. Do not restate the glass/material rules here.

## The ✅ comes from swiftui-ctx, not from this table

The table tells you *which* SwiftUI control replaces the bridge. The **canonical example** in a finding's
`## Correct` / `## Source` is the swiftui-ctx consensus shape + a real permalink, not a hand-written
snippet:

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup Toggle --platform ios --json   # consensus shape + recommended.id
bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart          # the GitHub permalink for ## Source
```

Floor values (e.g. `ColorPicker`/`ProgressView` iOS 14, `AsyncImage` iOS 15, `Material` iOS 15) are the
reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate.
Confirm a SwiftUI name is real (not an AI hallucination) against
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` and a `lookup` exit-3.

---

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://developer.apple.com/documentation/swiftui/toggle | primary-doc | high | `Toggle(_:isOn:)` — native replacement for `UISwitch`. iOS 13.0+. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/picker | primary-doc | high | `Picker` + `.pickerStyle(.segmented/.wheel)` — replaces `UISegmentedControl`/`UIPickerView`. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/colorpicker | primary-doc | high | `ColorPicker` — iOS 14.0+, replaces a color-well bridge. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/material | primary-doc | high | `Material` (`.ultraThinMaterial` …) — iOS 15.0+, replaces a plain `UIVisualEffectView` blur. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) | primary-doc | high | SwiftUI `.glassEffect(_:in:)` — iOS 26.0+, replaces a bridged glass `UIVisualEffectView`. Accessed 2026-06-16. |
