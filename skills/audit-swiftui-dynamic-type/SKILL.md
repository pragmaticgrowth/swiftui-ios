---
name: audit-swiftui-dynamic-type
description: Audits an iOS SwiftUI app for Dynamic Type defects that break Larger Text accessibility — writing per-finding Markdown to swiftui-audits/. Use when the user says body text does not grow when the system text size is increased, a label is clipped or truncated at accessibility sizes, an icon or spacing stays fixed while text scales, or a layout overlaps at the largest Dynamic Type sizes; when they ask to verify a text style (.font(.body/.headline/.title/.caption)), dynamicTypeSize limits, ScaledMetric, or minimumScaleFactor on iOS; when AI wrote .font(.system(size: 17)) or Font.system(size: 17) for body text (a fixed point size that never scales), a hard-coded spacing/icon size that should be @ScaledMetric, a .dynamicTypeSize cap that locks out large-text users, or a one-line label with no .minimumScaleFactor. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for VoiceOver or color/contrast (accessibility), text rendering or AttributedString craft (typography-text), or large-type reflow structure (adaptive-layout).
---

# Audit SwiftUI Dynamic Type

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, flag — every way text fails to honor **Larger Text** (Dynamic Type): a body
label set with a **fixed point size** (`.font(.system(size: 17))` / `Font.system(size: 17)`) that never
grows when the user raises the system text size, a **hard-coded spacing/icon dimension** that should scale
with type via `@ScaledMetric`, a **`dynamicTypeSize` cap** set so low it locks out accessibility-size users,
and a **single-line label with no `minimumScaleFactor`** that clips or truncates at large sizes. Findings are
written to disk in the toolkit's unified schema; no defect here is auto-fixed (every fix is a judgment about
which text style fits and how much a metric should scale). This is never a from-scratch typography generator.

**Dynamic Type is the most-used iOS accessibility feature, and AI under-serves it.** The training corpus is
heavy with `.font(.system(size: 17))`-style fixed sizing copied from design specs, where a number reads as
"the right size" — but a literal point size is frozen: it ignores the user's Larger Text setting entirely, so
a layout that looks fine at the default size clips, truncates, or overlaps at the accessibility sizes that a
large fraction of users actually run. The iOS idiom is a **text style** (`.font(.body)`, `.headline`,
`.title`, `.caption`…) which scales automatically, plus `@ScaledMetric` for the spacing and icon sizes that
must grow *with* the text. Be suspicious wherever AI typed a number into `.font(.system(size:))` or a
`.frame`/`.padding` next to scalable text.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **Font craft / rendering is not mine.** The *typographic* choice — `AttributedString` styling, custom
  fonts, `Text + Text` composition, `Font.system(_:design:)` vs a text style, kerning/tracking — belongs to
  `audit-swiftui-typography-text`. This skill owns the **scaling** half: whether text honors Dynamic Type at
  all. The `fixed .system(size:) on body text` seam is **mine (dynamic-type) as primary**, with
  `typography-text` the demoted companion (cross-ref-graph §1). Note the font-craft angle in one line and
  `cross_ref: typography-text`; do not re-author the type craft here.
- **Dynamic Type as an accessibility *obligation* vs the scaling *mechanics*.** The mechanics —
  text-style scaling, `@ScaledMetric`, `dynamicTypeSize`, `minimumScaleFactor` — are **this skill**. The
  framing of "supporting Dynamic Type is an a11y requirement" plus `accessibilityShowsLargeContentViewer`
  (the large-content HUD for icon-only controls) belongs to `audit-swiftui-accessibility`; `cross_ref:
  accessibility`, don't claim the a11y obligation itself.
- **Reflow at large sizes is shared.** When the *fix* for clipped text is a structural reflow — a
  `ViewThatFits`, a horizontal stack that must wrap to vertical at accessibility sizes — that layout
  restructuring is `audit-swiftui-adaptive-layout`. This skill flags that the text does not scale and
  `cross_ref: adaptive-layout` when the remedy is a size-class/`@Environment(\.dynamicTypeSize)`-gated reflow.
