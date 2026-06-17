---
name: audit-swiftui-ios-idiomaticness
description: Scores a finished iOS SwiftUI codebase 0-100 for how idiomatic it reads on iOS/iPadOS (a desktop habit shoehorned onto a phone) and writes a routed punch-list to swiftui-audits/. Use when the user says the app feels non-idiomatic, feels desktop-y, feels like a stretched iPad layout, doesn't feel like a real iPhone app, or asks "how iOS-native is this", "rate the iOS-idiom score", or "do an idiomaticness pass". Detects a deprecated NavigationView shell, .onHover/pointerStyle as the only interaction on a touch surface, hard-coded full-screen device frames, a .fullScreenCover where a sheet+presentationDetents fits, TabView misfit / too many tabs, a Table with no compact List fallback, navigationBarTitle, and UIScreen.main / UIApplication.shared global reach. AUDIT-ONLY, iOS-only, SwiftUI-only. This is a META-AUDIT: it SCORES and ROUTES each idiom smell to the owner skill, it does NOT contain the fixes. Not for macOS/Catalyst, not for HIG snapshot review, not for writing UI from scratch.
---

# Audit SwiftUI iOS Idiomaticness

**AUDIT-ONLY · iOS-only · SwiftUI-only · META-AUDIT (score + route, never fix).** Run this on a
*finished or in-progress* iOS SwiftUI project to answer one question: **"how idiomatic does this read on
iOS/iPadOS — or does a Mac/desktop habit show through?"** It emits a **0-100 idiom score** and a
**prioritized punch-list** where every smell is **routed to the owner skill that fixes it** — this skill
itself never writes a code fix. Findings are written to disk in the toolkit's unified schema with
`fix_mode: flag-only`; the run index is a `kind: nativeness-dashboard` (the iOS idiom dashboard).

iOS/iPadOS is **touch-first, adaptive, and multi-scene**: a finger (no cursor, no hover hardware on
iPhone), a screen whose size and class change across iPhone↔iPad↔Split View, resizable sheets with
detents, a `NavigationStack`/`NavigationSplitView` model, and a tab bar for top-level peers. A model
trained on pre-iOS-16 corpora or on Mac code emits views that compile and look plausible but carry
desktop/iPad-pointer habits and stale containers. That gap is what this skill measures.

## Boundary / seam note (stay in lane)

