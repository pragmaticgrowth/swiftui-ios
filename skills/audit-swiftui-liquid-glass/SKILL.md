---
name: audit-swiftui-liquid-glass
description: Audits a finished or in-progress iOS SwiftUI codebase for Liquid Glass defects on iOS 26 and writes per-finding Markdown to swiftui-audits/. Use when the user says glass looks broken, cluttered, opaque, or wrong; when they ask to verify Liquid Glass, glassEffect, GlassEffectContainer, the glass or glassProminent button styles, glassEffectID, glassEffectUnion, scroll-edge effects, or iOS 26 chrome; when AI may have written glassBackground, liquidGlass, LiquidGlassView, material(.glass), or glassBackgroundEffect on an iPhone or iPad target; when glass sits on list rows or cards; when an app also targets iOS 17-25 and glass symbols may be ungated; or when a navigation bar goes opaque. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for UIKit UIGlassEffect, not for Dark Mode or materials, not for the general availability sweep, not for writing new glass UI from scratch.
---

# Audit SwiftUI Liquid Glass

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way Liquid Glass goes wrong on an iOS 26
target: hallucinated names, wrong-layer placement, glass-on-glass, missing containers, missing/wrong
availability gates, scroll-edge traps, re-glassed free chrome, and broken morphs. Findings are written
to disk in the toolkit's unified schema; certain mechanical defects are fixed under the fix-safety
protocol. This is never a from-scratch glass generator.

Liquid Glass is the toolkit's **highest API-hallucination domain** (the API shipped at WWDC25, after
most training data). Be suspicious wherever AI wrote glass code.

## Boundary / seam note (stay in lane)

- **UIKit `UIGlassEffect` / `UIVisualEffectView` glass are out of scope.** If audited code reaches
  for a UIKit glass surface, note it in one line and point to the future `audit-uikit-liquid-glass`
  skill — do not audit UIKit glass here.
- **Materials (`.ultraThinMaterial` etc.) and Dark-Mode contrast** belong to
  `audit-swiftui-appearance-color` — except where a material is the *pre-26 fallback* for a gated glass
  call (that stays here).
- **The blanket "is every OS-floored API gated" sweep** belongs to `audit-swiftui-availability-gating`;
  this skill owns **glass** gating in depth and defers non-glass gating there.

## The three non-negotiable design rules

1. **Navigation layer only — never content.** Glass goes on toolbars/floating controls/sidebars, never
   on rows, cells, cards, text, images, charts, or full-screen backgrounds.
2. **Never glass-on-glass.** Glass can't sample glass; one glass layer over plain content.
3. **Group siblings in a `GlassEffectContainer`.** Ungrouped siblings sample independently → mismatched
   blur/tint, extra render passes, no morphing.

**The placement test:** remove the element — lost the ability to *navigate/act* → navigation layer
(glass OK); lost *information* → content (glass wrong). Full reasoning + the placement-map artifact:
`references/design-rules-and-placement.md`.

## Defect index (glass-01 … glass-18)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (build break / never-correct),
**warning** (compiles but non-native), **advisory** (judgment / perf). `auto` = mechanical single-answer
fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| glass-01 | `.glassBackground()` / `.liquidGlass()` / `LiquidGlassView` / `.material(.glass)` / `.background(.glass)` | hard-fail | auto | `glass-api-surface.md` |
| glass-02 | `.glassBackgroundEffect()` on an iOS target (visionOS-only) | hard-fail | auto | `glass-api-surface.md` |
| glass-03 | `.glassEffect()` on content — `List`/`ForEach`/`Table` row, card, `Text`, `Image` | warning | flag | `design-rules-and-placement.md` |
| glass-04 | two+ `.glassEffect(` nested/stacked (glass-on-glass) | warning | flag | `design-rules-and-placement.md` |
| glass-05 | two+ sibling glass in one stack, no `GlassEffectContainer` | warning | flag | `design-rules-and-placement.md` |
| glass-06 | a glass symbol ungated under a deployment target < iOS 26 | warning | flag | `availability-gating-glass.md` |
| glass-07 | `#available(macOS 26, *)` gating glass in an iOS target (wrong arm) | warning | auto | `availability-gating-glass.md` |
| glass-08 | `.regular` and `.clear` mixed in one group | warning | flag | `design-rules-and-placement.md` |
| glass-09 | two+ `.tint(` / `.glassProminent` among sibling glass (tint spam) | warning | flag | `design-rules-and-placement.md` |
| glass-10 | `.glassEffect()` hand-applied to auto-adopting chrome (toolbar/sidebar/sheet) | warning | flag | `chrome-and-scroll-edges.md` |
| glass-11 | leftover `.toolbarBackground(.visible)` / `.toolbarColorScheme(_:)` blocks glass | warning | auto | `chrome-and-scroll-edges.md` |
| glass-12 | `TextEditor` in a `NavigationSplitView` detail (iPad) → opaque navigation bar | warning | flag | `chrome-and-scroll-edges.md` |
| glass-13 | `.glassEffect()` + `.background(.ultraThinMaterial)` (double transparency) | advisory | flag | `chrome-and-scroll-edges.md` |
| glass-14 | hand-rolled glass button instead of `.buttonStyle(.glass)` | advisory | flag | `design-rules-and-placement.md` |
| glass-15 | `Tab(...)` adopted, selection on `@State` not `@SceneStorage` | advisory | flag | `migration-and-morphing.md` |
| glass-16 | backward-compat `LabelStyle` kept at an iOS-26 floor | advisory | auto | `migration-and-morphing.md` |
| glass-17 | `glassEffectID` morph missing a condition (container / namespace / animation / conditional render) | advisory | flag | `migration-and-morphing.md` |
| glass-18 | `glassEffectUnion` siblings differ in shape / variant / tint | advisory | flag | `migration-and-morphing.md` |

