---
name: audit-swiftui-widgets-live-activities
description: Audits an iOS WidgetKit + ActivityKit + Controls extension for timeline, Live Activity, and interactivity defects, writing findings to swiftui-audits/. Use when a widget goes stale or never refreshes, a Live Activity shows nothing on the Lock Screen or Dynamic Island, a tappable widget Button/Toggle does nothing, a widget uses the old IntentConfiguration, or a Control Center control will not build. Use when asked to verify TimelineProvider getTimeline reload policy (.atEnd/.after/.never), AppIntentConfiguration vs deprecated IntentConfiguration, ActivityConfiguration with its DynamicIsland, Button(intent:)/Toggle(isOn:intent:) interactivity (iOS 17), or ControlWidget (iOS 18). Use when AI wrote a getTimeline returning a Timeline with policy .never or no policy, an ActivityConfiguration with no dynamicIsland, or IntentConfiguration where AppIntentConfiguration fits. AUDIT-ONLY, iOS-only, SwiftUI-only. Not the AppIntent behind a widget (app-intents) or a data source's privacy manifest (privacy-permissions).
---

# Audit SwiftUI Widgets & Live Activities

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS WidgetKit /
ActivityKit / Controls extension to detect — and where certain, flag — every way a widget, Live Activity,
or Control Center control silently breaks: a `TimelineProvider.getTimeline` that returns a `Timeline` with
**no reload policy** (or a wrong `.never`) so the widget goes stale forever, an `ActivityConfiguration` with
**no `DynamicIsland`** so the Live Activity has nothing to render in the island, a **deprecated
`IntentConfiguration`** where `AppIntentConfiguration` is now the idiom, and an interactive
`Button(intent:)` / `Toggle(isOn:intent:)` whose `AppIntent` is missing. Findings are written to disk in the
toolkit's unified schema. This is never a from-scratch widget generator.

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **The `AppIntent` definition is not mine.** This skill owns the **placement** of interactive widget
  controls (`Button(intent:)` / `Toggle(isOn:intent:)` inside a widget body, wla-04) and the widget's
  **configuration intent**. The `AppIntent` type itself — its `title`, `@Parameter`, `perform()` — belongs
  to `audit-swiftui-app-intents`. Note the missing/empty intent in one line and `cross_ref: app-intents`.
- **The privacy manifest is not mine.** When a widget data source touches a protected resource (location,
  contacts) it needs a usage string / `PrivacyInfo.xcprivacy`. That **manifest correctness** is
  `audit-swiftui-privacy-permissions`; this skill owns only the **placement** inside the widget. `cross_ref`
  it, don't claim it.
- **Floor gating in depth.** A symbol above the iOS-17 floor (`AppIntentConfiguration` 17.0,
  `ControlWidget*` 18.0) needs an `#available`/`@available` gate. This skill owns that gating for its own
  symbols; `audit-swiftui-availability-gating` is the blanket net — `cross_ref` it only if the gate is the
  whole finding.
