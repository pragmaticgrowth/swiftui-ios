---
name: audit-swiftui-app-intents
description: Audits an iOS SwiftUI codebase for App Intents defects that make a feature invisible to Siri, Spotlight, and the Shortcuts app, writing findings to swiftui-audits/. Use when the user says a Shortcut never shows up, "Hey Siri" can't find an action, an intent has no spoken phrase, a parameter is unlabeled in the Shortcuts editor, or an intent crashes off the main actor; when they ask to verify AppIntent, perform(), the required static title, AppShortcutsProvider, appShortcuts, AppShortcut phrases, the Parameter title, OpenIntent, EntityQuery, or AppEntity; when AI wrote an AppIntent with no static title, an AppShortcutsProvider with empty phrases, a Parameter with no title, or left a legacy SiriKit INIntent unmigrated. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for interactive widget Button(intent:) placement (widgets-live-activities); not for intents touching protected resources (privacy-permissions); not for a contextMenu touch interaction (touch-gestures); not for the availability sweep.
---

# Audit SwiftUI App Intents

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way an **App Intent** is defined but stays invisible
or broken on the system surfaces it is meant to reach: an `AppIntent` with **no `static var title`**
(a protocol requirement — the type does not compile, or a stub title hides the real label), an
`AppShortcutsProvider` whose `appShortcuts` carry **empty or no `phrases`** (so Siri and Spotlight have
nothing to match — the action is undiscoverable), a `@Parameter` with **no `title:`** (it renders
unlabeled in the Shortcuts editor), a `perform()` doing UI work off the main actor, and a **legacy
SiriKit `INIntent` / `IntentConfiguration`** left unmigrated to the AppIntents framework. Findings are
written to disk in the toolkit's unified schema; certain mechanical defects are fixed under the
fix-safety protocol. This is never a from-scratch intent generator.

**App Intents are the system's discovery surface, not just app code.** The AppIntents framework
(iOS 16) is what lets Siri, Spotlight, the Shortcuts app, the Action button, and interactive widgets
*find* and *run* an app's actions. An intent that compiles is not the same as an intent the system can
surface: the `static title` is its display name, the `AppShortcut` `phrases` are the only thing Siri
matches a spoken request against, and a `@Parameter` `title` is the only label the user sees in the
editor. AI trained on cross-framework corpora ships intents that build but expose nothing — a provider
with no phrases is dead to Siri, a titleless parameter is a blank field. Be suspicious wherever an
`AppIntent` or `AppShortcutsProvider` is defined.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **Interactive `Button(intent:)` / `Toggle(isOn:_,intent:)` *placed in a widget*** belongs to
  `audit-swiftui-widgets-live-activities` (it owns widget interactivity placement); **the `AppIntent`
  definition itself** — its `title`, `perform()`, `@Parameter`s — is **this skill**. File the intent
  definition here, `cross_ref: widgets-live-activities` when the trigger is a widget control.
- **An intent that touches a protected resource** (Photos, Contacts, Location, microphone) needs the
  manifest / usage-string correctness owned by `audit-swiftui-privacy-permissions`. This skill owns the
  intent shape; note the protected-resource use in one line and `cross_ref: privacy-permissions`.
- **An `OpenIntent` / deep-link entry as a *scene-lifecycle* surface** (`onOpenURL`, scene restoration)
  leans on `audit-swiftui-app-lifecycle-background`; the `OpenIntent` *conformance* is this skill's.
  `cross_ref: app-lifecycle-background` when the smell is the open/restore lifecycle.
- **A `.contextMenu` action as a *touch interaction*** is `audit-swiftui-touch-gestures`; a context-menu
  action that should be a **Shortcuts/Siri-exposed `AppIntent`** is **this skill** (the reciprocal
  tiebreaker in cross-ref-graph.md §2). Flag the missing intent here, `cross_ref: touch-gestures`.
