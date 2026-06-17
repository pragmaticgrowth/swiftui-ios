---
name: audit-swiftui-adaptive-layout
description: Audits an iOS SwiftUI app for non-adaptive layout defects that ship an iPhone-only design on a Universal (iPhone + iPad) target, writing per-finding Markdown to swiftui-audits/. Use when the layout looks letter-boxed on iPad, content is pinned to a fixed width, a view ignores landscape or Split View multitasking, a NavigationSplitView collapses badly on iPhone, or the app never reacts to compact-vs-regular size classes; when verifying horizontalSizeClass, verticalSizeClass, ViewThatFits, containerRelativeFrame, or NavigationSplitView adaptivity; when AI wrote a full-screen view with a hard-coded .frame(width: 393), used UIScreen.main.bounds for sizing (deprecated iOS 16+), or shipped a NavigationSplitView with no size-class branch. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for split-view column content/toolbar (adaptive-navigation), List-vs-Table or Grid sizing (layout-and-tables), sheet/popover adaptivity (presentation-sheets-modals), whether a UIKit bridge should exist (uikit-overuse), or new layout UI.
---

# Audit SwiftUI Adaptive Layout

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way an iPhone-only layout habit fails to adapt across the iOS device
matrix: a full-screen view with a hard-coded `.frame(width:)`, `UIScreen.main.bounds` used as a layout
oracle (deprecated iOS 16+), a `NavigationSplitView` shipped with no size-class branch so it degrades on
compact width, a layout that never reads `horizontalSizeClass`/`verticalSizeClass`, and a manual
width-`if` ladder where `ViewThatFits` (iOS 16) or `containerRelativeFrame` (iOS 17) is the native answer.
Findings are written to disk in the toolkit's unified schema; this is never a from-scratch layout generator.

**The corpus is iPhone-portrait-shaped, not the device matrix.** The training corpus is overwhelmingly
single-iPhone-portrait SwiftUI, where one fixed column always fits and size classes never change — so AI
never learns to branch on `horizontalSizeClass`, never reaches for `ViewThatFits`, and freely pins content
to a literal width that happens to match an iPhone. The result compiles and looks correct in the iPhone
preview but reads as a blown-up phone app on iPad, breaks in landscape, and clips under Split View / Slide
Over multitasking. Be suspicious wherever AI built a full-screen container, a split-view shell, or any view
whose width it "knew" at author time.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **`NavigationSplitView` is a split axis.** *Whether the split adapts to size class* — an unconditional
  three-column split with no compact branch (adl-03) — is **this skill**. The split-view's **column
  content, titles, `.navigationSplitViewColumnWidth`, toolbar placement, and `NavigationStack` detail
  wiring** are `audit-swiftui-adaptive-navigation`. File the size-class-adaptation finding here,
  `cross_ref: adaptive-navigation`; do not audit the navigation chrome.
- **Size class vs arrangement.** A missing `horizontalSizeClass` *branch* (adl-04) is **this skill**. The
  *choice of arrangement once you know the size class* — `List`-vs-`Table` (a `Table` collapses to one
  column on iPhone), `Grid`/`LazyVGrid` column counts, the `controlSize` sizing axis — is
  `audit-swiftui-layout-and-tables`. `cross_ref` it when the defect is which container to use, not whether
  to branch at all.
- **Sheet / popover adaptivity is not mine.** A `.popover` that should adapt to a sheet on compact, a
  `.sheet` detent that should change by size class, belongs to `audit-swiftui-presentation-sheets-modals`.
  Note it in one line and `cross_ref: presentation-sheets-modals`.
- **`UIScreen.main` — WHETHER vs sizing-use.** That a `UIScreen.main.*` bridge *should not exist at all*
  (use `GeometryReader`/size class) is `audit-swiftui-uikit-overuse`. That a present `UIScreen.main.bounds`
  is being used **as a layout-width oracle** (adl-02) is **this skill**. This is a **keep-both** seam — file
  the layout finding here, `cross_ref: uikit-overuse`.

## The adaptive-layout judgment rules (the judgment core)

