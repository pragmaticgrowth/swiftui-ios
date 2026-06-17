---
name: audit-swiftui-adaptive-navigation
description: Audits a finished or in-progress iOS SwiftUI codebase for navigation-shell and toolbar defects on iOS 17+ (iPhone + iPad) and writes per-finding Markdown to swiftui-audits/. Use when the user says the navigation, sidebar, split view, title, or toolbar look wrong or collapse oddly on iPhone; when they ask to verify NavigationStack, NavigationSplitView, navigationDestination, columnVisibility, toolbar placements, ToolbarSpacer, navigationTitle, or navigationBarTitleDisplayMode; when AI wrote a deprecated NavigationView, an UNCONDITIONAL NavigationSplitView with no size-class gate, the deprecated navigationBarTitle, the deprecated navigationBarLeading/navigationBarTrailing placements, or navigationSplitViewColumnWidth on a detail column; or when a column is hidden by frame hacks instead of a columnVisibility binding. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for UIKit UINavigationController/UISplitViewController internals, the general availability sweep, or writing new navigation UI from scratch.
---

# Audit SwiftUI Navigation & Toolbars (Adaptive Navigation)

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way the navigation shell and toolbar go wrong on an
iOS 17+ (iPhone + iPad) target: a deprecated `NavigationView`, an **unconditional** `NavigationSplitView`
that collapses oddly on iPhone, two- vs three-column confusion, frame-hack column hiding, the deprecated
`navigationBarLeading`/`navigationBarTrailing` placements, the deprecated `navigationBarTitle`, and the
detail-column-width no-op. Findings are written to disk in the toolkit's unified schema; certain
mechanical defects are fixed under the fix-safety protocol. This is never a from-scratch navigation
generator.

The iPhone wants a **push/pop stack** (`NavigationStack`); the iPad (regular width) wants a
**multi-column** `NavigationSplitView`. The containers exist on both, but on iOS `NavigationStack` is the
**primary** shell — `NavigationSplitView` is the *adaptive* choice that must be **gated to regular width /
iPad idiom**, never used unconditionally, because on compact-width iPhone it collapses to a stack with
surprising behavior. Be suspicious wherever AI wrote an unconditional split view or a macOS-shaped nav.

## Boundary / seam note (stay in lane)

- **UIKit `UINavigationController` / `UISplitViewController` / `UIToolbar` internals are out of scope.** If
  audited code bridges to a UIKit nav or toolbar, note it in one line and route the *whether-to-bridge*
  decision to `audit-swiftui-uikit-overuse` and the *how* to `audit-swiftui-uikit-interop` — do not audit
  UIKit internals here.
- **`NavigationView` deprecation-flagging** is co-owned: `audit-swiftui-api-currency` owns the
  deprecation *flag*; **this skill owns the structural migration** to `NavigationStack`/`NavigationSplitView`.
  Emit a `cross_ref: api-currency` on a `NavigationView` finding.
- **Size-class gating of the split view** (`horizontalSizeClass`/`UIDevice.userInterfaceIdiom` companion
  note) crosses into `audit-swiftui-adaptive-layout`; the **structural** nav decision (split-vs-stack)
  stays here. The **push-vs-modal** decision (should this be a `.sheet` or a push?) crosses into
  `audit-swiftui-presentation-sheets-modals`. Sidebar `List` *styling* crosses into
  `audit-swiftui-controls-forms`; the `ToolbarSpacer` glass era crosses into `audit-swiftui-liquid-glass`.
  Cross_ref, don't double-own.

## The three non-negotiable iOS rules

1. **iPhone shell = `NavigationStack`; iPad/regular-width shell = a *gated* `NavigationSplitView`.**
   `NavigationView` is deprecated; `NavigationStack` (iOS 16.0+) is the primary push/pop shell and the
   correct drill-down container. An **unconditional** `NavigationSplitView` (no `horizontalSizeClass` /
   `userInterfaceIdiom` gate) is the defect — it collapses oddly on iPhone (nav-02).
2. **Drive columns with the binding, never the frame.** Column show/hide is the `columnVisibility:`
   initializer parameter bound to a `NavigationSplitViewVisibility` — not a boolean `+`
   `.frame(maxWidth: 0)` hack.
