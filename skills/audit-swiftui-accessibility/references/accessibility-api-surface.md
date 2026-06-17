# Accessibility API surface — the allow-list, the invented names, the legacy combinator (a11y-10/11)

The name/existence authority for the accessibility domain. Floor *values* are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the canonical invented-name list is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read, never restate. For the
**canonical call shape** of any modifier below, run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup
<api> --platform ios --json` and read its `consensus` + `recommended` permalink instead of pasting a static snippet.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK.

## A. Real SwiftUI accessibility modifiers (allow-list)

| Modifier / type | iOS floor | Notes |
|---|---|---|
| `accessibilityLabel(_:)` (string `StringProtocol`) | 14.0 | the announced name; `LocalizedStringResource` overload = 16.0; closure form `accessibilityLabel(content:)` = 15.0 |
| `accessibilityValue(_:)` | 14.0 | current value of a custom control; closure form `(_:isEnabled:)` = 15.0 |
| `accessibilityHint(_:)` | 14.0 | what an action does |
| `accessibilityHidden(_:)` | 14.0 | hide decorative elements from VoiceOver |
| `accessibilityElement(children:)` | 13.0 | `.combine` / `.ignore` / `.contain` — group a composite |
| `accessibilityAddTraits(_:)` / `accessibilityRemoveTraits(_:)` | 14.0 | `.isButton`, `.isToggle`(17.0), `.isHeader`, `.isImage`, `.isSelected` |
| `accessibilityAction(_:)` / `accessibilityAdjustableAction(_:)` | 13.0 | mirror a custom gesture / make a custom control adjustable |
| `accessibilityActions { … }` | 16.0 | a group of named accessibility actions |
| `accessibilityFocused(_:)` + `AccessibilityFocusState` | 15.0 | VoiceOver focus (NOT keyboard `@FocusState`) |
| `accessibilitySortPriority(_:)` | 14.0 | reading order within a container |
| `accessibilityChartDescriptor(_:)` | 15.0 | Audio Graph for a `Chart` |
| `accessibilityRepresentation(representation:)` | 15.0 | proxy a custom view with a standard control's semantics |
| `accessibilityShowsLargeContentViewer(_:)` | 15.0 | **iOS-specific** — large-content label for icon-only tab/toolbar items |
| `accessibilityRespondsToUserInteraction(_:)` | 15.0 | mark a non-interactive element as VoiceOver-actionable |
| `@Environment(\.accessibilityReduceMotion)` | 13.0 | read to branch motion off |
| `@Environment(\.accessibilityDifferentiateWithoutColor)` | 13.0 | read to add a non-color cue |

`consensus` for `accessibilityLabel` is **99% `(_)`** (the trailing-string shape);
`accessibilityShowsLargeContentViewer` is **88% trailing-closure `{ }`** — both confirmed via
`swiftui-ctx lookup --platform ios` (2026-06-16). **`.isToggle` is iOS 17.0 = the project floor → no gate** (the
old macOS gating concern does not transfer to iOS; see `labels-and-traits.md` a11y-12).

## B. a11y-10 — invented names (hard-fail, fix_mode: auto)

These do **not** exist; a `swiftui-ctx lookup` returns **exit 3** with a did-you-mean `suggestion`.

| ❌ Invented | ✅ Real |
|---|---|
| `.voiceOverLabel("…")` / `.a11yLabel("…")` / `.screenReaderLabel("…")` / `.accessibilityName("…")` | `.accessibilityLabel("…")` |
| `.accessibilityText("…")` | `.accessibilityLabel("…")` (or `.accessibilityValue` if it's a value) |
| `.voiceOverHint("…")` | `.accessibilityHint("…")` |

Verified: `swiftui-ctx lookup voiceOverLabel --platform ios` → exit 3, suggestion `widgetLabel, chartOverlay, …`
(2026-06-16). Cross-check any candidate against `_shared/hallucination-blacklist.md` before emitting.

## C. a11y-11 — the legacy combined modifier (warning, fix_mode: auto)

The pre-iOS-13.4 combinator bundled label/hint/traits/value into one `.accessibility(...)` call. Split it:

```
// ❌ legacy combined
.accessibility(label: Text("Add"), hint: Text("Adds a row"))
.accessibility(addTraits: .isButton)
// ✅ per-aspect modifiers (current)
.accessibilityLabel("Add")
.accessibilityHint("Adds a row")
.accessibilityAddTraits(.isButton)
```

`.accessibility(identifier:)` → `.accessibilityIdentifier(_:)` (test-only id, not user-facing).
**Confirmed deprecated: `iOS 13.0–18.0 Deprecated`** — Apple docs confirm the `@available(…, deprecated:)`
annotation; replacement is `accessibilityLabel(_:)`. The sibling combinators (`accessibility(hint:)`,
`accessibility(value:)`, `accessibility(hidden:)`, `accessibility(identifier:)`, `accessibility(addTraits:)`,
`accessibility(removeTraits:)`, `accessibility(sortPriority:)`) are deprecated likewise. The corpus
`deprecated:false` is a known false negative. Carry a11y-11 as `source: iOS 13.0–18.0 Deprecated →
accessibilityLabel(_:)`. The split rewrite is behavior-preserving regardless, so the auto-fix is safe under
the fix-safety protocol.

## Sources

- Floors + invented-name list: the toolkit's reconciled `_shared/floors-master.md` and
  `_shared/hallucination-blacklist.md` (re-confirmed 2026-06-16).
- Apple — Accessibility modifiers: `https://sosumi.ai/documentation/swiftui/view-accessibility` and
  `https://sosumi.ai/documentation/swiftui/view/accessibilitylabel(_:)` (fetch via Sosumi; access 2026-06-16).
- Practice shapes from the bundled `swiftui-ctx` corpus (`lookup accessibilityLabel --platform ios` /
  `accessibilityShowsLargeContentViewer --platform ios`, 2026-06-16) — every result GitHub-permalinked.
