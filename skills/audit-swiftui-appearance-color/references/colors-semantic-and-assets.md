# Reference — Semantic Color, Asset Catalogs & the Deprecated Color Modifiers (ac-01/02/03/04/08)

How shipping iOS apps color a SwiftUI view so it survives Dark Mode, vibrancy, and the deprecation of the
old color modifiers — and the ❌→✅ rewrites for the literal-color and deprecated-modifier defects. Floor /
deprecation *values* are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (read, never restate); the invented-name list
is `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Get the ✅ shape from the corpus,
not memory: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`.

**As of:** 2026-06-16 · iOS 17+ (iPhone & iPad) · Xcode 26 SDK.

---

## The principle

A color must answer "what should this be in Dark Mode / under vibrancy / under Increase Contrast" *for
itself*. A raw RGB literal cannot — it is one fixed appearance. Three ways to make it adaptive:

1. **Semantic SwiftUI system colors** — `.primary`, `.secondary`, `.tertiary`, `.quaternary` (foreground
   hierarchy), `Color.accentColor`, and the role colors (`.red`/`.green`/… resolve per-appearance). These
   adapt automatically.
2. **iOS UI-element system colors** — bridged from UIKit via `Color(uiColor:)` (iOS 13+): foreground
   `Color(.label)` / `Color(.secondaryLabel)` / `Color(.tertiaryLabel)`, fills `Color(.systemBackground)` /
   `Color(.secondarySystemBackground)` / `Color(.tertiarySystemBackground)`, and the grouped-table family
   `Color(.systemGroupedBackground)` / `Color(.secondarySystemGroupedBackground)`. These are the iOS-native
   surface colors — they carry Light/Dark *and* elevated/grouped variants and are the right answer behind a
   `List`/`Form` or a custom grouped surface (a plain `Color(.systemBackground)` under a grouped table is
   the wrong gray on iPhone and iPad).
3. **Named asset-catalog color sets** — `Color("BrandPrimary")` resolves a `*.xcassets` color set that
   carries an **Any Appearance** *and* a **Dark** variant (and optional High-Contrast variants). This is
   the home for a brand color you genuinely need to pin.

## ac-01 — hardcoded literal RGB

❌ `Rectangle().fill(Color(red: 0.13, green: 0.13, blue: 0.15))` — frozen; identical in Light and Dark.

✅ Move it into an asset catalog color set and reference it by name (if the project has `*.xcassets`,
confirmed in ORIENT):
```swift
Rectangle().fill(Color("Surface"))   // "Surface" color set: Any + Dark variants
```
✅ Or, if the literal is really an iOS system surface, reach for the system color directly:
`Rectangle().fill(Color(.secondarySystemBackground))`. ✅ Or, if it is really foreground text/chrome, use
the hierarchy: `.foregroundStyle(.secondary)`. The
exact ✅ shape and a permalinked real example come from `swiftui-ctx lookup foregroundStyle --json`
(`consensus` + `recommended`) and `swiftui-ctx file <id> --smart`.

The tier-2 ast-grep rule `ac-01-hardcoded-rgb.yml` catches the multi-line `red:/green:/blue:` init the
flat grep can't anchor. READ to confirm it is a content fill, not a deliberate brand swatch.

## ac-02 — `Color.white` / `Color.black` / `Color(white:)`

❌ `.background(Color.white)` / `.foregroundColor(Color.black)` — inverts wrongly in Dark Mode (white
panel in a dark app). ✅ an iOS system surface/foreground (`.background(Color(.systemBackground))`,
`.foregroundStyle(.primary)` or `Color(.label)`) or a named asset color. `Color.white`/`.black` are
legitimate *only* for a genuinely appearance-independent mark (a printed-page canvas, a fixed logo) — READ
to decide.

## ac-03 — `.foregroundColor(_:)` deprecated → `.foregroundStyle(_:)`

Confirmed deprecated in the corpus: `swiftui-ctx deprecated foregroundColor` → `replacement:
foregroundStyle`, `doc: https://sosumi.ai/documentation/swiftui/view/foregroundcolor`.

❌ `Text("Hi").foregroundColor(.secondary)` → ✅ `Text("Hi").foregroundStyle(.secondary)`.

**fix_mode: auto** — the same-argument rename `.foregroundColor(x)` → `.foregroundStyle(x)` is
behavior-identical and mechanical. The *craft* upgrade (a literal color → the `.secondary`/`.tertiary`
hierarchy) is `flag-only`. Emit `cross_ref: api-currency` (currency owns the deprecation flag; this skill
owns the replacement craft). `foregroundStyle(_:)` is iOS 15+ and takes a `ShapeStyle` — the consensus
shape from the corpus is `(_)` at 98% (`swiftui-ctx lookup foregroundStyle --platform ios --json`).

## ac-04 — `.accentColor(_:)` deprecated → `.tint(_:)`

Confirmed: `swiftui-ctx deprecated accentColor` → `replacement: tint`,
`doc: https://sosumi.ai/documentation/swiftui/view/accentcolor`.

❌ `.accentColor(.blue)` → ✅ `.tint(.blue)`. **fix_mode: auto** (same-argument rename). Both the
`tint(_ tint: Color?)` and `tint<S: ShapeStyle>(_ tint: S?)` overloads are iOS 15+. Consensus shape `(_)`
at 100% (`swiftui-ctx lookup tint --platform ios --json`). Emit `cross_ref: api-currency`.

## ac-08 — invented color APIs (hard-fail)

These are UIKit spellings or pure inventions — they do not exist as SwiftUI view modifiers:

| ❌ written | reality | ✅ |
|---|---|---|
| `.textColor(_:)` | not a SwiftUI modifier | `.foregroundStyle(_:)` |
| `.backgroundColor(_:)` | not a SwiftUI modifier | `.background(_:)` |
| `.tintColor(_:)` | UIKit property spelling | `.tint(_:)` |
| `.foregroundColour(_:)` | British misspelling | `.foregroundStyle(_:)` |

**`UIColor` is NOT in this list on iOS** — it is the native UIKit color type, bridged into SwiftUI via
`Color(uiColor:)` (and the `Color(.systemBackground)` sugar). Seeing `UIColor` or `Color(.label)` is
*correct* iOS code, not a hallucination. (On macOS the equivalent would be `Color(nsColor:)`; never emit
`nsColor:` on iOS.)

VERIFY with `swiftui-ctx lookup <name> --platform ios` — an **exit 3** (did-you-mean suggestion)
corroborates that no shipping iOS app uses it. Cross-check the invented list in
`_shared/hallucination-blacklist.md`.

---

## Sources

- Sosumi (fetched via `https://sosumi.ai/...`, access 2026-06-16): `documentation/swiftui/color`,
  `documentation/swiftui/color/init(uicolor:)`, `documentation/swiftui/view/foregroundstyle(_:)`,
  `documentation/swiftui/view/foregroundcolor` (deprecated banner),
  `documentation/swiftui/view/accentcolor` (deprecated banner), `documentation/swiftui/view/tint(_:)`,
  `documentation/uikit/uicolor` (system colors `label`/`systemBackground`/`systemGroupedBackground`).
- Apple HIG — Color (iOS): `developer.apple.com/design/human-interface-guidelines/color` (semantic +
  dark variants); UIKit standard/system colors.
- Corpus consensus/recommended examples via `swiftui-ctx lookup foregroundStyle --platform ios` /
  `lookup tint --platform ios` / `deprecated foregroundColor` / `deprecated accentColor`, accessed 2026-06-16.
