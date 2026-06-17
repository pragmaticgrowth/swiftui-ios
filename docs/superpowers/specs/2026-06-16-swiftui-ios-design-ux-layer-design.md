# swiftui-ios — Design & UX layer (design spec)

**Date:** 2026-06-16
**Status:** Draft — pending user review
**Author:** Claude (brainstormed with the user; research-grounded)
**Design source:** User request — "enhance it with new Liquid Glass design, SwiftUI, and Apple UX… my agent will be super powerful for UI and UX… all best-practices design perspective." Brainstormed to: **pixel-first**, **review + generate**, **simulator-run + preview-snapshots**, **auto-explore + manifest override**. Builds on the v0.4.1 plugin (34 static `audit-swiftui-*` skills + orchestrator + 4 write/lookup skills).

---

## 1. Context & goal

The plugin today is **34 technical-correctness audits** (does the API work, is it gated, will it crash) + 4 write/lookup skills. Every skill reads *code*; nothing ever renders or evaluates *design quality*. There is a literal hole: `audit-ios-swiftui-full/SKILL.md` routes HIG/snapshot review to **"the HIG review skill"** — which does not exist. Research confirmed the wider gap: **no tool enforces Apple HIG as a named ruleset; SF-font and system-spacing are enforced nowhere.** This plugin can own that.

**Goal:** a **Design & UX layer** that makes the agent evaluate *and* produce best-practice iOS design — grounded in Apple's HIG and the iOS 26 Liquid Glass design language, judged on **rendered pixels**, not just code. Two halves:

- **Review (Phase 1):** build the app, screenshot every screen across light/dark + Dynamic Type, run deterministic objective checks, then critique the pixels against a cited HIG/Liquid-Glass knowledge base, ending in a 0–100 **Design Score** dashboard — the design analogue of the existing `ios-idiomaticness` score.
- **Generate (Phase 2):** wire the same knowledge base into `build-ios-swiftui` + `ios-app-patterns` so new UI is HIG-idiomatic and Liquid-Glass-modern by default, and can self-check by rendering what it just wrote.

**The pipeline (new) extends the plugin's existing discipline to pixels:**

| Existing static audits | New design layer |
|---|---|
| LOCATE (grep/ast-grep) → VERIFY (read + swiftui-ctx/Sosumi) → REPORT | **CAPTURE** (build→boot→navigate→screenshot) → **CHECK** (deterministic objective) → **CRITIQUE** (vision, KB-grounded) → **SCORE** |

**Why hybrid (the load-bearing research finding):** VLM-only design critique overlaps human experts only ~21% and hallucinates false positives (arXiv 2506.16345). So objective, numeric facts (contrast ratio, 44 pt hit-targets, clipped text, Dynamic Type breakage) are produced by **deterministic checks** (Apple even ships `performAccessibilityAudit` for exactly these), and the **vision model is reserved for subjective judgment** (hierarchy, balance, affordance, glass placement, "feels native"). This mirrors LOCATE-never-decides: the deterministic tier locates objective violations; the model judges design against cited evidence and renders the verdict.

**Success criteria (Phase 1):**

1. From a buildable iOS project, `bash scripts/swiftui-capture.sh <proj>` produces a deterministic `swiftui-design/screens/` PNG set (≥ light+dark, default+AX Dynamic Type) + a `screens.manifest.json`, app-agnostic (no code added to the target for the crawl path), degrading with a clear message when the project can't build or no simulator is available.
2. A new skill `audit-swiftui-design-review` consumes those screenshots + the deterministic findings + the KB and emits scored findings (`severity 0–4`, finding = *expected → gap → fix*, each tied to a screenshot region) and a `swiftui-design/_DESIGN_SUMMARY.md` headlined by a 0–100 Design Score with per-category breakdown.
3. Every design *rule* the layer asserts cites a real HIG/WWDC URL from the KB; no rule is asserted from memory; the debunked-myths blacklist (`design-claims-blacklist.md`) is honored (the reviewer must not emit "max 3–5 tabs," "avoid pure black," "45–75 chars/line," a hard layout-pt grid as HIG, etc.).
4. The orchestrator `audit-ios-swiftui-full` gains a final **Visual design** wave that invokes the reviewer; the dangling "HIG review skill" reference resolves to it.
5. `validate-skills.py` stays clean (new skill: name==dir, description ≤1024 chars, no `<`/`>`); `audit-selftest.sh` stays green; the deterministic design-lint tells get fixtures in `tests/fixtures/`. `plugin.json` + `marketplace.json` bumped.

