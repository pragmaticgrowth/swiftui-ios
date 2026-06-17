---
name: audit-swiftui-uikit-interop
description: Audits an iOS SwiftUI app for UIKit-bridge correctness defects in UIViewRepresentable / UIViewControllerRepresentable / UIHostingController, writing per-finding Markdown to swiftui-audits/. Use when the user says a wrapped UIKit view "doesn't update" or "ignores its @Binding", a representable's state never propagates, a UITextView/WKWebView bridge feels stale, a delegate/Coordinator never fires or leaks, a keyboard won't show because becomeFirstResponder runs in the wrong place, or SwiftUI-in-UIKit via UIHostingController misbehaves; when AI wrote a UIViewRepresentable with no updateUIView body, read a @Binding in makeUIView but never re-applied it in updateUIView, set a UIKit delegate with no makeCoordinator, or strongly captured the parent in a Coordinator. AUDIT-ONLY, iOS-only, SwiftUI-only. This is the HOW of a bridge that already exists, not WHETHER it should (audit-swiftui-uikit-overuse owns that), not @Sendable/@MainActor at the bridge (audit-swiftui-concurrency-safety), not a from-scratch wrapper.
---

# Audit SwiftUI ⇄ UIKit Interop

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way a `UIViewRepresentable` / `UIViewControllerRepresentable` /
`UIHostingController` bridge is wired *wrong*: a representable with **no `updateUIView` body** (SwiftUI
state changes can never reach the UIKit view), a `@Binding`/property read in `makeUIView` but **never
re-applied in `updateUIView`** (the view freezes at its initial value), a UIKit **delegate set with no
`makeCoordinator`** (the delegate target is never created, so callbacks are silently dead), a **Coordinator
that strongly captures its parent** (retain cycle / stale closure), and a `becomeFirstResponder()` called
where it has no effect. Findings are written to disk in the toolkit's unified schema; certain mechanical
defects are flagged with the consensus shape. This is never a from-scratch UIKit-wrapper generator.

**A SwiftUI ⇄ UIKit bridge has exactly four parts, and three of them are easy to forget.** The corpus
shows **1,007 real bridges across 186 repos** (`UIViewRepresentable` 504 · `UIViewControllerRepresentable`
427 — `swiftui-ctx bridges`); the canonical shape is `makeUIView(context:)` → `updateUIView(_:context:)` →
`makeCoordinator()` → a nested `Coordinator` (`swiftui-ctx recipe uiview-bridge`). The training corpus is
heavy with *toy* representables that only `makeUIView` and stop — so AI routinely omits the `updateUIView`
body and the `makeCoordinator` that a delegate needs. The result compiles, renders once, and then ignores
every state change SwiftUI sends it. Be suspicious wherever AI wrapped a `UITextView`, `WKWebView`,
`MKMapView`, `UIScrollView`, or any delegate-driven UIKit control.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **WHETHER the bridge should exist at all is not mine.** If a `UIViewRepresentable` wraps something SwiftUI
  already has natively (a label → `Text`, a button → `Button`, a plain `UIScrollView` → `ScrollView`), that
  is `audit-swiftui-uikit-overuse`. This skill owns the **HOW** — once a bridge is justified, is it wired
  correctly. Note an "is this bridge even needed?" smell in one line and `cross_ref: uikit-overuse`; don't
  audit it here. This is a **bidirectional handshake**: overuse = whether, interop = how.
