---
name: audit-swiftui-appearance-color
description: Audits a finished or in-progress iOS SwiftUI codebase for appearance and color defects on iOS 17+ and writes per-finding Markdown to swiftui-audits/. Use when the user says Dark Mode looks broken, colors do not adapt, text is hardcoded gray, a background is the wrong gray on iPad, the app forces light or dark, contrast is too low, or a panel looks flat; when they ask to verify Color, hardcoded RGB, asset-catalog colors, iOS system colors Color(.systemBackground)/secondarySystemBackground/label, foregroundColor, foregroundStyle, accentColor, tint, Material, preferredColorScheme, or colorSchemeContrast; when AI may have written Color(red:green:blue:), Color.white, Color.black, .foregroundColor, .accentColor, .textColor, or .tintColor; or when an app forces a color scheme app-wide or ignores Increase Contrast. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for UIVisualEffectView bridging, not for Liquid Glass, not the general deprecation sweep, not WCAG accessibility audits, not writing new themed UI from scratch.
---

# Audit SwiftUI Appearance & Color

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way appearance and color go wrong on an iOS 17+
(iPhone & iPad) target: hardcoded `Color(red:green:blue:)` / `Color.white` / `Color.black` that freeze one
appearance, deprecated `.foregroundColor` / `.accentColor`, opaque `Color` backgrounds where a `Material`
or an iOS **system background** color belongs, a force-set `.preferredColorScheme` that overrides the
user's system appearance, ignored Increase-Contrast, and invented color APIs. Findings are written to disk
in the toolkit's unified schema; certain mechanical defects are fixed under the fix-safety protocol. This
is never a from-scratch theming generator.

Two of this domain's modifiers — `.foregroundColor` and `.accentColor` — are **deprecated** (their
deprecation post-dates most training data), so AI frequently emits them, and pads dark-broken literal RGB
throughout instead of reaching for the iOS system colors. Be suspicious wherever AI set a color.

## Boundary / seam note (stay in lane)

- **The `.foregroundColor(_:)` / `.accentColor(_:)` deprecation *flag*** is owned by
  `audit-swiftui-api-currency`; **this skill owns the positive `.foregroundStyle` hierarchy /
  asset-catalog / `.tint` craft.** Emit `cross_ref: api-currency` on ac-03/ac-04; do not double-own the flag.
- **Liquid Glass surfaces (`glassEffect`, the `.glass` button styles, `GlassEffectContainer`)** belong to
  `audit-swiftui-liquid-glass`. A *plain* `Material` (`.ultraThinMaterial` …) that is the right chrome
  fill stays here; a missing **glass** surface routes there. Emit `cross_ref: liquid-glass` on ac-06.
- **WCAG ratios, Differentiate-Without-Color, and the trait-level a11y audit** belong to
  `audit-swiftui-accessibility`; this skill detects the *mechanics* (an ignored `colorSchemeContrast`),
  a11y owns the contrast requirement. Emit `cross_ref: accessibility` on ac-07.
- **Custom colors that fail Differentiate Without Color** (color-only state signalling) belong to
  `audit-swiftui-accessibility`; a *color paired with scaled text* routes to `audit-swiftui-dynamic-type`.
  Note the seam in one line and `cross_ref` rather than re-auditing it here.
- **UIKit `UIColor` catalogs / `UIVisualEffectView` vibrancy** reached for via a representable are out of
  scope — note it in one line and point to the future `audit-swiftui-uikit-interop` (HOW to bridge) /
  `audit-swiftui-uikit-overuse` (WHETHER to bridge). `UIColor` itself is a *native iOS type* (see ac-08).

## Domain rules

