# Shared Reference — Unified Finding Schema & Output Contract

The byte-identical finding-file format every audit skill writes. All 34 audit skills inherit this
schema unchanged; the orchestrator's consolidation reads it. Do not redefine the schema inside a
skill's own `references/` — a skill adds only its own context-folder starter set and any catalogued
additive domain fields.

**As of:** 2026-06-07.

---

## 1. Output contract (where findings go)

- Every run writes findings under a top-level `swiftui-audits/` folder at the **audited project's
  root** (never inside the plugin):
  `swiftui-audits/<domain>/<context>/NN-slug.md`
- Each run also writes a per-domain index: `swiftui-audits/<domain>/_index.md` — a table of every
  finding written that run.
- `<domain>` = the skill's slug suffix (e.g. `api-currency`, `liquid-glass`).
- `<context>` = a domain-defined sub-bucket (e.g. `control-density/`, `adaptive-sizing/`,
  `availability-gating/` as a *context folder* inside a domain skill — distinct from the
  `availability-gating` *skill*).
- `NN` = a zero-padded sequence; `slug` = a short kebab description.
- The orchestrator additionally writes one consolidated `swiftui-audits/_SUMMARY.md`.
- `ios-idiomaticness` writes its `_index.md` with a `kind: nativeness-dashboard` discriminator.

---

## 2. Canonical frontmatter (mandatory, byte-identical across all skills)

```yaml
---
rule_id:      <slug-prefixed id, e.g. cur-02>
severity:     hard-fail | warning | advisory
confidence:   <0.0–1.0>
domain:       <skill slug suffix, e.g. api-currency>
context:      <context-folder name>
file:         <path relative to project root>
line:         <line or line-range>
api:          <the symbol in question>
availability: <iOS floor / "iOS ABSENT" / "n/a">
status:       open | fixed | duplicate-of <rule_id>
source:       <Apple URL + access date, or "verify against Xcode 26 SDK">
verified_on:  <YYYY-MM-DD>
fix_mode:     auto | flag-only
cross_ref:    <optional: sibling-domain slug + rule_id>
---
```

Field notes:
- `availability` is read from
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — never asserted from memory.
- `source` cites Apple primary docs (fetched per
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`) or carries the
  `verify against Xcode 26 SDK` flag.
- `status: duplicate-of <rule_id>` is set by the orchestrator's dedup pass (the file stays on disk for
  the audit trail but is excluded from the `_SUMMARY.md` master table).
- `cross_ref` targets and primary-owner verdicts derive from
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` — the same source the orchestrator's
  dedup uses, so the two never drift.

---

## 3. Body sections (fixed, in order)

```markdown
## What
## Why it's wrong on iOS
## Evidence
## Correct
## Fix applied?
## Source
```

`## Fix applied?` carries the post-fix verification evidence (fix-safety protocol §8).

---

## 4. Additive domain fields (allowed, catalogued)

A skill MAY add these alongside the canonical frontmatter; nothing else:

| Field | Owner domain(s) | Meaning |
|---|---|---|
| `model_kind` + `failure_shape` | state-observation | the observable wrapper + how it fails |
| `era` | api-currency only | free-string release wave |
| `swift_era` | concurrency-safety | the Swift concurrency era (renamed from `era` to avoid collision with api-currency's `era`) |
| `isolation_kind` | concurrency-safety | the isolation hazard class |
| `motion_role` | animation-motion | the animation's role |
| `justified` (a `status` value) | uikit-overuse | a bridge confirmed necessary |

> **Collision rule:** `concurrency-safety` MUST use `swift_era`, not `era` — `api-currency`'s `era`
> is a different, free-string field and the two must not share a key.

---

## 5. Context-folder ownership (resolve double-report risk)

- `control-density/` → **controls-forms** owns; layout-and-tables cross_refs only inside a
  `Table`/inspector.
- `custom-layout/` (the `Layout` protocol) → **layout-and-tables** owns; drawing-canvas classifies + routes.
- `adaptive-sizing/` → intentional two-domain split (content-frame = layout-and-tables, size-class =
  adaptive-layout; split-view columns = adaptive-navigation); each adds a companion note.
- preview-container canvas-crash → **previews** owns; swiftdata routes.

---

## Sources

Internal schema; cites no external API. Floor values, gating discipline, the cross-ref graph, and the
Apple-doc fetch path all live in sibling `_shared/` files referenced above via `${CLAUDE_PLUGIN_ROOT}`.
