# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map · iOS)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
adaptive-layout claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the layout-specific *map* of which iOS pages to fetch. The **practice** side (consensus shape +
permalinked example) comes from `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor
values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK. iPad modeled within `ios`.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …` line.
   Cross-check `introduced_ios` from `swiftui-ctx lookup <api> --platform ios --json` (it surfaces at
   `result.introduced_ios`, **not** under `result.availability`) against it and against `floors-master.md`.
   The reconciled floor in `floors-master.md` wins.
2. **Deprecation, not a low floor.** `UIScreen.main` / `UIScreen.main.bounds` is **deprecated iOS 16+** — it
   is a UIKit symbol; `swiftui-ctx lookup UIScreen` returns a "looks like a UIKit/AppKit type" note. Replace
   with `GeometryReader` / `horizontalSizeClass`; never gate (adl-02).
3. **Size class is the device test.** `UserInterfaceSizeClass` (`.compact`/`.regular`) via
   `@Environment(\.horizontalSizeClass)` / `verticalSizeClass` is the only correct branch — never a model
   name or a width literal.
4. **Seam deferral.** Split-view column content/titles/toolbar → `adaptive-navigation`; `List`-vs-`Table` /
   `Grid` column counts / `controlSize` sizing → `layout-and-tables`; sheet/popover adaptivity →
   `presentation-sheets-modals`; whether the `UIScreen` bridge should exist → `uikit-overuse`.

---

## A. SwiftUI adaptive-layout symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are
the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `horizontalSizeClass` / `verticalSizeClass` (`UserInterfaceSizeClass`, iOS 13.0) | `environmentvalues/horizontalsizeclass` · `userinterfacesizeclass` |
| `ViewThatFits` (iOS 16.0) | `viewthatfits` |
| `containerRelativeFrame(_:)` (iOS 17.0) | `view/containerrelativeframe(_:alignment:)` |
| `NavigationSplitView` (iOS 16.0) | `navigationsplitview` |
| `NavigationSplitViewVisibility` / `navigationSplitViewColumnWidth` | `navigationsplitviewvisibility` · `view/navigationsplitviewcolumnwidth(_:)` |
| `GeometryReader` / `GeometryProxy` | `geometryreader` · `geometryproxy` |
| `AnyLayout` (iOS 16.0) | `anylayout` |
| `\.supportsMultipleWindows` (iPad multi-window) | `environmentvalues/supportsmultiplewindows` |
| `UIScreen.main` (**UIKit, deprecated iOS 16+** — adl-02) | `documentation/uikit/uiscreen/main` |

**Deprecation trap (real but wrong on iOS):** `UIScreen.main` / `UIScreen.main.bounds` — replace, never gate.

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Layout | `design/human-interface-guidelines/layout` | adapt to size classes / orientation / multitasking (adl-01/04) |
| HIG — Multitasking on iPad | `design/human-interface-guidelines/multitasking` | Split View / Slide Over / Stage Manager (adl-01/02) |
| Building adaptive layouts | `documentation/swiftui/building_layouts_with_stack_views` · `documentation/swiftui/composing_custom_layouts_with_swiftui` | `ViewThatFits` / `AnyLayout` (adl-04/05) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2022/10056 | Compose custom layouts with SwiftUI | `ViewThatFits`, `AnyLayout`, the Layout protocol (adl-05) |
| wwdc2023/10054 | Build accessible apps with SwiftUI and UIKit | size-class + Dynamic-Type-driven layout (adl-04) |
| wwdc2024/10148 | Demystify SwiftUI containers | `containerRelativeFrame` / container-aware sizing (adl-06) |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Sarunw | `sarunw.com/posts/swiftui-viewthatfits/` | `ViewThatFits` usage on iOS (adl-05) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-make-views-adapt-with-viewthatfits` | adaptive layout primitives (adl-05) | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-use-different-layouts-based-on-size-classes` | `horizontalSizeClass` branching (adl-04) | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
