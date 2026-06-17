# Design & UX Layer — Phase 1 (Visual Design Reviewer) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pixel-first visual Design Reviewer to the swiftui-ios plugin: build the app, screenshot screens across light/dark + Dynamic Type, run deterministic objective checks, vision-critique against a cited HIG/Liquid-Glass knowledge base, and emit a 0–100 Design Score.

**Architecture:** A hybrid `CAPTURE → CHECK → CRITIQUE → SCORE` pipeline that extends the plugin's existing `LOCATE → VERIFY → REPORT` discipline to rendered pixels. A shared design knowledge base (`references/_shared/`) is the single source of truth; a new capture harness (`scripts/swiftui-capture.sh`) produces screenshots; a deterministic tier (static design-lint + `performAccessibilityAudit`) owns objective facts; a new skill (`audit-swiftui-design-review`) does the vision critique and scoring.

**Tech Stack:** Bash (reusing `swiftui-lint.sh` conventions), Python 3 (reusing `audit-scan.py` patterns), `jq`, `xcrun simctl` + `xcodebuild` (Xcode 26.x), optional `idb` (facebook/idb) and `EmergeTools/SnapshotPreviews`, Markdown skill/reference docs.

**Spec:** `docs/superpowers/specs/2026-06-16-swiftui-ios-design-ux-layer-design.md`. Read it before starting; this plan implements its §3–6, §8–11 (Phase 1 only — §7 generation is a later plan).

## Global Constraints

- iOS-only, SwiftUI-only, iOS-17 deployment floor; Liquid Glass features gated iOS 26. (verbatim from spec §11)
- Every design *rule* asserted by the layer cites a real HIG/WWDC URL; never assert a design number from memory. Design rules cite HIG; API/floors cite `swiftui-ctx`; Apple-doc API prose cites Sosumi — never crossed. (spec §3, §8.3)
- Honor `references/_shared/design-claims-blacklist.md`: never emit the debunked myths ("max 3–5 tabs," "avoid pure black," "45–75 chars/line," "0.3 s standard animation," "large title only at root," a "chrome" material, HIG-stated 16 pt margin / 8 pt grid). (spec §3, §8.3)
- The grep tier (`lint/grep-tells.tsv`) MUST stand alone; ast-grep is OPTIONAL and may be absent — never author a rule that REQUIRES ast-grep. (house rule)
- `validate-skills.py` must stay clean for any new/edited skill: `name` == directory, `description` ≤ 1024 chars, no `<`/`>` in frontmatter. (house rule)
- `audit-selftest.sh` must stay green (140 expected rules across 25 fixtures) and any new deterministic tell with a fixture must be additive. (house rule)
- Bump `.claude-plugin/plugin.json` + both `version` fields in `.claude-plugin/marketplace.json` on any user-facing change (target 0.5.0 at ship). (house rule)
- Implementer repo is `/Users/serkan/swiftui-ios`; always use absolute paths and `git -C /Users/serkan/swiftui-ios`. (SP3 reviewer-wrong-repo trap)
- All capture/harness work degrades gracefully: when Xcode/Simulator/idb is unavailable or the project can't build, emit a clear status and fall back to code-only — NEVER silently claim visual coverage not achieved. (spec §4, §10)
- Dogfood target for live tests: `/Users/serkan/life-runner/ios/LifeRunner` (Universal, iOS 17 floor, buildable). Set `export SWIFTUI_CTX_CATALOG="$PWD/catalog"` for any `swiftui-ctx` use.
- Work happens on branch `design-ux-layer` (already created; spec + v0.4.1 fixes already committed there).

---

## File Structure

**Knowledge base (new, `references/_shared/`):**
- `hig-design-rubric.md` — checkable HIG rubric by dimension, Apple numbers + source URLs.
- `liquid-glass-design.md` — iOS 26 Liquid Glass design language + anti-patterns + adoption.
- `ux-smell-catalog.md` — qualitative UX smells (SMELL → why → detect → source).
- `design-finding-schema.md` — finding format + severity + Design Score + dashboard contract.
- `design-claims-blacklist.md` — debunked design myths + the correct facts.

**Capture harness (new):**
- `scripts/swiftui-capture.sh` — build → boot → navigate → screenshot matrix + preview snapshots; emits `swiftui-design/`.

**Deterministic tier (new):**
- `skills/audit-swiftui-design-review/lint/grep-tells.tsv` — static `design-*` tells.
- `skills/audit-swiftui-design-review/lint/ast-grep/*.yml` — optional structural tells.
- `scripts/a11y-audit/` — optional `performAccessibilityAudit` XCTest runner (template + driver).
- `tests/fixtures/design-review.swift` + `tests/fixtures/design-review.expect` — selftest coverage.

**Reviewer skill (new):**
- `skills/audit-swiftui-design-review/SKILL.md` — the CAPTURE→CHECK→CRITIQUE→SCORE skill.
- `skills/audit-swiftui-design-review/references/` — pointers into the shared KB.
- `skills/audit-swiftui-design-review/scripts/design-capture.sh` — thin pointer to `scripts/swiftui-capture.sh`.