1. **Never hard-code a width for full-screen content.** A `.frame(width: 393)` (or any literal that matches
   one iPhone) freezes the layout to one device; on iPad it letter-boxes, in landscape it clips, under Split
   View it overflows. Full-screen content sizes to its container, not a number (adl-01). A small fixed width
   on a genuinely fixed-size element (an icon chip, a 1pt rule) is fine — judge intent.
2. **`UIScreen.main` is not a layout oracle.** `UIScreen.main.bounds`/`.main` is **deprecated on iOS 16+**
   (no scene context, wrong under multitasking) — read the container with `GeometryReader` or branch on size
   class instead (adl-02).
3. **A split must adapt to its width.** A `NavigationSplitView` with no `horizontalSizeClass` branch ships
   the regular-width split onto compact iPhone where it collapses unpredictably; gate the split or accept
   the automatic collapse deliberately (adl-03).
4. **A Universal layout reads its size class.** A view with device-dependent arrangement and **zero**
   `@Environment(\.horizontalSizeClass)` / `verticalSizeClass` reads never reacts to iPad-regular,
   landscape, or multitasking (adl-04).
5. **Prefer the native adaptive primitive.** A manual `if geo.size.width > …` ladder choosing between fixed
   layouts is what `ViewThatFits` (iOS 16) is for; a fractional-of-container width is
   `containerRelativeFrame` (iOS 17), not `UIScreen` arithmetic (adl-05/adl-06). A `GeometryReader` wrapped
   solely to make a size-class-shaped decision is the anti-pattern `horizontalSizeClass` replaces (adl-07).

Full ❌→✅ + the canonical adaptive exemplars: `references/adaptive-layout-patterns.md`.

## Defect index (adl-01 … adl-07)

