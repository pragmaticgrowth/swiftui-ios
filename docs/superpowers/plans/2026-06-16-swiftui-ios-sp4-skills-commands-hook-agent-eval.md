# swiftui-ios — SP4: write/scaffold skills + commands + hook + agent + eval + README/manifest (plan)

> Final sub-project of the iOS transform. Design source: `docs/superpowers/specs/2026-06-16-swiftui-ios-data-foundation-design.md` §1 (SP4). SP1–SP3 complete; swiftui-ios v0.3.0 (HEAD f097fde). The 34-skill audit suite + `audit-ios-swiftui-full` orchestrator are done.

**Impl repo:** `/Users/serkan/swiftui-ios`. macOS reference: `/Users/serkan/claude-swiftui-plugin` (READ-ONLY). Agents do NOT git commit; the orchestrator commits each batch. Reviewer-wrong-repo trap: absolute paths, `git -C /Users/serkan/swiftui-ios`.

**Goal:** the iOS plugin is feature-complete and self-consistent — write/scaffold skills are iOS, the 4 commands are model-first iOS, the deprecation hook uses iOS names, the reviewer agent is `swiftui-ios-reviewer`, the eval tasks are iOS, the README body + manifest are iOS, and NO macOS-only / dropped-slug reference remains anywhere. `validate-skills.py` stays green; the plugin loads.

## Global constraints
- Floors from `references/_shared/floors-master.md` (iOS); ground shapes in `swiftui-ctx` (`SWIFTUI_CTX_CATALOG=/Users/serkan/swiftui-ios/catalog`; `--platform ios`; `introduced_ios` at `result.introduced_ios`).
- Skill `description` <=1024 chars, NO angle brackets; `name`==dir. Run `python3 scripts/validate-skills.py` to self-check.
- iOS-17 floor; iPad within iOS. Reference the iOS audit skills + orchestrator (`audit-ios-swiftui-full`, `build-ios-swiftui`, `ios-app-patterns`, `swiftui-ios-reviewer`), never the dropped macOS slugs.

## Phase 0 — deterministic scaffolding (orchestrator)
- `git mv skills/macos-app-patterns skills/ios-app-patterns`
- `git mv agents/swiftui-reviewer.md agents/swiftui-ios-reviewer.md`
- `git mv scripts/macos-swiftui-lint.sh scripts/ios-swiftui-lint.sh`
- Regenerate `hooks/deprecated-names.txt` from the iOS catalog: `python3 scripts/gen_deprecated_list.py` (reads `catalog/insights.json`). Verify iOS deprecations.

## Phase 1 — content authoring (workflow; each task = disjoint files; author -> review -> fix)
1. **build-ios-swiftui** (18 files, 4920 lines; heavy retarget-in-place). One high-effort agent owns the whole skill. Rewrite SKILL.md (description: iOS triggers, "NOT for macOS"; body "Write correct iOS SwiftUI"; reference routing). Retarget every references/*.md macOS->iOS and RENAME the macOS-only ones with SKILL.md routing kept in sync: scenes-and-windows.md->app-lifecycle.md, menus-and-commands.md->(fold into app-intents/touch or drop), appkit-interop.md->uikit-interop.md, appkit-liquid-glass.md->(merge into liquid-glass.md, iOS 26), sandbox-and-files.md->file-handling.md, navigation-and-toolbars.md->adaptive-navigation.md, controls-and-pointer.md->controls-and-touch.md; retarget the platform-neutral ones in place (state-and-observation, swiftdata, concurrency, api-currency, version-and-hallucination, previews, view-performance, layout-and-tables, liquid-glass). Update `references/lint-checklist.md` to iOS rules. cross_refs -> swiftui-ios-reviewer, ios-app-patterns, audit-ios-swiftui-full, swiftui-examples. Also fix `scripts/ios-swiftui-lint.sh` (rename done in Phase 0) — its tells + the `lint-checklist.md` path must be iOS.
2. **ios-app-patterns** (renamed; SKILL.md + references/recipes.md). Retarget to the iOS recipes per the spec: tab-bar app, NavigationStack master-detail, sheet+detents flow, uiview-bridge, widget, onboarding. Ground each in `swiftui-ctx recipe <name>` (tab-bar-app, navigationstack-master-detail, sheet-detents, uiview-bridge, widget-scaffold, onboarding-flow). cross_refs -> build-ios-swiftui, swiftui-examples, audit-ios-swiftui-full.
3. **swiftui-examples** (4 files; lighter). Retarget the single-API-lookup CLI-usage skill to iOS framing + iOS examples; fix the residual `introduced_macos`/`min_macos` in references/commands.md + playbook.md -> iOS keys; corpus numbers -> 319 apps.
4. **swiftui-modernize** (2 files). Retarget deprecation/modernization to iOS (NavigationView->NavigationStack, foregroundColor->foregroundStyle still valid; drop macOS-only); ground in `swiftui-ctx deprecated`.
5. **agent swiftui-ios-reviewer** (renamed file). name: swiftui-ios-reviewer; description iOS ("319 real shipping iOS apps", iOS triggers); body retargeted; tools unchanged.
6. **commands (4)**: swiftui.md, swiftui-review.md, swiftui-audit.md, swiftui-settings.md — model-first rewrite per the spec: NO `allowed-tools`, NO `$ARGUMENTS`/`argument-hint`, the model reads intent from context. iOS framing; route swiftui-audit -> audit-ios-swiftui-full; swiftui-review -> swiftui-ios-reviewer; swiftui -> swiftui-ctx lookup; swiftui-settings -> the iOS settings/Form pattern. (swiftui-audit.md already has the orchestrator slug fixed in SP3.)
7. **eval**: retarget `eval/tasks.jsonl` (12 tasks) + `seeds/` to iOS prompts/ground_cmd/forbid (e.g. NavigationView->NavigationStack, wheel-picker-is-fine, sheet-detents, uiview-bridge). run.sh/score.py/gen-codex.sh are platform-neutral — touch only if they hardcode macOS.
8. **README.md body + plugin.json manifest**: skills table -> the iOS skills (34 audit + build-ios-swiftui/ios-app-patterns/swiftui-examples/swiftui-modernize + orchestrator); "audit suite (34 skills)"; pipeline narrative -> awesome-ios/open-source-ios-apps; caveats -> iOS-first; remove all 12 dropped macOS slugs; numbers -> 319 apps / iOS-17 floor. plugin.json: confirm name/keywords/description iOS; bump version (-> 0.4.0).

## Phase 2 — finalize (orchestrator)
- `python3 scripts/validate-skills.py` green; `bash scripts/audit-selftest.sh` green (unchanged); grep the whole repo for residual dropped slugs / `build-macos` / macOS-only framing in user-facing files -> zero.
- Confirm the plugin manifest lists everything; the hook's deprecated-names.txt is iOS.
- Final whole-branch review (opus) over the SP4 artifacts; fix Critical/Important; bump plugin.json; commit.

## Self-Review
- Coverage: 4 skills + 1 agent + 4 commands + hook + eval + README + manifest + the Phase-0 renames + the build-skill lint script — all enumerated.
- Forward-refs satisfied: build-ios-swiftui now exists with iOS content (async-data + orchestrator referenced it); README dropped slugs fixed.
- Disjoint writes: each task owns its skill/agent/command/file set; renames done deterministically in Phase 0.
