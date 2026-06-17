---
name: audit-swiftui-touch-gestures
description: Audits a finished or in-progress iOS SwiftUI codebase for touch-gesture and interaction defects and writes findings to swiftui-audits/. Use when the user says a view ignores taps, a pinch or rotate gesture is broken, a drag stutters, a row has no swipe actions or touch-and-hold menu, a List has no pull-to-refresh, or a custom gesture is unreachable by VoiceOver; when they ask to verify onTapGesture, onLongPressGesture, DragGesture, MagnifyGesture, RotateGesture, swipeActions, refreshable, contextMenu, simultaneousGesture, highPriorityGesture, accessibilityAction, or GestureState; when AI wrote deprecated MagnificationGesture or RotationGesture, or onHover/onContinuousHover/pointerStyle as the only interaction on a touch target where a finger never fires. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for FocusState/keyboardType/control density (controls-forms); not for fileImporter drag payloads (document-picker-permissions); not for gesture animation timing (animation-motion); not for the availability sweep.
---

# Audit SwiftUI Touch & Gestures

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way the **touch-interaction** layer goes wrong on
iPhone and iPad: deprecated pinch/rotate gestures, continuous gestures with no live `@GestureState`,
mis-composed gestures that fight a built-in, custom gestures unreachable by VoiceOver, missing
touch-and-hold `.contextMenu` / `.swipeActions` / pull-to-`.refreshable` affordances, and the inverse
trap — **pointer-only affordances (`.onHover` / `onContinuousHover` / `pointerStyle`) used as the *only*
interaction on a touch target, where a finger never triggers them.** Findings are written to disk in the
toolkit's unified schema; certain mechanical defects are fixed under the fix-safety protocol. This is
never a from-scratch gesture generator.

**iOS is touch-first, not pointer-driven** — a finger taps, long-presses, drags, swipes, and
pinches; there is no cursor and (on iPhone) no hover. `.onHover` / `onContinuousHover` / `pointerStyle`
are **iPad-pointer-only** affordances (trackpad / Magic Keyboard / Apple Pencil hover) — and `pointerStyle`
has **no iOS arm at all**. AI trained on cross-platform corpora ships hover-driven views that compile but
are **dead under a finger**, and forgets the touch idioms (touch-and-hold menu, swipe-to-act,
pull-to-refresh) a native iOS app is expected to have. Be suspicious wherever an interaction is wired to
the pointer alone, or a custom gesture has no accessibility action.

## Boundary / seam note (stay in lane)

- **`.focusable()` / `@FocusState` keyboard focus, `keyboardType`, `Form` / `.formStyle`, and control
  density (`.controlSize`/`.buttonStyle`/`.pickerStyle`)** belong to `audit-swiftui-controls-forms`. A
  tap/long-press/`.swipeActions` *on a control* is pointer-adjacent but theirs to host — note it in one
  line and `cross_ref` controls-forms — do not own it here.
- **`Transferable` drag *payloads*, `dropDestination`, `fileImporter`, security-scoped consent** belong
  to `audit-swiftui-document-picker-permissions`. This skill owns the *gesture mechanics* of a
  `DragGesture`; the dropped/transferred file's correctness is picker-permissions'.
- **Gesture-driven *animation timing*** (`withAnimation` coupled to a gesture, `.repeatForever`) belongs
  to `audit-swiftui-animation-motion`. This skill owns the gesture wiring; the motion is theirs.
- **A `.contextMenu` action that should be a Shortcuts/Siri-exposed `AppIntent`** leans on
  `audit-swiftui-app-intents`; **a long-press context menu as a touch interaction** is this skill's. Flag
  the touch idiom here, `cross_ref: app-intents` when the action belongs in Shortcuts.
- **A custom gesture reachable by VoiceOver** — whether a tap/drag target also carries an
  `.accessibilityAction` so VoiceOver users can trigger it — is a real defect this skill *flags* (tg-06),
  then `cross_ref`s `audit-swiftui-accessibility` for the deeper a11y craft.
- **The deprecation *flag* on `MagnificationGesture`/`RotationGesture`** is owned by
  `audit-swiftui-api-currency` (the blanket currency sweep); **this skill owns the replacement
  mechanics** (the `MagnifyGesture`/`RotateGesture` rewrite + its `@GestureState`). Emit `cross_ref:
  api-currency` on tg-01/tg-02.
