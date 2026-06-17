---
name: audit-swiftui-controls-forms
description: Audits an iOS SwiftUI app for text-input and control-style defects that make a field hard to type into or a picker render wrong, writing per-finding Markdown to swiftui-audits/. Use when a numeric field shows the wrong (full QWERTY) keyboard, an email/username field auto-capitalizes or auto-corrects, a plain TextField has no rounded border, the Return key has no Next/Done label, fields can't be advanced by keyboard, or a Picker renders as the wrong style; when asked to verify keyboardType, textInputAutocapitalization, autocorrectionDisabled, textFieldStyle, submitLabel, FocusState focus, pickerStyle, or controlSize on iOS; when AI wrote a numeric TextField with no keyboardType, an email field with no textInputAutocapitalization(.never), a bare TextField with no textFieldStyle, or a multi-field form with no submitLabel/FocusState wiring. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for tap/long-press/swipeActions (touch-gestures), VoiceOver (accessibility), color/material/tint (appearance-color), or new control UI.
---

# Audit SwiftUI Controls & Forms

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way a control reads as unfinished or hard to type into on iPhone/iPad:
a numeric `TextField` that pops the full QWERTY keyboard (no `.keyboardType`), an email/username field that
auto-capitalizes and auto-corrects the user's input, a free-standing `TextField` with no
`.textFieldStyle(.roundedBorder)` so it has no visible bounds, a multi-field form with no `.submitLabel` and
no `@FocusState` advance wiring so Return does nothing useful, and a `Picker` left at the default style where
the data wants `.segmented`/`.menu`/`.navigationLink`/`.wheel`. Findings are written to disk in the toolkit's
unified schema; certain mechanical defects are fixed under the fix-safety protocol. This is never a
from-scratch control generator.

**iOS is touch-first text entry, and the keyboard is the control.** Unlike the Mac, an iOS `Form` is grouped
out of the box (so a missing `.formStyle(.grouped)` is *not* a defect), `.pickerStyle(.wheel)` is a **native
iOS control** (never a compile error), and there is no pointer tooltip to demand. What the corpus omits on iOS
is the **keyboard configuration**: the right `.keyboardType`, suppressed auto-capitalization/auto-correction
for emails and codes, a `.submitLabel`, `@FocusState`-driven field advance, and a visible
`.textFieldStyle`. The result compiles and looks plausible but is awkward to type into. Be suspicious wherever
AI built a sign-in/settings/entry form or a styled `TextField`/`Picker`.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **Tap / long-press / `swipeActions` are not mine.** `.onTapGesture`, `.onLongPressGesture`,
  `.swipeActions` on rows, and gesture-driven interaction belong to `audit-swiftui-touch-gestures`. This skill
  owns the **text-input + control-styling** half only. Note a gesture smell in one line and
  `cross_ref: touch-gestures` — do not audit it here.
- **Keyboard focus vs VoiceOver focus.** `@FocusState` / `.focused($_)` (which field the keyboard targets,
  field advance, keyboard dismissal) is **this skill** (cf-06). `AccessibilityFocusState` /
  `.accessibilityFocused` (VoiceOver focus) is `audit-swiftui-accessibility` — different wrappers; `cross_ref`
  it, don't claim it.