- **The blanket "is every OS-floored API gated" sweep** belongs to `audit-swiftui-availability-gating`;
  this skill owns its own floor (AppIntents iOS 16, below the iOS-17 deployment floor → no gate) and
  defers the rest there.

## The three App Intents rules (the judgment core)

1. **Every `AppIntent` declares a `static var title: LocalizedStringResource`.** It is a protocol
   requirement *and* the action's display name in Siri / Shortcuts / the Action button — a missing or
   placeholder title means the intent has no name the user can see or speak (ain-01).
2. **An `AppShortcutsProvider` is worthless without `phrases`.** `appShortcuts` must return
   `AppShortcut`s whose `phrases` array is non-empty — the phrases are the *only* thing Siri and
   Spotlight match a request against. No phrases (or an empty array) = the action is undiscoverable by
   voice and Spotlight, even though it builds (ain-02).
3. **Every `@Parameter` carries a `title:`, and `perform()` is `async` + actor-correct.** A titleless
   `@Parameter` renders as a blank field in the Shortcuts editor (ain-03); a `perform()` that touches UI
   must hop to the main actor (`@MainActor` on the intent or an explicit hop) — doing UI work on the
   intent's background executor is a runtime hazard (ain-04).

**The discovery test:** can Siri *find* this action (a non-empty `phrases`), can the user *see* it
(a `static title`, a `@Parameter` `title`), and does `perform()` run on the right actor? Full ❌→✅ +
the canonical Siri-exposed-intent exemplar: `references/app-intents-and-shortcuts.md`.

## Defect index (ain-01 … ain-05)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (protocol requirement absent /
never-correct), **warning** (compiles but invisible / undiscoverable), **advisory** (judgment / runtime
hazard). `auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| ain-01 | a type conforming to `AppIntent` with **no** `static var title: LocalizedStringResource` → unnamed / non-compiling intent | hard-fail | flag | `app-intents-and-shortcuts.md` |
| ain-02 | an `AppShortcutsProvider` whose `appShortcuts` has **empty or no** `phrases` → invisible to Siri / Spotlight | warning | flag | `app-intents-and-shortcuts.md` |
| ain-03 | a `@Parameter` with **no** `title:` → renders unlabeled in the Shortcuts editor | warning | flag | `app-intents-and-shortcuts.md` |
| ain-04 | `perform()` doing UI / view-model work with no `@MainActor` / main-actor hop → off-actor runtime hazard | advisory | flag | `app-intents-and-shortcuts.md` |
| ain-05 | a legacy SiriKit `INIntent` / `IntentConfiguration` / `CustomIntentMigratedAppIntent` left unmigrated → pre-AppIntents API | warning | flag | `legacy-and-migration.md` |

**ain-01 is the only hard-fail.** `static var title` is a non-optional `AppIntent` protocol requirement —
its absence is a compile error, so a titleless intent in source either does not build or hides the title
behind a stub; READ to tell which. ain-02/ain-03 are *absence inside a structure* — grep surfaces the
`AppShortcutsProvider` / `@Parameter` candidate, the agent confirms the missing `phrases` / `title` after
READ. ain-05 is a real deprecation flag (SiriKit `INIntent` predates AppIntents); cross-check the legacy
name against `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` — read, never restate):**
`AppIntent` (the `perform() async throws -> some IntentResult` protocol; **`static var title:
LocalizedStringResource` required**), `AppShortcutsProvider` (`static var appShortcuts: [AppShortcut]`),
`AppShortcut(intent:phrases:shortTitle:systemImageName:)`, `@Parameter(title:)`, `OpenIntent`,
`EntityQuery` / `EntityStringQuery`, `AppEntity`, `AppEnum`, `IntentResult` /
`.result(...)` / `ProvidesDialog` / `ShowsSnippetView` — **all AppIntents framework, iOS 16.0+**, which
is **below the iOS-17 deployment floor, so no `#available` gate is needed**. `LocalizedStringResource`
(Foundation, iOS 16.0+). Newer surfaces — `App Shortcuts` for the **Action button**, `AppIntent` Siri /
Apple Intelligence schemas (`AssistantIntent`, `AssistantSchemas`) — are **iOS 18.0+**: gate or
`source: verify against Xcode 26 SDK`.

