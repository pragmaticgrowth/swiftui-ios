---
name: audit-swiftui-layout-and-tables
description: Audits an iOS SwiftUI codebase for layout and Table defects where an iPad/Mac-shaped grid or a device-frozen layout breaks on iPhone, and writes per-finding Markdown to swiftui-audits/. Use when the user says a Table shows one squished column on iPhone, a screen letter-boxes on iPad, content clips in landscape, or the app feels like a Mac window on a phone; when they ask to verify a Table used as the main collection, a size-class fallback to a List on compact width, sortOrder on iPad, ViewThatFits, Grid, containerRelativeFrame, fixedSize/layoutPriority, or a custom Layout protocol; when AI wrote a Table as the primary list with no compact List, a blanket fixedSize on a container, a fixed full-screen frame, or a hand-rolled Layout a built-in covers. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for size-class depth (adaptive-layout), NavigationSplitView columns (adaptive-navigation), control style variants (controls-forms), large-Table render cost (view-performance), or new layout from scratch.
---

# Audit SwiftUI Layout & Tables

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way an iPad/Mac-shaped grid or a device-frozen layout breaks on
iPhone: a `Table` used as the **primary collection** with no compact-width fallback to a `List`, a fixed
full-screen `.frame(width:)` that letter-boxes on iPad, a blanket `.fixedSize()` that clips on a small
screen, a `Table` with no `sortOrder` on a regular-width pane, and a custom `Layout` where a built-in
(`Grid`/`ViewThatFits`/`containerRelativeFrame`) would do. Findings are written to disk in the toolkit's
unified schema. This is never a from-scratch layout generator.