**Three claims are UNVERIFIED — carry as `advisory` with the flag, never assert as fact** (each is
flagged in its reference + becomes `source: verify against Xcode 26 SDK`): the iOS scroll-edge
**default** style (`.soft`-vs-`.hard`); the constrained-`TextEditor` opaque-navigation-bar **pitfall**
(glass-12); the double-transparency **crash** (glass-13).

## The real API, at a glance

**Real (exist on iOS 26.0+):** `glassEffect(_:in:)`, `GlassEffectContainer`, `.buttonStyle(.glass)` /
`.glassProminent`, `Glass` + `.regular` / `.clear` / `.identity` / `.interactive(_:)` / `.tint(_:)`,
`glassEffectID(_:in:)`, `glassEffectUnion(id:namespace:)`, `glassEffectTransition(_:)`,
`backgroundExtensionEffect()`, `scrollEdgeEffectStyle(_:for:)`, `scrollEdgeEffectHidden(_:for:)`,
`ToolbarContent.sharedBackgroundVisibility(_:)`. **`Glass.interactive(_:)` is iOS 26.0+ and the
natural touch-driven variant on iPhone/iPad — never flag it as invented or platform-wrong.**

**Hallucinated (never exist):** `.glassBackground()`, `.liquidGlass()`, `LiquidGlassView`,
`.material(.glass)`, `.background(.glass)`, `GlassContainer`, `.buttonStyle(.liquidGlass)`.
**Real-but-platform-wrong:** `.glassBackgroundEffect()` (visionOS-only — absent on iOS).

### ✅ Correct (grounded in shipping iOS-26 code, not a placeholder)

The corpus **consensus shape** for `glassEffect` is `(_, in:)` (44% of real iOS call sites; next is
`(_)` at 22%, then `()` at 20%). The canonical example below is the highest-authority real iOS-26 call
site (1amageek/Toolbar) — verbatim from `swiftui-ctx file ex_9844325cad --smart`:

```swift
GlassEffectContainer {                                  // group siblings (rule 3)
    slabContent
        .glassEffect(.regular, in: .rect(cornerRadius: ToolbarSurfaceMetrics.cornerRadius))  // consensus (_:in:) shape, gated by an iOS-26 floor
}
```

- **Real call site (permalink):** https://github.com/1amageek/Toolbar/blob/651c24079698401734dbca70c00632ef1498b295/Sources/Toolbar/ToolbarContainer.swift#L109
- **Apple spec (Sosumi `doc:`):** https://sosumi.ai/documentation/swiftui/view/glasseffect(_:in:) — confirms `iOS 26.0+`, matching `floors-master.md`.

Signatures, floors, and the full ❌→✅ rewrites: `references/glass-api-surface.md`. Floor *values* are
the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` and the canonical
invented-name list in `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read,
never restate them.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). It is load-bearing:
   glass-06/07 fire **only** when the floor is **below iOS 26**. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-liquid-glass --dir <sources> --json /tmp/glass.json --sarif /tmp/glass.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + tier-2 structural ast-grep rules
   (`lint/ast-grep/*.yml` — the not-in-container/glass-on-glass/wrong-arm rules grep can't express),
   plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a
   flagged file did not fully parse, so a structural miss can't masquerade as clean; READ those by hand.
   The runner only LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Container
   nesting, cross-line ownership, and gate scope are invisible to grep. Build a per-file inventory: each
   glassed view + navigation-or-content (placement test) + its container + its gate.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a hallucinated name, a `macOS` gate arm, an ungated symbol under a <26 floor).
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, a
   behavior claim), run **both** evidence sources. (a) **Practice** — `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx
   lookup <api> --json` (and `swiftui-ctx deprecated <api>` for a currency/deprecation rule): read its
   `consensus` (the canonical shape), `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`,
   and `co_occurs_with`; a `lookup` **exit 3** (not-found, with a did-you-mean `suggestion`) corroborates a
   hallucination finding — no shipping iOS app uses the symbol. (b) **Spec** — confirm via **Sosumi**:
   `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with
   the citation or discard. Carry the three UNVERIFIED items as `advisory` with `source: verify against
   Xcode 26 SDK` — never as fact.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (glass-01/02/07/11/16), one conventional commit per finding citing its
   `rule_id`, never weaken a check. The ✅ "Correct" is **not a hand-written snippet** — it is the
   swiftui-ctx **consensus shape** put in `## Correct`, backed by a real iOS-26 example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus
   the Sosumi `doc:`) goes in `## Source` as the canonical example. Leave `flag-only` findings `open` with that
   ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep each fixed file to confirm the tell no longer matches; record the evidence
   in `## Fix applied?`. Re-confirm every citation still resolves and still says `iOS 26.0`. If a fix
   introduced a new tell (e.g. a `glassEffect` you added now needs a gate), loop that file back to
   DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can