1. **Color is semantic, not literal.** Use a SwiftUI system color (`.primary`, `.secondary`,
   `Color.accentColor`), an **iOS UI-element system color** (`Color(.label)`, `Color(.secondaryLabel)`,
   `Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `Color(.systemGroupedBackground)`), or a
   **named asset-catalog color** that carries Any/Dark variants. A raw `Color(red:green:blue:)` or
   `Color.white`/`.black` paints one appearance and breaks Dark Mode. The iOS grouped-background colors are
   the load-bearing idiom for `List`/`Form` and grouped-table surfaces — a plain `Color(.systemBackground)`
   under a grouped table reads as the wrong gray on both iPhone and iPad.
2. **Style the foreground through the hierarchy.** `.foregroundStyle(.secondary)` / `.tertiary` adapts to
   appearance and vibrancy; a hardcoded gray does not. `.foregroundColor` is deprecated → `.foregroundStyle`.
3. **Let chrome breathe with a `Material`.** Overlays, popovers, sheet/toolbar-adjacent fills, and HUD
   panels behind content want `.ultraThinMaterial`/`.regularMaterial` (or a glass surface), not an opaque
   `Color` fill.
4. **Never force the appearance app-wide.** `.preferredColorScheme(.dark)` at the root overrides the
   user's iOS system setting (Settings → Display & Brightness) — an anti-pattern. Scope it to a deliberate
   preview/island only.
5. **Honor Increase Contrast.** Read `@Environment(\.colorSchemeContrast)` and branch where custom colors
   would otherwise fall below the system contrast.

## Defect index (ac-01 … ac-08)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (never-correct / invented),
**warning** (compiles but non-native / breaks Dark Mode / deprecated), **advisory** (judgment / craft).
`auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| ac-01 | hardcoded `Color(red:green:blue:)` / `Color(.sRGB…)` literal RGB → breaks Dark Mode | warning | flag | `colors-semantic-and-assets.md` |
| ac-02 | `Color.white` / `Color.black` / `Color(white:)` as content fg/bg → no Dark-Mode adapt; use an iOS system color | warning | flag | `colors-semantic-and-assets.md` |
| ac-03 | `.foregroundColor(_:)` deprecated → `.foregroundStyle(_:)` (+ `.secondary` hierarchy) | warning | auto | `colors-semantic-and-assets.md` |
| ac-04 | `.accentColor(_:)` deprecated → `.tint(_:)` | warning | auto | `colors-semantic-and-assets.md` |
| ac-05 | forced `.preferredColorScheme(_:)` at app/root scope → overrides user appearance | warning | flag | `color-scheme-and-contrast.md` |
| ac-06 | opaque `Color` background where a `Material` or an iOS system background belongs (overlay/sheet/grouped table) | advisory | flag | `materials-and-vibrancy.md` |
| ac-07 | custom colors with no `@Environment(\.colorSchemeContrast)` branch under Increase Contrast | advisory | flag | `color-scheme-and-contrast.md` |
| ac-08 | invented color API: `.textColor(`, `.backgroundColor(`, `.tintColor(` (UIKit spelling) → SwiftUI modifier | hard-fail | flag | `colors-semantic-and-assets.md` |

**Currency seam:** ac-03 and ac-04 carry `cross_ref: api-currency` (currency flags the deprecation;
appearance owns the replacement craft). ac-06 carries `cross_ref: liquid-glass`; ac-07 carries
`cross_ref: accessibility`.

## The real API, at a glance

**Real (exist on iOS 17):** `Color` (`.primary`, `.secondary`, `Color.accentColor`, named asset-catalog
`Color("Brand")`, and the iOS UI-element bridges `Color(.label)`/`Color(.secondaryLabel)`/
`Color(.systemBackground)`/`Color(.secondarySystemBackground)`/`Color(.systemGroupedBackground)` — all
`Color(uiColor:)`-family, iOS 13+), `foregroundStyle(_:)` (iOS 15+, takes a `ShapeStyle` hierarchy —
`.secondary`/`.tertiary`), `tint(_:)` (Color & `ShapeStyle` overloads, iOS 15+),
`Material` (`.ultraThinMaterial`/`.regularMaterial` … iOS 15+),
`@Environment(\.colorScheme)` / `@Environment(\.colorSchemeContrast)` (iOS 13+),
`preferredColorScheme(_:)` (iOS 13+, *for scoped use*), `ShapeStyle` hierarchy levels
(`.primary`/`.secondary`/`.tertiary`/`.quaternary`/`.quinary`). **`foregroundColor(_:)` and
`accentColor(_:)` still resolve but are deprecated → `foregroundStyle(_:)` / `tint(_:)`.**

**`UIColor` is native on iOS** — it is the UIKit color type, bridged into SwiftUI via `Color(uiColor:)` /
the `Color(.systemBackground)`-style sugar. It is **not** an ac-08 hallucination here (that is the macOS
inversion). The bridge to use is `Color(uiColor:)`, never `Color(nsColor:)`.

**Invented (never a SwiftUI modifier on any platform):** `.textColor(_:)`, `.backgroundColor(_:)`,
`.tintColor(_:)` (the UIKit `tintColor` spelling), `.foregroundColour(_:)` (British misspelling). Confirm
any uncertain name via `swiftui-ctx lookup <api> --platform ios` (exit 3 = no shipping iOS app uses it) +
the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read, never restate.

Floor / deprecation *values* are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate the table here.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:` `.iOS(...)`). The
   project floor is **iOS 17**; every floor here (`foregroundStyle`/`tint`/`Material` iOS 15) sits below
   it, so no color symbol in this domain needs a `#available` gate. Note whether the project also targets
   iPad (it does unless `TARGETED_DEVICE_FAMILY` excludes `2`) — the grouped-background ✅ matters there.
   Also note whether an **asset catalog** (`*.xcassets`) with color sets exists — its presence changes the
   ac-01/02 ✅ to "move the literal into a color set." Record both.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-appearance-color --dir <sources> --json /tmp/ac.json --sarif /tmp/ac.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + the tier-2 structural ast-grep rule
   (`lint/ast-grep/*.yml` — the multi-arg `Color(red:green:blue:)` init grep can't reliably anchor across
   lines), a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a
   flagged file did not fully parse, so a structural miss can't masquerade as clean; READ those by hand.
   The runner only LOCATES. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a literal
   color is a content fill vs a deliberate brand mark, whether a `Color` background is chrome that wants a
   `Material`, whether a `.preferredColorScheme` is app-root vs a scoped preview, and whether a view even
   has custom colors that need a contrast branch are all invisible to grep. Build a per-file inventory:
   each color site + literal-or-semantic + its surface (content/chrome) + its scheme/contrast handling.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (an invented name, a literal `Color(red:`, a root `.preferredColorScheme`).
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, a
   deprecation you can't date), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx deprecated <api>` for ac-03/ac-04): read its `consensus`
   (the canonical shape), `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`, and
   `co_occurs_with`; a `lookup` **exit 3** (not-found, with a did-you-mean `suggestion`) corroborates an
   ac-08 hallucination — no shipping iOS app uses the symbol. (b) **Spec** — confirm via **Sosumi**:
   `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote
   with the citation or discard.

   **Deeper corpus evidence (this domain's VALUE vocabulary).** To ground an ac-06 Material pick or an
   ac-01/02 semantic-color/gradient replacement in the *real* vocabulary, run
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx valueBuilders` (filter e.g. `gradient`/`material`; Color/Material/gradient builders ranked by usage) and
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx conformances ShapeStyle` (and `… conformances ButtonStyle`)
   for custom `ShapeStyle`/`ButtonStyle` conformers (stable envelope + `next_actions` + permalinks), and
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx examples foregroundStyle --shape "(_)"` for the consensus
   modifier shape (`(_)`, 98%). E.g. the iOS corpus material consensus is **`regular` (8,174 uses via
   `valueBuilders`)**: prefer `.regularMaterial` as the ac-06 ✅ unless the surface is genuinely a thin
   overlay (`.ultraThinMaterial`). Per the shared CLI surface in `swiftui-ctx-reference.md`.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (ac-03 `.foregroundColor(x)` → `.foregroundStyle(x)`; ac-04 `.accentColor(x)`
   → `.tint(x)` — identical-argument mechanical renames), one conventional commit per finding citing its
   `rule_id`, never weaken a check. The ✅ "Correct" is **not a hand-written snippet** — it is the
   swiftui-ctx **consensus shape** put in `## Correct`, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink
   (plus the Sosumi `doc:`) goes in `## Source`. Leave `flag-only` findings `open` with that ✅. The
   verified canonical `.foregroundStyle(_:)` ✅ — the live swiftui-ctx **consensus shape `(_)` (100 %)**,
   grounded in real corpus code, not a placeholder:

   ```swift
   // ✅ Correct — swiftui-ctx `lookup foregroundStyle --platform ios` consensus `(_)` (98%); real example
   //    Finb/Bark `ex_d0fa885d9f` (author_authority 101,713, 8,478★, min_ios 17)
   Text(title)
       .foregroundStyle(.secondary)   // adapts to appearance + vibrancy; no frozen literal
   // permalink: https://github.com/Finb/Bark/blob/2a35a5b990415eada5fcc6c95deb9850c239796a/Widget/Widget.swift#L83
   // doc: https://sosumi.ai/documentation/swiftui/view/foregroundstyle(_:)
   ```
8. **DOUBLE-CHECK.** Re-grep each fixed file to confirm the tell no longer matches; record the evidence in
   `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a new tell (e.g. a
   `.foregroundStyle` you wrote now takes a literal `Color(red:` that should be a hierarchy/asset color),
   loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding. Auto-fix only the mechanical set (ac-03, ac-04 — both pure
same-argument renames); everything else is `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/appearance-color/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/appearance-color/_index.md`.
- `domain: appearance-color`. Frontmatter is the canonical schema; `fix_mode` is `auto` for ac-03/ac-04,
  else `flag-only`. `availability` reads from `floors-master.md`. `source` is an Apple URL + access date
  (fetched via Sosumi) or `verify against Xcode 26 SDK`. Emit `cross_ref` for ac-03/ac-04
  (`api-currency`), ac-06 (`liquid-glass`), ac-07 (`accessibility`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `hardcoded-color/` | a literal RGB / white / black color paints one appearance, or an invented color API appears (ac-01, ac-02, ac-08) |
| `deprecated-modifiers/` | `.foregroundColor` or `.accentColor` is used at/under their 26.5 close (ac-03, ac-04) |
| `color-scheme/` | the appearance is force-set app-wide, or Increase Contrast is ignored (ac-05, ac-07) |
| `materials/` | an opaque `Color` fills chrome that should breathe with a `Material` (ac-06) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/appearance-color/` with a lowercase-hyphen slug naming the sub-category, and note it in
the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a
hard requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/colors-semantic-and-assets.md` | literal RGB / white-black colors, the `.foregroundColor`→`.foregroundStyle` and `.accentColor`→`.tint` rewrites, asset-catalog color sets, invented color names (ac-01/02/03/04/08) |
| `references/materials-and-vibrancy.md` | an opaque `Color` where a `Material` belongs, the Material-vs-glass boundary, vibrancy (ac-06) |
| `references/color-scheme-and-contrast.md` | force-set `.preferredColorScheme`, honoring `colorScheme`/`colorSchemeContrast`, Increase Contrast (ac-05/07) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + the tier-2 structural `Color(red:green:blue:)` init rule); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability/deprecation value (the reconciled truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (ac-08) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule + iPhone/iPad idiom checks (any `#available` near a color symbol; all color floors sit below the iOS 17 project floor) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (api-currency, liquid-glass, accessibility) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-appearance-color --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, ac-01…ac-08) + a **tier-2 ast-grep**
structural rule (`lint/ast-grep/ac-01-hardcoded-rgb.yml` — the `Color(red:green:blue:)` literal init,
anchored on the call so the multi-line / multi-arg form grep can't reliably catch is caught structurally).
It runs a per-file **parse probe** (surfaces "did not fully parse"), emits unified **JSON + SARIF**, exits
**2** on any hard-fail (ac-08) for a CI gate, and **degrades to grep-only with a notice** if ast-grep is
unreachable (`npx --package @ast-grep/cli ast-grep`; faster: `brew install ast-grep`). It only LOCATES —
always READ each hit in full before reporting (step 3). The legacy `scripts/appearance-lint.sh` is a thin
pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