The inversion that drives this skill: **on iOS the `List` is the primary collection.** `Table` is an
**iPad/Mac multi-column control** — on iPhone (compact width) it collapses to a single squished column, so
shipping a `Table` as the main list with no size-class fallback is the defect, not the cure. The training
corpus carries a lot of Mac code where `Table` *is* the default data grid, so AI reaches for it on iOS
where a `List` (or a width-gated `Table`-on-iPad / `List`-on-iPhone split) is correct. Be suspicious
wherever AI modeled a data grid or froze a layout to a device width.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **`Table` collapse on iPhone is a shared seam.** The **multi-column structure** of the `Table` is
  **this skill** (lt-01). The **size-class adaptation** ("gate the `Table` to regular width, show a `List`
  on compact") is `audit-swiftui-adaptive-layout`'s — emit `cross_ref: adaptive-layout` and defer the
  `horizontalSizeClass` branching depth there.
- **Fixed full-screen frame** (`.frame(width: 393)` for content that should fill the device) is an
  **adaptive concern owned by `adaptive-layout`**; lt-02 here is a **companion note** — flag the raw
  arrangement, emit `cross_ref: adaptive-layout`, and defer the size-class fix there.
- **`NavigationSplitView` columns / sidebar sizing** belong to `audit-swiftui-adaptive-navigation`.
- **Control density.** `controlSize` exists on iOS (15.0+) but its `.small`/`.mini` densities are a
  pointer-driven Mac idiom — on iPhone, touch targets must not shrink below the 44pt minimum. Style
  variants (`.buttonStyle`/`.pickerStyle`) belong to `audit-swiftui-controls-forms`; `cross_ref` there.
- **Large-`Table` / large-`List` render cost** (≳5,000 rows, heavy cells) belongs to
  `audit-swiftui-view-performance`; note the ceiling in one line and `cross_ref`.
- **A `GeometryReader` feeding a `Canvas`** (drawing geometry) belongs to `audit-swiftui-drawing-canvas`;
  this skill owns `GeometryReader`/`Layout` only when it is doing **layout arrangement**.

## The layout rules (the judgment core — iOS-inverted)

1. **`List` is the iPhone primary; `Table` is an iPad/Mac control.** A `Table` used as the **main
   collection** with no size-class fallback to a `List` collapses to one squished column on iPhone. Gate
   the `Table` to regular width and show a `List` on compact, or use a `List` outright (lt-01).
2. **Don't freeze a layout to a device width.** A fixed full-screen `.frame(width:)` letter-boxes on iPad
   and clips in landscape; size content to its container, not to a literal iPhone point value (lt-02).
3. **A `Table` shown on iPad should sort.** On regular width users can sort columns — drive it with
   `sortOrder: $binding` to `[KeyPathComparator]` and `value:` columns. On a compact-only collection this
   is moot (lt-03).
4. **Reach for the targeted tool before the blunt one.** `layoutPriority` / single-axis
   `fixedSize(horizontal:vertical:)` / `containerRelativeFrame` before a blanket `.fixedSize()` (lt-04) or
   a custom `Layout` (lt-05).
5. **Prefer a built-in container.** `Grid` / `ViewThatFits` / `containerRelativeFrame` (all iOS 16/17)
   express most arrangements a hand-rolled `: Layout` reproduces, with free adaptivity (lt-05).

Full ❌→✅ + the canonical width-adaptive `Table`/`List` exemplar:
`references/layout-window-sizing.md` and `references/tables-and-density.md`.

## Defect index (lt-01 … lt-05)

`id · tell · severity · fix · open reference`. Severities: **warning** (compiles but breaks on a device
class), **advisory** (judgment / density). All are `flag` (the correct fix is a structural/judgment call).

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| lt-01 | `Table(` used as the primary collection with no `horizontalSizeClass`/compact `List` fallback → one squished column on iPhone | warning | flag | `tables-and-density.md` |
| lt-02 | fixed full-screen `.frame(width: <literal>)` for content that should fill the device → letter-boxes on iPad, clips in landscape | warning | flag | `layout-window-sizing.md` |
| lt-03 | `Table(` shown on iPad/regular with no `sortOrder:` binding / no `KeyPathComparator` → non-sortable where users expect it | advisory | flag | `tables-and-density.md` |
| lt-04 | blanket both-axis `.fixedSize()` on a *container* → freezes both axes, clips on a small screen | advisory | flag | `layout-window-sizing.md` |
| lt-05 | custom `: Layout` conformance where a built-in (`Grid`/`ViewThatFits`/`containerRelativeFrame`) fits | advisory | flag | `custom-layout.md` |

**No deprecation rule lives here.** The macOS `tableStyle(.inset(alternatesRowBackgrounds:))` deprecation
does **not apply to iOS** — `alternatingRowBackgrounds` is **iOS-ABSENT** (macOS-only; `swiftui-ctx lookup
alternatingRowBackgrounds --platform ios` exits 3). Do not flag it on an iOS target. lt-01 and lt-02
cross-ref `adaptive-layout` (the size-class owner).

## The real API, at a glance

**Real (exist on iOS, floors are the reconciled truth in `floors-master.md` — read, never restate):**
`Table` / `TableColumn` (iOS 16.0), `KeyPathComparator` (Foundation), `controlSize(_:)` (iOS 15.0),
`fixedSize()` / `fixedSize(horizontal:vertical:)`, `layoutPriority(_:)`, `containerRelativeFrame(_:alignment:)`
(iOS 17.0), the `Layout` protocol (iOS 16.0), `Grid`/`GridRow` (iOS 16.0), `ViewThatFits` (iOS 16.0),
`LazyVStack`/`LazyVGrid` (iOS 14.0). Size-class branching uses `@Environment(\.horizontalSizeClass)`.
The project floor is **iOS 17**, so all of these are unconditionally available (no gate) — confirm in
`floors-master.md` before relying on a floor.

**iOS-ABSENT (macOS-only — do NOT flag/suggest on an iOS target):** `alternatingRowBackgrounds`,
`TableColumnForEach`, the `tableStyle(.inset(alternatesRowBackgrounds:))`/`.bordered` deprecation, and the
scene-sizing modifiers `defaultSize(_:)` / `windowResizability(_:)` (no resizable window on iOS).

No invented names are central to this domain; if audited code reaches for a layout/Table symbol you can't
place, confirm via swiftui-ctx (`lookup --platform ios` **exit 3** = iOS-absent or likely hallucination) +
Sosumi before flagging, and cross-check `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.
Signatures + full ❌→✅: `references/layout-window-sizing.md`, `references/tables-and-density.md`,
`references/custom-layout.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) and the
   **target family** (iPhone-only vs Universal/iPad). The target family is load-bearing: a `Table` on an
   iPhone-only target with no iPad is still a one-column collapse; on a Universal target it wants a
   width-gated `Table`/`List` split. The project floor is **iOS 17** (`ios-gating.md` §5) — every symbol
   here is below it, so no gate is needed for a fix. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-layout-and-tables --dir <sources> --json /tmp/lt.json --sarif /tmp/lt.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, lt-01…lt-05) + tier-2 structural
   ast-grep rules (`lint/ast-grep/*.yml` — lt-01 Table-with-no-sizeclass-fallback, lt-03
   Table-without-sortOrder), plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its
   `parse_warnings`** — a flagged file did not fully parse, so a structural miss can't masquerade as
   clean; READ those by hand. The runner only LOCATES — never treat a hit as a finding. Engine + rule-file
   format + degradation: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a `Table`
   is the screen's primary collection or a small iPad-detail pane, whether the file branches on
   `horizontalSizeClass` anywhere, whether a `.frame(width:)` is a literal device width on full-screen
   content, and whether a `.fixedSize()` sits on a container vs a single `Text` are all invisible to grep.
   Build a per-file inventory: each `Table` + whether it is size-class-gated + its sort wiring; each fixed
   `.frame(width:)` + whether it is full-screen content; each container `.fixedSize()`; each `: Layout`.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (a `Table` that is the screen's main collection with no compact branch anywhere in the
   file/module; a container `.fixedSize()`; a literal full-screen `.frame(width:)`). A lone glanceable
   signal (a tiny static `Table` inside an iPad-only detail split, a `.frame(width:)` on a fixed-size
   badge) is *not* a defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you can't place, an iOS floor you're unsure of,
   the canonical shape), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read its
   `consensus` (the canonical shape), `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a
   `lookup --platform ios` **exit 3** means the symbol has **no iOS arm** (macOS-only — do NOT flag it on
   iOS) or is a hallucination. (b) **Spec** — confirm via **Sosumi**:
   `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol — read **only the iOS
   arm** of the availability string (`ios-gating.md` §4). Cross-check `introduced_ios` against
   `floors-master.md`. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
   **Deeper corpus evidence (lt-05 custom `Layout`):** before flagging a `: Layout` conformer as needless,
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx conformances Layout` for real conformers + permalinks —
   almost all are `FlowLayout`, the one shape no built-in covers; cite that permalink to distinguish a
   legit wrap-flow `Layout` from one a `Grid`/`ViewThatFits` would replace.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   one conventional commit per finding citing its `rule_id`, never weaken a check. Every defect here is
   `fix_mode: flag-only` — the correct fix is a structural/judgment call (does this collection want a
   width-gated split or an outright `List`; should content size to its container; does this `Table` want
   sort). The ✅ "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape**
   (`lookup --platform ios`) put in `## Correct`, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink
   (plus the Sosumi `doc:`) goes in `## Source`. Leave `flag-only` findings `open` with that ✅ in
   `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced
   a new tell (e.g. a `Table` you made sortable now needs an `.onChange(of: sortOrder)`), loop that file
   back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding. Everything here is `fix_mode: flag-only` because the correct
fix is a structural/judgment call (which collection wants a width split vs an outright `List`, whether
content should track its container, what a pane's density wants). A `Table` inside an iPad-only detail
column is correct, not a defect — confirm the target family and the size-class context before flagging.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/layout-and-tables/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/layout-and-tables/_index.md`.
- `domain: layout-and-tables`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every
  rule here. `availability` reads from `floors-master.md` (iOS floor / "iOS ABSENT" / "n/a"). `source` is
  an Apple URL + access date (fetched via Sosumi). Emit `cross_ref` on lt-01 and lt-02 (→ `adaptive-layout`),
  on a control-density note (→ `controls-forms`), and on any large-Table perf note (→ `view-performance`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `table-on-iphone/` | a `Table` is the screen's primary collection with no compact-width `List` fallback (lt-01) — `cross_ref` adaptive-layout |
| `device-frozen-frame/` | full-screen content is pinned to a literal `.frame(width:)` (lt-02) — `cross_ref` adaptive-layout |
| `table-sorting/` | a `Table` shown on iPad/regular has no `sortOrder`/`KeyPathComparator` (lt-03) |
| `sizing-fixedsize/` | a blanket both-axis `.fixedSize()` on a container clips on a small screen (lt-04) |
| `custom-layout/` | a custom `Layout` conformance where a built-in container fits (lt-05) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/layout-and-tables/` with a lowercase-hyphen slug naming the sub-category, and note it in
the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a
hard requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/layout-window-sizing.md` | the device-frozen `.frame(width:)` companion note and the `fixedSize`/`layoutPriority`/`containerRelativeFrame` confusion (lt-02/04) + the container-relative exemplar |
| `references/tables-and-density.md` | `Table`-on-iPhone collapse + the compact `List` fallback, the sort wiring, and the iOS control-density seam (lt-01/03) |
| `references/custom-layout.md` | a custom `Layout` conformance vs a built-in container, and the `GeometryReader`-vs-`Layout` seam (lt-05) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells lt-01…lt-05 + tier-2 structural lt-01 Table-no-sizeclass / lt-03 Table-without-sortOrder); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `Table`/`Grid`/`ViewThatFits`/`Layout` iOS 16.0, `controlSize` iOS 15.0, `containerRelativeFrame` iOS 17.0; `alternatingRowBackgrounds`/`TableColumnForEach` iOS-ABSENT) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up layout/Table symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule + `horizontalSizeClass` idiom (read only the iOS arm; the project floor is iOS 17, so a fix here needs no gate) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup --platform ios`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (`Table` collapse split, device-frozen frame, controlSize axis, large-Table perf) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-layout-and-tables --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this
skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, lt-01…lt-05) + **tier-2
ast-grep** structural rules (`lint/ast-grep/*.yml` — lt-01 Table-with-no-sizeclass-fallback, lt-03
table-without-sortOrder) that grep cannot express (the **absence** of a `horizontalSizeClass` branch in a
file carrying a `Table`, the **absence** of `sortOrder` inside a `Table` call span — both anchored on a
`kind: call_expression`). It runs a per-file **parse probe** (surfaces "did not fully parse" so a
structural miss can't look clean), emits unified **JSON + SARIF**, and **degrades to grep-only with a
notice** if ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster:
`brew install ast-grep`). It only LOCATES — always READ each hit in full before reporting (step 3). The
thin `scripts/lt-lint.sh` is a pointer to this runner. Engine + rule-file format + JSON/SARIF shape +
safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