**Not a SwiftUI symbol:** these live in the `AppIntents` framework (`import AppIntents`), not SwiftUI —
confirm a floor via `swiftui-ctx lookup <api> --platform ios` (it indexes AppIntents in `sdk_catalog`),
or via the **`app-intent` recipe** (`swiftui-ctx recipe app-intent`) for the canonical struct shape.
A `lookup` **exit 3** for a *capitalised* intent symbol (e.g. `OpenIntent`, `EntityQuery`) means it is
not in the *usage* corpus — it is still a **real Apple symbol** (in `floors-master.md` at iOS 16); do
**not** treat that exit 3 as a hallucination — confirm the floor in `floors-master.md` / Sosumi and the
shape via the recipe. If a code reaches for an intent symbol you genuinely cannot place, cross-check
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/app-intents-and-shortcuts.md`, `references/legacy-and-migration.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI + AppIntents sources (an `import AppIntents` is the marker;
   intents often live in an App Intents extension target). Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). Note the toolkit
   floor is **iOS 17** — the whole AppIntents core (`AppIntent`/`AppShortcutsProvider`/`@Parameter`/
   `AppShortcut`/`OpenIntent`/`EntityQuery`/`AppEntity`) is **iOS 16**, *below* the floor, so gates are
   rarely needed; only Action-button / Apple-Intelligence schema surfaces (iOS 18) need one. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-app-intents --dir <sources> --json /tmp/ain.json --sarif /tmp/ain.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, ain-01…ain-05), plus a per-file
   **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did
   not fully parse, so a structural miss can't masquerade as clean; READ those by hand. The runner only
   LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether an
   `AppIntent` conformer actually declares `static var title` (ain-01), whether an `AppShortcutsProvider`'s
   `appShortcuts` returns `AppShortcut`s with a **non-empty `phrases`** array (ain-02), whether each
   `@Parameter` carries a `title:` (ain-03), and whether `perform()` touches UI off the main actor
   (ain-04) are all *absence-inside-a-structure* and invisible to grep. Build a per-file inventory: each
   `AppIntent` type + its `title` + its `@Parameter`s + its `perform()` actor; each `AppShortcutsProvider`
   + every `AppShortcut`'s `phrases`.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. an `AppIntent` whose body declares no `static var title`, an `AppShortcut` with
   `phrases: []`, a `@Parameter` with no `title:` argument, a legacy `INIntent`). A `@Parameter` that is
   genuinely titled, a provider whose phrases are non-empty, or an intent already `@MainActor` is *not* a
   defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place,
   the canonical shape), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and `swiftui-ctx recipe
   app-intent` for the canonical `AppIntent` + `AppShortcutsProvider` shape): read its `consensus`,
   `recommended` permalink, `introduced_ios`, and `co_occurs_with`. **A `lookup` exit 3 on a capitalised
   intent symbol (`OpenIntent`/`EntityQuery`/`AppEntity`) is NOT a hallucination** — those are real Apple
   types absent from the *usage* corpus; confirm their floor in `floors-master.md` and shape via the
   recipe. (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor (AppIntents core = iOS 16). The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or
   discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Emit `cross_ref` on shared-seam findings (an intent triggered by a widget control →
   `widgets-live-activities`; an intent touching a protected resource → `privacy-permissions`; an
   `OpenIntent` lifecycle smell → `app-lifecycle-background`; a `.contextMenu` action that should be an
   intent → `touch-gestures`). Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a judgment call: the *text* of a
   `title`/`phrases`/`@Parameter title` and the right actor for `perform()` are author decisions, so all
   are `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check. The
   ✅ "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **recipe / consensus shape** put
   in `## Correct`, backed by a real iOS example fetched with `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus
   the Sosumi `doc:`) goes in `## Source`. The ain-02 ✅ is grounded in the live `swiftui-ctx lookup
   AppShortcut` recommended permalink (a non-empty `phrases` array — see
   `references/app-intents-and-shortcuts.md`). Leave `flag-only` findings `open` with that ✅ in
   `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches
   (an added `title`/`phrases`/`@Parameter title` clears the candidate); record the evidence in
   `## Fix applied?`. Re-confirm every citation still resolves and still says iOS 16. If a fix introduced a
   new tell (e.g. a `perform()` you moved to `@MainActor` now needs an actor-safe model call), loop that
   file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding. ain-01/02/03 hinge on a structure's *absence* (no `title`,
