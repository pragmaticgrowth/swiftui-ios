---
name: audit-swiftui-app-lifecycle-background
description: Audits an iOS SwiftUI app for scene-lifecycle and background-execution defects that lose user state on suspension or never run scheduled work, writing per-finding Markdown to swiftui-audits/. Use when state vanishes after backgrounding, edits are not saved before suspension, a background refresh never fires, a deep link or Handoff activity is dropped, or restoration is broken; when verifying scenePhase saving on .background, backgroundTask, BGTaskScheduler register/submit, SceneStorage, onOpenURL, onContinueUserActivity, or UIApplicationDelegateAdaptor; when AI wrote a scene with mutable state and no scenePhase save, a BGTaskScheduler submit with no matching register, a SceneStorage holding large non-UI model data, or an AppDelegate doing work scenePhase covers. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for the save itself (swiftdata), the load a scene event triggers (async-data), the AppIntent behind a deep link (app-intents), manifest correctness (privacy-permissions), or new lifecycle UI.
---

# Audit SwiftUI App Lifecycle & Background

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI project to
detect — and where certain, fix — every way the SwiftUI scene lifecycle and background-execution model is
left unwired: a scene with mutable in-flight state and no `onChange(of: scenePhase)` save on `.background`, a
`BGTaskScheduler.submit` with **no matching `register(forTaskWithIdentifier:)`** at launch, a background-task
request whose identifier is never declared in `Info.plist` `BGTaskSchedulerPermittedIdentifiers`, a
`@SceneStorage` holding large or non-UI model data, and an `@UIApplicationDelegateAdaptor` doing lifecycle
work `scenePhase` / `.backgroundTask` already covers. This domain absorbs the old macOS scenes-windows and
state-restoration concerns into the iOS scene-phase model. Findings are written to disk in the toolkit's
unified schema; this is never a from-scratch lifecycle generator.

**The corpus is a single foreground session, not a real device lifecycle.** The training corpus is
overwhelmingly one-shot SwiftUI views that launch, render, and never get suspended — so AI never learns that
iOS *will* background and terminate the app, that unsaved state is lost at suspension unless `scenePhase`
drives a save, that a background task must be **registered before** it can be submitted (and declared in the
plist), or that `@SceneStorage` is for small per-scene UI restoration, not the data model. The result
compiles and looks correct in the preview but silently drops edits on every background, never runs its
"refresh in the background" code, and fails state restoration. Be suspicious wherever AI built an `App`/scene
shell, scheduled background work, or persisted across launches.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **The lifecycle TRIGGER is mine; the SAVE is not.** That a scene drops to `.background` with **no save
  wired** (alb-01) is **this skill** — the `scenePhase` → save trigger. The **save shape itself** (a
  SwiftData `modelContext.save()`, an `@ModelActor` write) is `audit-swiftui-swiftdata`. File the missing
  trigger here, `cross_ref: swiftdata`; do not audit how the save is performed.
- **The scene EVENT is mine; the LOAD it kicks off is not.** That `onOpenURL` / `onContinueUserActivity`
  is the scene-lifecycle entry point (alb-06) is **this skill**. The **data load** that the URL/activity
  triggers (an async fetch, a `.task`) is `audit-swiftui-async-data`. File the lifecycle wiring here,
  `cross_ref: async-data`.
- **A deep link's INTENT is not mine.** When an `onOpenURL` / URL surface should be an `OpenIntent` /
  Shortcuts-exposed `AppIntent`, the intent definition is `audit-swiftui-app-intents`; note it in one line and
  `cross_ref: app-intents`.
- **The plist MANIFEST is split.** That a `BGTaskScheduler` identifier must be declared in
  `Info.plist` `BGTaskSchedulerPermittedIdentifiers` and that `UIBackgroundModes` must list the mode (alb-03)
  is **this skill's** wiring concern; the broader privacy/usage-string manifest correctness is
  `audit-swiftui-privacy-permissions` — `cross_ref` it when the gap is manifest hygiene.
- **`@SceneStorage` vs `@State`/`@AppStorage` placement** (alb-04): this skill owns it as a *restoration*
  concern; the general "where does this state live" question is `audit-swiftui-state-observation` —
  `cross_ref` it. `NavigationPath` restoration via `@SceneStorage` also touches `adaptive-navigation`.

## The app-lifecycle-background judgment rules (the judgment core)

1. **A scene with mutable state saves on `.background`.** A view/scene that holds unsaved in-flight edits
   must read `@Environment(\.scenePhase)` and `onChange(of: scenePhase)` to persist when the phase becomes
   `.background` — iOS suspends and may terminate without warning, and nothing else fires that save (alb-01).
   A read-only scene, or one whose every mutation is already persisted synchronously, is not a defect — judge it.
