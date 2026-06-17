---
name: audit-swiftui-safe-area-keyboard
description: Audits an iOS SwiftUI app for safe-area and keyboard-avoidance defects that overlap the notch, Dynamic Island, or home indicator, or trap a field behind the keyboard, writing per-finding Markdown to swiftui-audits/. Use when content runs under the status bar / Dynamic Island, a bottom bar sits under the home indicator, a blanket .ignoresSafeArea() hides content, or a scrolling form cannot dismiss the keyboard; when verifying safeAreaInset(edge:), ignoresSafeArea(.keyboard), scrollDismissesKeyboard, or safeAreaPadding; when AI wrote .ignoresSafeArea() with no edges/regions argument, used the deprecated .edgesIgnoringSafeArea, hand-rolled a keyboardWillShow observer, or shipped a scrolling form with no scrollDismissesKeyboard. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for keyboard avoidance inside a sheet (presentation-sheets-modals), insets shifting by size class (adaptive-layout), a safeAreaInset bar as layout (layout-and-tables), the scroll-dismiss control style (controls-forms), or new keyboard UI.
---

# Audit SwiftUI Safe Area & Keyboard

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way an iPhone safe-area / keyboard habit ships content under a system
inset or traps a field behind the keyboard: a blanket `.ignoresSafeArea()` that hides content behind the
status bar / Dynamic Island or under the home indicator, a fixed bottom bar pinned with no
`safeAreaInset(edge: .bottom)`, the **deprecated** `.edgesIgnoringSafeArea(.all)`, a scrolling form with **no**
`.scrollDismissesKeyboard`, and a hand-rolled `keyboardWillShow` NotificationCenter observer where SwiftUI's
automatic keyboard avoidance + `.ignoresSafeArea(.keyboard)` is the answer. Findings are written to disk in the
toolkit's unified schema; this is never a from-scratch layout generator.

**The corpus predates the notch-and-island device.** The training corpus is overwhelmingly old-iPhone
SwiftUI, where the safe area was a thin status bar, there was no home-indicator gesture region, and the
keyboard rarely covered a scrolling field — so AI freely reaches for a blanket `.ignoresSafeArea()` to "fill
the screen", pins a bar to the literal bottom, and never adds a keyboard-dismiss to a long form. The result
compiles and looks fine in a notch-less simulator but on a real iPhone 15/16 the title runs under the Dynamic
Island, the tab bar sits under the home indicator, and a keyboard-covered field can't be reached or escaped.
Be suspicious wherever AI built a full-bleed background, a fixed bottom bar, or a scrolling input form.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **Keyboard avoidance inside a presented sheet is not mine.** A `.sheet`/`.fullScreenCover` whose keyboard
  pushes the detent or fights the drag indicator belongs to `audit-swiftui-presentation-sheets-modals`. The
  **keyboard inset / `.scrollDismissesKeyboard` / `.ignoresSafeArea(.keyboard)`** half is **this skill**; the
  **detent sizing/interaction** half is presentation. File the keyboard finding here,
  `cross_ref: presentation-sheets-modals`; do not audit the detent.
- **How safe-area insets shift by size class is not mine.** That insets differ between iPhone compact and iPad
  regular, or that the Dynamic Island region changes the top inset, is `audit-swiftui-adaptive-layout` when the
  smell is a missing size-class branch. The **presence/absence of safe-area respect at a given size** is **this
  skill**; `cross_ref: adaptive-layout` when the defect is the size-class branch itself.
- **A `safeAreaInset` bar as layout arrangement is a split axis.** *Whether content respects the safe area*
  (sak-01/sak-03) is **this skill**. The **arrangement of the bar's contents** (stack/grid/spacing inside the
  inset bar) is `audit-swiftui-layout-and-tables`; `cross_ref` it when the issue is the bar's internal layout,
  not the inset.
- **The scroll-dismiss *control style* is a seam.** `.scrollDismissesKeyboard(.interactive)` vs
  `.immediately` as a **form-interaction** choice on a `Form` overlaps `audit-swiftui-controls-forms`; file the
  *missing-dismiss* finding here (sak-02), `cross_ref: controls-forms` when the form's control idiom is also at
  stake. A UIKit `becomeFirstResponder`/`UIResponder` bridge to drive focus is `audit-swiftui-uikit-interop`.

## The safe-area & keyboard judgment rules (the judgment core)

