---
description: Build an iOS settings/preferences screen as a grounded grouped Form — the idiomatic iOS pattern (Form + Section + Toggle/Picker/NavigationLink), grounded in real shipping apps via swiftui-ctx.
---
This file is instructions for *you* to run — there is no pre-computed output to wait for, and nothing here is broken.

iOS has no `Settings` scene. The idiomatic iOS preferences screen is a grouped `Form` — usually pushed onto a `NavigationStack` or presented in a sheet — built from `Section`s of `Toggle`, `Picker`, `NavigationLink`, and labeled rows, with values persisted via `@AppStorage` / `@Bindable` settings model.

Read from the conversation what the settings screen needs (which toggles, pickers, sub-screens, what state backs them). If that is unstated, build a representative scaffold and note where to add the user's own rows.

**Do this now**, via the Bash tool — ground the shape in real iOS apps (the CLI self-builds and self-locates):

    "$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" recipe settings-form --json

Then for each control you place, confirm the real call shape and iOS floor:

    "$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" lookup Form --platform ios
    "$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" lookup Toggle --platform ios
    "$CLAUDE_PLUGIN_ROOT/scripts/swiftui-ctx" lookup Picker --platform ios

Build the screen grounded in that output:
- Wrap the rows in a `Form`; group related rows in `Section`s with headers; use `.navigationTitle` on the enclosing `NavigationStack`.
- Follow each control's `consensus` shape and the `recommended` example; back values with `@AppStorage` or an observable settings model.
- Honor `introduced_ios` for any API you reach for — do not exceed the project's deployment target.
- If a `next_actions` line shows a `file …` command, run it to fetch the real, compilable enclosing view before writing code.