- **Scaled row heights / spacing inside a `List`/`Table`** are `audit-swiftui-layout-and-tables`; note and
  `cross_ref` when the issue is row arrangement, not the text's own scaling.

## The Dynamic Type rules (the judgment core)

1. **Prefer a text style over a fixed point size.** `.font(.body)` / `.headline` / `.title` / `.caption`
   scale automatically with the user's Larger Text setting. `.font(.system(size: 17))` and
   `Font.system(size: 17)` are **frozen** — they never grow, so body/title text built this way fails Dynamic
   Type (dt-01, dt-02). A fixed size is only defensible for a non-text glyph or a fixed-geometry badge — judge
   the call site.
2. **Spacing and icon sizes that pair with text must scale too.** A `@ScaledMetric` wrapper makes a number
   grow with the type so layout stays proportional; a hard-coded `.frame(width: 44)` / `.padding(16)` next to
   scalable text leaves icons and gaps frozen while the text grows, breaking the rhythm (dt-03).
3. **Never cap `dynamicTypeSize` so low it excludes large-text users.** `.dynamicTypeSize(...
   DynamicTypeSize.large)` or a fixed `.dynamicTypeSize(.large)` clamps text *below* the accessibility sizes —
   locking out exactly the users Dynamic Type exists for. A cap is legitimate only at the **accessibility**
   range (e.g. `...DynamicTypeSize.accessibility1`) to bound an extreme; below that it is a regression (dt-04).
4. **A single-line label that may grow needs `minimumScaleFactor`.** `.lineLimit(1)` on scalable text with no
   `.minimumScaleFactor(_:)` clips or truncates at large sizes; the idiom is to allow the text to shrink to
   fit (or to drop the one-line constraint) so it stays readable (dt-05).

Full ❌→✅ + the canonical scaled-layout exemplar: `references/dynamic-type-scaling.md`.

## Defect index (dt-01 … dt-05)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (never-correct on iOS),
**warning** (compiles but breaks Larger Text), **advisory** (judgment / proportion). `auto` = mechanical
single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| dt-01 | `.font(.system(size: N))` on body/title text → a frozen point size that never scales with Larger Text | warning | flag | `dynamic-type-scaling.md` |
| dt-02 | `Font.system(size: N)` constructor used for a text style → same frozen size, the value-init form | warning | flag | `dynamic-type-scaling.md` |
| dt-03 | a hard-coded `.frame`/`.padding`/`CGFloat` for spacing/icon size next to scalable text, no `@ScaledMetric` → frozen geometry while text grows | advisory | flag | `dynamic-type-scaling.md` |
| dt-04 | `.dynamicTypeSize(.large)` / a cap below the accessibility range → locks out large-text users | warning | flag | `dynamic-type-scaling.md` |
| dt-05 | `.lineLimit(1)` on scalable text with no `.minimumScaleFactor(_:)` → clips/truncates at large sizes | advisory | flag | `dynamic-type-scaling.md` |

