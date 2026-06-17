# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
navigation/toolbar claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the navigation-specific *map*
of which pages to fetch. **The practice half is `swiftui-ctx`** — run `lookup <api> --platform ios --json`
/ `deprecated <api>` per `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values
live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17+ deployment floor (iPhone + iPad) · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Spec — does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. A placement *absent* from the iOS arm = platform-wrong (replace, never gate). Read **only the iOS
   arm** per `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.
2. **Practice — how do shipping iOS apps write it + is it deprecated-in-the-wild?**
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` → `introduced_ios`,
   `deprecated`+`migrate_to`/`replacement`, the consensus shape, the `recommended` permalink,
   `co_occurs_with`. A `lookup` **exit 3** (no iOS arm) corroborates a platform-wrong finding.
3. **Type-property floors** can inherit the enclosing type's floor in DocC — cross-check against WWDC
   provenance per the shared sosumi reference §4.

---

## A. SwiftUI navigation/toolbar symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floor
values are reconciled in `floors-master.md`.

| Symbol | Path | iOS |
|---|---|---|
| `NavigationStack` (the primary iOS shell) | `navigationstack` | 16.0+ |
| `navigationDestination(for:)` | `view/navigationdestination(for:destination:)` | 16.0+ |
| `NavigationSplitView` (gate to regular/iPad) | `navigationsplitview` | 16.0+ |
| `NavigationSplitViewVisibility` | `navigationsplitviewvisibility` | 16.0+ |
| `NavigationView` (deprecated) | `navigationview` | 13.0+ → deprecated |
| `navigationSplitViewColumnWidth(min:ideal:max:)` | `view/navigationsplitviewcolumnwidth(min:ideal:max:)` | 16.0+ (no-op on detail: verify-SDK) |
| `navigationTitle(_:)` | `view/navigationtitle(_:)-43srq` | 13.0+ |
| `navigationBarTitle(_:)` (deprecated) | `view/navigationbartitle(_:)` | 13.0+ → deprecated |
| `navigationBarTitleDisplayMode(_:)` (iOS-only, current) | `view/navigationbartitledisplaymode(_:)` | 14.0+ |
| `ToolbarItemPlacement.topBarLeading` / `.topBarTrailing` (current) | `toolbaritemplacement/topbarleading` | 14.0+ |
| `ToolbarItemPlacement.bottomBar` (current) | `toolbaritemplacement/bottombar` | 14.0+ |
| `ToolbarItemPlacement.navigationBarLeading` / `.navigationBarTrailing` (deprecated) | `toolbaritemplacement/navigationbarleading` | 14.0+ → deprecated |
| `ToolbarSpacer` / `SpacerSizing` | `toolbarspacer` · `spacersizing` | 26.0+ |
| `searchable(text:placement:prompt:)` | `view/searchable(text:placement:prompt:)-18a8f` | 16.0+ |
| `searchToolbarBehavior(_:)` (`.minimize` iOS/iPadOS) | `view/searchtoolbarbehavior(_:)` | 26.0+ |
| `inspector(isPresented:content:)` / `inspectorColumnWidth(_:)` | `view/inspector(ispresented:content:)` | 17.0+ |
| `ContentUnavailableView` | `contentunavailableview` | 17.0+ |
| `SidebarListStyle` (`.sidebar`) | `sidebarliststyle` | 13.0+ |

**Deprecated (replace on an iOS target):** `NavigationView` (→ `NavigationStack`/`NavigationSplitView`),
`navigationBarTitle` (→ `navigationTitle`), `.navigationBarLeading`/`.navigationBarTrailing`
(→ `.topBarLeading`/`.topBarTrailing`). **Current and correct on iOS (do NOT flag):** `.topBarLeading`,
`.topBarTrailing`, `.bottomBar`, `navigationBarTitleDisplayMode`.

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| Migrating to new navigation types | `documentation/swiftui/migrating-to-new-navigation-types` | `NavigationView` → split/stack; column semantics |
| HIG — Navigation bars | `design/human-interface-guidelines/navigation-bars` (verify exact path) | iOS bar placement intent |
| HIG — Split views | `design/human-interface-guidelines/split-views` (verify exact path) | iPad multi-column idiom; compact collapse |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<YYYY>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2022/10054 | The SwiftUI cookbook for navigation | `NavigationStack`/`navigationDestination`/`NavigationSplitView`, the column model |
| wwdc2023/10161 | Inspectors in SwiftUI | `.inspector(isPresented:)`, 225 pt, compact → sheet |
| wwdc2025/256 | What's new in SwiftUI | `ToolbarSpacer`, `searchToolbarBehavior`, the new design system |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Michael Sena | `msena.com/posts/three-column-swiftui-macos/` | `navigationSplitViewColumnWidth` no-op on detail | medium |
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-create-a-two-column-or-three-column-layout-with-navigationsplitview` | 2-/3-column inits; compact auto-collapse | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- swiftui-ctx CLI contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