This is a **router, not a repairer.** Every finding here carries a `cross_ref` to the **owner skill**;
the owner skill holds the ❌→✅ fix, the floor, and the auto-fix. Do **not** restate or apply those fixes.
Seam ownership + the exact `cross_ref` targets are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` (the idiomaticness / nativeness row — the
iOS analogue of the `macos-nativeness` router row) — read it, never restate it.

- **Navigation shell / `NavigationView` / `navigationBarTitle` / `TabView` fit** →
  **`audit-swiftui-adaptive-navigation`** (and `api-currency` owns the deprecation *flag*).
- **`.sheet` detents, `.fullScreenCover` over-reach, `.popover` adaptation** →
  **`audit-swiftui-presentation-sheets-modals`**.
- **`.onHover` / `pointerStyle` / touch-vs-pointer affordance** → **`audit-swiftui-touch-gestures`**.
- **Hard-coded device frames, missing size-class branch, `ViewThatFits`/`containerRelativeFrame`** →
  **`audit-swiftui-adaptive-layout`**.
- **`Table`-where-`List`-on-compact** → **`audit-swiftui-layout-and-tables`** (+ adaptive-layout for the
  size-class branch).
- **`UIScreen.main` / `UIApplication.shared.windows` / UIKit global reach** →
  **`audit-swiftui-uikit-overuse`** (the WHETHER; `uikit-interop` owns the HOW of a justified bridge).

## The one rule

**A smell is the *absence* of an iOS idiom or the *presence* of a Mac/iPad-pointer / deprecated-UIKit
habit — not the presence of a bad one alone.** Most tells are "this `.sheet` has **no**
`presentationDetents`", "this `Table` has **no** compact `List` fallback", "this `.onHover` is the
**only** interaction", "this app's root is a `NavigationView`". Grep **locates candidate sites**; the
**absence/misuse judgment is yours after READ**. Never score a smell you have not confirmed by reading
the view in full and grounding the floor in `swiftui-ctx`.

## Smell index (idi-01 … idi-09)

`id · one-line tell · severity · fix · routed owner skill · reference`. Severities: **warning**
(compiles but non-idiomatic), **advisory** (judgment / fit). There are **no hard-fails** — nothing here
breaks the build; it breaks the *feel*. **`fix` is `flag` (flag-only) for every row** (this skill
routes, never fixes).

| id | One-line tell (the desktop/iPad-habit smell) | Sev | Fix | Route → owner skill | Reference |
|---|---|---|---|---|---|
| idi-01 | `NavigationView` as the navigation root (deprecated push shell, iOS 16+) | warning | flag | adaptive-navigation | `idiom-catalog.md` |
| idi-02 | `.onHover`/`pointerStyle`/`onContinuousHover` as the **only** interaction on a touch surface | advisory | flag | touch-gestures | `idiom-catalog.md` |
| idi-03 | hard-coded full-screen `.frame(width: 3xx …)` device frame (no adaptive container) | warning | flag | adaptive-layout | `idiom-catalog.md` |
| idi-04 | `.fullScreenCover` where a `.sheet`+`presentationDetents` fits, or a sheet with **no** detents | advisory | flag | presentation-sheets-modals | `idiom-catalog.md` |
| idi-05 | `TabView` whose tabs are not top-level peers, or **>5** tabs (collapse to More on iPhone) | advisory | flag | adaptive-navigation | `idiom-catalog.md` |
| idi-06 | `UIScreen.main`/`.bounds` device metrics (deprecated; use a SwiftUI geometry source) | advisory | flag | uikit-overuse | `idiom-catalog.md` |
| idi-07 | `Table` with no `horizontalSizeClass` branch to a `List` on compact (iPad-only feel) | advisory | flag | layout-and-tables | `idiom-catalog.md` |
| idi-08 | `.navigationBarTitle` (deprecated iOS 14+ → `.navigationTitle` + display-mode) | advisory | flag | adaptive-navigation | `idiom-catalog.md` |
| idi-09 | `UIApplication.shared.windows`/`keyWindow` global reach (deprecated iOS 15+) | advisory | flag | uikit-overuse | `idiom-catalog.md` |

The **0-100 score** is computed from the confirmed smell set by **category weight** — navigation-idiom
(25), modality (20), touch-vs-pointer (20), adaptive-coverage (25), platform-surface (10). Each
`idi-NN` scores into exactly one category. The rubric, the dashboard layout, and the punch-list ordering
are in `references/idiom-catalog.md`; the route-not-fix discipline is in the seam note above + the
cross-ref graph.

## The real API, at a glance

These are the iOS idioms whose **absence** (or whose deprecated counterpart's **presence**) is the smell
— all real on the floors below (the reconciled values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; never restated here, read them):
`NavigationStack` (iOS 16.0+), `NavigationSplitView` (16.0+), `TabView` (13.0+), `navigationTitle`
+ `navigationBarTitleDisplayMode`, `sheet` (13.0+), `presentationDetents`/`presentationDragIndicator`
(16.0+), `fullScreenCover` (14.0+), `horizontalSizeClass`/`verticalSizeClass` (13.0+),
`containerRelativeFrame` (17.0+), `ViewThatFits` (16.0+), `Table` (collapses to one column on compact).
The canonical **shape** of each is fetched live from `swiftui-ctx`
(`lookup <api> --platform ios --json` → `result.consensus`, `result.introduced_ios`) in VERIFY — never
hand-assert a signature. The deprecated/UIKit-reach names you flag (route them) are `NavigationView`,
`navigationBarTitle`, `UIScreen.main`/`.bounds`, `UIApplication.shared.windows`/`keyWindow`; the
pointer-only iPad idioms are `.onHover`/`pointerStyle`/`onContinuousHover`. Confirm any name you cannot
place via `swiftui-ctx lookup … --platform ios` (**exit 3** = not in the iOS corpus / likely no-iOS-arm
or a hallucination) cross-checked against
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — it bounds which
   idioms are even *available* to expect (`containerRelativeFrame` only ≥17, `presentationDetents`/
   `ViewThatFits`/`NavigationStack` only ≥16). Note whether the target is iPhone-only or Universal — it
   decides whether `.onHover`/`Table`/`NavigationSplitView` are pointer/iPad-justified (idi-02/07) or
   pure smell. Find the `@main App` scene body: it anchors the navigation shell (idi-01/05).
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-ios-idiomaticness --dir <sources> --json /tmp/idi.json --sarif /tmp/idi.sarif`.
   It runs this skill's **tier-1 grep tells** (`lint/grep-tells.tsv`, idi-01…idi-09) — the tier that
   **stands alone** (ast-grep is *not* installed; any optional `lint/ast-grep/*.yml` is never required) —
   a per-file **parse probe**, and emits unified JSON + SARIF. **Read `parse_warnings`** — a file that
   didn't fully parse must be READ by hand. The runner only **LOCATES candidate sites**; the presence of
   an idiom or an interactive view is never itself a finding. Engine + rule format:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full**. The smell is an **absence/misuse** (no
   `presentationDetents`, no compact `List` branch, hover-only, a `NavigationView` shell) — invisible to
   grep, decidable only by reading the whole view + the App body + the deployment target. Build a
   per-view inventory: each navigation container + its kind; each modal + its detents; each interactive
   view + whether it has a touch path; each frame + whether it's adaptive; each `Table` + its size-class
   branch.
