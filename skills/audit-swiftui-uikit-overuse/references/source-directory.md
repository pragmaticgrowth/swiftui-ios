# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
overuse claim (does the SwiftUI replacement exist? at this floor? does it cover the UIKit control's
behavior?). **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the overuse-specific *map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK · iOS 17 deployment floor.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the SwiftUI replacement exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. Also run `swiftui-ctx lookup <api> --platform ios --json` for the practice-side `introduced_ios`
   + consensus shape; a `lookup` exit-3 (not-found / no-iOS-arm) means the name is unused in shipping iOS
   apps — re-check it.
2. **Does it cover the UIKit control's behavior?** Read the SwiftUI doc's modifiers + the
   `co_occurs_with` list from `swiftui-ctx`. If a capability is missing (rich-text layout, cell-reuse
   grid, inputAccessoryView, paging/zoom scroll), the bridge may be a justified hatch, not overuse.
3. **Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.** Fall back to
   Sosumi (it never 404s on a valid human URL).

## A. SwiftUI replacement-symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`).

| Replaces (UIKit) | SwiftUI symbol | Path |
|---|---|---|
| `UILabel` / `UIButton` | `Text` · `Button` | `text` · `button` |
| `UISwitch` / `UISlider` | `Toggle` · `Slider` | `toggle` · `slider` |
| `UITextField` / `UITextView` (26) | `TextField` · `TextEditor` | `textfield` · `texteditor` |
| `UIStepper` / `UIDatePicker` | `Stepper` · `DatePicker` | `stepper` · `datepicker` |
| color well | `ColorPicker` | `colorpicker` |
| `UIProgressView` / `UIActivityIndicatorView` | `ProgressView` | `progressview` |
| `UISegmentedControl` / `UIPickerView` | `Picker` | `picker` |
| `UIScreen.main(.bounds)` | `GeometryReader` · `containerRelativeFrame(_:)` | `geometryreader` · `view/containerrelativeframe(_:)` |
| `UIApplication.shared.windows` | `scenePhase` | `scenephase` |
| `UIPasteboard` | `PasteButton` + `Transferable` | `pastebutton` · `coretransferable/transferable` (CoreTransferable) |
| `UIVisualEffectView` | `.glassEffect(_:in:)` · `Material` | `view/glasseffect(_:in:)` · `material` |

## B. UIKit pages (confirm an escape hatch is genuinely beyond SwiftUI)

| Page | Path |
|---|---|
| `UITextView` (rich-text engine) | `documentation/uikit/uitextview` |
| `UICollectionView` (cell-reuse / compositional layout) | `documentation/uikit/uicollectionview` |
| `UIScreen.main` (deprecation note) | `documentation/uikit/uiscreen/main` |
| `UIViewRepresentable` (the bridge contract) | `documentation/swiftui/uiviewrepresentable` |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2022/10072 | Use SwiftUI with UIKit | bridge only the piece that needs it; prefer native SwiftUI |
| wwdc2023/10148 | What's new in SwiftUI | `PasteButton`/`Transferable` ergonomics; `containerRelativeFrame` |
| wwdc2025/256 | What's new in SwiftUI | iOS-26 rich-text `TextEditor`; native surfaces that retire bridges |

## D. Practitioners (corroboration only — never primary; label `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| swiftui-ctx `recipe uiview-bridge` | (bundled CLI) | what a real bridge wraps (judge overuse vs justified) | high |
| swiftui-ctx `recipe draggable-reorder` | (bundled CLI) | the `Transferable` drag/drop/paste pattern | high |
| swiftui-ctx `bridges <kind>` | (bundled CLI) | the corpus census of UIKit bridges (1,007) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- swiftui-ctx CLI contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