- **`@Sendable` / `@MainActor` correctness at the bridge is not mine.** A Coordinator captured into a UIKit
  callback that hops off the main actor, a non-`Sendable` value crossing the boundary, an `await` in a
  delegate method — those are `audit-swiftui-concurrency-safety`. I own the **retain cycle / wiring** angle
  of a Coordinator (uik-04); the **isolation hazard** angle is concurrency's. `cross_ref:
  concurrency-safety` when a captured Coordinator also crosses an actor boundary; don't claim the isolation.
- **API currency at the bridge.** A *deprecated* UIKit-bridge symbol (e.g. a renamed delegate API) is
  `audit-swiftui-api-currency` (it owns every deprecation flag); the *wiring* is mine. `cross_ref` it.
- **`becomeFirstResponder` vs accessibility focus.** Programmatic first-responder (keyboard) is mine
  (uik-06); `AccessibilityFocusState`/`.accessibilityFocused` (VoiceOver focus) is
  `audit-swiftui-accessibility` — different mechanism; `cross_ref`, don't conflate.

## The four bridge rules (the judgment core)

1. **A representable MUST implement `updateUIView` with a real body.** `makeUIView` builds the view *once*;
   `updateUIView(_:context:)` is the **only** path SwiftUI state reaches the UIKit view. A representable with
   no `updateUIView`, or an empty `updateUIView { }`, freezes at its initial render — every `@State`/`@Binding`
   change above it is dropped (uik-01).
2. **Every property/`@Binding` read in `makeUIView` must be re-applied in `updateUIView`.** Setting
   `view.text = text` only in `makeUIView` binds the *initial* value; when `text` changes, SwiftUI calls
   `updateUIView`, and if that body doesn't re-assign `uiView.text = text` the view never catches up
   (uik-02).
3. **A UIKit delegate/dataSource needs a `makeCoordinator` + a `Coordinator` that owns it.** Setting
   `view.delegate = context.coordinator` requires `makeCoordinator()` to *return* that Coordinator; without
   it `context.coordinator` is never your object and the delegate callbacks are dead. The Coordinator must
   **not** strongly capture the parent representable (`self.parent = parent` is fine — a struct value; a
   retained closure capturing `self` of a class is the cycle) (uik-03, uik-04).
4. **Bridge in the correct direction with the right host.** SwiftUI-in-UIKit uses `UIHostingController`
   (and you must add it as a child VC + pin its view, not just `addSubview`); `becomeFirstResponder()` must
   run after the view is in the window (in `updateUIView` or a Coordinator callback, not in `makeUIView`
   before the view exists) (uik-05, uik-06).

Full ❌→✅ + the canonical `makeUIView → updateUIView → makeCoordinator → Coordinator` exemplar:
`references/representable-correctness.md`.

## Defect index (uik-01 … uik-06)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (the bridge is structurally
broken — state cannot propagate / delegate is dead), **warning** (compiles but a value/callback is lost),
**advisory** (judgment / direction). `auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| uik-01 | a `UIViewRepresentable`/`UIViewControllerRepresentable` with **no `updateUIView`/`updateUIViewController`** (or an empty body) → SwiftUI state can never propagate | hard-fail | flag | `representable-correctness.md` |
| uik-02 | a property/`@Binding` set in `makeUIView` but **never re-applied in `updateUIView`** → view freezes at its initial value | warning | flag | `representable-correctness.md` |
| uik-03 | a UIKit `delegate`/`dataSource` assigned to `context.coordinator` with **no `makeCoordinator()`** → Coordinator never created, callbacks dead | hard-fail | flag | `representable-correctness.md` |
| uik-04 | a `Coordinator` that **strongly captures its parent / `self` in a retained closure** → retain cycle / stale parent | warning | flag | `representable-correctness.md` |
| uik-05 | a `UIHostingController` added via bare `addSubview` with **no `addChild` / `didMove(toParent:)`** → broken child-VC containment | advisory | flag | `hosting-and-firstresponder.md` |
| uik-06 | `becomeFirstResponder()` called in `makeUIView` (view not yet in the window) → no-op; belongs in `updateUIView` or a Coordinator callback | advisory | flag | `hosting-and-firstresponder.md` |

**uik-01 and uik-03 are the hard-fails** — a representable that can't update or whose delegate never fires
is structurally non-functional, not merely non-idiomatic. uik-04 cross-refs `concurrency-safety` (the same
capture is also the isolation seam); uik-01/02/03 may cross-ref `uikit-overuse` if the bridge shouldn't exist.

## The real API, at a glance

