---
name: audit-swiftui-presentation-sheets-modals
description: Audits an iOS SwiftUI app for sheet, cover, and popover presentation defects that read as a stale or non-idiomatic modal — writing per-finding Markdown to swiftui-audits/. Use when the user says a sheet always covers the whole screen with no way to peek the content behind it, a half-sheet won't resize, a bottom sheet has no grab handle, a trivial confirmation takes over the entire screen, a popover renders full-screen on iPhone, or a sheet's background won't go clear; when they ask to verify .sheet, presentationDetents, presentationDragIndicator, .fullScreenCover, .popover, presentationBackground, or presentationContentInteraction on iOS; when AI wrote a content-rich .sheet with no .presentationDetents (so it is locked full-height when a partial/medium detent is the iOS 16+ idiom), a .fullScreenCover for a small dismissible dialog (where a .sheet is the idiom), or a .popover with no .presentationCompactAdaptation for compact width. AUDIT-ONLY, iOS-only, SwiftUI-only.
---

# Audit SwiftUI Presentation, Sheets & Modals

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, flag — every way a modal presentation reads as a pre-iOS-16, non-idiomatic
take-over: a content-rich `.sheet` locked full-height with **no `presentationDetents`** (the iOS 16+ idiom
is a resizable medium/custom detent so the user can peek the content behind), a `.fullScreenCover` used for a
**trivial dismissible dialog** where a `.sheet` is the idiom, a bottom sheet with **no
`presentationDragIndicator`** grab handle, a `.popover` with **no `presentationCompactAdaptation`** that
collapses to an opaque full-screen cover on compact width, and a custom `presentationBackground` /
`presentationContentInteraction` that is mis-applied. Findings are written to disk in the toolkit's unified
schema; no defect here is auto-fixed (every fix is a judgment call about modality and detent choice). This is
never a from-scratch modal generator.

**The iOS modal vocabulary changed in iOS 16 and AI under-uses it.** The training corpus is heavy with
pre-iOS-16 SwiftUI where `.sheet` had exactly one shape — a full-height card — so AI ships content-rich
sheets with no detents, reaches for `.fullScreenCover` to force "importance" on a dialog that should be a
dismissible sheet, and drops a `.popover` with no compact adaptation (which silently becomes a full-screen
cover on iPhone). The result compiles and looks plausible, but reads as a stale, heavy-handed modal on
modern iOS. Be suspicious wherever AI presented content in a `.sheet`, `.fullScreenCover`, or `.popover`.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **Push-vs-present and the navigation container are not mine.** Whether a flow should be a
  `NavigationStack` push (or a `NavigationSplitView` detail column on iPad) instead of a modal at all belongs
  to `audit-swiftui-adaptive-navigation`. This skill owns the **modal presentation surface** (`.sheet` /
  `.fullScreenCover` / `.popover`) and its detents/background/interaction — not the choice of navigation
  container. Note a "this should be a push, not a sheet" smell in one line and `cross_ref: adaptive-navigation`.
- **Keyboard avoidance and safe-area insets inside a sheet are not mine.** When a `TextField` inside a
  presented sheet is covered by the keyboard, or content collides with the home indicator / drag indicator
  region, that is `audit-swiftui-safe-area-keyboard` (`safeAreaInset`, `ignoresSafeArea(.keyboard)`,
  `.scrollDismissesKeyboard`). This skill owns the **presentation modifier**; `cross_ref: safe-area-keyboard`
  when the defect is the inset/keyboard behavior of the sheet's *content*.
- **Size-class layout of the presented content** (a two-column `ViewThatFits` body inside the sheet) is
  `audit-swiftui-adaptive-layout`. `.popover`'s **compact-adaptation** (psm-04) is mine — that is a
  *presentation* concern, not a content-layout one; `cross_ref: adaptive-layout` only when the sheet's body
  branches on `horizontalSizeClass` for its own arrangement.

## The presentation rules (the judgment core)

