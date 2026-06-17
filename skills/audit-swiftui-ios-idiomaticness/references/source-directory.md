# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map, iOS pages)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence idiom
call (does the iOS-idiomatic affordance exist? at this iOS floor? does the deprecated habit really have
a SwiftUI replacement?). **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the idiom-specific *map* of
which pages to fetch. Floor values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · iPad modeled within `ios` · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the iOS-idiomatic affordance exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. Also run `swiftui-ctx lookup <api> --platform ios --json` for the practice-side
   `result.introduced_ios` + `result.consensus` shape; a `lookup` **exit 3** (not-found) means the name
   is unused in shipping iOS apps / likely no-iOS-arm — re-check it.
2. **Does the deprecated habit really have a SwiftUI replacement?** `swiftui-ctx deprecated <api> --json`
   → `replacement` / `migrate_to` / `note`. If the corpus has no replacement, the call may be a justified
   hatch, not a smell — route conservatively.
3. **Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.** Fall back to
   Sosumi (it never 404s on a valid human URL).

---

## Page map (fetch via Sosumi in VERIFY)

| Smell | Apple-doc path (prefix `https://sosumi.ai`) | Confirms |
|---|---|---|
| idi-01, idi-08 | `/documentation/swiftui/navigationstack` · `/documentation/swiftui/navigationsplitview` · `/documentation/swiftui/navigationview` (deprecation) · `/documentation/swiftui/view/navigationtitle(_:)-string` | the `NavigationStack`/`SplitView` idiom + `navigationBarTitle` deprecation |
| idi-02 | `/documentation/swiftui/view/onhover(perform:)` · `/documentation/swiftui/view/pointerstyle(_:)` | `.onHover` iOS 13.4+ / `pointerStyle` — pointer affordances, iPad-pointer only |
| idi-03, idi-07 | `/documentation/swiftui/environmentvalues/horizontalsizeclass` · `/documentation/swiftui/view/containerrelativeframe(_:alignment:)` · `/documentation/swiftui/viewthatfits` · `/documentation/swiftui/table` | size-class / adaptive-frame idiom; `Table` compact-collapse |
| idi-04 | `/documentation/swiftui/view/sheet(ispresented:ondismiss:content:)` · `/documentation/swiftui/view/presentationdetents(_:)` · `/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)` | `.sheet` + detents vs `.fullScreenCover` modality |
| idi-05 | `/documentation/swiftui/tabview` · `/documentation/swiftui/tab` | `TabView` top-level-peer idiom + the iPhone More-tab collapse |
| idi-06 | `/documentation/uikit/uiscreen` (deprecation) · `/documentation/swiftui/geometryreader` | `UIScreen.main` deprecation → SwiftUI geometry source |
| idi-09 | `/documentation/uikit/uiapplication/windows` (deprecation) · `/documentation/uikit/uiwindowscene` | `UIApplication.shared.windows`/`keyWindow` deprecation → scene source |

---

## Practitioner / WWDC anchors (context for the idiom rubric)

- **WWDC22 "The SwiftUI cookbook for navigation"** — the `NavigationStack`/`NavigationSplitView` model
  that retires `NavigationView` (idi-01/05/08).
- **WWDC22/23 "Bring multiple windows to your SwiftUI app" / sheets sessions** — `presentationDetents`,
  `.presentationDragIndicator` (idi-04).
- **WWDC22 "Compose custom layouts with SwiftUI" + size-class HIG** — adaptive layout over fixed frames
  (idi-03/07).
- **HIG → Navigation / Modality / Tab bars** — the idiom baselines the score benchmarks against.

Always re-confirm the live floor in `swiftui-ctx` + Sosumi before scoring; this map is the *where*, not
the *truth*.
