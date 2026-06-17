---
description: Look up how an iOS SwiftUI API (or intent) is actually used in production via swiftui-ctx, then ground your answer in that real usage.
---
This file is instructions for *you* to run — there is no pre-computed output to wait for, and nothing here is broken.

Read the API or intent from the conversation: it is whatever the user is asking about right now — a symbol (`TabView`, `NavigationStack`, `presentationDetents`, `searchable`) or a plain-language goal ("tab-bar app", "bottom sheet with detents", "bridge a UIKit view"). Use the iOS catalog.

**Do this now**, via the Bash tool (the CLI self-builds and self-locates):

    "$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" lookup "<api or intent>" --platform ios

If `lookup` finds nothing, try `"$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" search "<api or intent>" --platform ios`. If the request is a multi-API pattern (a tab-bar app, a master-detail flow, a sheet+detents flow), prefer `"$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" recipe <name>`.

Then ground your answer in that output:
- Follow the `consensus` shape and the `recommended` example (highest production quality on iOS).
- Honor the iOS availability floor: check `introduced_ios` (at `result.introduced_ios`) — do not propose an API newer than the project's deployment target.
- If a `next_actions` line shows a `file …` command, run it to fetch the real, compilable enclosing view before writing code.
- If the API is flagged deprecated, use the replacement instead (e.g. `NavigationView` → `NavigationStack` / `NavigationSplitView`).