- **The blanket "is every OS-floored API gated" sweep** belongs to `audit-swiftui-availability-gating`;
  this skill owns **gesture-modifier** gating (e.g. a wrong-arm `#available(macOS …)` around a gesture)
  and defers the rest there.

## The three non-negotiable touch rules

1. **Every interaction a finger should reach must answer touch.** A view whose *only* affordance is
   `.onHover` / `onContinuousHover` / `pointerStyle` is **dead on iPhone** (no hover) and dead on a
   no-pointer iPad — there must be a tap / long-press / gesture fallback. Hover may *augment* on iPad, it
   may never be the sole path.
2. **A custom gesture must be reachable by VoiceOver.** A bare `onTapGesture` / `DragGesture` /
   `LongPressGesture` with no `.accessibilityAction` (and no underlying `Button`/control) is invisible to
   assistive technology — the interaction does not exist for a VoiceOver user.
3. **A continuous gesture needs live state.** A pinch/drag/rotate must surface its in-flight value through
   `@GestureState` (auto-resets when the gesture ends) or a committed `@State`; reading nothing
   mid-gesture makes the interaction feel frozen.

**The touch test:** can a finger (no pointer, no keyboard) trigger this interaction, and can VoiceOver?
If the only trigger is `.onHover`/`pointerStyle`, or there is no `.accessibilityAction` on a custom
gesture, the interaction is unreachable. Full reasoning + the affordance-map artifact:
`references/touch-affordances.md`.

## Defect index (tg-01 … tg-11)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (build break / never-correct on
iOS), **warning** (compiles but non-native / unreachable), **advisory** (judgment / perf). `auto` =
mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| tg-01 | `MagnificationGesture` (deprecated) → `MagnifyGesture` (iOS 17) | warning | flag | `gestures-and-state.md` |
| tg-02 | `RotationGesture` (deprecated) → `RotateGesture` (iOS 17) | warning | flag | `gestures-and-state.md` |
| tg-03 | continuous `DragGesture`/`MagnifyGesture`/`RotateGesture` with **no** `@GestureState` (no live value) | warning | flag | `gestures-and-state.md` |
| tg-04 | `.gesture(` on a control that also has a built-in gesture, or two `.gesture()` chained → `.simultaneousGesture` / `.highPriorityGesture` | advisory | flag | `gestures-and-state.md` |
| tg-05 | `.onHover` / `onContinuousHover` / `pointerStyle` is the **only** interaction (no tap/gesture fallback) — dead under a finger | warning | flag | `touch-affordances.md` |
| tg-06 | custom `onTapGesture`/`DragGesture`/`LongPressGesture` with **no** `.accessibilityAction` (unreachable by VoiceOver) | warning | flag | `touch-affordances.md` |
| tg-07 | row/item with actions but **no** touch-and-hold `.contextMenu` (the iOS idiom for secondary actions) | warning | flag | `touch-affordances.md` |
| tg-08 | `pointerStyle(_:)` on an iOS target — **no iOS arm at all** (platform-wrong) | hard-fail | flag | `gesture-availability.md` |
| tg-09 | a gesture/affordance gated on the **`macOS`** arm in an iOS target (wrong arm) | hard-fail | auto | `gesture-availability.md` |
| tg-10 | `.swipeActions` as the *only* secondary-action path — also expose the same actions in a `.contextMenu` | advisory | flag | `touch-affordances.md` |
| tg-11 | scrollable data `List`/`ScrollView` with **no** `.refreshable` (missing the pull-to-refresh idiom) | advisory | flag | `touch-affordances.md` |

