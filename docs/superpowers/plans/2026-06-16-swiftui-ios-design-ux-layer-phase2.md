# Design & UX Layer — Phase 2 (design-aware generation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make the plugin's *write* path produce HIG-idiomatic, Liquid-Glass-modern UI by default — by wiring the Phase 1 design knowledge base into `build-ios-swiftui` and `ios-app-patterns`, with an optional render-and-self-check loop.

**Architecture:** No new pipeline. The same `references/_shared/` KB that the reviewer consumes (Phase 1) becomes generation guidance the write skills cite. Generated UI defaults to system text styles, semantic colors, 44 pt targets, correct glass placement, HIG navigation, and real empty/loading/error states; after generating a screen the author may render it via `scripts/swiftui-capture.sh` and critique via `audit-swiftui-design-review` (close the loop).

**Tech Stack:** Markdown skill edits; the Phase 1 KB (`hig-design-rubric.md`, `liquid-glass-design.md`, `ux-smell-catalog.md`, `design-claims-blacklist.md`); `swiftui-capture.sh` + `audit-swiftui-design-review`.

**Spec:** `docs/superpowers/specs/2026-06-16-swiftui-ios-design-ux-layer-design.md` §7 (Component 5). **Base:** branch `design-ux-generation` off `design-ux-layer` (which carries the Phase 1 KB).

## Global Constraints

- iOS-only, SwiftUI-only, iOS-17 floor; Liquid Glass gated iOS 26. (spec §11)
- Generation cites the KB for design choices; never assert a design number from memory; honor `design-claims-blacklist.md` (no "max 3–5 tabs", "0.3s animation", etc.). (spec §3)
- `validate-skills.py` must stay clean (description ≤1024 chars, no `<`/`>`, name==dir); `audit-selftest.sh` must stay green.
- Bump `plugin.json` + both `marketplace.json` version fields on user-facing change (target 0.5.1).
- Absolute paths; repo `/Users/serkan/swiftui-ios`.

## File Structure

- Modify: `skills/build-ios-swiftui/SKILL.md` — add a "Design defaults (HIG + Liquid Glass)" section + KB rows in the Reference index.
- Modify: `skills/ios-app-patterns/SKILL.md` — design-vet the rule + cite the KB + require a `#Preview` per scaffold.
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `docs/superpowers/SDD-PROGRESS.md`.

> No `design-system.md` reference is added — `hig-design-rubric.md` (typography/color scales) already *is* the system-token guidance; a separate doc would duplicate it (YAGNI). The skills point at the rubric instead.

---

## Task 1: build-ios-swiftui — design defaults + KB references

**Files:**
- Modify: `/Users/serkan/swiftui-ios/skills/build-ios-swiftui/SKILL.md`

**Interfaces:**
- Consumes: the Phase 1 KB files in `references/_shared/`. Produces: generation that defaults to HIG/glass best practices and can self-check.

- [ ] **Step 1: Add a "Design defaults (HIG + Liquid Glass)" section.** Insert after the "Operating contract" section a concise checklist that says: generate with built-in text styles (never `.font(.system(size:))`), semantic/system colors with dark + increased-contrast variants (never hardcoded `.black`/`.white`/raw RGB for foreground), 44×44 pt minimum tap targets, Liquid Glass only on the navigation layer (one `GlassEffectContainer`, emphasis-tint a single action, iOS-26 gated), HIG navigation (tab bar for peer sections, `NavigationStack` for drill-down, split view by size class), SF Symbols for standard actions, and real empty/loading/error states. End with: "Ground each choice in `${CLAUDE_PLUGIN_ROOT}/references/_shared/hig-design-rubric.md` / `liquid-glass-design.md`; never assert a number from memory or a myth from `design-claims-blacklist.md`. Optional self-check: after writing a screen, render it with `scripts/swiftui-capture.sh` and critique via `audit-swiftui-design-review`."

- [ ] **Step 2: Add the KB to the Reference index.** Append three rows to the Reference index table:
  - `` `../../references/_shared/hig-design-rubric.md` `` | Design defaults — type scale, contrast, 44 pt, spacing, nav limits (cited HIG)
  - `` `../../references/_shared/liquid-glass-design.md` `` | Liquid Glass *design* placement/tint/adoption (complements `references/liquid-glass.md` API)
  - `` `../../references/_shared/design-claims-blacklist.md` `` | Debunked design myths to never assert