- **Tint / accessory background crossover** (`AccessoryWidgetBackground`, a widget's tint) belongs to
  `audit-swiftui-appearance-color`.

## The four widget rules (the judgment core)

1. **Every timeline declares when to reload.** `getTimeline(...)` MUST return `Timeline(entries:policy:)`
   with a deliberate `.atEnd` / `.after(date)` / `.never`. A `.never` on a clock/countdown widget is a
   silent staleness bug; the right default for time-driven content is `.atEnd` or `.after` (wla-01).
2. **A Live Activity must render its Dynamic Island.** `ActivityConfiguration(for:)` MUST attach a
   `DynamicIsland { ... }` presentation alongside the Lock Screen view — otherwise the activity is blank in
   the island on every device with one (wla-02).
3. **Use the current configuration type.** `AppIntentConfiguration` (iOS 17) replaces the older
   `IntentConfiguration` (SiriKit-intent backed). A new widget reaching for `IntentConfiguration` is
   carrying a legacy intent surface forward (wla-03).
4. **Interactive widget controls need a real `AppIntent`.** `Button(intent:)` / `Toggle(isOn:intent:)`
   (iOS 17) are the *only* way a widget reacts to a tap; the wired `AppIntent` is owned by `app-intents` —
   placement here, definition there (wla-04).

Full ❌→✅ + the canonical exemplars: `references/widgets-timelines.md` and
`references/live-activities-controls.md`.

## Defect index (wla-01 … wla-06)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (never-correct / will not build),
**warning** (compiles but silently broken), **advisory** (judgment / currency). `auto` = mechanical
single-answer fix; `flag` = show the ✅, dev applies. No defect in this domain is auto-fixed — every fix is a
structural/judgment call, so all are `flag-only`.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| wla-01 | `getTimeline(...)` returning `Timeline(entries:policy:)` with `.never` on time-driven content (or no policy in the chain) → widget goes stale, never refreshes | warning | flag | `widgets-timelines.md` |
| wla-02 | `ActivityConfiguration(for:) { … }` with **no `DynamicIsland { … }`** → Live Activity is blank in the Dynamic Island | warning | flag | `live-activities-controls.md` |
| wla-03 | `IntentConfiguration(kind:intent:provider:)` in a new widget where `AppIntentConfiguration` (iOS 17) fits → legacy SiriKit-intent surface | advisory | flag | `widgets-timelines.md` |
| wla-04 | `Button(intent:)` / `Toggle(isOn:_,intent:)` in a widget body whose `AppIntent` is missing/empty → tap does nothing | warning | flag | `live-activities-controls.md` |
| wla-05 | `StaticConfiguration` / `AppIntentConfiguration` `.supportedFamilies(...)` listing a family the body cannot render (e.g. `.accessoryRectangular` with a non-accessory view) → blank widget on that family | advisory | flag | `widgets-timelines.md` |
| wla-06 | `ControlWidgetButton` / `ControlWidgetToggle` (iOS 18) used with no `#available(iOS 18, *)` gate under an iOS-17 target → won't build below 18 | warning | flag | `live-activities-controls.md` |

**wla-04 and wla-06 cross-ref siblings.** `Button(intent:)` placement is this skill; the `AppIntent` body is
`app-intents` (wla-04 `cross_ref: app-intents`). `ControlWidgetButton`/`ControlWidgetToggle` are **iOS 18.0**
(confirmed via swiftui-ctx, see VERIFY) — under-gated, **not** platform-wrong; gate it, `cross_ref:
availability-gating` only if the gate is the entire finding.

## The real API, at a glance

**Real (exist on iOS; floors read from `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — never
restate, confirm via swiftui-ctx):** `StaticConfiguration` (iOS 14.0), `IntentConfiguration` (iOS 14.0,
legacy), `AppIntentConfiguration` (**iOS 17.0**), `Timeline` (iOS 14.0), `WidgetConfiguration`,
`ActivityConfiguration` (**iOS 16.1**), `DynamicIsland` (**iOS 16.1**), `Button(intent:)` /
`Toggle(isOn:intent:)` (iOS 17.0), `ControlWidgetButton` / `ControlWidgetToggle` (**iOS 18.0**).

**Conformance / pattern symbols (no single floor — see the recipe):** `Widget`, `ControlWidget`,
`WidgetBundle` are protocols/builders. `TimelineProvider` / `AppIntentTimelineProvider` and
`ActivityAttributes` are **not in `sdk_catalog`** (swiftui-ctx `lookup` **exit 3**) — they ship in
**WidgetKit / ActivityKit**, which the catalog does not floor; carry them as
`verify against Xcode 26 SDK`, never fabricate a number. `TimelineProvider` is WidgetKit's provider
protocol (iOS 14.0, well-known); `ActivityAttributes` is ActivityKit (iOS 16.1, well-known) — both marked
`verify against Xcode 26 SDK` in findings.

If audited code reaches for a widget symbol you can't place, confirm via swiftui-ctx (`lookup` **exit 3** =
not-in-corpus: either a WidgetKit/ActivityKit symbol the SwiftUI catalog doesn't floor, or a hallucination —
disambiguate via Sosumi) + cross-check `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.
Signatures + full ❌→✅: `references/widgets-timelines.md`, `references/live-activities-controls.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the widget-extension sources (the `*Widget.swift`, `*LiveActivity.swift`,
   `*Control.swift`, the `@main WidgetBundle`). Read the **deployment target** (`project.pbxproj`
   `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — it sets which floor a fix may rely on
   (`AppIntentConfiguration` / `Button(intent:)` = iOS 17.0, `ActivityConfiguration` / `DynamicIsland` =
   iOS 16.1, `ControlWidget*` = iOS 18.0). A fix that uses a floor above the target needs an
   `#available(iOS NN, *)` / `@available(iOS NN, *)` gate per
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-widgets-live-activities --dir <sources> --json /tmp/wla.json --sarif /tmp/wla.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, wla-01…wla-06), plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a structural miss can't masquerade as clean; READ those by hand. The runner only LOCATES —
   never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. Whether a
   `getTimeline`'s returned `Timeline` carries a *deliberate* policy (a static info widget legitimately uses
   `.never`; a clock/countdown does not), whether an `ActivityConfiguration` closure actually contains a
   `DynamicIsland`, whether a `Button(intent:)` names a real `AppIntent`, and which `supportedFamilies` the
   body can render are all invisible to grep. Build a per-file inventory: each provider + its return policy;
   each `ActivityConfiguration` + its island; each configuration type; each interactive control + its intent.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a countdown `getTimeline` returning `.never`, an `ActivityConfiguration` with no
   `DynamicIsland` in its closure, an `IntentConfiguration` in a freshly written widget). A genuinely static
   widget using `.never`, or a Lock-Screen-only activity that *does* attach an island, is *not* a defect —
   judge it.