**Wiring (modify):**
- `scripts/audit-signals.tsv` — add the `design-review` signal row.
- `skills/audit-ios-swiftui-full/SKILL.md` — add Wave 9 (Visual design); resolve the "HIG review skill" pointer.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — version bump.
- `README.md`, `docs/superpowers/SDD-PROGRESS.md` — document the layer.

---

## Task 1: KB — `hig-design-rubric.md`

**Files:**
- Create: `/Users/serkan/swiftui-ios/references/_shared/hig-design-rubric.md`

**Interfaces:**
- Produces: a reference doc consumed by `audit-swiftui-design-review` (Task 12) and the deterministic tells (Task 10). Section anchors other files cite: `## Layout & spacing`, `## Typography`, `## Color & contrast`, `## Hit targets & controls`, `## SF Symbols`, `## Navigation & structure`, `## Motion`, `## Accessibility (visual)`, `## States`.

**Content source:** spec §3 (`hig-design-rubric.md` bullet) + the verified HIG numbers/URLs from the research (HIG Layout/Typography/Color/Dark Mode/Materials/Accessibility/Buttons/SF Symbols/Tab Bars/Navigation Bars/Sidebars/Modality/Toolbars/Motion/Loading/Progress/Alerts/Feedback/Launching). Use Apple's hard numbers verbatim: type scale (Body 17/22 … Caption 2 11/13; default 17, min 11), contrast 4.5:1 (≤17 pt) / 3:1 (18 pt or bold) / 7:1 custom, hit target 44×44 (floor 28), spacing 12 pt bezeled / 24 pt borderless, title <15 chars, sidebar ≤2 levels, toolbar ≤3 groups + 1 primary, alerts ≤3 buttons / ≤2-line title, Dynamic Type ≥200% / AX1–AX5.

- [ ] **Step 1: Write the rubric file.** One `##` section per dimension above. Each rule on its own line as `RULE — number/threshold (if any) — rationale — SOURCE_URL`. Where a number is API-sourced not HIG (16 pt margin / 8 pt grid / 45–75 chars), explicitly mark `(API default, NOT HIG)` and do not attach a HIG URL. Start the file with a one-paragraph header stating the grounding rule ("cite HIG for design rules; never assert from memory") and a fetch-date stamp `Verified: 2026-06-16`.

- [ ] **Step 2: Verify every numeric rule carries a source.** Run:
```bash
cd /Users/serkan/swiftui-ios
# every line containing a digit-colon-digit ratio or a 'pt' number must contain a URL or the (API default…) marker
awk '/[0-9]+(\.[0-9]+)?:[0-9]|[0-9]+ ?pt/ && !/developer\.apple\.com|API default/' references/_shared/hig-design-rubric.md
```
Expected: **no output** (every quantified rule is sourced or marked API-default).

- [ ] **Step 3: Verify no blacklisted myth leaked in.** Run:
```bash
grep -niE 'max .*(3|5) tabs|3-5 tabs|avoid pure black|45-75|45–75|0\.3 ?s' references/_shared/hig-design-rubric.md
```
Expected: **no output** (or only inside an explicit "do NOT claim" caveat — verify by eye if any line matches).

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add references/_shared/hig-design-rubric.md
git commit -m "feat(design-kb): add HIG design rubric (cited, verified)"
```

---

## Task 2: KB — `liquid-glass-design.md`

**Files:**
- Create: `/Users/serkan/swiftui-ios/references/_shared/liquid-glass-design.md`

**Interfaces:**
- Produces: reference doc consumed by Task 10 (glass tells), Task 12 (reviewer), and cross-linked from `skills/audit-swiftui-liquid-glass`. Section anchors: `## Core principle`, `## Where glass belongs`, `## Concentricity & containers`, `## Morphing`, `## Tinting`, `## Legibility & accessibility`, `## Light/dark & adaptivity`, `## Anti-patterns`, `## Adoption`.

**Content source:** spec §3 (`liquid-glass-design.md` bullet) + research thread 1 (the nine-topic Liquid Glass brief, WWDC25 219/356/323/284 + HIG Materials/Layout + Adopting Liquid Glass). This is the *design language*; API names (`GlassEffectContainer`, `glassEffectID`, `ToolbarSpacer`, `scrollEdgeEffectStyle`, `UIDesignRequiresCompatibility`) appear only to make a rule checkable.

- [ ] **Step 1: Write the file** with the nine `##` sections above; each rule `RULE — rationale — SOURCE_URL`. Include the `## Anti-patterns` design-smell list (glass-on-glass, glass-in-content, over-tint, hardcoded radii/sizes, custom bar/sheet backgrounds, alpha-fade) and the `## Adoption` rule that good adoption *removes* custom chrome and that `UIDesignRequiresCompatibility` is a deliberate opt-out to flag, not fix. Header states the cite-don't-assert rule + `Verified: 2026-06-16`.

- [ ] **Step 2: Verify cross-link consistency** with the existing glass audit. Run:
```bash
cd /Users/serkan/swiftui-ios
grep -c 'developer.apple.com' references/_shared/liquid-glass-design.md   # expect >= 8 distinct sources
ls skills/audit-swiftui-liquid-glass/references/   # confirm the API audit still exists (we complement, not replace)
```
Expected: ≥ 8 source URLs; the existing glass skill untouched.

