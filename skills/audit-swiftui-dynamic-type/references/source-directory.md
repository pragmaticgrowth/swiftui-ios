# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map · iOS)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence Dynamic
Type claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI commands and
the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the
Dynamic-Type-specific *map* of which pages to fetch. The **practice** side (consensus shape + permalinked
example) comes from `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …` line.
   Cross-check `introduced_ios` from `swiftui-ctx lookup <api> --platform ios --json` (surfaces at
   `result.introduced_ios`, NOT `result.availability`) against it and against `floors-master.md`. Absence of
   an iOS arm = no-iOS-arm symbol — a `lookup` **exit 3** corroborates it.
2. **The scaling floors.** `font` text styles / `minimumScaleFactor` are **iOS 13.0**; `@ScaledMetric` is
   **iOS 14.0**; `dynamicTypeSize` / `DynamicTypeSize` / `\.isAccessibilitySize` are **iOS 15.0**. At the
   iOS-17 deployment floor all are unconditional. The reconciled floor in `floors-master.md` wins.
3. **The UIKit bridge has no SwiftUI catalog entry.** `UIFontMetrics(forTextStyle:).scaledFont(for:)` and
   `adjustsFontForContentSizeCategory` are **UIKit** — `swiftui-ctx lookup` exits 3 for them. Cite the
   well-known **iOS 11** introduction from Sosumi/the SDK and mark `availability: verify against Xcode 26 SDK`;
   never fabricate a SwiftUI-catalog floor for them.
4. **Seam deferral.** Font craft / `AttributedString` → `typography-text`; Dynamic Type as an a11y obligation /
   `accessibilityShowsLargeContentViewer` → `accessibility`; reflow at large sizes → `adaptive-layout`; scaled
   rows in a `List`/`Table` → `layout-and-tables`.

---

## A. SwiftUI Dynamic Type symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are
the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `font(_:)` (text styles `.body`/`.headline`/`.title`/…) | `view/font(_:)` |
| `Font.system(_:design:weight:)` (text-style init) | `font/system(_:design:weight:)` |
| `Font.TextStyle` (`.body`/`.largeTitle`/`.caption2`…) | `font/textstyle` |
| `@ScaledMetric` (`ScaledMetric(wrappedValue:relativeTo:)`, **iOS 14.0+**) | `scaledmetric` |
| `dynamicTypeSize(_:)` / `dynamicTypeSize(_:)` range (**iOS 15.0+**) | `view/dynamictypesize(_:)` |
| `DynamicTypeSize` (`.xSmall`…`.accessibility5`) (**iOS 15.0+**) | `dynamictypesize` |
| `minimumScaleFactor(_:)` (**iOS 13.0+**) | `view/minimumscalefactor(_:)` |
| `\.isAccessibilitySize` environment value (**iOS 15.0+**) | `environmentvalues/isaccessibilitysize` |
| `lineLimit(_:)` / `allowsTightening(_:)` / `truncationMode(_:)` | `view/linelimit(_:)` |
| `UIFontMetrics` (UIKit bridge — **verify against Xcode 26 SDK**, iOS 11) | `uikit/uifontmetrics` |
| `adjustsFontForContentSizeCategory` (UIKit — **verify against SDK**, iOS 10) | `uikit/uicontentsizecategoryadjusting/adjustsfontforcontentsizecategory` |

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Typography | `design/human-interface-guidelines/typography` (verify exact path against current HIG) | Dynamic Type, text styles, supporting Larger Text (dt-01/02) |
| Applying custom fonts to text | `documentation/swiftui/applying-custom-fonts-to-text` | scaling a custom font with `relativeTo:` (dt-01/03) |
| Scaling fonts automatically (UIKit) | `documentation/uikit/scaling-fonts-automatically` | `UIFontMetrics` bridge (UIKit interop) |
| Accessibility — Text & Dynamic Type | `documentation/accessibility` | Dynamic Type as an a11y obligation (cross_ref accessibility) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2024/10074 | Get started with Dynamic Type | text styles, `@ScaledMetric`, large-content viewer (dt-01/03) |
| wwdc2023/10078 | Animate with springs | (n/a — unrelated; placeholder, confirm session before citing) |
| wwdc2022/10027 | What's new in SwiftUI | Dynamic Type refinements (dt-04) |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-use-dynamic-type-with-a-custom-font` | `@ScaledMetric` and `relativeTo:` (dt-03) | high |
| Sarunw | `sarunw.com/posts/dynamic-type-in-swiftui/` | text styles vs fixed sizes; `dynamicTypeSize` (dt-01/04) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-limit-the-dynamic-type-size-of-a-view` | `dynamicTypeSize` capping (dt-04) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- UIKit-bridge symbols (`UIFontMetrics`, `adjustsFontForContentSizeCategory`) are not in the SwiftUI catalog —
  floors marked **verify against Xcode 26 SDK** per the rule in the SKILL body.
- Practitioner URLs as listed (trust labelled; corroboration only).
</content>