4. **DETECT.** Apply the index. A smell counts **only at 100% certainty** that the idiom is truly absent
   *or* the habit is truly misapplied *and* the floor/target supports the idiomatic alternative (e.g.
   don't flag a missing `containerRelativeFrame` under an iOS-16 target; don't flag `.onHover` on a
   Universal target where it's iPad-pointer polish atop a real touch path). Assign each its **category**
   for scoring (`references/idiom-catalog.md`).
5. **VERIFY.** For any idiom whose existence/shape/iOS floor you are < ~100% sure of, run **both**
   evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read its
   `result.consensus` (the canonical shape), `result.introduced_ios` (NOT under `result.availability`),
   `result.recommended` permalink, and `result.co_occurs_with`; for a deprecation route (idi-01/08)
   also `swiftui-ctx deprecated <api> --json` (`replacement`/`migrate_to`). A `lookup` **exit 3** means
   the symbol you expected is not in the iOS corpus / likely no-iOS-arm. (b) **Spec** — confirm the iOS
   floor via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` per `references/source-directory.md`
   and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` (never `WebFetch`
   developer.apple.com). Cross-check `result.introduced_ios` against `floors-master.md`. The CLI
   contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
   **Deeper corpus evidence (benchmark the score):** anchor the 0-100 to a real-iOS-app baseline —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx recipe <name> --json` for the canonical idiom shape
   (e.g. a `NavigationStack` root, a `.sheet { … }.presentationDetents([…])`), and
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx bridges --json` to see which UIKit reaches the corpus
   still tolerates vs which it has retired. Phrase findings as "the idiomatic iOS shape is X (Nx more
   common in the corpus); this app uses the deprecated Y".
6. **SCORE + REPORT.** Compute the 0-100 idiom score (`references/idiom-catalog.md` rubric). Write each
   confirmed smell as a finding (output contract below), one per file, with its `cross_ref` to the owner
   skill. Write the run's `_index.md` as the **idiom dashboard** (`kind: nativeness-dashboard`): the
   score, the per-category breakdown (navigation-idiom / modality / touch-vs-pointer / adaptive-coverage
   / platform-surface), and the prioritized punch-list.