- [ ] **Step 3: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add references/_shared/liquid-glass-design.md
git commit -m "feat(design-kb): add Liquid Glass design language (iOS 26, cited)"
```

---

## Task 3: KB — `ux-smell-catalog.md`

**Files:**
- Create: `/Users/serkan/swiftui-ios/references/_shared/ux-smell-catalog.md`

**Interfaces:**
- Produces: reference doc consumed by Task 12 (the vision critique's qualitative pass). Section anchors: `## Native vs not`, `## Hierarchy`, `## Affordances`, `## Consistency`, `## States`, `## Modality & flow`, `## Density & touchability`, `## Forms & input`, `## Accessibility UX`.

**Content source:** spec §3 (`ux-smell-catalog.md` bullet) + research thread 3 (the iOS UX smell catalog). Each entry: `SMELL — why it's bad — how to detect (pixels and/or code) — source`. The "how to detect" must be practical for a model looking at a screenshot + code.

- [ ] **Step 1: Write the file** with the nine `##` sections; each smell as the four-part bullet. Keep the screenshot-detectable cues concrete (e.g. FAB = "floating circle, single glyph, drop shadow, pinned bottom-trailing"; missing large title = "only a small centered title, no large left-aligned heading").

- [ ] **Step 2: Verify structure.** Run:
```bash
cd /Users/serkan/swiftui-ios
grep -c '^## ' references/_shared/ux-smell-catalog.md   # expect 9
grep -ciE 'detect' references/_shared/ux-smell-catalog.md  # every smell has a detect cue; expect a high count
```
Expected: 9 sections; a detect cue on essentially every smell.

- [ ] **Step 3: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add references/_shared/ux-smell-catalog.md
git commit -m "feat(design-kb): add iOS UX smell catalog"
```

---

## Task 4: KB — `design-finding-schema.md`

**Files:**
- Create: `/Users/serkan/swiftui-ios/references/_shared/design-finding-schema.md`

**Interfaces:**
- Produces: the byte-stable finding format + scoring contract consumed by Task 12 and Task 13. Defines the exact field set and the Design Score computation the reviewer MUST follow.

**Content source:** spec §3 (`design-finding-schema.md` bullet) + research thread 5 part B (UICrit/Nielsen patterns).

- [ ] **Step 1: Write the file** defining:
  - **Finding fields** (exact keys): `rule_id`, `severity` (0–4), `category` (one of: Layout, Typography, ColorContrast, Hierarchy, AffordanceControls, Navigation, LiquidGlass, Motion, States, AccessibilityVisual), `screen`, `variant` (e.g. `dark/axxxl`), `region` (bbox `[x,y,w,h]` or element label), `expected`, `gap`, `fix`, `evidence` (screenshot path), `source` (HIG URL), `tier` (`deterministic`|`vision`).
  - **Severity scale:** Nielsen 0–4 verbatim (0 not-a-problem … 4 catastrophe) for vision findings; deterministic hits also carry an objective name (minor/moderate/serious/critical).
  - **Design Score:** per-category 0–100 → weighted overall 0–100; deterministic violations are hard deductions; vision findings weighted by severity; **re-scored last** for before/after delta. Specify the exact weighting table (equal weight default; document the formula so two runs match).
  - **Multi-screen aggregation:** MAX severity, tie-break by occurrence count.
  - **Dashboard contract:** `swiftui-design/_DESIGN_SUMMARY.md` layout (headline score, per-category breakdown, master finding table sorted severity-desc with evidence refs).

- [ ] **Step 2: Verify the schema is self-consistent.** Run:
```bash
cd /Users/serkan/swiftui-ios
grep -E 'rule_id|severity|category|expected|gap|fix|evidence|source|tier' references/_shared/design-finding-schema.md | head
grep -ciE 'design score|0-100|0–100' references/_shared/design-finding-schema.md  # scoring section present
```
Expected: all field names present; scoring section present.

- [ ] **Step 3: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add references/_shared/design-finding-schema.md
git commit -m "feat(design-kb): add design finding schema + Design Score contract"
```

---

## Task 5: KB — `design-claims-blacklist.md`

**Files:**
- Create: `/Users/serkan/swiftui-ios/references/_shared/design-claims-blacklist.md`

**Interfaces:**
- Produces: the design analogue of `hallucination-blacklist.md`, consumed by Task 12 (reviewer must not emit these) and Task 1's verify step.

**Content source:** spec §3 (`design-claims-blacklist.md` bullet) + the "debunked-by-current-HIG claims" lists the research agents flagged.

- [ ] **Step 1: Write the file** as a table: `MYTH | CORRECT FACT | SOURCE`. Include at minimum: "max 3–5 tabs on iPhone" → HIG says "five or fewer" only for *customizable* tab sets; "avoid pure black backgrounds" → not stated; "45–75 characters per line" → not in HIG; "0.3 s standard animation / named easing" → Apple publishes no iOS number; "large title only at root" → not stated; a "chrome" material → does not exist (materials are ultraThin/thin/regular/thick); "HIG mandates 16 pt margins / 8 pt grid" → those are UIKit/SwiftUI API defaults, not HIG.

