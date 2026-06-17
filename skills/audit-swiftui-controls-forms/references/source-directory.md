# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
controls/forms claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file
is the controls-specific *map* of which pages to fetch. The **practice** side (consensus shape + permalinked
example) comes from `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK · project floor iOS 17.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …` line.
   Cross-check `introduced_ios` from `swiftui-ctx lookup <api> --platform ios --json` against it and against
   `floors-master.md`. A `lookup` **exit 3** (with a did-you-mean `suggestion`) corroborates "no iOS arm / no
   corpus usage" — likely a hallucination or a non-iOS symbol.
2. **No platform-wrong cases in this domain on iOS.** Unlike macOS, `.pickerStyle(.wheel)` / `WheelPickerStyle`
   is a **native iOS** picker style (`introduced_ios 13.0`) — never gate or replace it for existing. An iOS
   `Form` is grouped by default, so a missing `.formStyle(.grouped)` is **not** a defect.
3. **The iOS-17 project floor.** Every symbol in this domain (`keyboardType` 13.0, `pickerStyle` 13.0,
   `textFieldStyle` 13.0, `autocorrectionDisabled` 13.0, `help` 14.0, `textInputAutocapitalization` 15.0,
   `submitLabel` 15.0, `controlSize` 15.0, `@FocusState`/`.focused` 15.0, `formStyle` 16.0,
   `scrollDismissesKeyboard` 16.0, `focusable` 17.0) is **at or below iOS 17** — none need a `#available` gate.
4. **Seam deferral.** Tap/long-press/`swipeActions` → `touch-gestures`; VoiceOver focus / labels →
   `accessibility`; `controlSize` as a layout axis → `layout-and-tables`; `.buttonStyle(.glass)` →
   `liquid-glass`; navigation container → `adaptive-navigation`.

---

## A. SwiftUI controls / text-input / focus symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are
the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `keyboardType(_:)` (`.numberPad`/`.decimalPad`/`.emailAddress`/`.URL`/`.phonePad`) | `view/keyboardtype(_:)` |
| `textInputAutocapitalization(_:)` (`.never`/`.words`/`.sentences`/`.characters`) | `view/textinputautocapitalization(_:)` |
| `autocorrectionDisabled(_:)` | `view/autocorrectiondisabled(_:)` |
| `textFieldStyle(_:)` (`.roundedBorder`/`.plain`/`.automatic`) | `view/textfieldstyle(_:)` |
| `submitLabel(_:)` (`.done`/`.next`/`.go`/`.search`/`.send`/`.return`) | `view/submitlabel(_:)` |
| `focused(_:equals:)` / `@FocusState` | `view/focused(_:equals:)` · `focusstate` |
| `onSubmit(_:_:)` | `view/onsubmit(of:_:)` |
| `pickerStyle(_:)` (`.segmented`/`.menu`/`.navigationLink`/`.wheel`/`.inline`) | `view/pickerstyle(_:)` |
| `WheelPickerStyle` / `.pickerStyle(.wheel)` (**native iOS** — iOS 13.0+) | `wheelpickerstyle` |
| `controlSize(_:)` / `ControlSize` (`.mini`/`.small`/`.regular`/`.large`/`.extraLarge`) | `view/controlsize(_:)` · `controlsize` |
| `scrollDismissesKeyboard(_:)` | `view/scrolldismisseskeyboard(_:)` |

**No platform-wrong symbols in this domain on iOS.** `.pickerStyle(.wheel)` is native; an ungrouped-looking
`Form` is the iOS default (grouped), not a defect.

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Text fields | `design/human-interface-guidelines/text-fields` | keyboard type, return-key label, autocorrection (cf-01/02/04) |
| HIG — Pickers | `design/human-interface-guidelines/pickers` | segmented vs wheel vs menu vs list on iOS (cf-05) |
| Managing text input | `documentation/swiftui/focusstate` · `documentation/swiftui/view/focused(_:equals:)` | `@FocusState` keyboard focus + field advance on iOS (cf-06) |
| HIG — Settings | `design/human-interface-guidelines/settings` | the grouped iOS settings `Form` (already the default) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2021/10018 | Direct and reflect focus in SwiftUI | `@FocusState`, `.focused(_:equals:)`, field advance (cf-06) |
| wwdc2021/10058 | The SwiftUI cookbook for navigation | pushed `.navigationLink` pickers, forms in a stack (cf-05) |
| wwdc2023/10054 | What's new in SwiftUI | text-entry + control refinements on iOS (cf-01/02/04) |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Sarunw | `sarunw.com/posts/swiftui-keyboard-type/` | `.keyboardType` cases on iOS (cf-01) | medium |
| Sarunw | `sarunw.com/posts/swiftui-textfield-style/` | `.textFieldStyle(.roundedBorder)` on iOS (cf-03) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui` (FocusState / submitLabel articles) | `@FocusState` field advance + `.submitLabel` (cf-04/06) | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