7. **ROUTE (this skill's "FIX").** This skill is `fix_mode: flag-only` for **every** smell — it applies
   **no** code change. The `## Correct` of each finding is **not a fix here**; it is (a) a one-line "run
   `<owner-skill>` to fix this" route, and (b) the `swiftui-ctx` **consensus shape** as the canonical ✅
   idiom, backed by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink
   goes in `## Source`. The fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`) still governs: since nothing is
   `fix_mode: auto`, **no commit is made by this skill** — it hands off.
8. **DOUBLE-CHECK.** Re-confirm each finding's `cross_ref` names a valid sibling slug (per
   `cross-ref-graph.md`) and the routed owner actually owns that fix (no double-ownership). Re-confirm
   every iOS floor citation still resolves. Recompute the score from the final finding set so the
   dashboard total equals the sum of its category sub-scores.

## Confidence gating (load-bearing)

Score a smell **only at 100% certainty** the idiom is absent (or the habit misapplied) and the
idiomatic alternative is in-floor for the target. Anything less goes to VERIFY (step 5) first — never
emit a speculative smell. This skill never auto-fixes (`fix_mode: flag-only` everywhere) — it routes.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized:

- Findings: `swiftui-audits/ios-idiomaticness/<context>/NN-slug.md` (one per file, zero-padded, ordered).
- Run index: `swiftui-audits/ios-idiomaticness/_index.md` with `kind: nativeness-dashboard` (the score +
  category breakdown + prioritized punch-list — layout in `references/idiom-catalog.md`).
- `domain: ios-idiomaticness`. `fix_mode: flag-only` on **every** finding. Every finding carries a
  `cross_ref` to its owner skill (`status: open`, never `fixed` by this skill). Each finding's body
  includes a **`## Why it's wrong on iOS`** section (the desktop/iPad-habit explanation) and a
  `## Correct` (the route + the consensus idiom shape). `availability` reads from `floors-master.md`.
  `source` is an Apple URL via Sosumi or `verify against Xcode 26 SDK`.

**Starter `<context>` folders (file here when…):**

| `<context>` | File an idiom smell here when… |
|---|---|
| `navigation-idiom/` | a `NavigationView` shell, a `TabView` misfit / >5 tabs, or stale `navigationBarTitle` (idi-01, idi-05, idi-08) → `cross_ref` adaptive-navigation |
| `modality/` | a `.fullScreenCover` over-reach or a `.sheet` with no detents (idi-04) → `cross_ref` presentation-sheets-modals |
| `touch-vs-pointer/` | `.onHover`/`pointerStyle` as the only interaction on a touch surface (idi-02) → `cross_ref` touch-gestures |
| `adaptive-coverage/` | a hard-coded device frame or a `Table` with no compact branch (idi-03, idi-07) → `cross_ref` adaptive-layout / layout-and-tables |
| `platform-surface/` | `UIScreen.main` or `UIApplication.shared.windows` global reach (idi-06, idi-09) → `cross_ref` uikit-overuse |

**New-folder rule:** *if a smell does not fit an existing context folder, create a new lowercase-hyphen
folder under `swiftui-audits/ios-idiomaticness/` and note it in the run's `_index.md`. Prefer an existing
folder when the fit is reasonable; two runs over the same code produce structurally identical trees.*

## Reference routing

| File | Open when |
|---|---|
| `references/idiom-catalog.md` | the per-smell depth — the desktop/iPad-habit tell, why AI emits it, the absence-detection method, the **category** + **owner** route, and the 0-100 rubric / dashboard layout (idi-01 … idi-09) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC source map (iOS pages) fetched via Sosumi |
| `lint/grep-tells.tsv` | step LOCATE — this skill's tier-1 grep-tell rule set (idi-01…idi-09) fed to the shared runner; the self-standing tier (ast-grep is not installed). Edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every iOS floor/availability value (the reconciled truth — `NavigationStack`/`SplitView` 16.0, `presentationDetents`/`ViewThatFits` 16.0, `containerRelativeFrame` 17.0, `fullScreenCover` 14.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS `@available(iOS NN, *)` gating rule when an idiomatic alternative needs a floor gate above the target |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (cross-check a name you cannot place) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys + the `kind: nativeness-dashboard` discriminator |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the fix-safety protocol (step 7 — here only the no-auto-fix / hand-off clause) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup --platform ios`/`deprecated`/`recipe`/`bridges`/`file --smart` for the consensus idiom shape + permalink (steps 5 VERIFY · 7 ROUTE) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | the idiomaticness/nativeness seam row + every `cross_ref` target (this skill's whole output is routes) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-ios-idiomaticness --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this
skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv` — the deprecated-shell /
pointer-idiom / device-frame / UIKit-reach *presence* tells + the modal/`TabView`/`Table` *locators*
idi-01…idi-09). This tier **stands alone**: ast-grep is **not installed** in this environment, so the
self-test relies only on these grep tells — any `lint/ast-grep/*.yml` is optional and never required.
**Most idi-* smells are an *absence/misuse*** (no detents, no compact branch, hover-only), which grep
cannot decide — the runner only **locates candidate sites**; the absence/misuse judgment is the LLM's
after READ (step 3). It runs a per-file **parse probe**, emits unified **JSON + SARIF**, exits **0** (no
hard-fail rules — idiomaticness breaks feel, not the build), and **degrades to grep-only with a notice**
if ast-grep is unreachable. The thin `scripts/ios-idiomaticness-lint.sh` is a pointer to this runner.
Engine + rule-file format + JSON/SARIF shape: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