- [ ] **Step 3: Validate.** Run:
```bash
cd /Users/serkan/swiftui-ios && python3 scripts/validate-skills.py 2>&1 | tail -1
grep -c 'hig-design-rubric\|liquid-glass-design\|design-claims-blacklist' skills/build-ios-swiftui/SKILL.md
```
Expected: `… skills OK + manifests valid`; ≥ 3 KB references present.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add skills/build-ios-swiftui/SKILL.md
git commit -m "feat(design-gen): build-ios-swiftui generates HIG/glass-idiomatic UI by default"
```

---

## Task 2: ios-app-patterns — design-vetted scaffolds

**Files:**
- Modify: `/Users/serkan/swiftui-ios/skills/ios-app-patterns/SKILL.md`

**Interfaces:**
- Consumes: the KB. Produces: scaffolds that use system styles/semantic colors/44 pt + ship a `#Preview` (so each is immediately capture-able by the reviewer).

- [ ] **Step 1: Design-vet the rule + cite the KB.** In "The rule" (or a new one-line bullet), add: scaffolds use built-in text styles, semantic colors, 44 pt targets, and HIG navigation per `${CLAUDE_PLUGIN_ROOT}/references/_shared/hig-design-rubric.md` + `liquid-glass-design.md`; **ship a `#Preview` with each scaffold** so it can be rendered + design-reviewed (`audit-swiftui-design-review`).

- [ ] **Step 2: Add KB to References.** Add to the `## References` section the two KB pointers (`hig-design-rubric.md`, `liquid-glass-design.md`).

- [ ] **Step 3: Validate.** Run:
```bash
cd /Users/serkan/swiftui-ios && python3 scripts/validate-skills.py 2>&1 | tail -1
grep -c 'hig-design-rubric\|#Preview\|design-review' skills/ios-app-patterns/SKILL.md
```
Expected: skills OK; KB + preview + reviewer references present.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add skills/ios-app-patterns/SKILL.md
git commit -m "feat(design-gen): ios-app-patterns scaffolds are design-vetted + previewable"
```

---

## Task 3: Ship — version, docs, green check

**Files:**
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `docs/superpowers/SDD-PROGRESS.md`

- [ ] **Step 1: Bump to 0.5.1.**
```bash
cd /Users/serkan/swiftui-ios
sed -i '' 's/"version": "0.5.0"/"version": "0.5.1"/' .claude-plugin/plugin.json
sed -i '' 's/"version": "0.5.0"/"version": "0.5.1"/g' .claude-plugin/marketplace.json
jq -e . .claude-plugin/plugin.json >/dev/null && jq -e . .claude-plugin/marketplace.json >/dev/null && echo "manifests valid ✓"
```

- [ ] **Step 2: Docs.** README: add one line under the write/look-up skills that generation is now HIG/glass-aware. SDD-PROGRESS: append a Phase 2 note under the SP6 entry (KB wired into build-ios-swiftui + ios-app-patterns; self-check loop; Phase 2 done).

- [ ] **Step 3: Full green check.**
```bash
cd /Users/serkan/swiftui-ios
export SWIFTUI_CTX_CATALOG="$PWD/catalog"
python3 scripts/validate-skills.py 2>&1 | tail -1
bash scripts/audit-selftest.sh 2>&1 | tail -1
```
Expected: validate-skills 40 OK; audit-selftest 146/26.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md docs/superpowers/SDD-PROGRESS.md
git commit -m "chore(design-gen): ship Design & UX layer Phase 2 (v0.5.1) + docs"
```

---

## Self-Review

- Spec §7 coverage: design defaults in build-ios-swiftui (Task 1) ✓, design-vetted ios-app-patterns + previewable (Task 2) ✓, self-check loop referenced (Task 1 Step 1) ✓, `design-system.md` intentionally omitted (rubric covers it — documented) ✓.
- Placeholder scan: doc-edit steps specify exact sections + verifications; no vague TODOs.
- Consistency: KB filenames identical to Phase 1; skill names (`audit-swiftui-design-review`) and script (`swiftui-capture.sh`) match Phase 1.
