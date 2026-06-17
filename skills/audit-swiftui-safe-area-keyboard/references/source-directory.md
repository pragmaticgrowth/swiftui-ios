# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map · iOS)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
safe-area / keyboard claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`;
this file is the safe-area/keyboard-specific *map* of which iOS pages to fetch. The **practice** side
(consensus shape + permalinked example) comes from
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK. iPad modeled within `ios`.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …` line.
   Cross-check `introduced_ios` from `swiftui-ctx lookup <api> --platform ios --json` (it surfaces at
   `result.introduced_ios`, **not** under `result.availability`) against it and against `floors-master.md`.
   The reconciled floor in `floors-master.md` wins.
2. **Deprecation, not a low floor.** `.edgesIgnoringSafeArea(_:)` is **deprecated iOS 14.0+** — replaced by
   `.ignoresSafeArea(_:edges:)`. Replace; never gate (sak-04).
3. **UIKit, not a SwiftUI symbol.** `keyboardLayoutGuide` is `UIView.keyboardLayoutGuide` (UIKit, iOS 15.0) —
   `swiftui-ctx lookup keyboardLayoutGuide` is **not-found** ("did you mean keyboardShortcut…"). In SwiftUI the
   equivalent is the automatic keyboard safe area + `.ignoresSafeArea(.keyboard)`; a `keyboardLayoutGuide`
   reference means a UIKit bridge → `cross_ref: uikit-interop`. Carry its floor as **verify against Xcode 26 SDK**.
4. **Seam deferral.** Keyboard inside a presented sheet/detent → `presentation-sheets-modals`; insets shifting
   by size class → `adaptive-layout`; the inset bar's internal arrangement → `layout-and-tables`; the
   scroll-dismiss *control style* on a `Form` → `controls-forms`.

---

## A. SwiftUI safe-area / keyboard symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are the
reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `ignoresSafeArea(_:edges:)` (iOS 14.0; `.container`/`.keyboard` regions) | `view/ignoressafearea(_:edges:)` |
| `safeAreaInset(edge:alignment:spacing:content:)` (iOS 15.0) | `view/safeareainset(edge:alignment:spacing:content:)` |
| `scrollDismissesKeyboard(_:)` (iOS 16.0; `.interactive`/`.immediately`/`.never`/`.automatic`) | `view/scrolldismisseskeyboard(_:)` |
| `safeAreaPadding(_:_:)` (iOS 17.0) | `view/safeareapadding(_:)` |
| `contentMargins(_:_:for:)` (iOS 16.1) | `view/contentmargins(_:_:for:)` |
| `SafeAreaRegions` (`.container`/`.keyboard`/`.all`) | `safearearegions` |
| `ScrollDismissesKeyboardMode` | `scrolldismisseskeyboardmode` |
| `.edgesIgnoringSafeArea(_:)` (**deprecated iOS 14.0+** — sak-04) | `view/edgesignoringsafearea(_:)` |
| `keyboardLayoutGuide` (**UIKit** `UIView.keyboardLayoutGuide`, iOS 15.0 — not a SwiftUI symbol) | `documentation/uikit/uiview/keyboardlayoutguide` |

**Deprecation trap (real but wrong on iOS):** `.edgesIgnoringSafeArea(_:)` — replace with `.ignoresSafeArea`,
never gate. **UIKit-only:** `keyboardLayoutGuide` — bridge smell, `cross_ref: uikit-interop`.

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Layout (safe areas, margins) | `design/human-interface-guidelines/layout` | keep content inside the safe area; the home-indicator / Dynamic Island regions (sak-01/03) |
| Adding a safe-area inset | `documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)` | reserving space for a bottom bar (sak-03) |
| Keyboard avoidance / focus | `documentation/swiftui/view/scrolldismisseskeyboard(_:)` · `documentation/swiftui/view/ignoressafearea(_:edges:)` | dismissing the keyboard, opting out of the keyboard safe area (sak-02/05) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2021/10018 | Add rich graphics to your SwiftUI app | `safeAreaInset`, background bleed vs content (sak-01/03) |
| wwdc2023/10054 | Build accessible apps with SwiftUI and UIKit | keyboard + safe-area interaction, Dynamic-Type growth (sak-02) |
| wwdc2020/10041 | Build a SwiftUI view in Swift Playgrounds | safe-area and `ignoresSafeArea` basics (sak-01) |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Sarunw | `sarunw.com/posts/swiftui-keyboard-avoidance/` | SwiftUI automatic keyboard avoidance + `scrollDismissesKeyboard` (sak-02/05) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-dismiss-the-keyboard-when-the-user-scrolls` | `scrollDismissesKeyboard` usage (sak-02) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-place-content-in-the-safe-area-with-safeareainset` | `safeAreaInset` bottom bar (sak-03) | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
