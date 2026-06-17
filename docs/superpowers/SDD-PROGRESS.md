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
# Published: github.com/pragmaticgrowth/swiftui-ios (public, tag v0.4.0). macOS reference repo never modified.
# Full per-batch ledger (every commit + deferred minors) lived in the macOS controller repo at .git/sdd/progress.md
#   (github.com/serkanhaslak/claude-swiftui-plugin) — this in-repo SDD-PROGRESS.md is the iOS-side summary.
