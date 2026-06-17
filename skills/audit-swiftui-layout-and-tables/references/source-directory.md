# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
layout/Table claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the layout-specific *map* of which pages to fetch. The **practice** side (consensus shape +
permalinked example) comes from `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor
values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 26 · iOS-17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line — **read only the iOS arm** (`ios-gating.md` §4). Cross-check `introduced_ios` from
   `swiftui-ctx lookup <api> --platform ios --json` against it and against `floors-master.md`.
2. **iOS-ABSENT check.** A `swiftui-ctx lookup … --platform ios` **exit 3** means the symbol has **no iOS
   arm** — it is macOS-only (`alternatingRowBackgrounds`, `TableColumnForEach`, `defaultSize`,
   `windowResizability`) and must **not** be flagged or suggested on an iOS target. A `lookup` exit 3
   *with* a did-you-mean suggestion can instead corroborate a hallucination — disambiguate with Sosumi.
3. **No iOS deprecation rule here.** The macOS-only `tableStyle(.inset(alternatesRowBackgrounds:))`
   deprecation does **not apply to iOS** — `alternatingRowBackgrounds` is iOS-ABSENT, so there is nothing
   to migrate to. Don't carry a deprecation finding for it on iOS.

---

## A. SwiftUI layout / Table / sizing symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors
are the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path | Note |
|---|---|---|
| `Table` / `TableColumn` / `TableRow` | `table` · `tablecolumn` · `tablerow` | iOS 16.0; collapses to 1 column on compact |
| `KeyPathComparator` (Foundation) | `documentation/foundation/keypathcomparator` | sort comparator |
| `controlSize(_:)` / `ControlSize` | `view/controlsize(_:)` · `controlsize` | iOS 15.0; `.small`/`.mini` are a Mac idiom |
| `fixedSize()` / `fixedSize(horizontal:vertical:)` | `view/fixedsize()` · `view/fixedsize(horizontal:vertical:)` | iOS 13.0 |
| `layoutPriority(_:)` | `view/layoutpriority(_:)` | iOS 13.0 |
| `containerRelativeFrame(_:alignment:)` | `view/containerrelativeframe(_:alignment:)` | iOS 17.0 |
| `Layout` (protocol) / `Grid` / `GridRow` / `ViewThatFits` | `layout` · `grid` · `gridrow` · `viewthatfits` | iOS 16.0 |
| `horizontalSizeClass` / `verticalSizeClass` (the width gate) | `environmentvalues/horizontalsizeclass` · `environmentvalues/verticalsizeclass` | the iOS adaptive idiom |
| **iOS-ABSENT** `alternatingRowBackgrounds` · `TableColumnForEach` · `defaultSize` · `windowResizability` | — | macOS-only; do NOT flag on iOS |

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| Layout (HIG) | `design/human-interface-guidelines/layout` | size classes, 44pt touch targets, adaptivity |
| Tables (HIG) | `design/human-interface-guidelines/tables` (verify exact path) | when a table fits iPad vs a list on iPhone |
| Layout fundamentals | `documentation/swiftui/layout-fundamentals` | frame, priority, fixedSize, custom `Layout` overview |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2022/10056 | Compose custom layouts with SwiftUI | the `Layout` protocol, `Grid`, `ViewThatFits` (when to hand-roll vs built-in) |
| wwdc2022/10054 | The SwiftUI cookbook for navigation | adaptive `NavigationStack`/`NavigationSplitView` on iPhone vs iPad |
| wwdc2021/10018 | Add rich graphics to your SwiftUI app | `Table` on iPad, `controlSize`, size-class adaptation |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Sarunw | `sarunw.com/posts/swiftui-table/` | `Table`/`TableColumn`/`sortOrder` wiring (note: read iOS caveats) | medium |
| Majid Jabrayilov | `swiftwithmajid.com/2022/06/22/building-custom-layout-in-swiftui/` | the custom `Layout` protocol (lt-05) | high |
| Majid Jabrayilov | `swiftwithmajid.com/2022/12/06/adapting-layout-in-swiftui/` | `ViewThatFits`/size-class adaptive layout on iOS | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- iOS gating + the iOS-arm reading rule: `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