1. **A content-rich `.sheet` should offer detents.** Since iOS 16, `presentationDetents([.medium, .large])`
   (or a `.fraction`/`.height` custom detent) lets the user resize the sheet and peek the content behind. A
   `.sheet` whose body is a scrollable list / a form / a detail card and carries **no `presentationDetents`**
   is locked full-height — the pre-iOS-16 default — and reads as stale (psm-01).
2. **A bottom sheet with detents wants a grab handle.** `presentationDragIndicator(.visible)` is the iOS
   idiom that signals a resizable/dismissible sheet; a detented sheet with no drag indicator is missing the
   affordance (psm-02).
3. **Reserve `.fullScreenCover` for genuinely immersive / no-dismiss flows.** Onboarding, a camera/media
   capture, an interruptive sign-in. A `.fullScreenCover` wrapping a small confirmation / picker / settings
   dialog is the wrong modality — a `.sheet` (dismissible by swipe-down) is the iOS idiom (psm-03).
4. **A `.popover` must adapt for compact width.** On iPhone (compact horizontal size class) a `.popover`
   with no `presentationCompactAdaptation(_:)` silently becomes an opaque full-screen cover — almost never
   the intent. Set `.presentationCompactAdaptation(.popover)` / `.none`, or use a `.sheet` with a `.medium`
   detent for compact (psm-04).
5. **Custom presentation background / interaction is deliberate, not decorative.** `presentationBackground`
   (iOS 16.4) and `presentationContentInteraction(.scrolls)` (iOS 16.4) change how the sheet reads and
   behaves; flag a `presentationBackground(.clear)` with no visible material behind it, or a
   `presentationContentInteraction` applied to a non-detented sheet where it is a no-op (psm-05).

Full ❌→✅ + the canonical detented-sheet exemplar: `references/sheets-detents-covers.md`.

## Defect index (psm-01 … psm-05)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (never-correct on iOS),
**warning** (compiles but non-idiomatic), **advisory** (judgment / affordance). `auto` = mechanical
single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| psm-01 | content-rich `.sheet { … }` with no `.presentationDetents(…)` in its chain → locked full-height, pre-iOS-16 modal | warning | flag | `sheets-detents-covers.md` |
| psm-02 | a detented `.sheet` (carries `.presentationDetents`) with no `.presentationDragIndicator(.visible)` → missing grab-handle affordance | advisory | flag | `sheets-detents-covers.md` |
| psm-03 | `.fullScreenCover` wrapping a trivial dismissible dialog / picker / confirmation → wrong modality; a `.sheet` is the iOS idiom | warning | flag | `sheets-detents-covers.md` |
| psm-04 | `.popover(…)` with no `.presentationCompactAdaptation(…)` → opaque full-screen cover on compact-width iPhone | warning | flag | `sheets-detents-covers.md` |
| psm-05 | `presentationBackground(.clear)` with no material behind it, or `presentationContentInteraction` on a non-detented sheet (no-op) | advisory | flag | `sheets-detents-covers.md` |

**No defect here is a hard-fail or auto-fix.** Every fix is a modality/detent judgment (which detents, is
this immersive, does this popover want `.popover` or `.sheet` adaptation), so all are `flag-only`. psm-01 and
psm-04 cross-ref siblings (safe-area-keyboard for keyboard inside the sheet; adaptive-navigation for
"present-vs-push").

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` — read, never restate):**
`sheet(isPresented:onDismiss:content:)` / `sheet(item:…)`, `fullScreenCover(isPresented:…)` /
`fullScreenCover(item:…)`, `popover(isPresented:attachmentAnchor:arrowEdge:content:)`,
`presentationDetents(_:)` / `presentationDetents(_:selection:)`, `presentationDragIndicator(_:)`
(`.visible`/`.hidden`/`.automatic`), `presentationBackground(_:)` / `presentationBackground { }`,
`presentationContentInteraction(_:)` (`.scrolls`/`.resizes`/`.automatic`),
`presentationCompactAdaptation(_:)` / `presentationCompactAdaptation(horizontal:vertical:)`,
`presentationBackgroundInteraction(_:)`, `presentationCornerRadius(_:)`. Custom detents:
`PresentationDetent.fraction(_:)` / `.height(_:)` / `.medium` / `.large`, `CustomPresentationDetent`.

**Floor-gated (the iOS-16 inflection):** `presentationDetents` / `presentationDragIndicator` are **iOS 16.0**;
`presentationBackground` / `presentationContentInteraction` / `presentationCompactAdaptation` /
`presentationBackgroundInteraction` are **iOS 16.4**. Read the exact floors from `floors-master.md`. A fix
that introduces any of these under a target below its floor needs an `#available(iOS NN, *)` gate per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` — but with the iOS-17 deployment floor, all of these
are available unconditionally.

