---
name: audit-swiftui-design-review
description: Pixel-first visual design and UX reviewer for an iOS SwiftUI app. Builds it, screenshots every screen across light/dark and Dynamic Type via the Simulator, runs deterministic objective checks, then critiques the rendered pixels against a cited Apple HIG + iOS 26 Liquid Glass knowledge base, ending in a 0-100 Design Score. Use when the user says "audit my app's design", "is this screen HIG-compliant", "rate my UI/UX", "does this look native", "review my Liquid Glass design", "critique my screens", "design review", or wants a design-quality pass rather than a code-correctness audit. AUDIT-ONLY, iOS-only, SwiftUI-only. Grounds every finding in a cited HIG/WWDC rule and never asserts debunked design myths. Complements the 34 static code audits and is the orchestrator's visual-design wave. Not for code-correctness (route to the audit-swiftui-* domain skills), not for writing UI from scratch (route to build-ios-swiftui).
---

# Audit iOS SwiftUI — Visual Design & UX Review

**AUDIT-ONLY · iOS-only · SwiftUI-only · PIXEL-FIRST.** This skill judges *rendered design quality*, not code correctness. It extends the toolkit's `LOCATE→VERIFY→REPORT` discipline to pixels: **CAPTURE → CHECK → CRITIQUE → SCORE**. It is a **hybrid** reviewer — deterministic checks own the objective facts (contrast, 44 pt targets, clipped text, Dynamic Type); the model judges the subjective layer (hierarchy, balance, affordance, glass placement, "feels native"). Research is clear that vision-only critique hallucinates, so **the model never invents a number** — every finding cites a rule in the knowledge base, and the deterministic tier supplies the measurable ones.

This complements — never replaces — the 34 static `audit-swiftui-*` code audits. When two findings collide on the same `file:line`, defer to `references/_shared/cross-ref-graph.md` (glass design ↔ `audit-swiftui-liquid-glass`; contrast ↔ `audit-swiftui-accessibility`; type ↔ `audit-swiftui-typography-text`/`audit-swiftui-dynamic-type`).

## The knowledge base (the only source of design truth)

Read these before critiquing; cite the exact rule + its Apple URL in every finding. **Never assert a design number from memory; never emit a blacklisted myth.**

| Open for | File |
|---|---|
| measurable HIG rules (type scale, contrast 4.5/3/7:1, 44 pt, spacing, nav limits) | `${CLAUDE_PLUGIN_ROOT}/references/_shared/hig-design-rubric.md` |
| iOS 26 Liquid Glass design language + anti-patterns + adoption | `${CLAUDE_PLUGIN_ROOT}/references/_shared/liquid-glass-design.md` |
| qualitative UX smells (native-vs-not, hierarchy, affordance, states, forms) | `${CLAUDE_PLUGIN_ROOT}/references/_shared/ux-smell-catalog.md` |
| finding format + severity (Nielsen 0–4) + the 0–100 Design Score | `${CLAUDE_PLUGIN_ROOT}/references/_shared/design-finding-schema.md` |
| debunked myths you must NEVER assert | `${CLAUDE_PLUGIN_ROOT}/references/_shared/design-claims-blacklist.md` |
| iOS floors / iOS-26 gating for Liquid Glass | `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`, `ios-gating.md` |
| fix-safety protocol (FIX step) | `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` |

## Workflow (execute verbatim)

1. **CAPTURE.** Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-capture.sh <project-dir> --variants full`
   (or `skills/audit-swiftui-design-review/scripts/design-capture.sh`). It builds, boots the Simulator,
   navigates (auto-explore + an optional `swiftui-design/screens.manifest.json`), and writes
   `swiftui-design/screens/<screen>__<appearance>__<type>.png` + `capture.json`. **READ `capture.json`
   first**: if `status:"unavailable"`, fall back to **code-only** — say so in a banner at the top of the
   report ("no pixels captured — reduced confidence") and critique from the SwiftUI source + the static
   tier only. Respect `coverage` (note auth walls / idb-absent / not-captured screens — never claim a
   screen you didn't see). For a deterministic, complete run, write/commit a `screens.manifest.json`.
2. **CHECK (deterministic — no model judgment).** Run the static tells:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-design-review --dir <project-dir> --json -`.
   Optionally run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/a11y-audit/run.sh <project-dir>` (Apple's
   `performAccessibilityAudit` — contrast/Dynamic Type/hit-region/clipped). Ingest every hit as a
   `tier: deterministic` finding (high confidence). These LOCATE; you still READ the code/screenshot to
   confirm and to attach the region.
3. **CRITIQUE (vision — the subjective layer).** For EACH screen × variant, read the screenshot **with the
   KB in context** and go category by category (Layout, Typography, ColorContrast, Hierarchy,
   AffordanceControls, Navigation, LiquidGlass, Motion, States, AccessibilityVisual) — **one category per
   pass** (this cuts hallucination). Write each finding in the mandatory shape **Expected → Gap → Fix**,
   pin it to a screen region, cite the KB rule's source URL, and set Nielsen severity 0–4. **Confidence
   gate:** report only when the pixels (or a merged deterministic fact) clearly support it — uncertain →
   omit. **Never** state a number absent from `hig-design-rubric.md`, and **never** restate a
   `design-claims-blacklist.md` myth. Dark mode + AX5 variants are where most real issues surface
   (clipping, contrast, overlap) — critique them specifically.
4. **SCORE.** Compute per-category and overall 0–100 per `design-finding-schema.md` (deduct by severity;
   deterministic hits deduct too). Aggregate cross-screen issues at MAX severity, tie-break by count.
5. **REPORT.** Write each finding to `swiftui-design/<screen>/NN-slug.md` and author the single dashboard
   `swiftui-design/_DESIGN_SUMMARY.md` (headline Design Score + band, per-category breakdown, the
   coverage note from step 1, and the master finding table). Lead the dashboard with the score.
6. **FIX (optional — only if asked + clean git tree).** Apply safe fixes per
   `fix-safety-protocol.md` (system text styles, semantic colors, `.accessibilityLabel`, correct glass
   placement, etc.), **re-capture** the touched screens, and **re-score** to show `before → after`.

## Boundaries (stay in lane)

- Judges design against the **HIG**, not against a golden screenshot — this is not visual-regression diffing.
- Contains **no** code-correctness rules — a crash/race/deprecation belongs to the static `audit-swiftui-*` owner.
- Never edits `references/_shared/` or a sibling skill's files — it consumes them.
- Writing UI from scratch → `build-ios-swiftui`; a single code domain → that `audit-swiftui-*` skill.

## Sources

Internal to the toolkit: the design rules live in the `references/_shared/` KB above (each rule carries
its Apple HIG/WWDC URL); the capture mechanism is `scripts/swiftui-capture.sh`; the deterministic tier is
`scripts/swiftui-lint.sh` (`dr-*` tells) + `scripts/a11y-audit/`. No external API is asserted here that
isn't cited in the KB.