5. **VERIFY.** For anything ≤ ~70% confidence (a floor you're unsure of, whether a configuration type is
   current, whether a symbol exists on iOS), run **both** evidence sources. (a) **Practice** — `B=/Users/serkan/swiftui-ios/swiftui-scan/.build/release/swiftui-ctx; export SWIFTUI_CTX_CATALOG=/Users/serkan/swiftui-ios/catalog; "$B" lookup <api> --platform ios --json`:
   read its `introduced_ios` (at `result.introduced_ios`), `consensus` (the canonical shape),
   `deprecated`+`replacement`, and the `diverse[].permalink` real example. A `lookup` **exit 3** means the
   symbol is **not in the SwiftUI catalog** — for WidgetKit/ActivityKit types (`TimelineProvider`,
   `AppIntentTimelineProvider`, `ActivityAttributes`) that is expected (the catalog floors SwiftUI +
   WidgetKit-config symbols, not the whole framework), so carry the well-known floor as
   `verify against Xcode 26 SDK`; for an unknown name it corroborates a hallucination. (b) **Spec** —
   confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md`
   for the path and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never
   `WebFetch` `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md`; the reconciled
   floor wins. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
   Promote with the citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   **every fix is `flag-only`** in this domain (which reload policy a widget wants, whether an island is
   needed, whether a configuration migration is safe are all judgment calls), one conventional commit per
   finding citing its `rule_id`, never weaken a check. The ✅ "Correct" is **not a hand-written snippet** —
   it is the swiftui-ctx **consensus shape** put in `## Correct`, backed by a real iOS example fetched with
   `"$B" file <diverse.id> --smart` whose GitHub permalink (plus the Sosumi `doc:`) goes in `## Source`. The
   wla-02 ✅ is grounded in the live `ActivityConfiguration` / `DynamicIsland` consensus + their
   `firefox-ios` permalinks (see `references/live-activities-controls.md`). Leave `flag-only` findings `open`
   with that ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep / re-run the lint over each fixed file to confirm the tell no longer matches;
   record the evidence in `## Fix applied?`. Re-confirm every citation still resolves. If a fix introduced a
   new tell (e.g. an `AppIntentConfiguration` you migrated to now needs an `#available(iOS 17, *)` gate under
   a lower target), loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become a