2. **A background task must be registered before it is submitted.** `BGTaskScheduler.shared.submit(request)`
   only works if a matching `register(forTaskWithIdentifier:using:launchHandler:)` ran at launch (in the
   `App` init / `@UIApplicationDelegateAdaptor`) — a `submit` with no `register` throws and the task never
   runs (alb-02).
3. **A background-task identifier must be declared in the plist.** Every `BGAppRefreshTaskRequest` /
   `BGProcessingTaskRequest` identifier must appear in `Info.plist`
   `BGTaskSchedulerPermittedIdentifiers`, and the matching mode in `UIBackgroundModes`; an undeclared
   identifier is rejected at register time (alb-03).
4. **`@SceneStorage` is for small per-scene UI restoration, not the data model.** `@SceneStorage` round-trips
   tiny UI state (a selected tab, a search string, a `NavigationPath`) per scene; stuffing large or non-UI
   model data into it is wrong — that belongs in the model layer (alb-04). The SwiftUI `.backgroundTask`
   scene modifier (`.appRefresh` / `.urlSession`) still needs the same registration + plist wiring (alb-05).
5. **Use the scene event for entry, and don't over-reach for an AppDelegate.** `onOpenURL` /
   `onContinueUserActivity` are the SwiftUI scene-lifecycle entry points (alb-06); an
   `@UIApplicationDelegateAdaptor` doing lifecycle/background work that `scenePhase` / `.backgroundTask` /
   `onOpenURL` already express is overuse — keep the AppDelegate for the few things SwiftUI genuinely lacks
   (alb-07).

Full ❌→✅ + the canonical lifecycle exemplars: `references/lifecycle-and-background.md`.

## Defect index (alb-01 … alb-07)

`id · tell · severity · fix · open reference`. Severities: **hard** (throws / never runs), **warning**
(compiles but loses state or work), **advisory** (judgment / placement). `auto` = mechanical single-answer
fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| alb-01 | a scene reads `@Environment(\.scenePhase)` but has no `onChange(of: scenePhase)` save on `.background` → unsaved state lost on suspension | warning | flag | `lifecycle-and-background.md` |
| alb-02 | `BGTaskScheduler...submit(` with no matching `register(forTaskWithIdentifier:)` at launch → throws, task never runs | warning | flag | `lifecycle-and-background.md` |
| alb-03 | `BGAppRefreshTaskRequest` / `BGProcessingTaskRequest` whose identifier is not declared in `Info.plist` `BGTaskSchedulerPermittedIdentifiers` (+ `UIBackgroundModes`) → register rejected | warning | flag | `lifecycle-and-background.md` |
| alb-04 | `@SceneStorage` holding large or non-UI model data → wrong store; per-scene UI restoration only | advisory | flag | `lifecycle-and-background.md` |
| alb-05 | `.backgroundTask(.appRefresh` / `.urlSession` scene modifier with no identifier registration / plist declaration in scope → never scheduled | advisory | flag | `lifecycle-and-background.md` |
| alb-06 | `onOpenURL` / `onContinueUserActivity` scene-event entry — confirm the lifecycle is wired (route the load to async-data, the intent to app-intents) | advisory | flag | `lifecycle-and-background.md` |
| alb-07 | `@UIApplicationDelegateAdaptor` doing lifecycle/background work `scenePhase` / `.backgroundTask` / `onOpenURL` already cover → AppDelegate overuse | advisory | flag | `lifecycle-and-background.md` |

**No hard-fail in this domain; every defect is a state-loss or wiring gap, so all are flag-only.** alb-01
cross-refs swiftdata (the save shape), alb-06 cross-refs async-data (the load) + app-intents (the intent),
alb-03 cross-refs privacy-permissions (manifest), alb-04 cross-refs state-observation (where state lives).

## The real API, at a glance

**Real (exist on iOS; floors are the reconciled truth in `floors-master.md` / `swiftui-ctx lookup
--platform ios` — read, never restate):** `@Environment(\.scenePhase)` (`ScenePhase`, `.active`/`.inactive`/
`.background`, **iOS 14.0**), `onChange(of:_:)` (**iOS 14.0**; the 1-parameter closure form is deprecated
iOS 17 → `audit-swiftui-api-currency`), `@SceneStorage` (`SceneStorage`, **iOS 14.0**), `@AppStorage`
(`AppStorage`, **iOS 14.0**), `onOpenURL(perform:)` (**iOS 14.0**), `onContinueUserActivity(_:perform:)`
(**iOS 14.0**), `@UIApplicationDelegateAdaptor` (**iOS 14.0**), the `.backgroundTask(_:action:)` scene
modifier with `.appRefresh` / `.urlSession` (`BackgroundTask`, **iOS 16.0**). The project floor is **iOS
17**, so all of these are available without a gate.

