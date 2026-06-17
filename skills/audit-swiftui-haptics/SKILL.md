---
name: audit-swiftui-haptics
description: Audits a finished or in-progress iOS SwiftUI codebase for haptic-feedback defects and writes findings to swiftui-audits/. Use when the user says a tap or success has no haptic, a vibration feels laggy, haptics fire on every scroll tick or frame, or a feedback generator is created per call; when they ask to verify sensoryFeedback, UIImpactFeedbackGenerator, UINotificationFeedbackGenerator, UISelectionFeedbackGenerator, prepare, impactOccurred, selectionChanged, or CHHapticEngine; when AI wrote a raw UIImpactFeedbackGenerator().impactOccurred() where the SwiftUI .sensoryFeedback(_:trigger:) modifier (iOS 17) fits, a generator used with no prepare() so the first buzz lags, a generator re-instantiated per call, or haptics on a high-frequency event. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for whether a UIKit type should be bridged at all (uikit-overuse); not for the gesture wiring that triggers feedback (touch-gestures); not for the haptic as a non-visual a11y channel (accessibility); not the availability sweep.
---

# Audit SwiftUI Haptics

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way haptic feedback goes wrong: a raw
`UIImpactFeedbackGenerator().impactOccurred()` where the declarative `.sensoryFeedback(_:trigger:)` modifier
(iOS 17) is the native fit, a feedback generator fired with **no** `.prepare()` so the first buzz is
noticeably delayed, a generator **re-instantiated per call** (so `.prepare()` can never warm the engine),
and haptics **fired on every frame / scroll tick** (overuse that desensitizes and drains the Taptic Engine).
Findings are written to disk in the toolkit's unified schema; certain mechanical defects are flagged under
the fix-safety protocol. This is never a from-scratch haptics generator.

**iOS 17 made haptics declarative.** Before `.sensoryFeedback`, the only path was a UIKit
`UIFeedbackGenerator` subclass — imperative, easy to get wrong (forgot `.prepare()`, leaked a generator,
fired it in a `body` recompute). AI trained on pre-iOS-17 corpora reaches for the raw generator by reflex,
even on an iOS 17 target where `.sensoryFeedback(_:trigger:)` ties the buzz to a state change and the engine
warm-up is handled for you. The raw call compiles and buzzes, but it is the non-native shape. Be suspicious
wherever AI built a tap/success/selection buzz with a UIKit generator, fired feedback in a hot path, or
created a generator inline at the call site.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **WHETHER a UIKit type should be bridged at all** is `audit-swiftui-uikit-overuse`. On the
  raw-`UIImpactFeedbackGenerator`-where-`.sensoryFeedback`-fits seam, **this skill owns the feedback
  *idiom*** (hap-01 — the `.sensoryFeedback` rewrite is the native craft) and is **primary**; emit
  `cross_ref: uikit-overuse` for the "should this be SwiftUI at all" angle. Do not file the same site as a
  generic over-bridge here.
- **The gesture / event that *triggers* the feedback** (`.onTapGesture`, `DragGesture`, a
  `.swipeActions` row) belongs to `audit-swiftui-touch-gestures`. This skill owns the *feedback call*; the
  gesture wiring is theirs — `cross_ref: touch-gestures` when a gesture-triggered buzz is the seam.
- **The haptic as a *non-visual accessibility channel*** (a buzz substituting for a visual-only cue, or
  respecting a user who disables haptics) is `audit-swiftui-accessibility`. Note it in one line and
  `cross_ref: accessibility` — do not audit the a11y obligation here.
- **The blanket "is every OS-floored API gated" sweep** is `audit-swiftui-availability-gating`; this skill
  owns the `.sensoryFeedback` iOS-17 floor in depth (at the deployment floor, so rarely a gate) and defers
  the rest there.

## The three haptics rules (the judgment core)

1. **On an iOS 17 target, prefer `.sensoryFeedback(_:trigger:)`.** It ties the buzz to a state change
   declaratively, the engine warm-up is handled, and there is no generator to leak — a raw
   `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator`/`UISelectionFeedbackGenerator` at the call
   site is the pre-17 reflex (hap-01).
2. **If you must use a raw generator, `.prepare()` it first and keep it alive.** `.prepare()` warms the
   Taptic Engine so the first `.impactOccurred()` / `.notificationOccurred()` / `.selectionChanged()` is not
   latent; a generator **re-created per call** can never be warmed, so the buzz is always late (hap-02 — no
   `.prepare()`; hap-03 — generator re-instantiated per call).
3. **Haptics are a punctuation, not a texture.** A buzz on **every frame / scroll tick / high-frequency
   event** desensitizes the user, fights the system, and drains the Taptic Engine — feedback must mark a
   discrete, meaningful event (hap-04).