finding — never emit a speculative finding. **No defect in this domain is auto-fixed**: every correct fix is
a structural/judgment call (which reload policy this widget needs, whether the Live Activity truly needs an
island, whether migrating `IntentConfiguration` is safe without losing the intent), so all are
`fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/widgets-live-activities/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/widgets-live-activities/_index.md`.
- `domain: widgets-live-activities`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every
  defect. `availability` reads from `floors-master.md` for catalogued symbols, or carries
  `verify against Xcode 26 SDK` for the WidgetKit/ActivityKit framework types not in `sdk_catalog`
  (`TimelineProvider`, `AppIntentTimelineProvider`, `ActivityAttributes`). `source` is an Apple URL + access
  date (fetched via Sosumi) or `verify against Xcode 26 SDK`. Emit `cross_ref` on wla-04 (→ `app-intents`,
  the interactive intent definition), wla-06 (→ `availability-gating` when the gate is the whole finding),
  and any widget-data-source privacy note (→ `privacy-permissions`) or tint/accessory note (→
  `appearance-color`).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `timeline-policy/` | a `getTimeline` returns a `Timeline` with a wrong `.never` / no reload policy and goes stale (wla-01) |
| `live-activity/` | an `ActivityConfiguration` has no `DynamicIsland`, or a Live Activity presentation is incomplete (wla-02) |
| `widget-config/` | a widget uses deprecated `IntentConfiguration` where `AppIntentConfiguration` fits, or a `supportedFamilies` mismatch (wla-03, wla-05) |
| `interactivity/` | a `Button(intent:)` / `Toggle(isOn:intent:)` widget control's `AppIntent` is missing/empty (wla-04) — `cross_ref` app-intents |
| `control-widget/` | a `ControlWidgetButton` / `ControlWidgetToggle` (iOS 18) is used with no `#available(iOS 18, *)` gate under an iOS-17 target (wla-06) — `cross_ref` availability-gating |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/widgets-live-activities/` with a lowercase-hyphen slug naming the sub-category, and note it
in the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a
hard requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/widgets-timelines.md` | the `TimelineProvider` reload-policy bug, the `IntentConfiguration`→`AppIntentConfiguration` currency call, and the `supportedFamilies`/body mismatch (wla-01/03/05) |
| `references/live-activities-controls.md` | the `ActivityConfiguration`-without-`DynamicIsland`, interactive `Button(intent:)`/`Toggle(isOn:intent:)` placement, and the iOS-18 `ControlWidget*` gating (wla-02/04/06) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` | step LOCATE — this skill's tier-1 grep tell set fed to the shared runner (wla-01…wla-06); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `AppIntentConfiguration` 17.0, `ActivityConfiguration`/`DynamicIsland` 16.1, `ControlWidgetButton`/`ControlWidgetToggle` 18.0, `IntentConfiguration`/`StaticConfiguration`/`Timeline` 14.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a made-up widget/activity symbol) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (iOS-17 floor; `AppIntentConfiguration`/`Button(intent:)` 17 need no gate; `ControlWidget*` 18 does; the wrong-arm trap) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + context-folder ownership |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (interactive intent → app-intents, widget data privacy → privacy-permissions, gating net → availability-gating, tint → appearance-color) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-widgets-live-activities --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative **tier-1 grep tells** (`lint/grep-tells.tsv`, wla-01…wla-06). It runs a per-file **parse probe**
(surfaces "did not fully parse" so a structural miss can't look clean), emits unified **JSON + SARIF**, and
**degrades to grep-only with a notice** if ast-grep is unreachable. The structural absences (a
`getTimeline` whose returned `Timeline` carries no deliberate policy, an `ActivityConfiguration` closure with
no `DynamicIsland`) are not flat-grep-expressible and are caught at step 3 READ, not by a tell — the grep
tells LOCATE the provider / configuration / interactive control; you READ each in full before reporting
(step 3). The thin `scripts/widgets-live-activities-lint.sh` is a pointer to this runner. Engine + rule-file
format + JSON/SARIF shape + safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
