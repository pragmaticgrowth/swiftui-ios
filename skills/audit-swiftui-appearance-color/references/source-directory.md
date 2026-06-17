# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
appearance/color claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the appearance-specific *map*
of which pages to fetch. Floor values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17+ (iPhone & iPad) · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. Absence from the SwiftUI/Foundation index = treat as hallucinated until proven (corroborate with
   a `swiftui-ctx lookup --platform ios` exit-3). Note `UIColor` & the system colors live in the **UIKit**
   index (`documentation/uikit/uicolor`), not SwiftUI — they are real iOS types, bridged by `Color(uiColor:)`.
2. **Is it deprecated?** For ac-03/ac-04 run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx
   deprecated <api>` and cross-check the Sosumi "Deprecated" banner — `foregroundColor` → `foregroundStyle`
   and `accentColor` → `tint` are both confirmed deprecated in the corpus.
3. **Never** `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.

---

## A. SwiftUI / Foundation symbol map

Human doc path = `developer.apple.com/documentation/<framework>/<path>` (fetch via `sosumi.ai/...`).

| Symbol | Path | Floor |
|---|---|---|
| `Color` | `swiftui/color` | iOS 13.0+ |
| `Color(_:bundle:)` (named asset color) | `swiftui/color/init(_:bundle:)` | iOS 13.0+ |
| `Color(uiColor:)` (UIKit bridge) | `swiftui/color/init(uicolor:)` | iOS 13.0+ |
| `UIColor` system colors (`label`, `systemBackground`, `systemGroupedBackground`, …) | `uikit/uicolor` | iOS 13.0+ |
| `foregroundStyle(_:)` | `swiftui/view/foregroundstyle(_:)` | iOS 15.0+ |
| `foregroundColor(_:)` (deprecated) | `swiftui/view/foregroundcolor` | iOS 13.0+ (deprecated) |
| `tint(_:)` (Color & ShapeStyle overloads) | `swiftui/view/tint(_:)` | iOS 15.0+ |
| `accentColor(_:)` (deprecated) | `swiftui/view/accentcolor` | iOS 13.0+ (deprecated) |
| `Material` (`ultraThinMaterial`/`regularMaterial`…) | `swiftui/material` | iOS 15.0+ |
| `preferredColorScheme(_:)` | `swiftui/view/preferredcolorscheme(_:)` | iOS 13.0+ |
| `EnvironmentValues.colorScheme` | `swiftui/environmentvalues/colorscheme` | iOS 13.0+ |
| `EnvironmentValues.colorSchemeContrast` | `swiftui/environmentvalues/colorschemecontrast` | iOS 13.0+ |

**Absent from the index → hallucinated (never a SwiftUI modifier):** `.textColor(_:)`,
`.backgroundColor(_:)`, `.tintColor(_:)`, `.foregroundColour(_:)`. (`UIColor` is **not** here — it is a
real UIKit type bridged into SwiftUI on iOS.) See `_shared/hallucination-blacklist.md`.

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Color (iOS) | `design/human-interface-guidelines/color` | semantic + system colors, Dark variants |
| HIG — Dark Mode | `design/human-interface-guidelines/dark-mode` | appearance, not forcing scheme |
| HIG — Materials | `design/human-interface-guidelines/materials` | vibrancy, chrome fills |
| UIKit standard colors (system colors) | `documentation/uikit/uicolor/standard_colors` | `label`/`systemBackground`/grouped variants |
| Asset catalog color sets | `documentation/xcode/specifying-your-apps-color-scheme` | Any/Dark/High-Contrast variants |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2019/214 | Implementing Dark Mode on iOS | semantic/system colors, asset variants |
| wwdc2021/10018 | What's new in SwiftUI | `Material`, `ShapeStyle` hierarchy |
| wwdc2025/256 | What's new in SwiftUI | appearance + deprecations guidance |

## D. Practitioners (corroboration only — never primary; label findings low-confidence / verified-by-research)

| Source | Reliable for | Trust |
|---|---|---|
| Majid Jabrayilov — swiftwithmajid.com | `ShapeStyle` hierarchy, `Material`, environment colors | high |
| Hacking with Swift | asset-catalog colors, `colorScheme` environment | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Corpus consensus/recommended examples via `swiftui-ctx lookup --platform ios` (`foregroundStyle`,
  `tint`, `Material`) and `deprecated` (`foregroundColor`, `accentColor`), accessed 2026-06-16.