1. **Never ignore the safe area blanket-wide for content.** `.ignoresSafeArea()` with no `edges:`/`regions:`
   argument ignores **all** edges — content runs under the status bar / Dynamic Island at the top and under the
   home indicator at the bottom. It is correct **only** for a full-bleed *background* (a `Color`/`Image`/
   gradient *behind* content); foreground content must stay inside the safe area (sak-01).
2. **Scope the ignore to the edge you mean.** When a background legitimately bleeds, ignore only the edge(s) it
   needs — `.ignoresSafeArea(edges: .top)` / `.bottom` — not `.all`. The **deprecated** `.edgesIgnoringSafeArea`
   (replaced iOS 14.0 by `.ignoresSafeArea`) is always a flag (sak-04).
3. **A fixed bottom bar belongs in a `safeAreaInset`.** A bar `VStack`-pinned to the bottom (or overlaid at the
   bottom) overlaps the home indicator and is hidden by the keyboard; `safeAreaInset(edge: .bottom)` reserves
   real space above the home indicator and rides the keyboard correctly (sak-03).
4. **A scrolling input form must let the keyboard go.** A `Form`/`List`/`ScrollView` with text fields and **no**
   `.scrollDismissesKeyboard(.interactive)`/`.immediately` traps the keyboard over the lower fields with no way
   to dismiss it by dragging (sak-02).
5. **Don't hand-roll keyboard avoidance.** SwiftUI avoids the keyboard automatically; a `keyboardWillShow` /
   `keyboardFrameEndUserInfoKey` NotificationCenter observer (or a manual `.padding(.bottom, keyboardHeight)`)
   fights it and double-shifts. Opt out per-view with `.ignoresSafeArea(.keyboard)` instead (sak-05).

Full ❌→✅ + the canonical safe-area/keyboard exemplars: `references/safe-area-keyboard-patterns.md`.

## Defect index (sak-01 … sak-05)

`id · tell · severity · fix · open reference`. Severities: **hard** (deprecated / never-right), **warning**
(compiles but overlaps a system inset or traps the keyboard), **advisory** (judgment / prefer-native). `auto` =
mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| sak-01 | `.ignoresSafeArea()` with **no `edges:`/`regions:` argument** wrapping (or chained on) content → runs under status bar / Dynamic Island / home indicator | warning | flag | `safe-area-keyboard-patterns.md` |
| sak-02 | a scrolling input `Form`/`List`/`ScrollView` with text fields and **no** `.scrollDismissesKeyboard(…)` → keyboard traps the lower fields | warning | flag | `safe-area-keyboard-patterns.md` |
| sak-03 | a fixed bottom bar (`VStack`/`.overlay`/`ZStack` pinned bottom) with no `safeAreaInset(edge: .bottom)` → overlaps the home indicator, hidden by the keyboard | warning | flag | `safe-area-keyboard-patterns.md` |
| sak-04 | the **deprecated** `.edgesIgnoringSafeArea(…)` (replaced iOS 14.0 by `.ignoresSafeArea`) | hard | flag | `safe-area-keyboard-patterns.md` |
| sak-05 | a hand-rolled keyboard observer (`keyboardWillShow` / `keyboardFrameEndUserInfoKey` / `UIResponder.keyboard*`) instead of SwiftUI auto-avoidance + `.ignoresSafeArea(.keyboard)` | advisory | flag | `safe-area-keyboard-patterns.md` |