3. **The iOS navigation bar is real — use it.** `.topBarLeading`/`.topBarTrailing`/`.bottomBar` are the
   **correct** iOS placements (iOS 14.0+, current); `.navigationBarLeading`/`.navigationBarTrailing` are
   **deprecated** (→ `.topBarLeading`/`.topBarTrailing`); `navigationBarTitle` is **deprecated** (→
   `navigationTitle`). `navigationBarTitleDisplayMode(.inline/.large)` is iOS-only and **correct** — keep
   it.

**The shell test:** is this an iPhone target (or compact-width path) that wants drill-down? →
`NavigationStack`. Is it iPad/regular-width and wants a persistent sidebar? → `NavigationSplitView`
**gated to regular width / iPad**. Full reasoning + the column-map artifact:
`references/navigation-shell-and-columns.md`.

**Grounded ✅ (the consensus iOS shell).** `swiftui-ctx lookup NavigationStack --platform ios` →
`introduced_ios: 16.0`, `deprecated: false`. The trailing-closure `NavigationStack { … }` with
`.navigationDestination` for type-safe push is the iOS master-detail consensus
(`recipe navigationstack-master-detail`). This is the `## Correct` to put in every shell finding — not a
hand-written snippet. Real iOS call site (`airbnb/lottie-ios`, ★26763, `min_ios: 16`):

```swift
NavigationStack {
    List(items) { item in
        NavigationLink(item.name, value: item)
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
// https://github.com/airbnb/lottie-ios/blob/906e79b0648c16f02ad5844e345481ae05a94afe/Example/Example/ExampleApp.swift#L22
// doc: https://sosumi.ai/documentation/swiftui/navigationstack
```