**The haptics test:** is this a discrete, meaningful event (so it deserves one buzz), is the target iOS 17
(so `.sensoryFeedback` is the fit), and — if raw — is the generator a long-lived, `.prepare()`d instance?
Full ❌→✅ + the canonical `.sensoryFeedback` exemplar: `references/sensory-feedback.md`.

## Defect index (hap-01 … hap-04)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (never-correct on iOS),
**warning** (compiles but non-native / latent), **advisory** (judgment / overuse). `auto` = mechanical
single-answer fix; `flag` = show the ✅, dev applies. No defect in this domain is auto-fixed — every fix is
a judgment call (which feedback flavour, whether a generator should be hoisted, whether an event is
discrete), so all are `flag-only`.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| hap-01 | a raw `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator`/`UISelectionFeedbackGenerator` where `.sensoryFeedback(_:trigger:)` (iOS 17) fits | warning | flag | `sensory-feedback.md` |
| hap-02 | a feedback generator fired (`.impactOccurred()`/`.notificationOccurred()`/`.selectionChanged()`) with **no** `.prepare()` in scope → latent first buzz | warning | flag | `sensory-feedback.md` |
| hap-03 | a feedback generator **instantiated inline at the call site** (`UI…FeedbackGenerator().…Occurred()`) → re-created per call, can never be `.prepare()`d/warmed | warning | flag | `sensory-feedback.md` |
| hap-04 | a haptic fired on a high-frequency event (`.onChange`/`scrollPosition`/`DragGesture().onChanged`/per-frame) → overuse desensitizes + drains the Taptic Engine | advisory | flag | `sensory-feedback.md` |