become a finding — never emit a speculative finding. Auto-fix only the mechanical set
(glass-01/02/07/11/16); everything else is `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/liquid-glass/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/liquid-glass/_index.md`.
- `domain: liquid-glass`. Frontmatter is the canonical schema; `fix_mode` is `auto` for
  glass-01/02/07/11/16, else `flag-only`. `availability` reads from `floors-master.md` (iOS 26.0). `source` is an
  Apple URL + access date (fetched via Sosumi) or `verify against Xcode 26 SDK`.

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `hallucinated-api/` | a name doesn't exist on iOS (glass-01) or a visionOS-only symbol on an iOS target (glass-02) |
| `design-rules-navigation-layer/` | glass sits on content — rows, cells, cards, text, images, charts, fields, backgrounds (glass-03) |
| `glass-on-glass/` | glass is stacked on glass (glass-04) |
| `container-grouping/` | sibling glass lacks a `GlassEffectContainer`, or a morph/union is mis-wired (glass-05, glass-17, glass-18) |
| `availability-gating/` | a glass symbol is ungated under a <26 floor, or gated on the `macOS` arm (glass-06, glass-07) |
| `scroll-edge-effects/` | the `TextEditor` opaque-toolbar trap or a scroll-edge legibility issue (glass-12) |
| `chrome-auto-adoption/` | free chrome is re-glassed, leftovers block glass, or variant/tint discipline breaks (glass-08, glass-09, glass-10, glass-11, glass-14) |
| `migration/` | Tab/`@SceneStorage` restoration, the auto-removable `LabelStyle`, or double-transparency (glass-13, glass-15, glass-16) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/liquid-glass/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a
hard requirement.* Two runs over the same code produce structurally identical trees.

> **Go-beyond artifact (optional):** `swiftui-audits/liquid-glass/_placement-map.md` classifying every
> glassed view as `navigation`/`content` with a container-coverage score — see
> `references/design-rules-and-placement.md`.

## Reference routing

| File | Open when |
|---|---|
| `references/glass-api-surface.md` | a name/signature/existence question — the real allow-list + hallucination ❌→✅ (glass-01/02) |
| `references/design-rules-and-placement.md` | placement, glass-on-glass, container grouping, variant/tint, hand-rolled buttons (glass-03/04/05/08/09/14) + the placement map |
| `references/availability-gating-glass.md` | glass gating depth, the wrong-arm trap, the pre-26 fallback choice (glass-06/07) |
| `references/chrome-and-scroll-edges.md` | auto-adoption, leftover-override removal, scroll edges, the `TextEditor` trap, double transparency (glass-10/11/12/13) |
| `references/migration-and-morphing.md` | Tab/`@SceneStorage`, `@available(obsoleted:26)` LabelStyle, morph/union wiring (glass-15/16/17/18) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + tier-2 structural ast-grep); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule + wrong-arm failure |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-liquid-glass --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this
skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, glass-01/02/03/06/07/08/09/11/12/13/15/16/17/18)
+ **tier-2 ast-grep** structural rules (`lint/ast-grep/*.yml` — glass-04 glass-on-glass, glass-05
not-in-container, glass-07 wrong-arm gate-scope) that grep cannot express. It runs a per-file **parse
probe** (surfaces "did not fully parse" so a structural miss can't look clean), emits unified **JSON +
SARIF**, exits **2** on any hard-fail (glass-01/02/06/07) for a CI gate, and **degrades to grep-only with a
notice** if ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster: `brew install ast-grep`).
It only LOCATES — always READ each hit in full before reporting (step 3). The legacy
`scripts/glass-lint.sh` is now a thin pointer to this runner. Engine + rule-file format + JSON/SARIF
shape + safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
