# Grouping, custom-control values, VoiceOver focus order (a11y-03/04/09)

The *structure* axis: collapsing composites into one element, exposing the value of a hand-rolled control,
and driving a sane VoiceOver reading order. Floors in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.
For canonical shapes run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --json`.

## a11y-03 — composite reads as fragments (warning, flag-only)

A `List` row that is visually *one* control — an icon + title + subtitle + chevron in an `HStack` — is
announced as four separate VoiceOver swipes unless grouped (the most common iOS defect). Collapse it:

```
// ❌ four VoiceOver stops, no single meaning
HStack { Image(systemName: "folder"); VStack { Text(name); Text(detail) }; Spacer(); Image(systemName: "chevron.right") }
// ✅ one element, one announcement
HStack { … }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(name), \(detail)")
```

`accessibilityElement(children:)` is **iOS 13.0** (`floors-master.md`); choose the child
behaviour deliberately: `.combine` merges children's labels; `.ignore` replaces them (you supply the label);
`.contain` keeps them as a navigable container. The **defect is the absence** of grouping on a composite that
is conceptually one control — a genuinely independent stack of controls should stay ungrouped. READ to decide.
`co_occurs_with`: `accessibilityChildren`, `accessibilityLabeledPair`, `accessibilityRotor`.

## a11y-04 — custom value control with no value (warning, flag-only)

Native `Slider`/`Stepper`/`Gauge`/`ProgressView` expose their value automatically. A **hand-rolled** rating
star-row, segmented meter, or custom knob does not — VoiceOver announces the label but not the state:

```
// ✅ custom 0–5 star rating
StarRow(rating: rating)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Rating")
    .accessibilityValue("\(rating) of 5 stars")
    .accessibilityAdjustableAction { direction in /* increment/decrement */ }
```

Pair `.accessibilityValue` with `.accessibilityAdjustableAction` so VoiceOver users can change it. Only flag
**custom** controls — confirm by reading that it's not a native control wrapped trivially.

## a11y-09 — broken VoiceOver focus order (advisory, flag-only)

`AccessibilityFocusState` (iOS 15) moves VoiceOver focus programmatically — e.g. to an error after a failed
submit. Two failure shapes:

1. **Declared but never driven** — `@AccessibilityFocusState var focused: Field?` exists but nothing ever
   assigns it; the intent (move focus on validation) silently never happens.
2. **Broken reading order** — a visually-reordered layout (a `Spacer`-pushed action above its label, an
   overlay) reads in the wrong sequence; fix with `.accessibilitySortPriority(_:)` (higher reads first).

```
@AccessibilityFocusState private var focusedField: Field?
…
.accessibilityFocused($focusedField, equals: .email)
// on failure:  focusedField = .email
```

This is **VoiceOver** focus — keyboard `@FocusState` (hardware-keyboard / text-field focus) is
`audit-swiftui-controls-forms`' seam; do not double-own. Different wrappers, different assistive paths.

## Sources

- Apple — `accessibilityElement(children:)` (iOS 13): `https://sosumi.ai/documentation/swiftui/view/accessibilityelement(children:)`;
  `accessibilityValue(_:)` (iOS 14): `https://sosumi.ai/documentation/swiftui/view/accessibilityvalue(_:)`;
  `AccessibilityFocusState` (iOS 15): `https://sosumi.ai/documentation/swiftui/accessibilityfocusstate` (via Sosumi; access 2026-06-16).
- `accessibilityAdjustableAction` (iOS 13): `https://sosumi.ai/documentation/swiftui/view/accessibilityadjustableaction(_:)` (access 2026-06-16).
- Practice consensus + `co_occurs_with` from the bundled `swiftui-ctx` corpus (`lookup accessibilityValue --platform ios`, 2026-06-16).