**sak-04 is the only hard-fail; sak-02 cross-refs controls-forms, sak-03 cross-refs layout-and-tables.**
`.edgesIgnoringSafeArea` is a **deprecation** (replaced iOS 14.0), not a low floor — replace it with
`.ignoresSafeArea(edges:)`, never wrap it in `#available`. A `swiftui-ctx lookup edgesIgnoringSafeArea
--platform ios` corroborates the replacement is `ignoresSafeArea`.

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` / `swiftui-ctx lookup
--platform ios` — read, never restate):** `ignoresSafeArea(_:edges:)` (iOS 14.0; `.container`/`.keyboard`
regions, `.top`/`.bottom`/`.all` edges), `safeAreaInset(edge:alignment:spacing:content:)` (iOS 15.0),
`scrollDismissesKeyboard(_:)` (iOS 16.0; `.interactive`/`.immediately`/`.never`/`.automatic`),
`safeAreaPadding(_:_:)` (iOS 17.0), `contentMargins(_:_:for:)` (iOS 16.1). The `regions` overload of
`ignoresSafeArea` lets a view opt out of the **keyboard** safe area specifically:
`.ignoresSafeArea(.keyboard, edges: .bottom)`.

**Deprecation trap (real but wrong on iOS):** `.edgesIgnoringSafeArea(_:)` — **deprecated iOS 14.0+**,
replaced by `.ignoresSafeArea(_:edges:)`; replace, never gate (sak-04). **UIKit, not a SwiftUI symbol:**
`keyboardLayoutGuide` (UIKit `UIView.keyboardLayoutGuide`, iOS 15.0 — `swiftui-ctx lookup keyboardLayoutGuide`
**exit / not-found**, "did you mean keyboardShortcut…") is the UIKit answer; in SwiftUI the equivalent is the
automatic keyboard safe area, so a `keyboardLayoutGuide` reference inside a SwiftUI view usually means a UIKit
bridge — `cross_ref: uikit-interop`. Carry its floor as **verify against Xcode 26 SDK** (not in the catalog).

No invented names are central to this domain; if audited code reaches for a safe-area/keyboard symbol you
can't place, confirm via swiftui-ctx (`lookup --platform ios` **exit 3** = likely hallucination or no-iOS-arm
symbol) + Sosumi before flagging, and cross-check the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/safe-area-keyboard-patterns.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target** (`project.pbxproj`
   `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). The project floor is **iOS 17**, so every
   real API here — `ignoresSafeArea` (14.0), `safeAreaInset` (15.0), `scrollDismissesKeyboard` (16.0),
   `safeAreaPadding` (17.0) — is available without a gate; confirm against `floors-master.md`. Note whether the
   app even has notch/home-indicator-bearing screens (any full-screen view does). Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-safe-area-keyboard --dir <sources> --json /tmp/sak.json --sarif /tmp/sak.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, sak-01…sak-05) plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully parse,
   so a structural miss can't masquerade as clean; READ those by hand. The runner only LOCATES — never treat a
   hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether an
   `.ignoresSafeArea()` is on a full-bleed *background* (fine) or on foreground *content* (defect), whether a
   `Form`/`ScrollView` actually contains text fields, whether a bottom `VStack` is a genuinely pinned bar or
   ordinary stacked content, and whether a `keyboardWillShow` observer is doing avoidance or something else are
   all invisible to grep. Build a per-file inventory: each `.ignoresSafeArea` + what it wraps; each scrolling
   container + its fields + its scroll-dismiss; each bottom-pinned bar + its inset wiring; each keyboard
   observer.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `.ignoresSafeArea()` on a `VStack` of content, a `Form` with `TextField`s and no
   `.scrollDismissesKeyboard`, a `.edgesIgnoringSafeArea(.all)`). A `.ignoresSafeArea()` on a `Color`/`Image`
   *background* layer, a non-input `List` of plain text, or a bottom view that is not a fixed bar is *not* a
   defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a floor you're unsure of, the canonical shape, whether a region
   overload exists on iOS), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read its `consensus`
   (canonical shape — e.g. `ignoresSafeArea` `()` / `(_, edges)`, `safeAreaInset` `(edge)`,
   `scrollDismissesKeyboard` `(_)`), `recommended` permalink, `introduced_ios` (surfaces at
   `result.introduced_ios`, **not** under `result.availability`), and `co_occurs_with`; a `lookup` **exit 3**
   (or a not-found "did you mean…" for `keyboardLayoutGuide`) corroborates a UIKit-only / no-SwiftUI-arm symbol.
   (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:` floor —
   the reconciled floor wins. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a judgment/structural call: is this a
   background or content, which edge to scope to, which dismiss mode the form wants — so all are `flag-only`),
   one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅ "Correct" is **not a
   hand-written snippet** — it is the swiftui-ctx **consensus shape** put in `## Correct`, backed by a real iOS
   example fetched with `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose
   GitHub permalink (plus the Sosumi `doc:`) goes in `## Source`. The sak-02 ✅ is grounded in the live
   `swiftui-ctx lookup scrollDismissesKeyboard --platform ios` consensus (`(_)` 100%) + its recommended iOS
   permalink (see `references/safe-area-keyboard-patterns.md`). Leave `flag-only` findings `open` with that ✅ in
   `## Correct`. If a gate above the project floor is needed, route via
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a new
   tell (e.g. you scoped `.ignoresSafeArea()` to `.top` but the bottom bar still has no `safeAreaInset` —
   sak-03), loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is a
structural/judgment call (is this a background or foreground content, which single edge a bleed needs, which
scroll-dismiss mode the form wants, whether a bottom view is even a fixed bar), so all are `fix_mode:
flag-only`. sak-04 is a hard-fail but still flag-only — the replacement edge (`.top` vs `.bottom` vs `.all`)
depends on what the original `.edgesIgnoringSafeArea` argument meant.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/safe-area-keyboard/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/safe-area-keyboard/_index.md`.
- `domain: safe-area-keyboard`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every
  defect. `availability` reads from `floors-master.md` (the iOS floor, e.g. `ignoresSafeArea` iOS 14.0,
  `safeAreaInset` iOS 15.0, `scrollDismissesKeyboard` iOS 16.0, `safeAreaPadding` iOS 17.0; sak-04 is a
  **deprecation** of `.edgesIgnoringSafeArea`, not a floor; `keyboardLayoutGuide` is `verify against Xcode 26
  SDK`). `source` is an Apple URL + access date (fetched via Sosumi) or `verify against Xcode 26 SDK`. Body
  includes **`## Why it's wrong on iOS`**. Emit `cross_ref` on sak-02 (→ `presentation-sheets-modals` when the
  form is inside a sheet, or `controls-forms` for the dismiss-style choice), sak-03 (→ `layout-and-tables` for
  the bar's internal arrangement), and any size-class note (→ `adaptive-layout`) or `keyboardLayoutGuide`
  bridge (→ `uikit-interop`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `ignore-safe-area-blanket/` | a `.ignoresSafeArea()` with no edge/region argument wraps foreground content (sak-01) |
| `scoped-ignore/` | a bleed should scope to one edge, or uses the deprecated `.edgesIgnoringSafeArea` (sak-04) |
| `keyboard-dismiss/` | a scrolling input form has no `.scrollDismissesKeyboard` (sak-02) — `cross_ref` presentation/controls-forms |
| `bottom-bar-inset/` | a fixed bottom bar has no `safeAreaInset(edge: .bottom)` and overlaps the home indicator (sak-03) — `cross_ref` layout-and-tables |
| `manual-keyboard-avoidance/` | a hand-rolled `keyboardWillShow` observer replaces SwiftUI auto-avoidance (sak-05) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/safe-area-keyboard/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/safe-area-keyboard-patterns.md` | the blanket-ignore / deprecated-edgesIgnoring / missing-scroll-dismiss / bottom-bar-inset / manual-avoidance defects, the `safeAreaInset` and `.ignoresSafeArea(.keyboard)` idioms, and the canonical exemplars (sak-01…sak-05) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi (iOS pages) |
| `lint/grep-tells.tsv` | step LOCATE — this skill's declarative tier-1 grep rule set fed to the shared runner (sak-01…sak-05); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled iOS truth — `ignoresSafeArea` 14.0, `safeAreaInset` 15.0, `scrollDismissesKeyboard` 16.0, `safeAreaPadding` 17.0, `contentMargins` 16.1) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (project floor iOS 17; gate only symbols above it) + the deprecation-is-not-a-low-floor trap (sak-04 `.edgesIgnoringSafeArea` is replaced, never gated) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up safe-area/keyboard symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup --platform ios`/`recipe` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (keyboard-in-sheet → presentation-sheets-modals, insets-by-size-class → adaptive-layout, inset-bar arrangement → layout-and-tables, scroll-dismiss style → controls-forms) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-safe-area-keyboard --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, sak-01…sak-05) covering the blanket
`.ignoresSafeArea()`, the deprecated `.edgesIgnoringSafeArea`, the scrolling form with no
`.scrollDismissesKeyboard`, the bottom-pinned bar with no `safeAreaInset`, and the hand-rolled
`keyboardWillShow` observer. The grep tier **stands alone** (ast-grep is not required and not installed);
structural absence calls (a `Form`/`ScrollView` with text fields but *no* `.scrollDismissesKeyboard` — sak-02 —
and a bottom bar with *no* `safeAreaInset` — sak-03) are LOCATED broadly by grep and resolved by the agent in
READ. It runs a per-file **parse probe** (surfaces "did not fully parse" so a structural miss can't look
clean), emits unified **JSON + SARIF**, and exits **2** on the sak-04 hard-fail for a CI gate. It only LOCATES
— always READ each hit in full before reporting (step 3). The thin `scripts/safe-area-keyboard-lint.sh` is a
pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