**hap-01 is the keystone (primary on the uikit-overuse seam); hap-02/03 are the raw-generator latency
pair.** None is a hard-fail: a raw `UIFeedbackGenerator` is *valid* iOS, just non-native on an iOS 17
target — it is **not** platform-wrong, never gate it away, prefer `.sensoryFeedback` and keep the raw path
only when the generator is correctly hoisted + `.prepare()`d (e.g. a Core-Haptics-adjacent custom pattern).

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` — read, never restate):**
`sensoryFeedback(_:trigger:)` / `SensoryFeedback` (**iOS 17.0+** — at the deployment floor, so **no gate
needed**; the value list is `.impact` / `.success` / `.warning` / `.error` / `.selection` / `.increase` /
`.decrease` / `.start` / `.stop` / `.alignment` / `.levelChange`). The pre-17 UIKit path — `UIImpactFeedbackGenerator`,
`UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator` (all subclasses of `UIFeedbackGenerator`),
their `.prepare()` and `.impactOccurred()` / `.notificationOccurred(_:)` / `.selectionChanged()` — is **iOS
10.0+** but **not in the SwiftUI corpus** (`swiftui-ctx lookup UIImpactFeedbackGenerator` returns
`introduced_ios: null`); cite the well-known iOS-10 introduction and mark `source: verify against Xcode 26
SDK`, never assert a corpus floor for it. **Advanced custom patterns:** `CHHapticEngine` / Core Haptics
(iOS 13.0+, also outside the SwiftUI corpus — `verify against Xcode 26 SDK`).

`.sensoryFeedback` floors are confirmed live: `swiftui-ctx lookup sensoryFeedback --platform ios` →
`introduced_ios: 17.0`, `deprecated: false`, consensus `(_, trigger)` 92%. No invented names are central
here; if audited code reaches for a feedback symbol you can't place, confirm via swiftui-ctx (`lookup`
**exit 3** = likely hallucination or no-iOS-arm) + Sosumi before flagging, and cross-check
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/sensory-feedback.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). It is load-bearing,
   but the toolkit floor is **iOS 17** — `.sensoryFeedback` sits *at* it, so the hap-01 rewrite needs **no
   gate**. Record the target anyway: a genuine pre-17 target legitimizes the raw generator (then hap-02/03
   still apply — `.prepare()` + hoisting).
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-haptics --dir <sources> --json /tmp/hap.json --sarif /tmp/hap.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, hap-01…hap-04) plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a miss can't masquerade as clean; READ those by hand. The runner only LOCATES — never treat a
   hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a generator
   is **hoisted to a stored property** (so `.prepare()` *can* warm it) vs **created inline** (hap-03),
   whether a `.prepare()` exists anywhere in scope (hap-02), whether the firing site is a **discrete event**
   vs a **per-frame / scroll / `.onChanged` hot path** (hap-04), and whether the target is iOS 17 (so
   hap-01 applies) are all invisible to grep. Build a per-file inventory: each generator + where it lives +
   its `.prepare()` + each fire site + the event that drives it.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `UIImpactFeedbackGenerator().impactOccurred()` inline on an iOS 17 target = hap-01 +
   hap-03; an `.impactOccurred()` with no `.prepare()` in scope = hap-02; a buzz inside
   `DragGesture().onChanged` = hap-04). A correctly hoisted, `.prepare()`d generator used for one discrete
   event on a pre-17 target is *not* a defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, the
   canonical shape), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read its `consensus` (the
   canonical shape), `recommended` permalink, `introduced_ios`, and `co_occurs_with`. For
   `.sensoryFeedback` this returns `introduced_ios: 17.0` + the consensus `(_, trigger)` shape; for a UIKit
   generator / `CHHapticEngine` it returns `introduced_ios: null` (outside the SwiftUI corpus) — you
   **cannot** confirm a floor from swiftui-ctx, so cite the well-known iOS-10 (generators) / iOS-13 (Core
   Haptics) introduction and mark `verify against Xcode 26 SDK`; never fabricate a floor. (b) **Spec** —
   confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md`
   for the path and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never
   `WebFetch` `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md`. The CLI
   contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the
   citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Emit `cross_ref` on shared-seam findings (hap-01 → `uikit-overuse`, the should-this-be-SwiftUI
   angle; a gesture-triggered buzz → `touch-gestures`; a haptic-as-non-visual-cue → `accessibility`). Write
   the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a judgment call, so all are
   `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅
   "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in
   `## Correct`, backed by a real iOS example fetched with `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus the
   Sosumi `doc:`) goes in `## Source` as the canonical example. The hap-01 ✅ is grounded in the live
   `swiftui-ctx lookup sensoryFeedback` consensus (`.sensoryFeedback(_, trigger:)`, 92%) + its recommended
   iOS-26 permalink (see `references/sensory-feedback.md`). Leave `flag-only` findings `open` with that ✅ in
   `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves and still says the
   expected floor. If a fix introduced a new tell (e.g. a `.sensoryFeedback` you added now drives off an
   `.onChange` that fires too often → hap-04), loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. hap-04 hinges on the event being *high-frequency*: a buzz on a
discrete `.onChange` (a value that flips once on user action) is **not** overuse; a buzz on a continuously
changing `scrollPosition` / `DragGesture().onChanged` is. **No defect in this domain is auto-fixed**: which
feedback flavour (`.impact` vs `.success` vs `.selection`), whether to hoist a generator, and whether an
event is discrete are all judgment calls, so all are `fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/haptics/<context>/NN-slug.md` (one finding per file, zero-padded, ordered).
  Per-run index: `swiftui-audits/haptics/_index.md`.
- `domain: haptics`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every defect.
  `availability` reads from `floors-master.md` for `.sensoryFeedback` (iOS 17.0); for a UIKit generator /
  `CHHapticEngine` it is the well-known iOS-10 / iOS-13 floor with `source: verify against Xcode 26 SDK`.
  The body's iOS-specific rationale goes in **`## Why it's wrong on iOS`**. Emit `cross_ref` per the seam
  note (step 6).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `prefer-sensory-feedback/` | a raw UIKit generator is used where `.sensoryFeedback(_:trigger:)` fits on an iOS 17 target (hap-01) — `cross_ref` uikit-overuse |
| `generator-lifecycle/` | a generator fires with no `.prepare()`, or is re-instantiated inline per call (hap-02, hap-03) |
| `haptic-overuse/` | a haptic fires on a high-frequency / per-frame / scroll event (hap-04) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/haptics/` with a lowercase-hyphen slug naming the sub-category, and note it in the run's
`_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/sensory-feedback.md` | the `.sensoryFeedback` rewrite, the `.prepare()` + generator-hoisting craft, and the overuse rule — every defect (hap-01/02/03/04) + the canonical `.sensoryFeedback` exemplar |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` | step LOCATE — this skill's declarative tier-1 grep tells (hap-01…hap-04) fed to the shared runner; edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `sensoryFeedback`/`SensoryFeedback` iOS 17.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up feedback symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (`.sensoryFeedback` sits at the iOS 17 floor → no gate) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + the `## Why it's wrong on iOS` body section |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (uikit-overuse primary verdict, touch-gestures, accessibility) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-haptics --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, hap-01…hap-04) for the raw-generator
reach, the inline-instantiation shape, the bare fire-with-no-`.prepare()`, and the high-frequency-event
overuse. It runs a per-file **parse probe** (surfaces "did not fully parse" so a miss can't look clean),
emits unified **JSON + SARIF**, and **degrades to grep-only with a notice** if ast-grep is unreachable
(this skill ships **grep tells only** — no tier-2 rules — so it runs fully under grep alone). It only
LOCATES — always READ each hit in full before reporting (step 3). The thin `scripts/haptics-lint.sh` is a
pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