no `phrases`, no `@Parameter title`) — a grep hit is only a candidate; the missing member is confirmed
after READ. **No defect in this domain is auto-fixed**: the *text* of every fix (a title string, the Siri
phrases, a parameter label) and the right actor for `perform()` are author decisions, so all are
`fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/app-intents/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/app-intents/_index.md`.
- `domain: app-intents`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every defect.
  `availability` reads from `floors-master.md` (AppIntents core = iOS 16; Action-button / Apple
  Intelligence schemas = iOS 18). `source` is an Apple URL + access date (fetched via Sosumi) or
  `verify against Xcode 26 SDK`. Emit `cross_ref` per the seam note (step 6).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `intent-title/` | an `AppIntent` declares no `static var title` (ain-01) |
| `siri-phrases/` | an `AppShortcutsProvider`'s `appShortcuts` carry empty / no `phrases` and the action is undiscoverable (ain-02) |
| `parameter-title/` | a `@Parameter` has no `title:` and renders unlabeled in the Shortcuts editor (ain-03) |
| `perform-actor/` | a `perform()` touches UI work off the main actor (ain-04) |
| `legacy-migration/` | a legacy SiriKit `INIntent` / `IntentConfiguration` is left unmigrated to AppIntents (ain-05) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/app-intents/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/app-intents-and-shortcuts.md` | the required `static title`, the `AppShortcutsProvider` `phrases`, the `@Parameter title`, and `perform()` actor-correctness (ain-01/02/03/04) + the canonical Siri-exposed-intent exemplar |
| `references/legacy-and-migration.md` | the legacy SiriKit `INIntent` / `IntentConfiguration` → AppIntents migration (ain-05) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` | step LOCATE — this skill's declarative tier-1 grep tells (ain-01…ain-05) fed to the shared runner; edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — AppIntents core iOS 16; Action-button / Apple-Intelligence schemas iOS 18) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical deprecated/invented-name list (cross-check a made-up intent symbol; SiriKit `INIntent` is real-but-legacy, not invented) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (AppIntents is iOS 16 → below the iOS-17 floor → no gate; only iOS-18 schema surfaces need one) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`recipe app-intent`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (widget-placement, privacy, lifecycle, contextMenu tiebreaker) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-app-intents --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, ain-01…ain-05) surface `AppIntent` /
`AppShortcutsProvider` / `@Parameter` / `perform()` / legacy-`INIntent` **candidates** — the structural
defects (the *absence* of a `static title`, of non-empty `phrases`, of a `@Parameter title`) are confirmed
by the agent after READ (step 3), since grep cannot prove a member is missing. It runs a per-file **parse
probe** (surfaces "did not fully parse" so a structural miss can't look clean), emits unified **JSON +
SARIF**, exits **2** on any hard-fail (ain-01) for a CI gate, and **degrades to grep-only with a notice**
if ast-grep is unreachable. It only LOCATES — always READ each hit in full before reporting (step 3). The
thin `scripts/app-intents-lint.sh` is a pointer to this runner. Engine + rule-file format + JSON/SARIF
shape + safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
