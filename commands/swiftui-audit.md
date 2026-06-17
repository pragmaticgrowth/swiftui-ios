---
description: Run the full iOS-SwiftUI audit suite over a codebase — steer to the relevant domains, then audit each against real production evidence.
---
This file is instructions for *you* to run — there is no pre-computed output to wait for, and nothing here is broken.

Determine the audit target from the conversation: the path the user named, or the current directory (`.`) if none was given.

**Do this now**, via the Bash tool — the relevance scan (which of the 34 domain auditors actually apply here):

    python3 "$CLAUDE_PLUGIN_ROOT/scripts/audit-scan.py" "<path or .>"

Now drive the **`audit-ios-swiftui-full`** orchestrator:
1. From the scan above, take `relevant_skills[]` (the `always` cross-cutting set + any `cond` domains whose signal hit) — ignore `skipped_skills`.
2. Run them in the orchestrator's wave order (guards → state & data → UI domains → boundary & scoring); each `audit-swiftui-<domain>` skill locates candidates with the shared lint engine, then READS each hit and judges it against `swiftui-ctx` evidence (`--platform ios`) + Sosumi (the engine never reports a finding as fact).
3. Write per-finding Markdown to `swiftui-audits/` in the shared `finding-schema.md` format and roll everything into `swiftui-audits/_SUMMARY.md` with the 0-100 nativeness score.
4. Apply only fixes permitted by `fix-safety-protocol.md` (guards-first, mechanical renames such as `NavigationView` → `NavigationStack`); flag the rest for the developer.

Tip: tier-2 structural rules need `ast-grep` (`brew install ast-grep ripgrep`); without it the engine still runs the grep tier.
