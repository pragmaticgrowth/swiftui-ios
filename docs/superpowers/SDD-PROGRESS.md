# swiftui-ios SP1 — progress ledger
Plan: docs/superpowers/plans/2026-06-16-swiftui-ios-data-foundation.md
Impl repo: /Users/serkan/swiftui-ios  (separate git repo)
Controller repo/branch: /Users/serkan/claude-swiftui-plugin @ swiftui-ios-transform

- Task 1: complete (commit e0f548a, review clean; plan rsync exclude anchored to /swiftui-ctx)
- Task 2: complete (commit 562823d, review clean; macOS 14/14 + iOS 5/5 TDD)
- Task 3: complete (commit b444b81, review clean; 482 modifiers/1119 types, 3361 iOS floors)
- Task 4: complete (commit 693f761, review clean; 2474 candidates = 837 apps + 1637 libs)
- Task 5: complete (commit 268c62d, review clean; 16 iOS terms + inverted pass)
- Task 6: complete (commit 5d21981, review clean; classify_platform TDD, full rename verified, +3 out-of-brief sites caught)
- Task 7: complete (commits a8e707f+b3a06f3, review clean; 6 iOS recipes; draggable-reorder re-anchored)
- Task 8: complete (commit 6c4ffde; smoke PASS: TabView+detents ok, platform Counter ios:4 cross:1, no misclass)
- Task 9: COMPLETE — full harvest exit 0; catalog committed (swiftui-ios 9dd7b4e); doctor OK.
#   319 SwiftUI apps (2474 cand -> 614 gated -> 319 SwiftUI; 298 non-SwiftUI dropped); platforms ios:229 cross:85 macos:5.
#   13 recipes populated (uiview-bridge 182 repos, nav-stack 141, tab-bar 108, ...; widget/app-intent empty=expected).
#   ALL SP1 SUCCESS CRITERIA MET. Deferred to SP2: sdk label lacks installed-version (Minor#4); --platform ios active filtering; README body retarget (SP4).

## Final whole-branch review: 3 Important issues FIXED (commit 6feda7a):
#   1) SwiftUI-presence floor (was unimplemented) — repos w/o SwiftUI dropped at stage 5
#   2) ipad_idioms now persisted in by_repo profiles
#   3) LFS bypass completed (filter.lfs.process=)
#   + opus fixer hardened a real KeyError (_provenance on dropped repo). py_compile clean.
# swiftui-ios HEAD after fixes: 6feda7a. Harvest will run corrected 04_run/05_catalog.
# REMAINING for full coverage: SP2 (CLI iOS defaults + references), SP3 (29 audit skills), SP4 (write/scaffold skills, commands, hook, agent, eval, manifest). Each = own spec->plan->build.

## Minor findings (final-review triage)
- T3: 02a_flatten.py uses bare open() (3 sites) — file handles not closed (hygiene)
- T5/M1: search_with_text duplicates retry/backoff loop (no shared helper)
- T5/M2: --terms flag does not gate the inverted pass (always runs 2 inverted queries)
- T5/M3: match_files counts result-objects in inverted pass vs file-lines in positive pass (semantic drift; not a hard gate)
- T6/M1: scripts/02b_availability.py docstring still says introduced_macos (code emits introduced_ios) — cosmetic
- T6/M2: 05_catalog.py COOC_NOISE comment wording stale ('non-macOS') — cosmetic
- T7/M (minor, non-block): widget-scaffold/app-intent secondary-api filter may over-filter; falls back to unfiltered
- T8/SP2: --platform ios is a no-op in examplesFiltered() (only macos branch) — active iOS filtering is SP2 scope
- T8/brief: task-8 smoke probe checked .examples[] but lookup returns recommended/diverse (brief probe wrong, CLI correct)

## SP2 — CLI + references retarget
- SP2-T1: complete (commit 38bb403, review clean; default ios, iOS floors surface, uiview-bridge routing)
- SP2-T2: complete (commits 6947a66+7bf4f88; iOS floors 3361/22, ios-gating, numbers fixed; 2 Important doc bugs fixed; reviewer Critical was false-positive/wrong-repo)
- SP2-T3: complete (commit 9952877; v0.2.0; verify: doctor OK, introduced_ios surfaces at result.introduced_ios=13.0 for TabView, uiview-bridge 8 ex, fixtures green).
# SP2 COMPLETE. swiftui-ios HEAD 9952877. CLI is iOS-correct: default ios, iOS floors, platform filtering, uiview-bridge routing; references = iOS floors + ios-gating.
# REMAINING: SP3 (29 audit skills — largest), SP4 (write/scaffold skills, commands, hook, agent, eval, README/manifest body).
- SP2-T1/M (minor): SwiftUICtx NS-path prose hardcodes uiview-bridge wording (cosmetic; NS types absent in iOS catalog)
- SP2-T2/M (defer to SP3): hallucination-blacklist cell values still say (macOS NN+) for cross-platform APIs — re-floor to iOS when blacklist is wired into iOS audit skills