No invented names are central to this domain; if audited code reaches for a presentation modifier you can't
place, confirm via swiftui-ctx (`lookup` **exit 3** = likely hallucination or no-iOS-arm symbol) + Sosumi
before flagging, and cross-check the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/sheets-detents-covers.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — it sets which floor a
   fix may rely on (`presentationDetents`/`presentationDragIndicator` = iOS 16.0+;
   `presentationBackground`/`presentationContentInteraction`/`presentationCompactAdaptation` = iOS 16.4+;
   `.sheet` = iOS 13.0+, `.fullScreenCover` = iOS 14.0+, `.popover` = iOS 13.0+ — all from
   `floors-master.md`). At the iOS-17 deployment floor every detent/background modifier is available
   unconditionally; record the target so a sub-floor fix is gated.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-presentation-sheets-modals --dir <sources> --json /tmp/psm.json --sarif /tmp/psm.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, psm-01…psm-05), plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a structural miss can't masquerade as clean; READ those by hand. ast-grep tier-2 rules are
   optional and NOT installed in this environment; the grep tier stands alone. The runner only LOCATES —
   never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a `.sheet`'s
   chain carries `.presentationDetents`, whether the sheet's body is genuinely content-rich (a list/form/card
   that benefits from a medium detent) vs a tiny confirmation, whether a `.fullScreenCover` wraps an
   immersive flow or a trivial dialog, whether a `.popover` carries a compact adaptation, and whether a
   `presentationBackground(.clear)` has material behind it are all invisible to grep. Build a per-file
   inventory: each `.sheet`/`.fullScreenCover`/`.popover` + its presentation-modifier chain + the nature of
   its presented content.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a content-rich `.sheet` whose chain carries no `.presentationDetents`, a
   `.fullScreenCover` wrapping a one-button confirmation, a `.popover` with no compact adaptation). A small
   confirmation `.sheet` that is *meant* to be full-height, a genuinely immersive `.fullScreenCover`
   (onboarding/camera), or an iPad-only `.popover` that never appears on compact width is *not* a defect —
   judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a detent shape you can't place, a floor you're unsure of, the
   canonical detented-sheet shape, whether a modifier exists on iOS), run **both** evidence sources. (a)
   **Practice** — `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `swiftui-ctx deprecated <api>` for a currency rule): read its `consensus` (the canonical shape),
   `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a `lookup`
   **exit 3** (not-found, with a did-you-mean `suggestion`) corroborates a hallucination or a no-iOS-arm
   symbol. (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`
   for the protocol (never `WebFetch` `developer.apple.com`). Cross-check `introduced_ios` against
   `floors-master.md` and the Sosumi `doc:` floor — the reconciled floor wins. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
   **Deeper corpus evidence (detented-sheet vocab):** to judge whether a `.sheet` is a genuine content sheet
   that wants detents and which detents the idiom uses, ground it in the corpus — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx recipe sheet-detents --json` for the canonical
   `.sheet { … }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)` shape plus
   permalinked exemplar screens, and `swiftui-ctx recipe fullscreen-cover-flow --json` for the real
   immersive-cover idiom — cite it to defend a psm-01 "this sheet wants detents" or a psm-03 "this cover
   should be a sheet" call.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a modality/detent judgment, so all
   are `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅
   "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in
   `## Correct`, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus
   the Sosumi `doc:`) goes in `## Source` as the canonical example. The psm-01 ✅ is grounded in the live
   `swiftui-ctx lookup presentationDetents --platform ios` consensus + its recommended permalink (see
   `references/sheets-detents-covers.md`). Leave `flag-only` findings `open` with that ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. detents you added now want a `.presentationDragIndicator`, or a `.sheet` you swapped in for
   a `.fullScreenCover` now wants a keyboard-avoidance check → `cross_ref: safe-area-keyboard`), loop that
   file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is
