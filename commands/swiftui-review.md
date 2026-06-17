---
description: Review iOS SwiftUI code or the current diff for deprecated APIs and non-idiomatic usage, grounded in real shipping iOS apps via the swiftui-ios-reviewer agent.
---
This file is instructions for *you* to run — there is no pre-computed output to wait for, and nothing here is broken.

Determine the review target from the conversation: a specific file or path the user named, or — if none was given — the current working diff (`git diff`, falling back to the changed Swift files on the branch).

**Do this now:** invoke the **`swiftui-ios-reviewer`** subagent (via the Task tool) and hand it that target. The agent judges code against real iOS production usage — not memory — using the `swiftui-ctx` CLI (`"$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx"`).

What the review must do:
1. For each SwiftUI symbol used, run `"$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" deprecated <api> --json` (flag + replacement) and compare the call site to `"$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" lookup <api> --platform ios` `consensus`.
2. Check the iOS availability floor: any API whose `introduced_ios` is above the project's deployment target is a finding.
3. Report findings as `file:line — issue → fix` with the swiftui-ctx permalink as evidence, ranked deprecated (high) > non-consensus shape (medium) > nit.

Do not rewrite code unless the user explicitly asks. If the `swiftui-ios-reviewer` agent is unavailable, perform the review inline following the same steps.