**No defect here is a hard-fail or auto-fix.** Every fix is a judgment (is this a non-text glyph that may stay
fixed, how much should a metric scale, is this cap an accessibility bound or a regression), so all are
`flag-only`. dt-01/dt-02 cross-ref `typography-text` (font craft); dt-03 cross-refs `adaptive-layout`/
`layout-and-tables` when the remedy is a reflow.

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` — read, never restate):**
`font(_:)` with a text style (`.body`/`.headline`/`.subheadline`/`.title`/`.title2`/`.title3`/`.largeTitle`/
`.callout`/`.footnote`/`.caption`/`.caption2`) — the scaling path (Font/font = iOS 13.0); `@ScaledMetric`
(`ScaledMetric(wrappedValue:relativeTo:)`, iOS 14.0) for type-relative numbers; `dynamicTypeSize(_:)` /
`dynamicTypeSize(_ :ClosedRange)` and the `DynamicTypeSize` enum (`.xSmall`…`.xxxLarge`,
`.accessibility1`…`.accessibility5`) — iOS 15.0; `minimumScaleFactor(_:)` (iOS 13.0) +
`allowsTightening(_:)` / `lineLimit(_:)` / `truncationMode(_:)` for fit; `@Environment(\.dynamicTypeSize)`
and `\.isAccessibilitySize` (iOS 15.0) to branch a layout. **UIKit bridge (read floors from the SDK):**
`UIFontMetrics(forTextStyle:).scaledFont(for:)` and `adjustsFontForContentSizeCategory` — these are UIKit,
**not** in the SwiftUI catalog; cite the well-known iOS 11 introduction and mark `availability: verify
against Xcode 26 SDK`, never fabricate a floor.

No invented names are central to this domain; if audited code reaches for a scaling symbol you can't place,
confirm via swiftui-ctx (`lookup` **exit 3** = likely hallucination or no-iOS-arm symbol) + Sosumi before
flagging, and cross-check the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/dynamic-type-scaling.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — it sets which floor a
   fix may rely on (`@ScaledMetric` = iOS 14.0+; `dynamicTypeSize`/`DynamicTypeSize`/`\.isAccessibilitySize`
   = iOS 15.0+; `font` text styles / `minimumScaleFactor` = iOS 13.0+ — all from `floors-master.md`). At the
   iOS-17 deployment floor every scaling API is available unconditionally; record the target so a sub-floor
   fix is gated per `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-dynamic-type --dir <sources> --json /tmp/dt.json --sarif /tmp/dt.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, dt-01…dt-05), plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a structural miss can't masquerade as clean; READ those by hand. ast-grep tier-2 rules are
   optional and NOT installed in this environment; the grep tier stands alone. The runner only LOCATES —
   never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a
   `.font(.system(size:))` is on genuine body/title *text* (vs a fixed-geometry badge or a non-text glyph),
   whether a hard-coded `.frame`/`.padding` sits next to scalable text (so it should be `@ScaledMetric`),
   whether a `.dynamicTypeSize` cap clamps below the accessibility range, and whether a `.lineLimit(1)` is on
   text that can grow are all invisible to grep. Build a per-file inventory: each `Text`/`Label` + its font
   (text style vs fixed size); each spacing/icon dimension + whether it is `@ScaledMetric`; each
   `dynamicTypeSize` cap + its bound; each one-line label + its `minimumScaleFactor`.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. `.font(.system(size: 17))` on a `Text` body string, a `.dynamicTypeSize(.large)` cap, a
   hard-coded icon `.frame` beside a scalable label). A fixed `.system(size:)` on a **non-text** symbol glyph,
   a decorative badge with a deliberately fixed geometry, or a `.dynamicTypeSize(...accessibility3)`
   accessibility-range bound is *not* a defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a scaling symbol you can't place, a floor you're unsure of, the
   canonical scaled shape, whether a modifier exists on iOS), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `swiftui-ctx deprecated <api>` for a currency rule): read its `consensus` (the canonical shape),
   `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a `lookup`
   **exit 3** (not-found, with a did-you-mean `suggestion`) corroborates a hallucination or a no-iOS-arm
   symbol. (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`
   for the protocol (never `WebFetch` `developer.apple.com`). Cross-check `introduced_ios` against
   `floors-master.md` and the Sosumi `doc:` floor — the reconciled floor wins. For the **UIKit** bridge
   (`UIFontMetrics`, `adjustsFontForContentSizeCategory`) the SwiftUI catalog has no entry — `lookup` exits 3;
   cite the iOS 11 introduction from Sosumi/SDK and mark `availability: verify against Xcode 26 SDK`. The CLI
   contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation
   or discard. **Deeper corpus evidence (scaling vocab):** to judge whether a number should be `@ScaledMetric`
   and which `relativeTo:` text style the idiom uses, ground it in the corpus — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup ScaledMetric --platform ios --json` returns the consensus
   `(relativeTo: .body)` shape plus a permalinked exemplar; cite it to defend a dt-03 "this spacing should
   scale" or a dt-01 "this should be a text style" call.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a text-style/scale judgment, so all
   are `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅
   "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in
   `## Correct`, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus
   the Sosumi `doc:`) goes in `## Source` as the canonical example. The dt-03 ✅ is grounded in the live
   `swiftui-ctx lookup ScaledMetric --platform ios` consensus (`@ScaledMetric(relativeTo: .body)`) + its
   recommended permalink (see `references/dynamic-type-scaling.md`). Leave `flag-only` findings `open` with
   that ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. a `.font(.body)` you swapped in for a fixed size now wants a `@ScaledMetric` for the icon
   beside it, or a one-line label you kept now wants a `minimumScaleFactor`), loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is a