- [ ] **Step 2: Verify completeness against the rubric.** Run:
```bash
cd /Users/serkan/swiftui-ios
grep -ciE 'tabs|pure black|45|easing|0\.3|chrome|8 ?pt|16 ?pt|large title' references/_shared/design-claims-blacklist.md
```
Expected: a hit for each myth class (≥ 6).

- [ ] **Step 3: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add references/_shared/design-claims-blacklist.md
git commit -m "feat(design-kb): add design-claims blacklist (debunked HIG myths)"
```

---

## Task 6: Capture harness — build/boot/screenshot skeleton + degradation

**Files:**
- Create: `/Users/serkan/swiftui-ios/scripts/swiftui-capture.sh` (chmod +x)

**Interfaces:**
- Produces: `swiftui-capture.sh <project-dir> [--out DIR] [--device NAME] [--no-idb]`. Emits `<out>/capture.json` (`{status, project, device, screens:[...], failures:[...]}`) and `<out>/screens/*.png`. Default `--out` = `<project-dir>/swiftui-design`. Consumed by Task 8 (navigation), Task 9 (previews), Task 12 (reviewer). Exit 0 on success or clean degradation; never crashes the caller.

- [ ] **Step 1: Write the failing test (a smoke script).** Create `/Users/serkan/swiftui-ios/tests/capture-smoke.sh`:
```bash
#!/usr/bin/env bash
# Smoke: degradation path must emit valid capture.json with status=unavailable when given a non-buildable dir.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$ROOT/scripts/swiftui-capture.sh" "$TMP" --out "$TMP/out" >/dev/null 2>&1
jq -e '.status=="unavailable"' "$TMP/out/capture.json" >/dev/null \
  && echo "capture-smoke: degradation OK ✓" || { echo "capture-smoke: FAIL"; exit 1; }
```

- [ ] **Step 2: Run it to verify it fails.** Run:
```bash
cd /Users/serkan/swiftui-ios && bash tests/capture-smoke.sh
```
Expected: FAIL (script not yet present / no capture.json).

- [ ] **Step 3: Implement the skeleton.** Write `scripts/swiftui-capture.sh` following the `swiftui-lint.sh` header/arg conventions. It must: resolve args; check `xcodebuild`/`xcrun simctl`/`jq` presence; if Xcode or a simulator is unavailable OR no `.xcodeproj`/`.xcworkspace` found OR build fails → write `{"status":"unavailable","reason":"...","project":...}` to `<out>/capture.json` and exit 0. On success path (deferred to later tasks) it will set `status:"ok"`. Use verified commands: `xcodebuild -list -json`, `simctl list devices available --json`, `xcodebuild build -scheme … -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath <out>/build CODE_SIGNING_ALLOWED=NO`, locate `.app` via `BUILT_PRODUCTS_DIR`, `simctl bootstatus -b`, `simctl install`, `simctl launch`, `simctl io <udid> screenshot`. For this task, implement through "boot + install + launch + one screenshot named `home`" on the success path; everything beyond is later tasks.

- [ ] **Step 4: Run the smoke test to verify degradation passes.** Run:
```bash
cd /Users/serkan/swiftui-ios && bash tests/capture-smoke.sh
```
Expected: `capture-smoke: degradation OK ✓`.

- [ ] **Step 5: Run the live success path against LifeRunner.** Run:
```bash
cd /Users/serkan/swiftui-ios
bash scripts/swiftui-capture.sh /Users/serkan/life-runner/ios --out /tmp/cap1 2>&1 | tail -5
jq '.status' /tmp/cap1/capture.json; ls /tmp/cap1/screens/ 2>/dev/null
```
Expected: `"ok"` and at least `home.png` present (the app builds; if the sandbox blocks a sim boot, document it and accept the degradation path — note in the commit).

- [ ] **Step 6: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add scripts/swiftui-capture.sh tests/capture-smoke.sh
git commit -m "feat(capture): swiftui-capture.sh skeleton — build/boot/screenshot + degradation"
```

---

## Task 7: Capture harness — variant matrix (light/dark × Dynamic Type) + clean status bar

**Files:**
- Modify: `/Users/serkan/swiftui-ios/scripts/swiftui-capture.sh`

**Interfaces:**
- Consumes: the Task 6 success path. Produces: per-screen variant PNGs named `<screen>__<appearance>__<type>.png` and a `screens[].variants` array in `capture.json`.

- [ ] **Step 1: Add status-bar override + variant loop.** After install, before screenshots, run `xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100` and `xcrun simctl privacy "$UDID" grant all "$BUNDLE_ID" || true`. Wrap the screenshot step in two loops: `for APPEARANCE in light dark` (`simctl ui "$UDID" appearance "$APPEARANCE"`) × `for SIZE in large accessibility-extra-extra-extra-large` (`simctl ui "$UDID" content_size "$SIZE" || true`), relaunching the app (`simctl launch --terminate-running-process`) between changes so UIKit re-reads them. Add a `--variants minimal|full` flag (default `minimal` = light+dark at `large`; `full` adds the AX type).

- [ ] **Step 2: Run against LifeRunner with full variants.** Run:
```bash
cd /Users/serkan/swiftui-ios
bash scripts/swiftui-capture.sh /Users/serkan/life-runner/ios --out /tmp/cap2 --variants full 2>&1 | tail -3
ls /tmp/cap2/screens/ | sort
```
Expected: files like `home__light__large.png`, `home__dark__large.png`, `home__light__axxxl.png`, `home__dark__axxxl.png` (or the degradation note if sim boot is blocked).

- [ ] **Step 3: Verify capture.json records variants.** Run:
```bash
jq '.screens[0].variants' /tmp/cap2/capture.json
```
Expected: an array of the variant names captured.

- [ ] **Step 4: Re-run the smoke test (no regression).** Run:
```bash
cd /Users/serkan/swiftui-ios && bash tests/capture-smoke.sh
```
Expected: `capture-smoke: degradation OK ✓`.

- [ ] **Step 5: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add scripts/swiftui-capture.sh
git commit -m "feat(capture): light/dark × Dynamic Type variant matrix + clean status bar"
```

---

## Task 8: Capture harness — navigation (deep-link + idb AX-crawl + manifest)

**Files:**
- Modify: `/Users/serkan/swiftui-ios/scripts/swiftui-capture.sh`

**Interfaces:**
- Consumes: Task 7. Produces: multi-screen capture driven by `<out>/screens.manifest.json` if present, else auto-explore; writes a discovered manifest back. Adds `wait_for_idle`. Honors `--no-idb`.

- [ ] **Step 1: Add the manifest + navigation logic.** Implement:
  - `wait_for_idle()` — poll `idb ui describe-all --udid "$UDID" --json | shasum` until stable for 2 polls or 20 tries (fallback `sleep 1` if idb absent).
  - If `<out>/screens.manifest.json` exists: iterate entries `{name, deeplink?, taps?[], variants?}`; for `deeplink` use `simctl openurl`, for `taps` use `idb ui tap` sequences; screenshot per entry across its variants.
  - Else auto-explore: try registered URL schemes via `simctl openurl` for known routes; if `idb` available, `idb ui describe-all --json`, tap tappable element-frame centers, re-describe, screenshot each new state (cap depth/count, log the cap — never silent). Write the discovered screens to `screens.manifest.json`.
  - `--no-idb` skips the AX-crawl (deep-links + manifest only) and logs reduced coverage.

- [ ] **Step 2: Test manifest-driven capture.** Create a tiny manifest and run:
```bash
cd /Users/serkan/swiftui-ios
mkdir -p /tmp/cap3
printf '{"screens":[{"name":"home"}]}' > /tmp/cap3/screens.manifest.json
bash scripts/swiftui-capture.sh /Users/serkan/life-runner/ios --out /tmp/cap3 2>&1 | tail -3
jq '.screens | length' /tmp/cap3/capture.json
```
Expected: ≥ 1 screen captured; coverage note printed if idb absent.

- [ ] **Step 3: Verify a discovered manifest is written on auto-explore.** Run (fresh out dir, no manifest):
```bash
cd /Users/serkan/swiftui-ios
rm -rf /tmp/cap4
bash scripts/swiftui-capture.sh /Users/serkan/life-runner/ios --out /tmp/cap4 2>&1 | tail -3
test -f /tmp/cap4/screens.manifest.json && echo "manifest written ✓" || echo "(no manifest — check idb availability note)"
```
Expected: manifest written (or an explicit reduced-coverage note when idb is unavailable — acceptable degradation).

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add scripts/swiftui-capture.sh
git commit -m "feat(capture): navigation — deep-link + idb AX-crawl + manifest override"
```

---

## Task 9: Capture harness — `#Preview` snapshots

**Files:**
- Modify: `/Users/serkan/swiftui-ios/scripts/swiftui-capture.sh`

**Interfaces:**
- Consumes: Task 8. Produces: `<out>/previews/*.png` (+ JSON sidecars) when SnapshotPreviews is wired, behind a `--previews` flag; records `previews_status` in `capture.json`.

- [ ] **Step 1: Add the `--previews` path.** When `--previews` is passed: detect whether the project links `EmergeTools/SnapshotPreviews` (a test target importing `SnapshottingTests`). If yes, run `TEST_RUNNER_SNAPSHOTS_EXPORT_DIR="<out>/previews" xcodebuild test -scheme <scheme> -destination 'platform=iOS Simulator,id=<UDID>'` and collect the PNG+JSON. If not present, set `capture.json.previews_status = "not-wired"` with a one-line how-to (add the SPM package + a `SnapshotTest` subclass) and continue — do NOT fail. Note `ImageRenderer` is the documented fallback for self-contained synchronous components only.

- [ ] **Step 2: Test the not-wired path.** Run:
```bash
cd /Users/serkan/swiftui-ios
bash scripts/swiftui-capture.sh /Users/serkan/life-runner/ios --out /tmp/cap5 --previews 2>&1 | tail -3
jq '.previews_status' /tmp/cap5/capture.json
```
Expected: `"not-wired"` (LifeRunner doesn't link SnapshotPreviews) with guidance — clean, non-fatal.

- [ ] **Step 3: Re-run smoke (no regression).** Run:
```bash
cd /Users/serkan/swiftui-ios && bash tests/capture-smoke.sh
```
Expected: `capture-smoke: degradation OK ✓`.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add scripts/swiftui-capture.sh
git commit -m "feat(capture): optional #Preview snapshots via SnapshotPreviews"
```

---

## Task 10: Deterministic tier — static design-lint tells + fixtures

**Files:**
- Create: `/Users/serkan/swiftui-ios/skills/audit-swiftui-design-review/lint/grep-tells.tsv`
- Create: `/Users/serkan/swiftui-ios/skills/audit-swiftui-design-review/lint/ast-grep/dr-fab.yml` (optional structural)
- Create: `/Users/serkan/swiftui-ios/tests/fixtures/design-review.swift`
- Create: `/Users/serkan/swiftui-ios/tests/fixtures/design-review.expect`

**Interfaces:**
- Consumes: the shared `swiftui-lint.sh` engine (TSV format: `id <TAB> severity <TAB> ERE <TAB> message`). Produces: `dr-*` findings (`tier: deterministic`) for Task 12. The grep tier stands alone.

**Content source:** spec §5 (static design-lint list) + the greppable smells from the KB (ux-smell-catalog / hig-design-rubric).

- [ ] **Step 1: Write the failing fixture + expect.** `design-review.swift` contains known violations: a hardcoded `.font(.system(size: 22))`; an icon-only `Button { } label: { Image(systemName: "gear") }` with no `.accessibilityLabel`; a FAB (`Circle().shadow(...)` pinned bottom-trailing in a `ZStack`); a `TextField("Email", text: $e)` with no `.keyboardType`; a `.foregroundColor(.black)`. `design-review.expect` lists the rule_ids that must fire (e.g. `dr-fontsize`, `dr-iconbtn-label`, `dr-fab`, `dr-keyboardtype`, `dr-hardcoded-color`).

- [ ] **Step 2: Run selftest to verify it fails.** Run:
```bash
cd /Users/serkan/swiftui-ios && bash scripts/audit-selftest.sh 2>&1 | tail -3
```
Expected: FAIL for `design-review` (rules not defined yet).

- [ ] **Step 3: Write the grep tells.** Author `grep-tells.tsv` with a `dr-*` rule per fixture violation, each `warn`/`adv` severity (none `hard` — design smells are not ship-blockers), each message phrased LOCATE-only ("READ the screenshot/code and confirm"), citing the KB. Add the optional `dr-fab.yml` ast-grep rule (structural FAB shape) marked optional. Example rows (tab-separated):
```
dr-fontsize	warn	\.font\(\.system\(size:	hardcoded font size — prefer a built-in text style (Body 17pt) so Dynamic Type works. See hig-design-rubric.md#typography.
dr-iconbtn-label	warn	Image\(systemName:	icon-only control candidate — if it's the sole label of a Button with no .accessibilityLabel, VoiceOver reads the symbol name. See hig-design-rubric.md#accessibility-visual.
dr-fab	warn	Circle\(\)	possible Android FAB — a floating circular shadowed button bottom-trailing is non-idiomatic on iOS. See ux-smell-catalog.md#native-vs-not.
dr-keyboardtype	warn	TextField\(	text field — confirm .keyboardType/.textContentType match the field semantics. See ux-smell-catalog.md#forms-input.
dr-hardcoded-color	adv	\.foregroundColor\(\.(black|white)\)	hardcoded color — prefer semantic colors that adapt to dark mode. See hig-design-rubric.md#color-contrast.
```

- [ ] **Step 4: Run selftest to verify it passes.** Run:
```bash
cd /Users/serkan/swiftui-ios && bash scripts/audit-selftest.sh 2>&1 | tail -2
```
Expected: `audit-selftest: <N> expected rules fired across <M> fixtures ✓` (count increased; design-review fixture green).

- [ ] **Step 5: Verify the tells stand alone without ast-grep.** Run:
```bash
cd /Users/serkan/swiftui-ios
bash scripts/swiftui-lint.sh --skill audit-swiftui-design-review --no-ast --quiet tests/fixtures/design-review.swift 2>/dev/null | jq '.counts'
```
Expected: all `dr-*` rule_ids present from the grep tier alone.

- [ ] **Step 6: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add skills/audit-swiftui-design-review/lint tests/fixtures/design-review.swift tests/fixtures/design-review.expect
git commit -m "feat(design-det): static design-lint tells + selftest fixture"
```

---

## Task 11: Deterministic tier — `performAccessibilityAudit` runner (optional)

**Files:**
- Create: `/Users/serkan/swiftui-ios/scripts/a11y-audit/README.md`
- Create: `/Users/serkan/swiftui-ios/scripts/a11y-audit/DesignA11yAuditTemplate.swift`
- Create: `/Users/serkan/swiftui-ios/scripts/a11y-audit/run.sh`

**Interfaces:**
- Produces: `run.sh <project-dir> [--out DIR]` → emits `<out>/a11y-audit.json` (`{status, findings:[{type, element, screenshot}]}`) by running an XCUITest that calls `try app.performAccessibilityAudit()`. Optional: when no test target can be added, `status:"not-wired"` with instructions. Consumed by Task 12 as `tier: deterministic` objective findings.

**Content source:** spec §5 (rendered objective checks) + research thread 4/5 (`performAccessibilityAudit` audit types: contrast, dynamicType, hitRegion, textClipped, sufficientElementDescription, elementDetection, trait).

- [ ] **Step 1: Write the XCUITest template** (`DesignA11yAuditTemplate.swift`) that launches the app and runs `try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .hitRegion, .textClipped, .sufficientElementDescription])`, attaching each issue's element screenshot. Include a header comment: this is a template to drop into the project's UI test target.

- [ ] **Step 2: Write `run.sh`** to detect a UI test target; if present, `xcodebuild test` the audit and convert the `.xcresult` issues to `a11y-audit.json`; else write `{"status":"not-wired"}` + how-to. Never fail the caller.

- [ ] **Step 3: Test the not-wired path.** Run:
```bash
cd /Users/serkan/swiftui-ios
bash scripts/a11y-audit/run.sh /Users/serkan/life-runner/ios --out /tmp/a11y 2>&1 | tail -2
jq '.status' /tmp/a11y/a11y-audit.json
```
Expected: `"not-wired"` (or `"ok"` with findings if a test target exists) — clean either way.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add scripts/a11y-audit
git commit -m "feat(design-det): optional performAccessibilityAudit runner"
```

---

## Task 12: Reviewer skill — `audit-swiftui-design-review`

**Files:**
- Create: `/Users/serkan/swiftui-ios/skills/audit-swiftui-design-review/SKILL.md`
- Create: `/Users/serkan/swiftui-ios/skills/audit-swiftui-design-review/scripts/design-capture.sh`
- Create: `/Users/serkan/swiftui-ios/skills/audit-swiftui-design-review/references/README.md` (pointers into the shared KB)

**Interfaces:**
- Consumes: `scripts/swiftui-capture.sh` (Task 6–9), the deterministic tells (Task 10) + a11y runner (Task 11), and the KB (Tasks 1–5). Produces: `swiftui-design/<screen>/NN-slug.md` findings + `swiftui-design/_DESIGN_SUMMARY.md` per `design-finding-schema.md`.

- [ ] **Step 1: Write `SKILL.md`** with frontmatter (`name: audit-swiftui-design-review`, a ≤1024-char description with no `<`/`>` covering "audit my iOS app's design/UX," "is this screen HIG-compliant," "rate my UI," "review my Liquid Glass design," AUDIT-ONLY/iOS-only/SwiftUI-only) and a body documenting the CAPTURE→CHECK→CRITIQUE→SCORE workflow verbatim from spec §6: run capture (or degrade to code-only with a banner), ingest deterministic findings, critique each screenshot per KB dimension **one category per pass** using `expected → gap → fix`, cite the KB source, honor the blacklist, 100%-certainty gate, compute the Design Score, write the dashboard, optional FIX+re-capture. Add a Reference Routing table pointing into the 5 KB files + `cross-ref-graph.md`. Add the thin `design-capture.sh` (calls `${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-capture.sh "$@"`).

- [ ] **Step 2: Validate the skill.** Run:
```bash
cd /Users/serkan/swiftui-ios && python3 scripts/validate-skills.py 2>&1 | tail -2
```
Expected: `validate-skills: <N> skills OK + manifests valid` (count +1; name==dir; description clean).

- [ ] **Step 3: Add the STEER signal.** Append a `design-review` row to `scripts/audit-signals.tsv` so STEER marks it relevant on any SwiftUI project (mode `always`, since visual review applies whenever buildable; the skill self-degrades). Run:
```bash
cd /Users/serkan/swiftui-ios
export SWIFTUI_CTX_CATALOG="$PWD/catalog"
python3 scripts/audit-scan.py tests/fixtures 2>/dev/null | jq '.relevant_skills | index("audit-swiftui-design-review")'
```
Expected: a non-null index (the skill is selected).

- [ ] **Step 4: Dogfood the reviewer end-to-end on LifeRunner.** Run the capture, then perform the skill's critique manually against the produced screenshots (the skill is model-executed; verify the artifacts exist and the workflow is followed):
```bash
cd /Users/serkan/swiftui-ios
bash scripts/swiftui-capture.sh /Users/serkan/life-runner/ios --out /Users/serkan/life-runner/ios/swiftui-design --variants full 2>&1 | tail -3
ls /Users/serkan/life-runner/ios/swiftui-design/screens/ 2>/dev/null | head
```
Expected: screenshots exist (or a documented degradation). Confirm the SKILL.md instructs grounding every finding in a KB citation and refusing blacklisted myths.

- [ ] **Step 5: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add skills/audit-swiftui-design-review/SKILL.md skills/audit-swiftui-design-review/scripts skills/audit-swiftui-design-review/references scripts/audit-signals.tsv
git commit -m "feat(design-review): add audit-swiftui-design-review skill + STEER signal"
```

---

## Task 13: Orchestrator integration — Wave 9 + resolve the "HIG review skill" pointer

**Files:**
- Modify: `/Users/serkan/swiftui-ios/skills/audit-ios-swiftui-full/SKILL.md`

**Interfaces:**
- Consumes: Task 12's skill name. Produces: the orchestrator dispatches the reviewer last and references it by name.

- [ ] **Step 1: Add Wave 9.** In the run-order table, add `| **9 · Visual design** | audit-swiftui-design-review | Reads the whole rendered app + all prior findings; pixel-level HIG/Liquid-Glass/UX critique + Design Score. Requires a buildable project; degrades to code-only. |`. Update the "34 skills total" prose to note the visual reviewer as a final cross-cutting pass.

- [ ] **Step 2: Resolve the dangling pointer.** Find the "HIG review skill" reference in the boundaries/routing prose and replace it to name `audit-swiftui-design-review`. Run:
```bash
cd /Users/serkan/swiftui-ios
grep -n 'HIG review skill\|audit-swiftui-design-review' skills/audit-ios-swiftui-full/SKILL.md
```
Expected: the old "HIG review skill" phrasing now resolves to the named skill.

- [ ] **Step 3: Re-validate skills.** Run:
```bash
cd /Users/serkan/swiftui-ios && python3 scripts/validate-skills.py 2>&1 | tail -1
```
Expected: still `… skills OK + manifests valid`.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add skills/audit-ios-swiftui-full/SKILL.md
git commit -m "feat(design-review): wire reviewer as orchestrator Wave 9 (resolve HIG-review pointer)"
```

---

## Task 14: Ship — version bump + docs + final green check

**Files:**
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `docs/superpowers/SDD-PROGRESS.md`

**Interfaces:**
- Consumes: all prior tasks. Produces: a shippable v0.5.0 with the layer documented.

- [ ] **Step 1: Bump versions to 0.5.0.** Run:
```bash
cd /Users/serkan/swiftui-ios
sed -i '' 's/"version": "0.4.1"/"version": "0.5.0"/' .claude-plugin/plugin.json
sed -i '' 's/"version": "0.4.1"/"version": "0.5.0"/g' .claude-plugin/marketplace.json
jq -e . .claude-plugin/plugin.json >/dev/null && jq -e . .claude-plugin/marketplace.json >/dev/null && echo "manifests valid ✓"
```
Expected: `manifests valid ✓`.

- [ ] **Step 2: Document the layer.** Add a README section ("Design & UX review — pixel-first") describing `audit-swiftui-design-review` + `swiftui-capture.sh` + the Design Score, and append a SDD-PROGRESS entry ("Design & UX layer — Phase 1 (v0.5.0)") summarizing the 4 components + the deferred Phase 2 plan.

- [ ] **Step 3: Full green check.** Run:
```bash
cd /Users/serkan/swiftui-ios
export SWIFTUI_CTX_CATALOG="$PWD/catalog"
python3 scripts/validate-skills.py 2>&1 | tail -1
bash scripts/audit-selftest.sh 2>&1 | tail -1
bash tests/capture-smoke.sh
bash -n scripts/swiftui-capture.sh && echo "capture syntax OK"
```
Expected: validate-skills OK; selftest ✓; capture-smoke ✓; capture syntax OK.

- [ ] **Step 4: Commit.**
```bash
cd /Users/serkan/swiftui-ios
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md docs/superpowers/SDD-PROGRESS.md
git commit -m "chore(design-review): ship Design & UX layer Phase 1 (v0.5.0) + docs"
```

---

## Self-Review

**Spec coverage (Phase 1 = spec §3–6, §8–11):**
- KB (spec §3) → Tasks 1–5 ✓
- Capture harness (spec §4) → Tasks 6–9 ✓
- Deterministic tier (spec §5) → Tasks 10–11 ✓
- Vision-critique skill + Design Score (spec §6) → Tasks 12–13 ✓
- Determinism/boundaries/house-rules (spec §8–11) → Global Constraints + per-task verify steps ✓
- Phase 2 (spec §7) → deferred to its own plan (stated in handoff) ✓

**Placeholder scan:** No "TBD/implement later/add error handling"; doc-content tasks point to their verified research source + give exact structure + a concrete verification command (appropriate for content generation, not vague). Code/script steps show real commands and TSV/flag content.

**Type/name consistency:** `swiftui-capture.sh` flags (`--out`, `--device`, `--variants`, `--no-idb`, `--previews`) and `capture.json` keys (`status`, `screens[].variants`, `previews_status`) are consistent across Tasks 6–9 and consumed by Task 12. Skill name `audit-swiftui-design-review` is identical in Tasks 10, 12, 13, 14. `dr-*` rule_ids defined in Task 10 are the ones the reviewer ingests in Task 12. KB filenames are identical across Tasks 1–5 and the Reference Routing in Task 12.

---

## Notes for the executor

- **The capture harness needs a real Xcode + Simulator.** If this environment's sandbox blocks `simctl boot`, the *degradation* path is still fully testable (Task 6 smoke), and the success-path steps should be run where a simulator is available; document any blocked step in its commit rather than faking output.
- **The reviewer skill is model-executed**, so its "test" is artifact + workflow verification (the screenshots exist, the SKILL.md enforces citation + blacklist + per-category passes), not a unit assertion.
- **Phase 2 (design-aware generation)** is intentionally out of this plan — write `docs/superpowers/plans/2026-06-16-swiftui-ios-design-ux-layer-phase2.md` after Phase 1 lands and is dogfooded.