## Defect index (nav-01 … nav-12)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (build break / deprecated removal
risk / never-correct on iOS), **warning** (compiles but non-adaptive / silently no-ops), **advisory**
(judgment / craft). `auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| nav-01 | `NavigationView {` — deprecated container → `NavigationStack`/`NavigationSplitView` | hard-fail | auto | `navigation-shell-and-columns.md` |
| nav-02 | **unconditional** `NavigationSplitView {` with no `horizontalSizeClass`/`userInterfaceIdiom` gate → collapses oddly on iPhone | warning | flag | `navigation-shell-and-columns.md` |
| nav-03 | three-column `init(sidebar:content:detail:)` whose `content:` is `EmptyView()`/placeholder → should be 2-column | warning | flag | `navigation-shell-and-columns.md` |
| nav-04 | boolean `+` `.frame(maxWidth: shown ? .infinity : 0)` (or `width: 0`) to hide a column | warning | flag | `navigation-shell-and-columns.md` |
| nav-06 | `.navigationBarLeading` / `.navigationBarTrailing` placement — **deprecated** → `.topBarLeading` / `.topBarTrailing` | hard-fail | auto | `toolbar-placements-and-titles.md` |
| nav-07 | `.navigationBarTitle(` — **deprecated** → `navigationTitle` (keep `navigationBarTitleDisplayMode`) | hard-fail | auto | `toolbar-placements-and-titles.md` |
| nav-08 | `.navigationSplitViewColumnWidth(` on the **detail** closure — silent no-op on detail | warning | flag | `inspector-and-detail-width.md` |
| nav-09 | sidebar `List` missing `.listStyle(.sidebar)` → wrong material / selection highlight (iPad split sidebar) | advisory | flag | `navigation-shell-and-columns.md` |
| nav-10 | `.searchable(` on a column instead of the `NavigationSplitView`/`NavigationStack` → wrong toolbar slot | advisory | flag | `toolbar-placements-and-titles.md` |
| nav-11 | `ToolbarSpacer(` / `SpacerSizing` used ungated under a < iOS 26 floor | warning | flag | `toolbar-placements-and-titles.md` |
| nav-12 | empty detail is a blank view, not `ContentUnavailableView` | advisory | flag | `inspector-and-detail-width.md` |

> **nav-05 retired on iOS.** On macOS, nav-05 flagged `.topBarLeading`/`.topBarTrailing` as a compile
> error (macOS-absent). On **iOS those placements are CORRECT** (`introduced_ios: 14.0`, not deprecated) —
> the rule is **inverted out**: a `.topBarLeading`/`.topBarTrailing` placement is **never** a finding here.

**One claim is UNVERIFIED — carry as the reference's `verify against Xcode 26 SDK`, never as fact:** the
`navigationSplitViewColumnWidth` **no-op on the detail column** (nav-08, practitioner-confirmed) and the
inspector standard width (**225 pt** Apple examples / **270 pt** community-observed).

## The real API, at a glance

**Real (current on an iOS 17+ target):** `NavigationStack` (the primary shell; iOS 16.0+) +
`navigationDestination(for:)` (type-safe push; iOS 16.0+), `NavigationSplitView` (2-/3-col inits +
`columnVisibility:` / `preferredCompactColumn:` variants, iOS 16.0+) **gated to regular width / iPad**,
`NavigationSplitViewVisibility` (`.all`/`.doubleColumn`/`.detailOnly`/`.automatic`), `navigationTitle(_:)`
(iOS 13.0+), `navigationBarTitleDisplayMode(_:)` (`.inline`/`.large`/`.automatic`, iOS 14.0+ — **iOS-only
and correct**), the iOS placements `.topBarLeading` / `.topBarTrailing` / `.bottomBar` / `.principal` /
`.primaryAction` (iOS 14.0+, current), `ToolbarItem` / `ToolbarItemGroup`, `ToolbarSpacer` + `SpacerSizing`
(`.fixed`/`.flexible`, **iOS 26.0+** — gate it), `.searchable` (iOS 16.0+), `ContentUnavailableView`
(iOS 17.0+), `.inspector(isPresented:)` + `.inspectorColumnWidth` (iOS 17.0+).

**Deprecated (replace):** `NavigationView` (→ `NavigationStack` / `NavigationSplitView`),
`.navigationBarLeading` / `.navigationBarTrailing` (→ `.topBarLeading` / `.topBarTrailing`),
`navigationBarTitle` (→ `navigationTitle`).

Signatures, floors, and the full ❌→✅ rewrites: the routed `references/*.md`. Floor *values* are the
reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate
them.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) and the **target
   idiom** (iPhone-only / iPad / Universal). Both are load-bearing: nav-02 (unconditional split view) is a
   real defect on a Universal/iPhone target but expected on an iPad-only target; nav-11 (`ToolbarSpacer`)
   fires **only** when the floor is **below iOS 26**. Record both.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-adaptive-navigation --dir <sources> --json /tmp/nav.json --sarif /tmp/nav.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + the tier-2 structural ast-grep rule
   (`lint/ast-grep/*.yml` — nav-03's empty-middle-column shape, which grep can't express; nav-04's
   frame-hack and nav-08's columnWidth-on-detail stay grep tells, READ-confirmed, per the rule-file note),
   plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a
   flagged file did not fully parse, so a structural miss can't masquerade as clean; READ those by hand.
   The runner only LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a
   `NavigationStack` is the *shell* or a *column drill-down*, whether a `NavigationSplitView` is **gated**
   to regular width, whether a three-column `content:` is truly empty, and whether a `columnWidth` sits on
   the detail closure are all cross-line facts invisible to grep. Build a per-file inventory: each
   navigation container + its role (shell/column) + its size-class/idiom gate (✅/❌) + its columns + each
   toolbar placement + each title modifier.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `navigationBarTitle` call, a `NavigationView`, a `NavigationSplitView` with no
   size-class branch anywhere in the file on a Universal target).
5. **VERIFY.** For anything ≤ ~70% confidence (a placement you're unsure is current, a floor you can't
   place, the detail-column no-op behavior), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `swiftui-ctx deprecated <api>` for a currency/deprecation rule): read `introduced_ios`, `deprecated`,
   `migrate_to`/`replacement`, the consensus shape, and the `recommended` permalink; a `lookup`
   **exit 3** (no iOS arm) corroborates a platform-wrong finding. (b) **Spec** — confirm via **Sosumi**:
   `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
   Promote with the citation or discard. Carry nav-08's no-op + inspector width as
   `source: verify against Xcode 26 SDK` — never as fact.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Emit `cross_ref` on shared-seam findings (nav-01 → `api-currency`; nav-02 → `adaptive-layout`).
   Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (nav-01/06/07 — the mechanical container/placement/title renames), one
   conventional commit per finding citing its `rule_id`, never weaken a check. The ✅ "Correct" is **not a
   hand-written snippet** — it is the swiftui-ctx **consensus shape** put in `## Correct`, backed by a
   real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink
   (plus the Sosumi `doc:`) goes in `## Source` as the canonical example. Leave `flag-only` findings
   `open` with that ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep each fixed file to confirm the tell no longer matches; record the evidence
   in `## Fix applied?`. Re-confirm every citation still resolves and still says its `iOS` floor. If a
   fix introduced a new tell (e.g. a split view that now needs a size-class gate), loop that file back to
   DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding (especially nav-02 unconditional-split-view, which needs a
READ across the whole file to confirm there is *no* size-class/idiom branch, and nav-03
empty-middle-column). Auto-fix only the mechanical container/placement/title set (nav-01/06/07);
everything else is `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/adaptive-navigation/<context>/NN-slug.md` (one finding per file,
  zero-padded, ordered). Per-run index: `swiftui-audits/adaptive-navigation/_index.md`.
- `domain: adaptive-navigation`. Frontmatter is the canonical schema; `fix_mode` is `auto` for
  nav-01/06/07, else `flag-only`. `availability` reads from `floors-master.md`. `source` is an Apple URL
  + access date (fetched via Sosumi) or `verify against Xcode 26 SDK`. Emit `cross_ref` per the
  boundary/seam note.

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `navigation-shell/` | a deprecated `NavigationView`, or an unconditional `NavigationSplitView` with no size-class/idiom gate (nav-01, nav-02) |
| `column-structure/` | a 3-col init with an empty middle, a frame-hack column hide, or a missing sidebar style (nav-03, nav-04, nav-09) |
| `toolbar-placement/` | a deprecated placement, or `.searchable` on the wrong slot (nav-06, nav-10) |
| `titlebar-title/` | a deprecated `navigationBarTitle` used instead of `navigationTitle` (nav-07) |
| `inspector-detail-width/` | a `columnWidth` no-op on detail, or a blank empty-detail (nav-08, nav-12) |
| `availability-gating/` | `ToolbarSpacer`/`SpacerSizing` ungated under a < iOS 26 floor (nav-11) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/adaptive-navigation/` with a lowercase-hyphen slug naming the sub-category, and note it
in the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs
is a hard requirement.* Two runs over the same code produce structurally identical trees.

> **Go-beyond artifact (optional):** `swiftui-audits/adaptive-navigation/_column-map.md` classifying
> every navigation container as `shell`/`column-drilldown` with a column-count and size-class-gate
> coverage score — see `references/navigation-shell-and-columns.md`.

## Reference routing

| File | Open when |
|---|---|
| `references/navigation-shell-and-columns.md` | shell-vs-stack, the size-class/idiom gate on a split view, 2-/3-column inits, `columnVisibility` binding, sidebar `List` style, the column map (nav-01/02/03/04/09) |
| `references/toolbar-placements-and-titles.md` | current vs deprecated placements, `navigationTitle`/`navigationBarTitleDisplayMode`, `.searchable` slot, `ToolbarSpacer` gating (nav-06/07/10/11) |
| `references/inspector-and-detail-width.md` | the detail-column-width no-op, `.inspector` workaround, empty-detail `ContentUnavailableView` (nav-08/12) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + tier-2 structural ast-grep); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | toolbar/navigation hallucinated names |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule + the size-class idiom checks (nav-02, nav-11) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-adaptive-navigation --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this
skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`,
nav-01/02/04/06/07/08/09/10/11/12) + the **tier-2 ast-grep** structural rule (`lint/ast-grep/*.yml` —
nav-03 empty-middle-column shape) that grep cannot express; nav-04 frame-hack and nav-08
`columnWidth`-on-`detail:` stay grep tells (READ-confirmed) because they can't be a clean ast-grep rule.
It runs a per-file **parse probe** (surfaces "did not fully parse" so a structural miss can't look clean),
emits unified **JSON + SARIF**, exits **2** on any hard-fail (nav-01/06/07) for a CI gate, and **degrades
to grep-only with a notice** if ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster:
`brew install ast-grep`). It only LOCATES — always READ each hit in full before reporting (step 3). The
thin `scripts/nav-lint.sh` is a pointer to this runner. Engine + rule-file format + JSON/SARIF shape +
safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