**Success criteria (Phase 2):**

6. `build-ios-swiftui` and `ios-app-patterns` reference the shared KB so generated UI uses system text styles/colors, 44 pt targets, correct Liquid Glass placement, and HIG-correct navigation by default; each can optionally render-and-self-check via the capture harness.

**Out of scope:** Android/macOS; redesigning the 34 static audits (the design layer *complements* them); a hosted/cloud renderer (everything runs against the local Xcode/Simulator); pixel-perfect visual-regression diffing of two builds (that's a different tool — we critique against HIG, not against a golden baseline).

---

## 2. Architecture — reused vs. new

**Reused verbatim:** the plugin's skill shape (frontmatter + AUDIT/role header + workflow + reference routing), `references/_shared/` truth-doc pattern, the finding-schema discipline, `swiftui-ctx` (for grounding *shapes/floors*), Sosumi (for *Apple-doc* prose), and the orchestrator's STEER/wave model. The Design Score reuses the `ios-idiomaticness` meta-scorer pattern (0–100 + per-category, re-scored to show before/after on a fix pass).

**New (4 components for Phase 1, +1 for Phase 2):**

```
┌─ Component 1: Shared Design Knowledge Base (references/_shared/) ──────────────┐
│  hig-design-rubric.md · liquid-glass-design.md · ux-smell-catalog.md           │
│  design-finding-schema.md · design-claims-blacklist.md                         │
│  (single source of truth — BOTH review and generate consume it)                │
└───────────────────────────────────────────────────────────────────────────────┘
        │                                   │
   CAPTURE                              CRITIQUE/GENERATE
        ▼                                   ▼
┌─ Component 2: Capture harness ─┐   ┌─ Component 4: Vision-critique skill ─┐
│  scripts/swiftui-capture.sh    │   │  skills/audit-swiftui-design-review  │
│  build→boot→navigate→shoot     │──▶│  reads PNGs + det. findings + KB     │
│  matrix (light/dark × type)    │   │  → scored findings + Design Score    │
│  + #Preview snapshots          │   └──────────────────────────────────────┘
└────────────────────────────────┘            ▲
        │                                      │
        ▼                                      │
┌─ Component 3: Deterministic check tier ──────┘
│  static design-lint tells (grep/ast-grep) + optional performAccessibilityAudit │
│  objective facts only (contrast, 44pt, clipped, Dynamic Type) — no hallucination│
└───────────────────────────────────────────────────────────────────────────────┘

Phase 2 ─ Component 5: design-aware generation
  build-ios-swiftui + ios-app-patterns consult Component 1, optionally self-check via Component 2.
```

---

## 3. Component 1 — Shared Design Knowledge Base

Five new `references/_shared/` files. Each rule is phrased **checkable**, carries a one-line rationale, and **cites a real HIG/WWDC URL** (the research returned these verbatim and source-verified June 2026). Same anti-hallucination posture as `floors-master.md`/`hallucination-blacklist.md`: never assert a design number from memory; cite the page.

- **`hig-design-rubric.md`** — the checkable HIG rubric, by dimension, with Apple's hard numbers and their source URLs:
  - *Layout & spacing:* respect safe areas/system margins/layout guides; inset controls from edges (no full-width buttons on iOS); align components; most-important top+leading; don't crowd. (Flag: the "16 pt margin / 8 pt grid" numbers are **UIKit/SwiftUI API defaults, NOT the HIG** — attribute to the API, never cite HIG.)
  - *Typography:* the 11 built-in text styles with exact size/leading (Body 17/22, Large Title 34/41, … Caption 2 11/13); default 17 pt, **min 11 pt**; avoid light/ultralight; convey hierarchy via weight/size/color; custom fonts must support Dynamic Type + Bold Text.
  - *Color & contrast:* **4.5:1** for text ≤17 pt, **3:1** at 18 pt/bold (WCAG AA, what Accessibility Inspector uses); **7:1** for custom small text (Dark Mode page); prefer semantic colors; don't hardcode system color values; never color-alone for meaning; custom colors ship light+dark+increased-contrast.
  - *Hit targets & controls:* **44×44 pt** minimum tappable (floor 28×28); **12 pt** padding around bezeled / **24 pt** around borderless; 1–2 prominent buttons per view; visible pressed state; don't make a destructive action the default.
  - *SF Symbols:* prefer over custom glyphs; map standard actions to standard symbols; match weight/scale to adjacent text; one rendering mode per context; system colors so symbols adapt.
  - *Navigation & structure:* tab bar = peer top-level sections, persistent, icon+label; nav stack = hierarchical drill-down, standard back, title **<15 chars**, not the app name; sidebar = **≤2 levels**; toolbar = **≤3 groups, 1 primary trailing action**; modality only with clear benefit, obvious dismiss, **never >1 alert**.
  - *Motion:* purposeful only; brief, gesture-following; honor Reduce Motion (cross-dissolve, no parallax). (Flag: Apple publishes **no** numeric iOS duration/easing — don't assert "0.3 s".)
  - *Accessibility (visual):* contrast both modes; usable at **≥200%** type (AX1–AX5) with no clip/truncate; VoiceOver labels on every control/meaningful image; don't rely on color alone.
  - *States:* never blank while loading (placeholder/skeleton); determinate progress when known; alerts sparingly + jargon-free + ≤3 buttons / ≤2-line title; multi-channel feedback in context.

- **`liquid-glass-design.md`** — the iOS 26 Liquid Glass *design language* (not the API; API names appear only to make a rule checkable). Core principle (glass = floating navigation/chrome layer, defers to content, "lensing" not filling); **where glass belongs** (nav/tab/tool bars, controls, floating accessories) **vs. must not** (content, backgrounds, large fills, table/list); concentricity & containers (concentric corners, one `GlassEffectContainer` since "glass can't sample glass," group by function with spacers); morphing (morph not hard-cut; materialize/dematerialize, not alpha fade; menus spring from source); tinting (emphasis on **one primary action only**, never decorative, never tint-all); legibility/accessibility (Reduce Transparency/Increase Contrast/Reduce Motion must degrade; clear-glass over bright media needs ~35% dim; symbols flip with glass); light/dark (small elements flip, large don't; never hardcode); **anti-patterns** (glass-on-glass, glass-in-content, over-tint, hardcoded radii/sizes, custom bar/sheet backgrounds, alpha-fade); **adoption** (good = *removing* custom chrome, not adding glass everywhere; `UIDesignRequiresCompatibility` = deliberate opt-out, flag as non-adoption).

- **`ux-smell-catalog.md`** — the qualitative layer pure code misses, each as *SMELL → why → how-to-detect (pixels and/or code) → source*: native-vs-not tells (FAB, hamburger primary nav, top tab bar, Material icons/Roboto, missing large title, heavy elevation shadows, iPad-shrunk-on-iPhone, web-wrapper selection callouts); hierarchy (no/!single primary action, flat or cluttered, over-tinting); affordances (untappable-looking controls, ghost buttons, icon-only mystery-meat, swipe-only/long-press-only actions); consistency (mixed type scale/iconography/component styles/casing/nav patterns); empty/loading/error/first-run states; modality & flow (sheet-that-should-push, modal-in-modal, dead-end modal, hidden tab bar); density & touchability (sub-44 targets, content under notch/home-indicator/keyboard, truncation, edge-to-edge text); forms (wrong keyboard, missing AutoFill/`textContentType`, submit-only validation, placeholder-as-label); accessibility UX (breaks at AX5, hardcoded colors in dark mode, color-alone, unlabeled icons).

- **`design-finding-schema.md`** — the byte-stable design-finding format and scoring, borrowing the validated UICrit/Nielsen patterns:
  - *Finding:* `rule_id · severity(0–4) · category · screen · region(bbox or element) · expected → gap → fix · evidence(screenshot path) · source(HIG URL) · tier(deterministic|vision)`.
  - *Severity:* **Nielsen 0–4** (0 not-a-problem … 4 catastrophe) for subjective; deterministic rule hits also carry an objective name (minor/moderate/serious/critical) in parallel.
  - *Design Score:* per-category 0–100 (Layout, Typography, Color/Contrast, Hierarchy, Affordance/Controls, Navigation, Liquid Glass, Motion, States, Accessibility-visual) → weighted overall 0–100; deterministic violations are hard deductions, vision findings are weighted by severity; **re-scored last** for a before/after delta.
  - *Multi-screen aggregation:* a cross-screen issue takes **MAX severity, tie-broken by occurrence count**.
  - *Dashboard `_DESIGN_SUMMARY.md`:* headline score + per-category bars + a master finding table (severity-desc) with thumbnail/region refs.

- **`design-claims-blacklist.md`** — the design analogue of `hallucination-blacklist.md`: myths the reviewer/generator must **never** assert (each with the correct fact + source): "max 3–5 tabs on iPhone" (HIG says only "five or fewer" for *customizable* sets); "avoid pure black backgrounds"; "45–75 characters per line"; "0.3 s standard animation"; "large title only at root"; a "chrome" material; HIG-stated 16 pt margins / 8 pt grid (those are API defaults). Honored by both skills and (where greppable) by the deterministic tier.

> Grounding split, stated once for the whole layer: **HIG/WWDC URLs** are the source for *design rules*; **`swiftui-ctx`** for *real-world shapes/floors/API*; **Sosumi** for *Apple-doc API prose*. A design rule cites HIG; an API/floor cites swiftui-ctx — never crossed.

---

## 4. Component 2 — Capture harness (`scripts/swiftui-capture.sh`)

A new shared script, the pixel analogue of `swiftui-lint.sh`. App-agnostic for the crawl path (no code added to the target). All commands below are **verified against Xcode 26.5 on this machine**.

**Stages:**
1. **Orient:** discover scheme/workspace (`xcodebuild -list -json`) and a simulator destination (`xcrun simctl list devices available --json`); read the deployment target + device idiom; pick an iPhone sim by default (iPad optional).
2. **Build:** `xcodebuild build -scheme … -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath ./build CODE_SIGNING_ALLOWED=NO`; locate the `.app` via `BUILT_PRODUCTS_DIR`; read `CFBundleIdentifier`.
3. **Boot & prep:** `simctl bootstatus -b` (deterministic wait, no sleeps); `status_bar override --time 9:41 …` (clean shots); `privacy grant all` (no permission walls).
4. **Navigate (auto-explore + manifest override):**
   - If a `swiftui-design/screens.manifest.json` exists → drive it deterministically (each entry: route via `simctl openurl <deeplink>` *or* an `idb ui tap` sequence; the variants to capture).
   - Else auto-explore: `simctl openurl` for any registered URL schemes (fast, deterministic) **+** `idb ui describe-all --json` AX-tree crawl (tap element-frame centers, re-describe, screenshot each new state), `wait_for_idle` (AX-tree hash stable) before every shot to avoid mid-animation smears. Writes a discovered manifest back for next time.
5. **Variant matrix per screen:** `simctl ui appearance light|dark` × `simctl ui content_size large|accessibility-extra-extra-extra-large` (Dynamic Type is first-class in simctl) × optional `increase_contrast enabled`; relaunch between appearance/type changes (UIKit reads them at process start); `simctl io <udid> screenshot`.
6. **Preview snapshots (complementary):** `TEST_RUNNER_SNAPSHOTS_EXPORT_DIR=… xcodebuild test` with **EmergeTools/SnapshotPreviews** (auto-discovers every `#Preview`/`PreviewProvider`, exports PNG+JSON sidecar, built-in dark/Dynamic-Type/RTL variants). `ImageRenderer` is a fallback for self-contained synchronous components only (it renders `AsyncImage`/`ScrollView` blank).
7. **Emit:** `swiftui-design/screens/<screen>__<appearance>__<type>.png` + `screens.manifest.json` + a `capture.json` index (what ran, what failed, coverage).

**Degradation (never hard-crash the layer):** no Xcode/sim → emit `capture.json` with `status: unavailable` and a clear message, fall back to **code-only** design-lint (Component 3 static tells still run). `idb` absent → deep-links + manifest only, log reduced coverage (never silently). Auth/empty/async states → mitigations documented (deep-link past auth, seed `get_app_container` data, wait-for-loaded-element).

---

## 5. Component 3 — Deterministic check tier

Objective facts only; produced without the model so they never hallucinate. Two sub-tiers:

- **Static design-lint** (reuses `swiftui-lint.sh`): a `design-*` rule family in the reviewer skill's `lint/grep-tells.tsv` (+ optional ast-grep) for the *greppable* design smells — hardcoded `.font(.system(size:))`, `.foregroundColor`/hardcoded `Color(red:…)` without dark variant, FAB tell (`Circle()`+`.shadow` pinned bottom-trailing in a `ZStack`/overlay), hamburger-as-primary-nav, missing `.accessibilityLabel` on icon-only buttons, glass-in-content/glass-on-glass (cross-linked to `audit-swiftui-liquid-glass`), `.lineLimit(1)` on substantive labels, `TextField` without `.keyboardType`/`.textContentType`. The grep tier stands alone (ast-grep optional), per the house rule.
- **Rendered objective checks** (optional, when a test target can be added/generated): an `performAccessibilityAudit` runner (`scripts/a11y-audit`, XCTest) for the audit types Apple ships — `contrast`, `dynamicType`, `hitRegion` (sub-44 pt), `textClipped`, `sufficientElementDescription`, `elementDetection`, `trait` — each reported with the offending element's screenshot. This is the deterministic backbone for contrast/target/clipping numbers; the vision tier does not re-derive them.

The reviewer **merges** deterministic findings into its report as `tier: deterministic` (high confidence, hard score deductions) and spends the vision pass on what only judgment can see.

---

## 6. Component 4 — Vision-critique skill (`audit-swiftui-design-review`)

A new skill, same shape as the audit family but **pixel-driven**. Workflow:

1. **CAPTURE:** run Component 2 (or consume an existing `swiftui-design/`); if capture is unavailable, run code-only with an explicit "no pixels" banner and reduced confidence.
2. **CHECK:** run/ingest Component 3 deterministic findings.
3. **CRITIQUE (per screen, per variant):** the model reads each screenshot **with the KB in context**, and for each KB dimension emits findings using the *expected → gap → fix* template, **one category per pass** (research: per-criterion prompting cuts hallucination), each tied to a screen region. It must cite the KB rule's source and must not assert blacklisted myths. Confidence gate: report a finding only when the evidence in the pixels (or merged deterministic fact) supports it — uncertain → omit (same 100%-certainty discipline as the static audits).
4. **SCORE:** compute per-category + overall Design Score per `design-finding-schema.md`.
5. **REPORT:** write per-screen findings + `swiftui-design/_DESIGN_SUMMARY.md` (headline score, per-category, master table with screenshot evidence).
6. **FIX (optional, asked + clean tree):** apply safe fixes via the fix-safety protocol, re-capture the touched screens, re-score for a before/after delta.

**Orchestrator integration:** `audit-ios-swiftui-full` gains a final **Wave 9 · Visual design** that invokes this skill after the static waves (it reads the whole rendered app + the prior findings), and the dangling "HIG review skill" pointer is updated to name it. STEER marks it relevant whenever the project is buildable; it degrades to code-only otherwise.

---

## 7. Phase 2 — Component 5: design-aware generation

No new pipeline — wire the **same KB** into the write path so good design is the default, not an afterthought:

- **`build-ios-swiftui`** gains a "Design defaults" section pointing into `hig-design-rubric.md` + `liquid-glass-design.md` + `design-claims-blacklist.md`: generate with system text styles (never `.font(.system(size:))`), semantic colors with dark variants, 44 pt targets, correct Liquid Glass placement (chrome only, one container, emphasis-tint one action), HIG-correct navigation (tab vs stack vs split by size class), and proper empty/loading/error states. After generating a screen, it may **self-check** by rendering via Component 2 and running Component 4 on its own output (close the loop).
- **`ios-app-patterns`** (scaffolds/recipes) gets design-vetted templates: each recipe references the rubric and ships a `#Preview` so the new component is immediately capture-able.
- A small **`design-system.md`** reference (optional) captures the "use the system's scales, don't invent your own" stance the rubric implies, so generated code reaches for system tokens first.

---

## 8. Resolved choices

1. **Hybrid engine, not vision-only.** Objective numbers (contrast/44 pt/clipping/Dynamic Type) come from deterministic checks (`performAccessibilityAudit` + static lint); the model judges subjective design. Rationale: VLM-only ≈21% expert overlap + hallucination (arXiv 2506.16345). Matches LOCATE-never-decides.
2. **App-agnostic capture by default; manifest for determinism.** idb AX-crawl + deep-links need no code in the target; a committed `screens.manifest.json` upgrades to deterministic, complete coverage. (User choice: auto-explore + manifest override.)
3. **Anti-hallucination extends to design.** Every rule cites a HIG/WWDC URL; `design-claims-blacklist.md` bans the popular myths the research explicitly debunked. Design rules cite HIG; API/floors cite swiftui-ctx; never crossed.
4. **Preview snapshots via EmergeTools/SnapshotPreviews**, `ImageRenderer` fallback only — because `ImageRenderer` renders async/scroll content blank.
5. **Naming/packaging:** one new audit skill `audit-swiftui-design-review` (visual; complements, never replaces, the 34 static audits) + one new shared script `scripts/swiftui-capture.sh` + 5 KB files in `references/_shared/` + an optional `scripts/a11y-audit` runner. The reviewer is the orchestrator's missing "HIG review skill."
6. **Determinism:** two runs over the same build produce a structurally identical `swiftui-design/` tree; capture pins device `name=`+`OS=`, fixed status bar, and a stable screen-naming scheme; the Design Score is reproducible given the same screenshots + deterministic findings.
7. **Graceful no-build path:** when the project can't build / no simulator, the layer runs code-only (static design-lint + KB-grounded code review) and says so — never silently claims visual coverage it didn't have.

---

## 9. Build plan — reviewed batches (SDD)

Large; ships in reviewed batches, each implementer→reviewer→fix→ledger, absolute paths (`/Users/serkan/swiftui-ios`).

- **Batch A — KB foundation:** write the 5 `references/_shared/` files from the verified research (rubric, glass, smells, finding-schema, claims-blacklist) with citations. Cheapest, highest-leverage; everything consumes it. Gate: peer-review the citations; no uncited numbers; blacklist complete.
- **Batch B — Capture harness:** `scripts/swiftui-capture.sh` (build→boot→navigate→shoot matrix + manifest + degradation) + the preview-snapshot path. Gate: produces a deterministic PNG set on LifeRunner; degrades cleanly with no Xcode.
- **Batch C — Deterministic tier:** static `design-*` grep tells (+ fixtures so `audit-selftest.sh` covers them) + the optional `performAccessibilityAudit` runner. Gate: selftest green; tells fire on a fixture, quiet on clean.
- **Batch D — Reviewer skill:** `audit-swiftui-design-review` (CAPTURE→CHECK→CRITIQUE→SCORE) + `_DESIGN_SUMMARY.md` + orchestrator Wave 9 wiring + resolve the "HIG review skill" pointer. Gate: validate-skills clean; end-to-end Design Score on LifeRunner with cited findings + screenshot evidence; no blacklisted myths emitted.
- **Batch E — Phase 2 generation:** wire KB into `build-ios-swiftui` + `ios-app-patterns` (+ optional `design-system.md`); self-check loop. Gate: generated sample uses system styles/44 pt/correct glass; renders + scores well via the reviewer.
- **Batch F — Whole-layer review + ship:** dogfood the full layer on LifeRunner, eval task(s), bump `plugin.json`/`marketplace.json` (minor → 0.5.0), update README + SDD-PROGRESS.

---

## 10. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Vision critique hallucinates design issues. | Deterministic tier owns objective facts; per-category prompting; 100%-certainty gate; cite-or-omit; blacklist of myths. |
| Capture is flaky (async/auth/animation). | `wait_for_idle` AX-stability; deep-link past auth; seed app container; `status_bar override`; document every mitigation; never claim coverage not achieved. |
| Project won't build / no simulator (incl. CI). | Code-only fallback with an explicit banner; layer still produces KB-grounded findings. |
| Apple revises HIG numbers / Liquid Glass post-cutoff. | Every rule carries its source URL = a re-check pointer; KB is regenerable from research; values stamped with fetch date. |
| Tool sprawl / drift from plugin conventions. | One new skill + one new script + KB files; reuse `swiftui-lint.sh`, finding-schema, orchestrator patterns; validate-skills + selftest gates each batch. |
| `idb`/SnapshotPreviews are third-party deps. | Both optional; deep-links + simctl screenshot cover the baseline with zero extra installs; reduced coverage logged, never silent. |

---

## 11. Determinism / contract / boundaries

- **Determinism:** identical build + manifest → structurally identical `swiftui-design/` tree and an equivalent `_DESIGN_SUMMARY.md` (pinned device/OS/status-bar/naming).
- **Boundaries:** the reviewer judges design against **HIG**, not against a golden screenshot (not visual-regression); it complements — never duplicates — the 34 static audits (shared seams via `cross-ref-graph.md`, e.g. glass design ↔ `audit-swiftui-liquid-glass`, contrast ↔ `accessibility`, type ↔ `typography-text`/`dynamic-type`); it never edits `references/_shared/` of a sibling.
- **House rules kept:** iOS-only, SwiftUI-only, iOS-17 floor (Liquid Glass gated iOS 26); grep tier stands alone (ast-grep optional); cite-don't-assert; bump manifests on any user-facing change.

---

## 12. Sources (research-verified, June 2026)

**Liquid Glass / HIG (Apple):** HIG Materials, Layout, Typography, Color, Dark Mode, Accessibility, Buttons, SF Symbols, Tab Bars, Navigation Bars, Sidebars, Modality, Toolbars, Motion, Loading, Progress Indicators, Alerts, Feedback, Launching (`developer.apple.com/design/human-interface-guidelines/<topic>`); Technology Overviews — Liquid Glass + Adopting Liquid Glass (`developer.apple.com/documentation/TechnologyOverviews/…`); WWDC25 219 Meet Liquid Glass, 356 Get to know the new design system, 323 Build a SwiftUI app with the new design, 284 Build a UIKit app with the new design.
**Harness:** live `xcrun simctl`/`xcodebuild` help (Xcode 26.5); NSHipster simctl; idb docs (fbidb.io) + repo; status-bar overrides (jessesquires.com); localization launch args (useyourloaf.com).
**Preview snapshots:** EmergeTools/SnapshotPreviews (+ getsentry mirror); pointfreeco/swift-snapshot-testing; doordash-oss/swiftui-preview-snapshots; `ImageRenderer` (Apple Forums 728114/725196).
**Prior art / rubric:** UICrit (arXiv 2407.08850); Visual Prompting w/ Iterative Refinement (2412.16829); Synthetic Heuristic Evaluation (2507.02306); GPT-4o usability realism (2506.16345); MLLM prioritization (2508.16165); UI Judge (2510.08783); Nielsen 10 heuristics + 0–4 severity (nngroup.com); WCAG 1.4.3/2.5.5/2.5.8 (w3.org); Apple `performAccessibilityAudit` (Xcode 15+).

*(Full per-rule URLs live inline in the Component 1 KB files.)*