## SP3 — iOS audit suite (COMPLETE; v0.3.0)
Spec: docs/superpowers/specs/2026-06-16-swiftui-ios-sp3-audit-suite-design.md · Plan: docs/superpowers/plans/2026-06-16-swiftui-ios-sp3-audit-suite.md
- 34 domain audit skills + `audit-ios-swiftui-full` orchestrator, built in reviewed batches (A foundation+4 flagship, B universal 10, C retarget 13 w/ rule inversions, D net-new 7, E whole-branch review).
- Engine reused verbatim (swiftui-lint.sh / audit-gate.sh / audit-scan.py); only audit-signals.tsv + references/_shared/ were retargeted. Inversions captured: Form grouped-by-default, .wheel native, .topBarLeading correct, List-primary, iOS-26 glass.
- Foundation gaps fixed in-flight: gen_floors.py [:60] truncation (broke VERIFY); missing scripts/swiftui-ctx wrapper.
- Green: validate-skills 39 OK, audit-selftest 140 rules/25 fixtures, gate runs over all 34, STEER 32/34.

## SP4 — write/scaffold skills + commands + hook + agent + eval + README/manifest (COMPLETE; v0.4.0)
Plan: docs/superpowers/plans/2026-06-16-swiftui-ios-sp4-skills-commands-hook-agent-eval.md
- build-ios-swiftui (write skill), ios-app-patterns (recipes), retargeted swiftui-examples/swiftui-modernize, swiftui-ios-reviewer agent, 4 MODEL-FIRST commands, iOS deprecation hook (deprecated-names.txt from catalog), eval/tasks.jsonl (12 iOS tasks), iOS README + manifest.
- Final whole-plugin review: all scopes PASS (0 Critical, 0 Important).

# ===== PROGRAM COMPLETE ===== macOS swiftui plugin fully ported to this iOS plugin. v0.4.0.

## SP5 — live-dogfood bugfixes (v0.4.1)
Dogfooded the suite against a real app (life-runner/ios/LifeRunner — Universal, iOS 17 floor, ~10k LOC). LOCATE→VERIFY discipline held (all 48 gate "hard" hits were false positives at VERIFY); the run surfaced two engine precision bugs, both fixed:
- **audit-gate.sh now STEER-gated.** It consulted no relevance signal, so it ran swiftdata's broad `hard` nets (sd-01 = any `let x: [Type]`, sd-09 = any `Task {`) on a SwiftData-free repo → 44 false hard-fails blocking CI. Now reuses `audit-scan.py`; absent cond domains are marked `n/a — not present` (not run, not counted). `--all`/`--no-steer` forces all 34; degrades to all-34 if python3/scan unavailable. LifeRunner hard 48→4 (the 4 remaining are privacy pp-01, a present-domain Info.plist cross-check grep can't do — a VERIFY concern, not STEER).
- **swiftui-lint.sh parse-unbalanced FP fixed.** The brace/paren balance heuristic counted bracket chars inside string literals + comments, so a lone `")"` in a string (e.g. MarkdownText.swift `sep == ")"`) tripped a spurious `parse-unbalanced` warn under EVERY skill (~34 phantom warns/gate). Now strips `"…"` spans + `//` comments first (BSD-portable sed). Genuine imbalance still flags (verified in --no-ast fallback). LifeRunner gate warn 675→641.
- Green after: validate-skills 39 OK, audit-selftest 140/25, audit-scan 32/34, gate fixtures exit 2 preserved.

