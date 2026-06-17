# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
localization claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the localization-specific *map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-07 · iOS 26 (Tahoe) · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + its iOS floor?** Fetch `https://sosumi.ai/<path>` and read the
   `**Available on:** … iOS N+ …` line. Cross-check `introduced_ios` from
   `swiftui-ctx lookup <api> --platform ios --json` against `floors-master.md`.
2. **`String(localized:)` lives under the Swift overlay, not Foundation.** Its doc path is
   `documentation/swift/string/init(localized:...)`, **not** `/documentation/foundation/...` — a common
   wrong guess. Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.
3. **Practice shape:** `swiftui-ctx lookup Text --platform ios` / `lookup LocalizedStringKey --platform ios` gives the consensus call
   shape + a permalinked iOS example; trust it over memory, verify the spec on Sosumi.

---

## A. SwiftUI / Foundation / Swift symbol map

Human doc path = `developer.apple.com/<path>` (fetch via `sosumi.ai/<path>`). Floors per floors-master.

| Symbol | Path | Floor |
|---|---|---|
| `Text` (`LocalizedStringKey` overload) | `documentation/swiftui/text` | iOS 13.0+ |
| `Text.init(_:comment:)` | `documentation/swiftui/text/init(_:tablename:bundle:comment:)` | iOS 13.0+ |
| `Text.init(verbatim:)` | `documentation/swiftui/text/init(verbatim:)` | iOS 13.0+ |
| `Text.init(_:format:)` (FormatStyle overload) | `documentation/swiftui/text/init(_:format:)` | iOS 15.0+ |
| `LocalizedStringKey` | `documentation/swiftui/localizedstringkey` | iOS 13.0+ |
| `LocalizedStringResource` | `documentation/foundation/localizedstringresource` | iOS 16.0+ |
| `String.init(localized:…)` / `String.LocalizationValue` | `documentation/swift/string/init(localized:table:bundle:locale:comment:)` | iOS 15.0+ |
| `FormatStyle` / `.formatted()` | `documentation/foundation/formatstyle` | iOS 15.0+ |
| `InflectionRule` (automatic grammar agreement) | `documentation/foundation/inflectionrule` | iOS 15.0+ |
| `EnvironmentValues.layoutDirection` | `documentation/swiftui/environmentvalues/layoutdirection` | iOS 13.0+ |
| `flipsForRightToLeftLayoutDirection(_:)` | `documentation/swiftui/view/flipsforrighttoleftlayoutdirection(_:)` | iOS 13.0+ |

**Legacy / discouraged for new SwiftUI display code (not absent — flag for *translatability*):**
`NSLocalizedString` (`documentation/foundation/nslocalizedstring(_:tablename:bundle:value:comment:)`),
`String(format:)`, hand-built `DateFormatter`/`NumberFormatter` without `\.locale`.

## B. Apple conceptual / HIG / Xcode pages

| Page | Path | Anchors |
|---|---|---|
| Localizing & varying text with a String Catalog | `documentation/xcode/localizing-and-varying-text-with-a-string-catalog` | `.xcstrings` workflow; comments; extraction |
| Localizing strings that contain plurals | `documentation/xcode/localizing-strings-that-contain-plurals` | `%lld` variations; automatic grammar agreement / `inflect` |
| Preparing views for localization | `documentation/swiftui/preparing-views-for-localization` | literal-vs-variable; comments; previews |
| HIG — Right to left | `design/human-interface-guidelines/right-to-left` | mirroring; directional glyphs; numerals |

## C. WWDC sessions (`developer.apple.com/videos/play/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2023/10155 | Discover String Catalogs | `.xcstrings`; auto-extraction; plurals; comments |
| wwdc2021/10221 | Streamline your localized strings | `String(localized:)`; `LocalizationValue`; comments |
| wwdc2022/10110 | Build global apps: Localization by example | `String(localized:)`; automatic grammar agreement; SwiftUI layout |
| wwdc2022/10107 | Get it right ... to left | RTL mirroring; directional symbols; numerals |

## D. Practitioners (corroboration only — never primary; label `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Apple Developer — Localization | `developer.apple.com/localization/` | catalog + plural workflow | high (Apple) |
| Majid Jabrayilov | `swiftwithmajid.com/2021/09/03/localizing-swiftui-views/` | literal-vs-variable; `LocalizedStringKey` | high |
| Paul Hudson (Hacking with Swift) | `hackingwithswift.com/quick-start/swiftui` (localization articles) | String Catalog; `verbatim:` | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-07).
- Practice shapes from `swiftui-ctx lookup Text` / `lookup LocalizedStringKey` (permalinks in the
  domain references). Practitioner URLs as listed (trust labelled; corroboration only).