- **Color / material crossover** (a control's tint/material choice — `.tint`, `Color(.systemBackground)`)
  belongs to `audit-swiftui-appearance-color`. Note it and `cross_ref`, don't restyle it here.
- **`Form`/`List` inside navigation.** The control styling of the form is **this skill**; the navigation
  structure that hosts it (`NavigationStack` vs `NavigationSplitView`, `.navigationLink` picker pushing onto a
  stack) is `audit-swiftui-adaptive-navigation` — `cross_ref` it when the issue is the navigation container.

## The control rules (the judgment core)

1. **Configure the keyboard for the data.** A `TextField` bound to a number/amount/email/URL/phone needs the
   matching `.keyboardType(.numberPad`/`.decimalPad`/`.emailAddress`/`.URL`/`.phonePad)` — the iOS default is
   `.default` (full QWERTY), wrong for typed data (cf-01).
2. **Suppress capitalization/correction where it harms input.** An email, username, code, or URL field needs
   `.textInputAutocapitalization(.never)` and usually `.autocorrectionDisabled()` — otherwise iOS capitalizes
   the first letter and "corrects" valid identifiers (cf-02).
3. **A free-standing `TextField` needs a visible style.** Outside a grouped `Form`/inset `List`, a bare
   `TextField` has no border; `.textFieldStyle(.roundedBorder)` gives the standard iOS bordered field (cf-03).
4. **Multi-field forms need submit + focus wiring.** `.submitLabel(.next`/`.done)` labels the Return key, and
   `@FocusState` + `.focused($field, equals:)` + `.onSubmit` advances fields and dismisses the keyboard
   (cf-04 submit label, cf-06 focus wiring).
5. **Pick the picker style for the data.** Two-or-three mutually-exclusive options → `.pickerStyle(.segmented)`;
   a long list → `.menu` or `.navigationLink` (push); a spinning `.wheel` for a date/range value is **native
   and correct on iOS** — only flag a `.wheel` used for a binary choice that wants `.segmented` (cf-05). Set
   density with `.controlSize` (iOS 15.0+) where a compact control is wanted (cf-07).

Full ❌→✅ + the canonical iOS-entry-form exemplar: `references/forms-and-focus.md` and
`references/control-styles-density.md`.

## Defect index (cf-01 … cf-07)

`id · tell · severity · fix · open reference`. Severities: **warning** (compiles but the control is awkward to
use / mis-configured), **advisory** (judgment / style / density). `auto` = mechanical single-answer fix;
`flag` = show the ✅, dev applies. **No hard-fails in this domain on iOS** — every control symbol here exists
and compiles on iOS (`.pickerStyle(.wheel)` included); the defects are usability/idiom, not platform-wrong.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| cf-01 | a numeric/decimal/email/URL/phone `TextField` with no `.keyboardType(_:)` → full QWERTY for typed data | warning | flag | `forms-and-focus.md` |
| cf-02 | an email/username/code/URL `TextField` with no `.textInputAutocapitalization(.never)` / `.autocorrectionDisabled()` → input gets capitalized / "corrected" | warning | flag | `forms-and-focus.md` |
| cf-03 | a free-standing `TextField` (not in a grouped `Form`/inset `List`) with no `.textFieldStyle(.roundedBorder)` → no visible border | advisory | flag | `forms-and-focus.md` |
| cf-04 | a `TextField`/`SecureField` in a multi-field form with no `.submitLabel(_:)` → Return key has no Next/Done affordance | advisory | flag | `forms-and-focus.md` |
| cf-05 | a `Picker` with no explicit `.pickerStyle(_:)`, or a `.wheel` on a 2–3-option binary choice that wants `.segmented` → wrong style for the data | advisory | flag | `control-styles-density.md` |
| cf-06 | a custom focus-taking `View` (or a multi-field form) with no `@FocusState` / `.focused($_)` → keyboard can't be advanced or dismissed programmatically | warning | flag | `forms-and-focus.md` |
| cf-07 | a compact-density control left at the default `controlSize` where a `.small`/`.mini` is wanted (iOS 15.0+) | advisory | flag | `control-styles-density.md` |

**cf-06 cross-refs accessibility** (`@FocusState`↔`AccessibilityFocusState`). `.pickerStyle(.wheel)` and
`WheelPickerStyle` are **native iOS** (`introduced_ios 13.0`) — never flag them as platform-wrong or wrap them
in `#available`; a `swiftui-ctx lookup WheelPickerStyle --platform ios` returns a real `introduced_ios` (it is
a shipping iOS control), confirming it is correct (see VERIFY).

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` — read, never restate):**
`keyboardType(_:)` (`.default`/`.numberPad`/`.decimalPad`/`.emailAddress`/`.URL`/`.phonePad`/`.numbersAndPunctuation`),
`textInputAutocapitalization(_:)` (`.never`/`.words`/`.sentences`/`.characters`), `autocorrectionDisabled(_:)`,
`textFieldStyle(_:)` (`.roundedBorder`/`.plain`/`.automatic`), `submitLabel(_:)`
(`.done`/`.next`/`.go`/`.search`/`.send`/`.return`), `focused(_:)` / `focused(_:equals:)`, `@FocusState`,
`onSubmit(_:_:)`, `pickerStyle(_:)` (`.segmented`/`.menu`/`.navigationLink`/`.wheel`/`.inline`/`.automatic`),
`controlSize(_:)` (`.mini`/`.small`/`.regular`/`.large`), `scrollDismissesKeyboard(_:)`.
**`.buttonStyle(.glass)` / glass control styling are iOS 26.0+** and owned by `audit-swiftui-liquid-glass`;
note in one line and `cross_ref`, don't gate them here.

**iOS-native, do NOT flag as wrong:** `.pickerStyle(.wheel)` / `WheelPickerStyle` (a real iOS picker style,
`introduced_ios 13.0`); an ungrouped-looking `Form` (iOS `Form` is grouped **by default** — a missing
`.formStyle(.grouped)` is not a defect). **No tooltip idiom:** `.help(_:)` exists on iOS (14.0+) but surfaces
only under the iPad pointer — it is **not** a required affordance and never a finding here.

No invented names are central to this domain; if audited code reaches for a control/style symbol you can't
place, confirm via swiftui-ctx (`lookup --platform ios` **exit 3** = likely hallucination or no-iOS-arm) +
Sosumi before flagging, and cross-check the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/forms-and-focus.md`, `references/control-styles-density.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target** (`project.pbxproj`
   `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — it sets which floor a fix may rely on
   (`keyboardType`/`autocorrectionDisabled`/`textFieldStyle`/`pickerStyle` = iOS 13.0+, `help` = iOS 14.0+,
   `textInputAutocapitalization`/`submitLabel`/`controlSize` = iOS 15.0+, `formStyle` = iOS 16.0+,
   `scrollDismissesKeyboard` = iOS 16.0+, `focusable` = iOS 17.0+; `@FocusState`/`.focused` = iOS 15.0+). The
   **project floor is iOS 17**, so every symbol in this domain is already available and needs **no gate**; only
   a symbol above 17 would need a `#available(iOS NN, *)` arm. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-controls-forms --dir <sources> --json /tmp/cf.json --sarif /tmp/cf.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, cf-01…cf-07) + tier-2 structural ast-grep
   rules (`lint/ast-grep/*.yml` — cf-01 numeric-textfield-no-keyboardtype, cf-06 custom-view-not-focusable),
   plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged
   file did not fully parse, so a structural miss can't masquerade as clean; READ those by hand. The runner
   only LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a `TextField`
   is bound to numeric/email data (so the keyboard is wrong), whether a field is free-standing or already
   inside a grouped `Form`/inset `List` (so `.roundedBorder` is redundant), whether a form has multiple fields
   (so submit/focus wiring matters), and whether a `Picker`'s option count fits its style are all invisible to
   grep. Build a per-file inventory: each `TextField`/`SecureField` + its `.keyboardType`/autocaps/correction/
   style/submit/focus wiring; each `Picker` + its style + option count.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `TextField` bound to an amount with no `.keyboardType`, an email field with no
   `.textInputAutocapitalization(.never)`). A `TextField` bound to free-text prose (a note, a name) is *not* a
   keyboard defect — `.default` is correct there; a `Picker` already inside a `Form` may correctly use the
   automatic style. Judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a style case you can't place, a floor you're unsure of, the
   canonical shape, whether a picker style exists on iOS), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `swiftui-ctx deprecated <api>` for a currency/deprecation rule): read its `consensus` (the canonical
   shape), `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a
   `lookup` **exit 3** (not-found / no-iOS-arm, with a did-you-mean `suggestion`) corroborates a hallucination
   or a non-iOS symbol. (b) **Spec** — confirm via **Sosumi**:
   `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:` floor;
   the reconciled floor wins. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
   **Deeper corpus evidence (entry/Form vocab):** to judge whether a form is a genuine entry/settings pane and
   which controls the native idiom uses, ground it in the corpus — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx recipe settings-form --json` for the canonical
   `Form { Section { Toggle/Picker/LabeledContent } }` shape and a permalinked iOS exemplar — cite it to defend
   a "this is an entry/settings Form" or "this Picker/keyboard is the iOS idiom" call.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a judgment/structural call: which
   keyboard the data wants, whether a field is free-standing, which picker style fits, so all are
   `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅
   "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in
   `## Correct`, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus
   the Sosumi `doc:`) goes in `## Source` as the canonical example. The cf-01 ✅ is grounded in the live
   `swiftui-ctx lookup keyboardType --platform ios` consensus (`.keyboardType(_:)`, 100%) + its recommended
   iOS permalink (see `references/forms-and-focus.md`). Leave `flag-only` findings `open` with that ✅ in
   `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. an email field you gave `.keyboardType(.emailAddress)` now also wants
   `.textInputAutocapitalization(.never)`), loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is a
structural/judgment call (which keyboard the bound data wants, whether a field is free-standing or already in
a grouped container, which picker style fits the option count, whether a form is multi-field), so all are
`fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/controls-forms/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/controls-forms/_index.md`.
- `domain: controls-forms`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every defect.
  `availability` reads from `floors-master.md`. `source` is an Apple URL + access date (fetched via Sosumi)
  or `verify against Xcode 26 SDK`. Emit `cross_ref` on cf-06 (→ `accessibility` when VoiceOver focus is also
  at stake), on any tap/long-press/`swipeActions` note (→ `touch-gestures`), on any color/material note
  (→ `appearance-color`), and on a navigation-container note (→ `adaptive-navigation`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `keyboard-type/` | a numeric/email/URL/phone `TextField` has no matching `.keyboardType` (cf-01) |
| `text-input-config/` | an email/username/code/URL field has no `.textInputAutocapitalization(.never)` / `.autocorrectionDisabled()` (cf-02) |
| `field-style/` | a free-standing `TextField` lacks `.textFieldStyle(.roundedBorder)` (cf-03) |
| `submit-focus/` | a multi-field form has no `.submitLabel` or no `@FocusState` advance/dismiss wiring (cf-04, cf-06) — `cross_ref` accessibility |
| `picker-style/` | a `Picker` carries the wrong/default style for its option count, or a `.wheel` on a binary choice (cf-05) |
| `control-density/` | a compact control is left at the default `controlSize` where `.small`/`.mini` is wanted (cf-07) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/controls-forms/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/forms-and-focus.md` | the keyboard configuration (`.keyboardType`, autocaps/autocorrection), the free-standing `.textFieldStyle(.roundedBorder)`, the `.submitLabel` + `@FocusState` keyboard-focus/advance wiring (cf-01/02/03/04/06) + the canonical iOS-entry-form exemplar |
| `references/control-styles-density.md` | `pickerStyle` choice for the data (`.segmented`/`.menu`/`.navigationLink`/`.wheel`) and the `controlSize` density (cf-05/07) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells cf-01…cf-07 + tier-2 structural cf-01 numeric-textfield-no-keyboardtype / cf-06 custom-view-not-focusable); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `keyboardType`/`autocorrectionDisabled`/`textFieldStyle`/`pickerStyle`/`WheelPickerStyle` iOS 13.0, `help` 14.0, `textInputAutocapitalization`/`submitLabel`/`controlSize`/`@FocusState` 15.0, `formStyle`/`scrollDismissesKeyboard` 16.0, `focusable` 17.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up style/control symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (the iOS-17 project floor means every symbol here needs no gate; gate only a symbol above 17) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup --platform ios`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (tap/long-press/`swipeActions` half, `@FocusState`-vs-`AccessibilityFocusState`, color/material crossover, `Form`/`List`-in-navigation) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-controls-forms --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, cf-01…cf-07) + **tier-2 ast-grep** structural
rules (`lint/ast-grep/*.yml` — cf-01 numeric-textfield-no-keyboardtype, cf-06 custom-view-not-focusable) that
grep cannot express (the **absence** of `.keyboardType` on a `TextField` bound to numeric data, the
**absence** of `@FocusState`/`.focused` inside a custom `View` that uses a `TextField` — both anchored on a
`kind`). It runs a per-file **parse probe** (surfaces "did not fully parse" so a structural miss can't look
clean), emits unified **JSON + SARIF**, and **degrades to grep-only with a notice** if ast-grep is unreachable
(`npx --package @ast-grep/cli ast-grep`; faster: `brew install ast-grep`). It only LOCATES — always READ each
hit in full before reporting (step 3). The thin `scripts/cf-lint.sh` is a pointer to this runner. Engine +
rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