text-style/scale judgment (whether a `.system(size:)` is on real text or a fixed glyph, which text style a
number should be relative to, whether a cap is an accessibility bound or a regression, whether a one-line
label should shrink or wrap), so all are `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/dynamic-type/<context>/NN-slug.md` (one finding per file, zero-padded, ordered).
  Per-run index: `swiftui-audits/dynamic-type/_index.md`.
- `domain: dynamic-type`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every defect.
  `availability` reads from `floors-master.md` (UIKit-bridge symbols → `verify against Xcode 26 SDK`).
  `source` is an Apple URL + access date (fetched via Sosumi) or `verify against Xcode 26 SDK`. Each finding
  body carries a **`## Why it's wrong on iOS`** section. Emit `cross_ref` on dt-01/dt-02 (→ `typography-text`,
  the font-craft companion), dt-03 (→ `adaptive-layout` / `layout-and-tables` when the remedy is a reflow or
  scaled rows), and any "Dynamic Type is an a11y obligation" note (→ `accessibility`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `fixed-font-size/` | a `.font(.system(size:))` / `Font.system(size:)` freezes body/title text against Larger Text (dt-01, dt-02) — `cross_ref` typography-text |
| `scaled-metric/` | a hard-coded spacing/icon dimension beside scalable text should be `@ScaledMetric` (dt-03) — `cross_ref` adaptive-layout/layout-and-tables when a reflow |
| `type-size-cap/` | a `.dynamicTypeSize` cap clamps below the accessibility range and locks out large-text users (dt-04) |
| `truncation-fit/` | a one-line label has no `.minimumScaleFactor` and clips/truncates at large sizes (dt-05) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/dynamic-type/` with a lowercase-hyphen slug naming the sub-category, and note it in the run's
`_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/dynamic-type-scaling.md` | the fixed-size body text, the `@ScaledMetric` spacing/icon scaling, the `dynamicTypeSize` cap, and the `minimumScaleFactor` fit trap (dt-01…dt-05) + the canonical scaled-layout exemplar |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi (iOS pages) |
| `lint/grep-tells.tsv` | step LOCATE — this skill's tier-1 grep tell set fed to the shared runner (dt-01…dt-05); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `@ScaledMetric` 14.0, `dynamicTypeSize`/`DynamicTypeSize`/`isAccessibilitySize` 15.0, `font`/`minimumScaleFactor` 13.0; UIKit `UIFontMetrics`/`adjustsFontForContentSizeCategory` are not in the catalog → verify against the SDK) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up scaling symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (a sub-floor `@ScaledMetric`/`dynamicTypeSize` fix needs an `#available(iOS NN, *)` gate; at the iOS-17 floor these are unconditional) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (typography-text font craft, accessibility Dynamic-Type obligation, adaptive-layout reflow, layout-and-tables scaled rows) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-dynamic-type --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, dt-01…dt-05). The grep tier **stands alone**
here — ast-grep is NOT installed in this environment, so no tier-2 `.yml` is required; the grep tells are
self-test-validated against `tests/fixtures/dynamic-type.swift`. It runs a per-file **parse probe** (surfaces
"did not fully parse" so a structural miss can't look clean), emits unified **JSON + SARIF**, and **degrades
to grep-only with a notice** if ast-grep is unreachable. It only LOCATES — always READ each hit in full before
reporting (step 3). Because grep can flag the *presence* of a `.frame`/`.padding` or a `.lineLimit(1)` but not
whether the dimension sits beside scalable text or whether a `@ScaledMetric` / `minimumScaleFactor` is
*absent* from the surrounding view, every dt-03 / dt-05 hit MUST be read in full before reporting. The thin
`scripts/dynamic-type-lint.sh` is a pointer to this runner. Engine + rule-file format + JSON/SARIF shape +
safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
</content>
</invoke>