## SP6 — Design & UX layer, Phase 1: visual Design Reviewer (v0.5.0)
Spec: docs/superpowers/specs/2026-06-16-swiftui-ios-design-ux-layer-design.md · Plan: docs/superpowers/plans/2026-06-16-swiftui-ios-design-ux-layer-phase1.md (research-grounded, all design rules cite live HIG/WWDC URLs verified 2026-06-16). A pixel-first reviewer that extends LOCATE→VERIFY→REPORT to rendered pixels: **CAPTURE→CHECK→CRITIQUE→SCORE**, hybrid (deterministic facts + vision judgment).
- **Knowledge base** (5 `references/_shared/` docs): `hig-design-rubric.md` (measurable HIG rules + numbers), `liquid-glass-design.md` (iOS 26 design language), `ux-smell-catalog.md` (46 detectable smells), `design-finding-schema.md` (Nielsen 0–4 + 0–100 Design Score), `design-claims-blacklist.md` (7 debunked myths). Every rule cited; myths blacklisted; repo path refs (not wikilinks).
- **Capture harness** `scripts/swiftui-capture.sh` — build→boot→navigate→screenshot matrix (light/dark × Dynamic Type) + optional `#Preview` snapshots. Auto-explore via idb AX-tree + deep-links + `screens.manifest.json`; `wait_for_idle`; graceful code-only degradation. Live-verified on LifeRunner (home + auto-explored Sign in, distinct light/dark renders).
- **Deterministic tier** — 7 static `dr-*` tells (selftest 140/25 → 146/26, stand alone w/o ast-grep) + optional `scripts/a11y-audit/` (`performAccessibilityAudit`).
- **Reviewer skill** `audit-swiftui-design-review` (validate-skills 39→40, STEER `always`) + orchestrator **Wave 9** (resolves the dangling "HIG review skill" pointer). Dogfooded on LifeRunner → Design Score 87/100 with cited findings (AX5 overlap, ghosted Sign-in button, placeholder-only labels, hardcoded fonts), correctly dismissing 36 dr-fab false candidates (ring/avatars).
- **Phase 2 — design-aware generation (v0.5.1, COMPLETE).** Plan: docs/superpowers/plans/2026-06-16-swiftui-ios-design-ux-layer-phase2.md. Wired the same KB into the write path: `build-ios-swiftui` gained a "Design defaults (HIG + Liquid Glass)" section (system text styles, semantic colors, 44 pt, glass-on-chrome-only, HIG nav, real states) + KB rows in its Reference index; `ios-app-patterns` design-vets every scaffold and ships a `#Preview` so it's render-and-review-able. Both cite the rubric/glass/blacklist and can self-check via swiftui-capture.sh + audit-swiftui-design-review. No `design-system.md` added — the rubric already is the token guidance (YAGNI). Green: validate-skills 40 OK, audit-selftest 146/26.
## SP7 — readiness for real iOS-project use (v0.5.2)
Goal: confirm/complete the plugin so it's ready to use in LifeRunner or any iOS project. Closed three gaps the Phase-1/2 work left open:
- **Harness auth-bypass (`--launch-arg`/`--launch-env` + manifest `launch_args`).** The visual reviewer could only reach an app's pre-auth screens. Now `swiftui-capture.sh --launch-arg --demo-session` (or per-screen `launch_args`) reaches the signed-in app. Two real bugs fixed en route: (1) the manifest `read` used `IFS=$'\t'`, which coalesces empty columns (tab is whitespace) and misaligned `launch_args` → app launched signed-OUT; switched to the Unit-Separator ``. (2) added a launch settle so async sign-in completes before the screenshot.
- **Full signed-in review proven.** Captured LifeRunner's 4 tabs (Coach/Chat/Health/Me) × light/dark × {large, AX5} = 16 shots via `--demo-session` + `--initial-tab`; produced a real **Design Score 90/100** with verified findings (AX5 "Connections"→"Con-" truncation; confirm icon-only nav labels; hardcoded fonts) and confirmed the idiomatic strengths (native large titles, glass tab bar, inline confirm card, no Android tells).
- **Install-readiness verified** (plugin-dev:plugin-validator): install-ready YES — 40 skills, 4 commands, 1 agent, 1 hook, all manifests valid, all `${CLAUDE_PLUGIN_ROOT}` paths resolve, no blockers. Non-blocking note: `source:"."` ships the harvest/build pipeline (data/, swiftui-scan/, .deepsec/) → larger install; trim later if desired.
- Green: validate-skills 40 OK, audit-selftest 146/26, capture-smoke OK, doctor 319 repos. **Verdict: ready for use in iOS projects.**

# Published: github.com/pragmaticgrowth/swiftui-ios (public, tag v0.4.0). macOS reference repo never modified.
# Full per-batch ledger (every commit + deferred minors) lived in the macOS controller repo at .git/sdd/progress.md
#   (github.com/serkanhaslak/claude-swiftui-plugin) — this in-repo SDD-PROGRESS.md is the iOS-side summary.