**Two claims are UNVERIFIED — carry as `advisory` with the flag, never assert as fact** (each is flagged
in its reference + becomes `source: verify against Xcode 26 SDK`): the gesture-vs-built-in priority
resolution for tg-04 (verify the specific control's built-in gesture against the Xcode 26 SDK); and tg-11
(whether a given list truly *should* refresh on pull is a UX judgment, not mechanics).

## The real API, at a glance

**Real (exist on iOS):** `onTapGesture(count:perform:)` / `onLongPressGesture(...)` (iOS 13.0+),
`DragGesture` (iOS 13.0+), `MagnifyGesture` / `RotateGesture` (**iOS 17.0+** — at the deployment floor, so
**no gate needed**), `SpatialTapGesture` (iOS 16.0+), `@GestureState`, `.gesture` /
`.simultaneousGesture` / `.highPriorityGesture`, `.contextMenu(menuItems:)` (iOS 13.0+; touch-and-hold),
`.swipeActions(edge:allowsFullSwipe:)` (iOS 15.0+), `.refreshable` (iOS 15.0+; pull-to-refresh),
`.accessibilityAction(_:_:)` (iOS 13.0+). **iPad-pointer-only (augment, never the sole path):**
`onHover(perform:)` (iOS 13.4+), `onContinuousHover(coordinateSpace:perform:)` (iOS 16.0+).

**Platform-wrong on iOS (never use on an iOS target):** `pointerStyle(_:)` / `PointerStyle` — **macOS /
visionOS only, no iOS arm** (`swiftui-ctx lookup pointerStyle --platform ios` exits 3). Replace with a
touch interaction; never gate it on `#available(iOS …)`.
**Real-but-deprecated:** `MagnificationGesture` → `MagnifyGesture`; `RotationGesture` → `RotateGesture`
(the value carrier renames too: `.magnification` was `.magnitude`; `.rotation`).

**Grounded ✅ — the touch shape, from real shipping iOS code (not a placeholder).** The tg-06/secondary
consensus for `onTapGesture` is `{ … }` (94% of 1,533 real uses, `swiftui-ctx lookup onTapGesture
--platform ios`). A pairing with `.accessibilityAction` makes the tap reachable:

```swift
// ✅ touch + VoiceOver-reachable — verified shape in the corpus
card
    .onTapGesture { open(item) }
    .accessibilityAction { open(item) }              // VoiceOver can now trigger it
// Source: https://github.com/relatedcode/ProgressHUD/blob/e6f7339d70d793a12dbccb008d374e153f2b98b5/SwiftUI/Sources/ProgressHUD+Banner.swift#L63
// Spec:   https://sosumi.ai/documentation/swiftui/view/ontapgesture(count:perform:)  (onTapGesture — iOS 13.0+)
```

Every finding's `## Source` carries the live `recommended` permalink for *its* API, fetched fresh via
`swiftui-ctx lookup <api> --platform ios` + `file <recommended.id> --smart` (step 7) — the block above is
the worked template, not the only citation.

Signatures, floors, and the full ❌→✅ rewrites: `references/touch-affordances.md` +
`references/gestures-and-state.md`. Floor *values* are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` and the canonical deprecated/invented list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read, never restate them.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). It is load-bearing,
   but note the toolkit floor is **iOS 17** — `MagnifyGesture`/`RotateGesture` (iOS 17),
   `.swipeActions`/`.refreshable` (iOS 15), and `onContinuousHover` (iOS 16) all sit at-or-below it, so
   gates are rarely needed; record the target anyway. Also note the **idiom target** — an iPhone-only app
   (no iPad / no pointer support) makes any pointer-only affordance dead (tg-05).
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-touch-gestures --dir <sources> --json /tmp/tg.json --sarif /tmp/tg.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + tier-2 structural ast-grep rules
   (`lint/ast-grep/*.yml` — wrong-arm gate-scope and gesture-composition co-occurrence grep can't
   express), plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`**
   — a flagged file did not fully parse, so a structural miss can't masquerade as clean; READ those by
   hand. The runner only LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a view is
   *interactive* (so tg-05/06 apply), whether a gesture is *continuous* (so tg-03 applies), whether a
   pointer affordance has a touch fallback, whether a custom gesture has an `.accessibilityAction`, and
   gesture composition are invisible to grep. Build a per-file inventory: each interactive view + its
   touch affordances (tap / long-press / swipe / context-menu) + each gesture + its state + its
   accessibility action.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `MagnificationGesture`, a `pointerStyle` on an iOS target, an `.onHover`-only
   control, a continuous `DragGesture` with no `@GestureState`, a `#available(macOS)` arm).
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, a
   behavior claim), run **both** evidence sources. (a) **Practice** — `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx
   lookup <api> --platform ios --json` (and `swiftui-ctx deprecated <api>` for a currency/deprecation rule
   — tg-01/tg-02): read its `consensus` (the canonical shape), `deprecated`+`replacement`/`migrate_to`,
   `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a `lookup` **exit 3** corroborates a
   platform-wrong finding (tg-08 `pointerStyle`) — the symbol has no iOS arm. (b) **Spec** — confirm via
   **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the
   path and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never
   `WebFetch` `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the
   Sosumi `doc:` floor. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or
   discard. Carry the two UNVERIFIED items as `advisory` with `source: verify against Xcode 26 SDK`.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Emit `cross_ref` on shared-seam findings (tg-01/tg-02 → `api-currency`; tg-06 → `accessibility`;
   tg-05 → `ios-idiomaticness`; a `.contextMenu` action that should be a Shortcuts intent → `app-intents`;
   a `DragGesture` carrying a `Transferable` payload → `document-picker-permissions`). Write the run's
   `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (tg-09 wrong-arm rewrite), one conventional commit per finding citing its
   `rule_id`, never weaken a check. The ✅ "Correct" is **not a hand-written snippet** — it is the
   swiftui-ctx **consensus shape** put in `## Correct`, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink
   (plus the Sosumi `doc:`) goes in `## Source` as the canonical example. Leave `flag-only` findings `open`
   with that ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep each fixed file to confirm the tell no longer matches; record the evidence in
   `## Fix applied?`. Re-confirm every citation still resolves and still says the expected floor. If a fix
   introduced a new tell (e.g. a touch fallback you added now needs an `.accessibilityAction`), loop that
   file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding. tg-05/06/07 hinge on the view being *interactive*: a static
label is not a defect for lacking a touch fallback or accessibility action. Auto-fix only the mechanical
set (tg-09 wrong-arm rewrite); everything else is `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/touch-gestures/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/touch-gestures/_index.md`.
- `domain: touch-gestures`. Frontmatter is the canonical schema; `fix_mode` is `auto` for tg-09, else
  `flag-only`. `availability` reads from `floors-master.md`. `source` is an Apple URL + access date
  (fetched via Sosumi) or `verify against Xcode 26 SDK`. Emit `cross_ref` per the seam note (step 6).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `gesture-currency/` | a deprecated pinch/rotate gesture needs its `MagnifyGesture`/`RotateGesture` rewrite (tg-01, tg-02) |
| `gesture-state/` | a continuous gesture has no live `@GestureState`, or composition is wrong (tg-03, tg-04) |
| `dead-pointer-affordance/` | a pointer-only affordance is the sole interaction on a touch target (tg-05) |
| `gesture-accessibility/` | a custom gesture is unreachable by VoiceOver — no `.accessibilityAction` (tg-06) |
| `touch-idioms/` | a row/list is missing the touch-and-hold menu, swipe actions, or pull-to-refresh (tg-07, tg-10, tg-11) |
| `availability-gating/` | a `pointerStyle` on iOS, or a gesture gated on the wrong (`macOS`) arm (tg-08, tg-09) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/touch-gestures/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

> **Go-beyond artifact (optional):** `swiftui-audits/touch-gestures/_affordance-map.md` classifying every
> custom interactive view as `has-tap` / `has-long-press` / `has-swipe` / `has-context-menu` /
> `voiceover-reachable` with an affordance-coverage score — see `references/touch-affordances.md`.

## Reference routing

| File | Open when |
|---|---|
| `references/touch-affordances.md` | touch idioms + the inverse pointer trap — the dead-pointer-affordance rule, `.accessibilityAction` reachability, touch-and-hold `.contextMenu`, `.swipeActions`, `.refreshable` (tg-05/06/07/10/11) |
| `references/gestures-and-state.md` | gesture currency, live `@GestureState`, and gesture composition — the deprecated-rename mechanics + `.gesture` vs `.simultaneousGesture`/`.highPriorityGesture` (tg-01/02/03/04) |
| `references/gesture-availability.md` | the platform-wrong `pointerStyle` trap and the wrong-arm (`macOS`) gate (tg-08/09) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + tier-2 structural ast-grep); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical deprecated/invented-name list (deprecated gesture renames) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule + wrong-arm failure (tg-09) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-touch-gestures --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, tg-01/02/03/04/05/06/07/08/10/11) +
**tier-2 ast-grep** structural rules (`lint/ast-grep/*.yml` — tg-09 wrong-arm gate-scope and tg-04
gesture-composition co-occurrence) that grep cannot express. It runs a per-file **parse probe** (surfaces
"did not fully parse" so a structural miss can't look clean), emits unified **JSON + SARIF**, exits **2**
on any hard-fail (tg-08/tg-09) for a CI gate, and **degrades to grep-only with a notice** if ast-grep is
unreachable (`npx --package @ast-grep/cli ast-grep`; faster: `brew install ast-grep`). It only LOCATES —
always READ each hit in full before reporting (step 3). The thin `scripts/tg-lint.sh` is a pointer to this
runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