a modality/detent judgment (which detents fit the content, whether a flow is genuinely immersive, whether a
popover should adapt to `.popover` or become a `.sheet` on compact width), so all are `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/presentation-sheets-modals/<context>/NN-slug.md` (one finding per file,
  zero-padded, ordered). Per-run index: `swiftui-audits/presentation-sheets-modals/_index.md`.
- `domain: presentation-sheets-modals`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for
  every defect. `availability` reads from `floors-master.md`. `source` is an Apple URL + access date (fetched
  via Sosumi) or `verify against Xcode 26 SDK`. Each finding body carries a **`## Why it's wrong on iOS`**
  section. Emit `cross_ref` on psm-01 (→ `safe-area-keyboard` when a `TextField` in the sheet is covered by
  the keyboard), psm-03 (→ `adaptive-navigation` when the flow should be a push, not a modal), and psm-04 (→
  `adaptive-layout` when the popover's content branches on size class).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `sheet-detents/` | a content-rich `.sheet` lacks `.presentationDetents` and is locked full-height (psm-01) — `cross_ref` safe-area-keyboard when the keyboard covers a field |
| `drag-indicator/` | a detented `.sheet` has no `.presentationDragIndicator(.visible)` grab handle (psm-02) |
| `cover-modality/` | a `.fullScreenCover` wraps a trivial dismissible dialog where a `.sheet` is the idiom (psm-03) — `cross_ref` adaptive-navigation when it should be a push |
| `popover-adaptation/` | a `.popover` has no `.presentationCompactAdaptation` and collapses to full-screen on iPhone (psm-04) — `cross_ref` adaptive-layout when the content branches on size class |
| `presentation-background/` | a `presentationBackground(.clear)`/`presentationContentInteraction` is mis-applied or a no-op (psm-05) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/presentation-sheets-modals/` with a lowercase-hyphen slug naming the sub-category, and note
it in the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is
a hard requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/sheets-detents-covers.md` | the detent-less `.sheet`, the missing drag indicator, the `.fullScreenCover`-vs-`.sheet` modality call, the compact-popover adaptation, and the presentation-background/interaction traps (psm-01…psm-05) + the canonical detented-sheet exemplar |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi (iOS pages) |
| `lint/grep-tells.tsv` | step LOCATE — this skill's tier-1 grep tell set fed to the shared runner (psm-01…psm-05); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `presentationDetents`/`presentationDragIndicator` 16.0, `presentationBackground`/`presentationContentInteraction`/`presentationCompactAdaptation` 16.4, `.sheet` 13.0, `.fullScreenCover` 14.0, `.popover` 13.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up presentation modifier) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (a sub-floor detent/background fix needs an `#available(iOS NN, *)` gate; at the iOS-17 floor these are unconditional) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`recipe`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (adaptive-navigation present-vs-push, safe-area-keyboard keyboard-in-sheet, adaptive-layout popover content) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-presentation-sheets-modals --dir
<files-or-dir> [--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed
this skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, psm-01…psm-05). The grep tier
**stands alone** here — ast-grep is NOT installed in this environment, so no tier-2 `.yml` is required; the
grep tells are self-test-validated against `tests/fixtures/presentation-sheets-modals.swift`. It runs a
per-file **parse probe** (surfaces "did not fully parse" so a structural miss can't look clean), emits unified
**JSON + SARIF**, and **degrades to grep-only with a notice** if ast-grep is unreachable. It only LOCATES —
always READ each hit in full before reporting (step 3). Because grep can flag the *presence* of a `.sheet` /
`.fullScreenCover` / `.popover` but not the *absence* of `.presentationDetents` in its chain, every psm-01 /
psm-04 hit MUST be read in full to confirm no detent/adaptation modifier appears downstream. The thin
`scripts/presentation-sheets-modals-lint.sh` is a pointer to this runner. Engine + rule-file format +
JSON/SARIF shape + safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
