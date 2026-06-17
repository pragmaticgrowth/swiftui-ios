# a11y-audit — optional deterministic accessibility audit

Apple ships a first-party, deterministic accessibility audit (`XCUIApplication.performAccessibilityAudit`, Xcode 15+) that catches exactly the *objective* visual issues the design reviewer should not have to guess at: **contrast** below threshold, text that won't scale with **Dynamic Type**, **hit regions** under 44×44 pt, **clipped text**, and controls/images missing a usable description. Each issue is reported by XCTest with the offending element's screenshot.

This is the optional **rendered objective** sub-tier of the design layer's deterministic checks. It complements the always-on static `dr-*` tells in `skills/audit-swiftui-design-review/lint/` — those need no project changes; this one needs a UI test target.

## Wire it (once)

1. Copy `DesignA11yAuditTemplate.swift` into your app's **UI test target** (e.g. `<App>UITests`).
2. Make sure that target's scheme is testable on a simulator.
3. Run:
   ```bash
   bash scripts/a11y-audit/run.sh <project-dir> [--out DIR] [--device NAME]
   ```

## Output

`<out>/swiftui-design/a11y-audit.json`:
- `status: "not-wired"` — no `performAccessibilityAudit` test found (default; copy the template in).
- `status: "ok"` — the audit ran with no issues.
- `status: "test-failed"` — the audit reported issues; open `<out>/a11y.xcresult` for the per-element screenshots, or read `<out>/a11y-audit.log`.
- `status: "unavailable"` — no Xcode/scheme/simulator.

The reviewer (`audit-swiftui-design-review`) ingests these as `tier: deterministic` findings (high confidence, hard score deductions) so the vision pass doesn't have to re-derive contrast/target/clipping numbers.

> Extracting individual audit issues from the `.xcresult` into `findings[]` is a future enhancement; today the runner records status + points at the `.xcresult`/log. The static `dr-*` tells provide the always-on deterministic signal without any project wiring.
