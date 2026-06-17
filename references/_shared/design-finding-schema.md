# Design finding schema + Design Score (shared design truth)

**Verified: 2026-06-16.** The byte-stable format every design finding uses and the deterministic 0–100 **Design Score** computation. This is the design analogue of references/_shared/finding-schema.md (which governs the static audits). The reviewer skill `audit-swiftui-design-review` MUST follow this exactly so two runs over the same build produce an equivalent `swiftui-design/` tree. Rubric source for every finding: references/_shared/hig-design-rubric.md / references/_shared/liquid-glass-design.md / references/_shared/ux-smell-catalog.md; never assert a myth from references/_shared/design-claims-blacklist.md.

---

## 1. Finding format

Each finding is one Markdown file `swiftui-design/<screen>/NN-slug.md` with this frontmatter + body (every key required unless marked optional):

```yaml
---
rule_id: <stable id, e.g. dr-fontsize or vis-hierarchy-001>
severity: 0 | 1 | 2 | 3 | 4          # Nielsen scale, §2
category: Layout | Typography | ColorContrast | Hierarchy | AffordanceControls | Navigation | LiquidGlass | Motion | States | AccessibilityVisual
screen: <screen name from screens.manifest.json>
variant: <appearance/type, e.g. dark/axxxl or light/large>
region: [x, y, w, h]                 # bbox in screenshot px; OR an element label string if bbox unknown
tier: deterministic | vision         # deterministic = objective check (no model judgment); vision = model critique
evidence: swiftui-design/screens/<screen>__<variant>.png
source: <HIG/WWDC URL from the KB>    # the rule this finding is grounded in
status: open | duplicate-of <rule_id> | fixed   # optional; default open
---

## Expected
<the HIG/Liquid-Glass/UX standard, one sentence — quote the rubric>

## Gap
<what the screen actually does that violates it — point at the region>

## Fix
<the concrete change, ideally the SwiftUI modifier/structure>
```

The three body sections (`Expected → Gap → Fix`) are mandatory and in that order (the UICrit-validated critique shape). A finding with no cited `source`, or whose claim restates a references/_shared/design-claims-blacklist.md myth, is invalid and must not be written.

## 2. Severity (Nielsen 0–4)

For `tier: vision` findings, use Nielsen's scale verbatim:

| severity | meaning |
|---|---|
| 0 | not a usability/design problem at all |
| 1 | cosmetic only — fix if time allows |
| 2 | minor — low priority |
| 3 | major — high priority |
| 4 | catastrophe — imperative to fix before release |

Severity = f(frequency, impact, persistence). For `tier: deterministic` findings, carry the objective name in parallel in the body (`minor | moderate | serious | critical`) and map to a Nielsen number for scoring: contrast/clipping/hit-target failures = **3** (major) by default, 4 if the content is unreadable/unreachable.

## 3. Design Score (0–100)

Per-category score, then a weighted overall. **Deterministic, reproducible** given the same screenshots + deterministic findings.

**Per category** (the 10 categories in §1): start at 100, subtract per finding in that category by severity:

| severity | deduction |
|---|---|
| 4 | 25 |
| 3 | 12 |
| 2 | 5 |
| 1 | 2 |
| 0 | 0 |

Floor each category at 0. (Deterministic findings deduct on the same table — they are simply high-confidence.)

**Overall** = the mean of the 10 category scores, rounded to an integer (equal weight by default — document any reweighting inline so two runs match). Report it as the headline with a band: **90–100 excellent · 75–89 good · 60–74 needs work · <60 poor**.

**Re-score last.** On a FIX pass, recompute after fixes and show `before → after` per category and overall (the audit-swiftui-ios-idiomaticness skill before/after pattern).

## 4. Multi-screen aggregation

When the same issue appears on multiple screens, emit ONE finding at the **MAX severity** observed, **tie-broken by occurrence count** (more screens = ranked higher among equal severities). List every `screen` it occurs on in the body. Per-category scoring counts the aggregated finding once per affected screen for the deduction (so a pervasive issue costs more than a one-off).

## 5. Dashboard — `swiftui-design/_DESIGN_SUMMARY.md`

The single top-level design dashboard (sole author: the reviewer). Sections, in order:

1. **Headline Design Score** — the overall 0–100 + band, and (after a fix pass) `before → after`.
2. **Per-category breakdown** — a row per category: `category · score/100 · #findings (by severity)`.
3. **Coverage** — what `capture.json` actually captured (screens × variants), and what degraded (e.g. "code-only — no simulator", "idb absent: reduced crawl", "previews not-wired") so audited-and-clean is never confused with not-captured.
4. **Master finding table** — every non-duplicate finding: `rule_id · severity · category · screen · region · tier · source`, sorted severity-desc then category. `status: duplicate-of …` rows are omitted (kept on disk for the trail).

Determinism contract: identical build + `screens.manifest.json` ⇒ structurally identical `swiftui-design/` tree and an equivalent `_DESIGN_SUMMARY.md`.