**Verify-SDK (not in the SwiftUI catalog — UIKit `BackgroundTasks` framework):** `BGTaskScheduler`
(`.shared`, `register(forTaskWithIdentifier:using:launchHandler:)`, `submit(_:)`), `BGAppRefreshTaskRequest`,
`BGProcessingTaskRequest`, `BGTask` — introduced **iOS 13.0** (well-known), but **not confirmable via
swiftui-ctx** (covers SwiftUI/WidgetKit/ActivityKit/AppIntents only). Cite the well-known introduction and
mark `availability: verify against Xcode 26 SDK`; never fabricate a floor. Same for the `Info.plist` keys
`BGTaskSchedulerPermittedIdentifiers` and `UIBackgroundModes`.

No invented names are central to this domain; if audited code reaches for a lifecycle symbol you can't
place, confirm via swiftui-ctx (`lookup --platform ios` **exit 3** = likely hallucination or no-iOS-arm
symbol) + Sosumi before flagging, and cross-check the canonical invented-name list in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. Signatures + full ❌→✅:
`references/lifecycle-and-background.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources **and** locate the `Info.plist` (or the
   `INFOPLIST_KEY_*` build settings / generated plist). Read the **deployment target** (`project.pbxproj`
   `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). The project floor is **iOS 17**, so
   `scenePhase` / `@SceneStorage` / `onOpenURL` (iOS 14.0) and `.backgroundTask` (iOS 16.0) are all available
   without a gate — confirm against `floors-master.md`. Note whether `BGTaskSchedulerPermittedIdentifiers`
   and `UIBackgroundModes` exist in the plist; you will cross-check them in DETECT. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-app-lifecycle-background --dir <sources> --json /tmp/alb.json --sarif /tmp/alb.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, alb-01…alb-07) plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a structural miss can't masquerade as clean; READ those by hand. The runner only LOCATES —
   never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a
   `scenePhase` read actually drives a save on `.background`, whether a `BGTaskScheduler.submit` has a
   matching `register` anywhere in the launch path, whether a request's identifier appears in the plist,
   whether a `@SceneStorage` holds tiny UI state or a model object, and whether an
   `@UIApplicationDelegateAdaptor` is doing something SwiftUI already covers are all invisible to grep. Build
   a per-file inventory: each `scenePhase` read + its `onChange`; each `BGTaskScheduler` `submit`/`register`
   pair; each `BG*TaskRequest` identifier (and check the plist); each `@SceneStorage` + what it stores; each
   `onOpenURL`/`onContinueUserActivity`; the AppDelegate adaptor's body.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a scene with `scenePhase` and mutable `@State` but no `.background` save, a `submit`
   with no `register`, a `BGAppRefreshTaskRequest` identifier absent from the plist). A read-only scene, a
   `@SceneStorage` holding a single `Int` tab index, or an AppDelegate doing genuinely-SwiftUI-less work
   (push registration, third-party SDK init) is *not* a defect — judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a floor you're unsure of, the canonical lifecycle shape,
   whether a symbol exists on iOS), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read its `consensus`
   (canonical shape — e.g. `backgroundTask` `(withName)`, `scenePhase` via `@Environment`), `recommended`
   permalink, `introduced_ios` (surfaces at `result.introduced_ios`, **not** under `result.availability`),
   and `co_occurs_with`; a `lookup` **exit 3** corroborates a no-iOS-arm or hallucinated symbol. **For
   `BGTaskScheduler` / `BG*TaskRequest`, swiftui-ctx returns exit 3 — that is expected** (UIKit, not in the
   SwiftUI catalog); fall back to Sosumi and mark `availability: verify against Xcode 26 SDK`, do not invent
   a floor. (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor — the reconciled floor wins. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **only `fix_mode: auto`** (none in this domain are auto — every fix is a judgment/structural call: what
   to save, where to register, what the plist identifier is, whether a `@SceneStorage` belongs in the model
   — so all are `flag-only`), one conventional commit per finding citing its `rule_id`, never weaken a check.
   The ✅ "Correct" is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in
   `## Correct`, backed by a real iOS example fetched with `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx
   file <recommended.id> --smart` whose GitHub permalink (plus the Sosumi `doc:`) goes in `## Source`. The
   alb-01 ✅ is grounded in the live `swiftui-ctx lookup scenePhase --platform ios` consensus
   (`onChange(of: scenePhase)` saving on `.background`) + its recommended iOS permalink (see
   `references/lifecycle-and-background.md`). Leave `flag-only` findings `open` with that ✅ in `## Correct`.
   If a gate above the project floor is ever needed, route via
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. you added a `register` call that now needs its identifier in the plist — alb-03, or moved
   model data out of `@SceneStorage` and now need a SwiftData save trigger — alb-01), loop that file back to
   DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is
