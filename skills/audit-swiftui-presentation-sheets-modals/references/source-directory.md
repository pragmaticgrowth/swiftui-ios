# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map · iOS)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
presentation/sheet/modal claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`;
this file is the presentation-specific *map* of which pages to fetch. The **practice** side (consensus shape +
permalinked example) comes from `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor
values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …` line.
   Cross-check `introduced_ios` from `swiftui-ctx lookup <api> --platform ios --json` (surfaces at
   `result.introduced_ios`, NOT `result.availability`) against it and against `floors-master.md`. Absence of
   an iOS arm = no-iOS-arm symbol — a `lookup` **exit 3** corroborates it.
2. **The iOS-16 inflection.** `presentationDetents` / `presentationDragIndicator` are **iOS 16.0**;
   `presentationBackground` / `presentationContentInteraction` / `presentationCompactAdaptation` /
   `presentationBackgroundInteraction` are **iOS 16.4**. At the iOS-17 deployment floor all are
   unconditional. The reconciled floor in `floors-master.md` wins.
3. **Modality cases.** A `.fullScreenCover` is legitimate only for immersive / no-dismiss flows; a `.popover`
   needs `.presentationCompactAdaptation` to survive compact width as a popover. Confirm the recipe shapes via
   `swiftui-ctx recipe sheet-detents` and `swiftui-ctx recipe fullscreen-cover-flow`.
4. **Seam deferral.** Keyboard inside a sheet → `safe-area-keyboard`; present-vs-push → `adaptive-navigation`;
   size-class layout of the presented content → `adaptive-layout`.

---

## A. SwiftUI presentation symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are
the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `sheet(isPresented:onDismiss:content:)` / `sheet(item:…)` | `view/sheet(ispresented:ondismiss:content:)` |
| `fullScreenCover(isPresented:…)` / `fullScreenCover(item:…)` | `view/fullscreencover(ispresented:ondismiss:content:)` |
| `popover(isPresented:attachmentAnchor:arrowEdge:content:)` | `view/popover(ispresented:attachmentanchor:arrowedge:content:)` |
| `presentationDetents(_:)` / `presentationDetents(_:selection:)` (**iOS 16.0+**) | `view/presentationdetents(_:)` |
| `PresentationDetent` (`.medium`/`.large`/`.fraction(_:)`/`.height(_:)`) | `presentationdetent` |
| `presentationDragIndicator(_:)` (**iOS 16.0+**) | `view/presentationdragindicator(_:)` |
| `presentationBackground(_:)` / `presentationBackground { }` (**iOS 16.4+**) | `view/presentationbackground(_:alignment:)` |
| `presentationContentInteraction(_:)` (**iOS 16.4+**) | `view/presentationcontentinteraction(_:)` |
| `presentationCompactAdaptation(_:)` (**iOS 16.4+**) | `view/presentationcompactadaptation(_:)` |
| `presentationBackgroundInteraction(_:)` (**iOS 16.4+**) | `view/presentationbackgroundinteraction(_:)` |
| `presentationCornerRadius(_:)` (**iOS 16.4+**) | `view/presentationcornerradius(_:)` |

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Sheets | `design/human-interface-guidelines/sheets` (verify exact path against current HIG) | partial vs full sheets; detents; grab handle (psm-01/02) |
| HIG — Modality | `design/human-interface-guidelines/modality` | when a full-screen cover vs a dismissible sheet is right (psm-03) |
| HIG — Popovers | `design/human-interface-guidelines/popovers` | popovers are a regular-width affordance; compact adaptation (psm-04) |
| Presentation modifiers | `documentation/swiftui/view-presentation` | detents, background, content interaction (psm-01/05) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2022/10054 | What's new in SwiftUI | `presentationDetents`, the resizable sheet (psm-01/02) |
| wwdc2023/10093 | Beyond the basics of structured concurrency | (n/a — modal lifecycle context only) |
| wwdc2022/110492 | Bring multiple windows to your SwiftUI app | sheet-vs-window-vs-cover modality decisions (psm-03) |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Sarunw | `sarunw.com/posts/swiftui-sheet-presentationdetents/` | `presentationDetents` medium/large/custom on iOS 16 (psm-01) | medium |
| Sarunw | `sarunw.com/posts/swiftui-popover/` | `.popover` and compact adaptation on iPhone (psm-04) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-resize-a-sheet-to-fit-its-content-using-presentation-detents` | detents + drag indicator (psm-01/02) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