**Real (the bridge protocol-requirement surface; floors are the reconciled truth in `floors-master.md` —
read, never restate):** `UIViewRepresentable` / `UIViewControllerRepresentable` are **conformance patterns**
(no single floor symbol — `swiftui-ctx lookup UIViewRepresentable` redirects to `recipe uiview-bridge`),
their requirements `makeUIView(context:)`, `updateUIView(_:context:)`, `makeUIViewController(context:)`,
`updateUIViewController(_:context:)`, `makeCoordinator()`, the associated `Coordinator` type, and the
`Context` (`context.coordinator`, `context.environment`, `context.transaction`). `UIHostingController(rootView:)`
hosts SwiftUI inside UIKit (iOS 13.0+ — UIKit symbol, verify against the Xcode 26 SDK; the SwiftUI corpus
records `UIHostingController` consensus `(rootView)` at 100%). `becomeFirstResponder()` / `resignFirstResponder()`
are UIKit `UIResponder` methods.

**Not a bridge symbol (exit 3 in the corpus):** `Coordinator` and `makeCoordinator` resolve **exit 3** on
`swiftui-ctx lookup` — they are *protocol-requirement names*, not standalone catalog symbols; that exit 3 is
**expected**, not a hallucination signal. If audited code reaches for a bridge symbol you can't place (a made-up
`updateView`, a non-existent `Representable` base class), confirm via `swiftui-ctx lookup <api> --platform ios`
(**exit 3** + a did-you-mean = likely hallucination) + Sosumi, and cross-check
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` before flagging. Signatures + full ❌→✅:
`references/representable-correctness.md`, `references/hosting-and-firstresponder.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — it sets which floor a
   fix may rely on (the project floor is **iOS 17**; `UIViewRepresentable`/`UIHostingController` are the iOS 13
   bridge era — well below the floor, so no gate is needed for the bridge itself). Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-uikit-interop --dir <sources> --json /tmp/uik.json --sarif /tmp/uik.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, uik-01…uik-06) + any tier-2 structural
   ast-grep rules (`lint/ast-grep/*.yml` — the **absence** of an `updateUIView` inside a representable; the
   **absence** of `makeCoordinator` when a delegate is set), plus a per-file **parse probe**, and emits
   unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully parse, so a structural
   miss can't masquerade as clean; READ those by hand. The runner only LOCATES — never treat a hit as a
   finding. ast-grep is **not installed** on this machine, so tier-1 grep stands alone and the runner degrades
   to grep-only with a notice. Engine + rule-file format:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a representable
   actually carries an `updateUIView` (and whether its body is real or empty), whether a value read in
   `makeUIView` is re-applied in `updateUIView`, whether a delegate is wired to a `Coordinator` that
   `makeCoordinator` returns, and whether a Coordinator captures its parent strongly are all invisible to grep.
   Build a per-file inventory: each representable + its `make`/`update`/`makeCoordinator` set; each delegate
   assignment + its Coordinator; each `UIHostingController` + its containment; each `becomeFirstResponder` + its
   call site.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `UIViewRepresentable` whose body has `makeUIView` but no `updateUIView`; a
   `view.delegate = context.coordinator` with no `makeCoordinator` in the type). A representable that has a
   genuine `updateUIView` body re-applying its inputs, or one with no delegate (so no Coordinator needed), is
   *not* a defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a bridge shape you can't place, whether a symbol exists, the
   canonical wiring), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx recipe uiview-bridge --json` for the canonical `makeUIView →
   updateUIView → makeCoordinator → Coordinator` template + permalinked real examples, `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx bridges --json` for the 1,007-bridge corpus and `by_kind`
   breakdown, and `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` for a
   single symbol (`introduced_ios` is at `result.introduced_ios`; **exit 3** = not a standalone symbol — for
   `Coordinator`/`makeCoordinator` that is expected, for an invented name it corroborates a hallucination).
   (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the iOS path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check any floor against `floors-master.md`. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — adding an `updateUIView` body, re-applying a
   binding, or wiring a Coordinator are all structural/judgment calls, so all are `flag-only`), one
   conventional commit per finding citing its `rule_id`, never weaken a check. The ✅ "Correct" is **not a
   hand-written snippet** — it is the `swiftui-ctx recipe uiview-bridge` **canonical shape** put in
   `## Correct`, backed by a real bridge example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <example.id> --smart` whose GitHub permalink (plus the
   Sosumi `doc:`) goes in `## Source`. Leave `flag-only` findings `open` with that ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. the `updateUIView` you added now reads a `@Binding` that needs a Coordinator to write back),
   loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: each correct fix is a