a structural/judgment call (what state to persist, where the `register` belongs, which identifier the plist
needs, whether a scene is genuinely read-only), so all are `fix_mode: flag-only`. For `BGTaskScheduler` /
`BG*TaskRequest` the floor is **not confirmable via swiftui-ctx** — mark `availability: verify against Xcode
26 SDK` and never assert a fabricated floor.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/app-lifecycle-background/<context>/NN-slug.md` (one finding per file,
  zero-padded, ordered). Per-run index: `swiftui-audits/app-lifecycle-background/_index.md`.
- `domain: app-lifecycle-background`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for
  every defect. `availability` reads from `floors-master.md` (the iOS floor — `scenePhase`/`SceneStorage`/
  `onOpenURL`/`onContinueUserActivity`/`UIApplicationDelegateAdaptor` iOS 14.0, `.backgroundTask`/
  `BackgroundTask` iOS 16.0) **or** `verify against Xcode 26 SDK` for the UIKit `BGTaskScheduler` /
  `BG*TaskRequest` family. `source` is an Apple URL + access date (fetched via Sosumi) or `verify against
  Xcode 26 SDK`. Body includes **`## Why it's wrong on iOS`**. Emit `cross_ref` on alb-01 (→ `swiftdata`, the
  save shape), alb-06 (→ `async-data` for the load, `app-intents` for the intent), alb-03 (→
  `privacy-permissions`, the manifest), and alb-04 (→ `state-observation`, where state lives; →
  `adaptive-navigation` for `NavigationPath` restoration).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `scenephase-save/` | a scene with mutable state has no `onChange(of: scenePhase)` save on `.background` (alb-01) — `cross_ref` swiftdata |
| `bgtask-registration/` | a `BGTaskScheduler.submit` has no matching `register(forTaskWithIdentifier:)` at launch (alb-02) |
| `bgtask-plist/` | a `BG*TaskRequest` identifier is not declared in `BGTaskSchedulerPermittedIdentifiers` / `UIBackgroundModes` (alb-03) — `cross_ref` privacy-permissions |
| `scenestorage-misuse/` | `@SceneStorage` holds large or non-UI model data (alb-04) — `cross_ref` state-observation |
| `backgroundtask-modifier/` | a `.backgroundTask(.appRefresh`/`.urlSession)` scene modifier with no registration/plist wiring (alb-05) |
| `scene-events/` | an `onOpenURL` / `onContinueUserActivity` lifecycle entry needs the load/intent routed (alb-06) — `cross_ref` async-data / app-intents |
| `appdelegate-overuse/` | an `@UIApplicationDelegateAdaptor` does work `scenePhase` / `.backgroundTask` / `onOpenURL` already cover (alb-07) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/app-lifecycle-background/` with a lowercase-hyphen slug naming the sub-category, and note it
in the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a
hard requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/lifecycle-and-background.md` | the scenePhase-save, BGTaskScheduler register-and-submit, plist identifier, `@SceneStorage` misuse, `.backgroundTask` modifier, scene-event, and AppDelegate-overuse defects (alb-01…alb-07) + the canonical lifecycle exemplars |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi (iOS pages) |
| `lint/grep-tells.tsv` | step LOCATE — this skill's declarative tier-1 grep rule set fed to the shared runner (alb-01…alb-07); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled iOS truth — `scenePhase`/`SceneStorage`/`onOpenURL`/`onContinueUserActivity`/`UIApplicationDelegateAdaptor` iOS 14.0, `.backgroundTask`/`BackgroundTask` iOS 16.0; `BGTaskScheduler` is UIKit, not in the catalog → verify-SDK) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (project floor iOS 17; gate only symbols above it) — nothing in this domain floors above 17, so no gate is normally needed |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up lifecycle symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup --platform ios`/`recipe` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (save → swiftdata, load → async-data, intent → app-intents, manifest → privacy-permissions, state placement → state-observation) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-app-lifecycle-background --dir
<files-or-dir> [--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed
this skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, alb-01…alb-07) covering the
`@Environment(\.scenePhase)` read, the `BGTaskScheduler` submit/register pair, the `BG*TaskRequest`
identifier, the `@SceneStorage` store, the `.backgroundTask` scene modifier, the `onOpenURL`/
`onContinueUserActivity` entry, and the `@UIApplicationDelegateAdaptor`. The grep tier **stands alone**
(ast-grep is not required and not installed); structural-absence calls (a `scenePhase` read with *no*
`.background` save — alb-01, a `submit` with *no* `register` — alb-02, an identifier *missing* from the
plist — alb-03) are LOCATED broadly by grep and resolved by the agent in READ against the plist. It runs a
per-file **parse probe** (surfaces "did not fully parse" so a structural miss can't look clean) and emits
unified **JSON + SARIF**. It only LOCATES — always READ each hit in full before reporting (step 3). The thin
`scripts/app-lifecycle-background-lint.sh` is a pointer to this runner. Engine + rule-file format +
JSON/SARIF shape + safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