`id · tell · severity · fix · open reference`. Severities: **hard** (deprecated / device-frozen and
never-right for full-screen content), **warning** (compiles but non-adaptive), **advisory** (judgment /
prefer-native). `auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| adl-01 | full-screen content pinned to a literal `.frame(width: <number>)` → device-frozen, letter-boxes on iPad / clips in landscape & Split View | warning | flag | `adaptive-layout-patterns.md` |
| adl-02 | `UIScreen.main.bounds` / `UIScreen.main` used as a layout-width oracle — **deprecated iOS 16+**, no scene/multitasking context | hard | flag | `adaptive-layout-patterns.md` |
| adl-03 | `NavigationSplitView { … }` with no `horizontalSizeClass` branch in scope → regular-width split shipped onto compact iPhone | warning | flag | `adaptive-layout-patterns.md` |
| adl-04 | a layout file with arrangement logic but **zero** `@Environment(\.horizontalSizeClass)` / `verticalSizeClass` reads → never reacts to size class | advisory | flag | `adaptive-layout-patterns.md` |
| adl-05 | a manual `if … size.width >` ladder switching fixed layouts where `ViewThatFits` (iOS 16) is the idiom | advisory | flag | `adaptive-layout-patterns.md` |
| adl-06 | a fractional-of-screen width computed by arithmetic (`* 0.5`, `/ 2`) instead of `containerRelativeFrame` (iOS 17) | advisory | flag | `adaptive-layout-patterns.md` |
| adl-07 | `GeometryReader` wrapped only to make a width threshold decision → use `horizontalSizeClass` instead | warning | flag | `adaptive-layout-patterns.md` |

**adl-02 is the only hard-fail; adl-03 cross-refs adaptive-navigation, adl-02 cross-refs uikit-overuse.**
`UIScreen.main` is **deprecated on iOS 16+** (scene-less) — replace it, do not gate it behind
`#available`. A `swiftui-ctx lookup UIScreen` returns a "looks like a UIKit/AppKit type" note (it is not a
SwiftUI symbol) — corroborating that the layout answer is `GeometryReader`/size class, not `UIScreen`.

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` / `swiftui-ctx lookup
--platform ios` — read, never restate):** `@Environment(\.horizontalSizeClass)` /
`@Environment(\.verticalSizeClass)` (`UserInterfaceSizeClass`, `.compact`/`.regular`), `ViewThatFits`,
`containerRelativeFrame(_:)` (and `(_, count:span:spacing:alignment:)`), `NavigationSplitView`
(`{ }` / `(columnVisibility:)` shapes), `GeometryReader`, `AnyLayout`, `\.supportsMultipleWindows`
environment value. The size-class environment keys are `UserInterfaceSizeClass`; on iPhone the horizontal
class is `.compact` in portrait and (most models) `.compact` in landscape, `.regular` only on the largest
Plus/Max in landscape — so a size-class branch is the only correct device test, never a model name.

**Deprecation trap (real but wrong on iOS):** `UIScreen.main` / `UIScreen.main.bounds` — **deprecated iOS
16+**, returns the wrong rect under Split View / Slide Over and has no scene context; it is a UIKit symbol,
not a SwiftUI layout API (adl-02).

No invented names are central to this domain; if audited code reaches for a layout symbol you can't place,
confirm via swiftui-ctx (`lookup --platform ios` **exit 3** = likely hallucination or no-iOS-arm symbol) +
Sosumi before flagging, and cross-check the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/adaptive-layout-patterns.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target** (`project.pbxproj`
   `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) **and the target device family**
   (`TARGETED_DEVICE_FAMILY` — `1` = iPhone, `2` = iPad, `1,2` = Universal). A **Universal** target is what
   makes non-adaptive layout a defect; an iPhone-only target relaxes adl-03/adl-04 to advisory. The project
   floor is **iOS 17**, so `ViewThatFits` (iOS 16) and `containerRelativeFrame` (iOS 17) are both available
   without a gate — confirm against `floors-master.md`. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-adaptive-layout --dir <sources> --json /tmp/adl.json --sarif /tmp/adl.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, adl-01…adl-07) plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a structural miss can't masquerade as clean; READ those by hand. The runner only LOCATES —
   never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a
   `.frame(width:)` wraps full-screen content or a fixed chip, whether a `NavigationSplitView` is genuinely
   meant to collapse on compact, whether a file with no size-class read actually *has* device-dependent
   arrangement, and whether a `GeometryReader` is doing real geometry or just a width threshold are all
   invisible to grep. Build a per-file inventory: each `.frame(width:)` + what it wraps; each
   `NavigationSplitView` + the size-class reads in scope; each `UIScreen.main` use; each `GeometryReader`
   + what it reads.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `.frame(width: 393)` on a full-screen `VStack`, a `UIScreen.main.bounds` width, a
   `NavigationSplitView` in a file with no `horizontalSizeClass`). A fixed width on a genuinely fixed
   element, an iPhone-only target's deliberate single layout, or a `GeometryReader` doing real per-pixel
   drawing geometry is *not* a defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a floor you're unsure of, the canonical adaptive shape,
   whether a primitive exists on iOS), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read its `consensus`
   (canonical shape — e.g. `ViewThatFits` `(in)` / `{ }`, `containerRelativeFrame` `(_)`,
   `NavigationSplitView` `{ }` / `(columnVisibility)`), `recommended` permalink, `introduced_ios` (surfaces
   at `result.introduced_ios`, **not** under `result.availability`), and `co_occurs_with`; a `lookup`
   **exit 3** (or a "looks like a UIKit/AppKit type" note for `UIScreen`) corroborates a no-SwiftUI-arm
   symbol. (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor — the reconciled floor wins. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a judgment/structural call: which
   axis to branch on, whether a split should collapse, what the container width should be — so all are
   `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅
   "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in
   `## Correct`, backed by a real iOS example fetched with `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx
   file <recommended.id> --smart` whose GitHub permalink (plus the Sosumi `doc:`) goes in `## Source`. The
   adl-01/adl-05 ✅ is grounded in the live `swiftui-ctx lookup ViewThatFits --platform ios` consensus + its
   recommended iOS permalink (see `references/adaptive-layout-patterns.md`). Leave `flag-only` findings
   `open` with that ✅ in `## Correct`. If a gate above the project floor is needed, route via
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. you replaced `UIScreen.main.bounds` with a `GeometryReader` that now only reads a width
   threshold — adl-07), loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is