structural/judgment call (what `updateUIView` should re-apply, whether a delegate truly needs a Coordinator,
how to break a capture cycle, where `becomeFirstResponder` belongs), so all are `fix_mode: flag-only`. uik-01
and uik-03 are hard-fails but still flag-only — the body of the fix depends on what the bridge wraps.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/uikit-interop/<context>/NN-slug.md` (one finding per file, zero-padded, ordered).
  Per-run index: `swiftui-audits/uikit-interop/_index.md`.
- `domain: uikit-interop`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every defect.
  `availability` reads from `floors-master.md` (the bridge surface is iOS-13-era, below the iOS-17 floor).
  `source` is an Apple URL + access date (fetched via Sosumi) or `verify against Xcode 26 SDK`. Body carries a
  **`## Why it's wrong on iOS`** section. Emit `cross_ref` on uik-04 (→ `concurrency-safety` when the captured
  Coordinator also crosses an actor boundary), uik-01/02/03 (→ `uikit-overuse` when the bridge shouldn't exist
  at all), and any deprecated bridge symbol (→ `api-currency`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `missing-update/` | a representable has no `updateUIView`/`updateUIViewController` body, so state can't propagate (uik-01) |
| `binding-not-applied/` | a property/`@Binding` is set only in `makeUIView`, never re-applied in `updateUIView` (uik-02) |
| `coordinator-wiring/` | a delegate/dataSource is set with no `makeCoordinator`, or a Coordinator retains its parent (uik-03, uik-04) — `cross_ref` concurrency-safety on the capture |
| `hosting-controller/` | a `UIHostingController` is embedded without child-VC containment (uik-05) |
| `first-responder/` | `becomeFirstResponder()` is called where the view isn't yet in the window (uik-06) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/uikit-interop/` with a lowercase-hyphen slug naming the sub-category, and note it in the run's
`_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/representable-correctness.md` | the missing/empty `updateUIView`, the binding-not-reapplied freeze, the delegate-with-no-`makeCoordinator`, and the Coordinator retain cycle (uik-01/02/03/04) + the canonical `makeUIView → updateUIView → makeCoordinator → Coordinator` exemplar |
| `references/hosting-and-firstresponder.md` | `UIHostingController` child-VC containment (SwiftUI-in-UIKit) and the `becomeFirstResponder` call-site trap (uik-05/06) |
| `references/source-directory.md` | step VERIFY — the Apple/iOS source map fetched via Sosumi |
| `lint/grep-tells.tsv` | step LOCATE — this skill's tier-1 grep rule set fed to the shared runner (uik-01…uik-06); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled iOS truth; the bridge surface is iOS-13-era, below the iOS-17 floor) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS `#available(iOS NN, *)` gating rule (a fix that uses a symbol above the iOS-17 floor needs a gate) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up bridge/Coordinator symbol — note `Coordinator`/`makeCoordinator` exit 3 is *expected*, not hallucinated) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `recipe uiview-bridge`/`bridges`/`lookup`/`file --smart` for the canonical shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (uikit-overuse WHETHER↔HOW, concurrency-safety at the bridge, api-currency deprecations) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-uikit-interop --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, uik-01…uik-06, mandatory and self-test-validated)
+ optional **tier-2 ast-grep** structural rules (`lint/ast-grep/*.yml`) for the cases grep cannot express (the
**absence** of an `updateUIView` inside a representable conformance, the **absence** of `makeCoordinator` when a
delegate is assigned). It runs a per-file **parse probe** (surfaces "did not fully parse" so a structural miss
can't look clean), emits unified **JSON + SARIF**, exits **2** on any hard-fail (uik-01/uik-03) for a CI gate,
and — since **ast-grep is not installed here** — runs **grep-only with a notice** (the grep tier stands alone).
It only LOCATES — always READ each hit in full before reporting (step 3). The thin `scripts/uikit-interop-lint.sh`
is a pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