a structural/judgment call (which axis to branch on, whether full-screen content even owns that frame,
whether a split should collapse on compact), so all are `fix_mode: flag-only`. adl-02 is a hard-fail but
still flag-only — the replacement (`GeometryReader` vs `horizontalSizeClass`) depends on what the value fed.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/adaptive-layout/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/adaptive-layout/_index.md`.
- `domain: adaptive-layout`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every
  defect. `availability` reads from `floors-master.md` (the iOS floor, e.g. `ViewThatFits` iOS 16.0,
  `containerRelativeFrame` iOS 17.0, `NavigationSplitView` iOS 16.0, `horizontalSizeClass` iOS 13.0; adl-02
  is a **deprecation**, not a floor). `source` is an Apple URL + access date (fetched via Sosumi) or
  `verify against Xcode 26 SDK`. Body includes **`## Why it's wrong on iOS`**. Emit `cross_ref` on adl-02
  (→ `uikit-overuse`, the keep-both `UIScreen` seam), adl-03 (→ `adaptive-navigation`, the split-column
  seam), and any arrangement note (→ `layout-and-tables`) or sheet/popover note (→
  `presentation-sheets-modals`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `fixed-width/` | full-screen content is pinned to a literal `.frame(width:)` (adl-01) |
| `uiscreen-bounds/` | `UIScreen.main.bounds` / `UIScreen.main` is used as a layout oracle (adl-02) — `cross_ref` uikit-overuse |
| `split-no-sizeclass/` | a `NavigationSplitView` ships with no `horizontalSizeClass` branch (adl-03) — `cross_ref` adaptive-navigation |
| `no-size-class/` | a layout file has device-dependent arrangement but zero size-class reads (adl-04) |
| `prefer-viewthatfits/` | a manual width-`if` ladder where `ViewThatFits` is the idiom (adl-05) |
| `fractional-width/` | a fractional-of-screen width by arithmetic instead of `containerRelativeFrame` (adl-06) |
| `geometryreader-misuse/` | a `GeometryReader` wrapped only to make a width-threshold decision (adl-07) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/adaptive-layout/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/adaptive-layout-patterns.md` | the fixed-width / `UIScreen` / split-no-branch / missing size-class defects, the `ViewThatFits` and `containerRelativeFrame` idioms, and the canonical adaptive exemplars (adl-01…adl-07) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi (iOS pages) |
| `lint/grep-tells.tsv` | step LOCATE — this skill's declarative tier-1 grep rule set fed to the shared runner (adl-01…adl-07); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled iOS truth — `ViewThatFits` 16.0, `containerRelativeFrame` 17.0, `NavigationSplitView` 16.0, `horizontalSizeClass`/`verticalSizeClass` 13.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (project floor iOS 17; gate only symbols above it) + the deprecation-is-not-a-low-floor trap (adl-02 is replaced, never gated) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up layout symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup --platform ios`/`recipe` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (split-axis → adaptive-navigation, arrangement → layout-and-tables, sheet adaptivity → presentation-sheets-modals, `UIScreen` keep-both → uikit-overuse) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-adaptive-layout --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, adl-01…adl-07) covering the literal
`.frame(width:)`, the `UIScreen.main.bounds` layout oracle, the `NavigationSplitView` shell, the
manual width-`if` ladder, the fractional-width arithmetic, and the `GeometryReader`-for-threshold smell.
The grep tier **stands alone** (ast-grep is not required and not installed); structural absence calls (a
`NavigationSplitView` with *no* size-class read anywhere in the file — adl-03/adl-04) are LOCATED broadly by
grep and resolved by the agent in READ. It runs a per-file **parse probe** (surfaces "did not fully parse"
so a structural miss can't look clean), emits unified **JSON + SARIF**, and exits **2** on the adl-02
hard-fail for a CI gate. It only LOCATES — always READ each hit in full before reporting (step 3). The thin
`scripts/adaptive-layout-lint.sh` is a pointer to this runner. Engine + rule-file format + JSON/SARIF shape
+ safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
