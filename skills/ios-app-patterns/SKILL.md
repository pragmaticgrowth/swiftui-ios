---
name: ios-app-patterns
description: Use when asked to "build", "add", "scaffold", or "set up" a whole iOS SwiftUI feature — a tab-bar app (TabView), a NavigationStack master-detail flow, a bottom-sheet flow with detents, a UIKit bridge (UIViewRepresentable / UIViewControllerRepresentable), a home-screen widget (WidgetKit), or an onboarding / full-screen cover flow — or when you need the multi-API recipe (not a single call). Scaffolds these from real production iOS patterns via the swiftui-ctx CLI (recipe + file). Do NOT use for a single API lookup (use swiftui-examples), fixing deprecated code (use swiftui-modernize), or auditing a finished codebase (use audit-ios-swiftui-full).
license: MIT
cross_refs: [build-ios-swiftui, swiftui-examples, audit-ios-swiftui-full]
---

# ios-app-patterns — scaffold from real iOS recipes

For **building a whole feature**, not one call. Each recipe is a canonical template plus real examples from shipping
iOS apps, served by `swiftui-ctx`. (One API → `swiftui-examples`. Deprecated cleanup → `swiftui-modernize`. Finished
codebase → `audit-ios-swiftui-full`.)

`swiftui-ctx` = `${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx` (or `swiftui-ctx` on PATH). It self-builds + self-locates the catalog.

## The rule
Don't reconstruct an iOS pattern from memory — `NavigationStack` + `.navigationDestination` push wiring,
`.presentationDetents` argument shapes, and `UIViewRepresentable` (Coordinator + `makeUIView` / `updateUIView`) are
exactly where memory fails. Pull the recipe, then open a real example. Announce: *"Using ios-app-patterns."*

**Design-vet every scaffold.** Adapt recipes to use built-in text styles, semantic/system colors, 44 pt
targets, SF Symbols, and HIG navigation per `${CLAUDE_PLUGIN_ROOT}/references/_shared/hig-design-rubric.md`
and `liquid-glass-design.md` (never a number from memory or a myth from `design-claims-blacklist.md`).
**Ship a `#Preview` with each scaffold** so it can be rendered and design-reviewed (`audit-swiftui-design-review`).

## Workflow
1. `swiftui-ctx recipes` — list the patterns (or go straight to the one you need).
2. `swiftui-ctx recipe <name>` — the template skeleton + the APIs + real examples.
3. `swiftui-ctx file <example.id> --smart` (or the printed `file <permalink>`) — read the real, compilable code.
4. Adapt the template to the task; verify each API's current shape with `swiftui-ctx lookup <api> --platform ios` if unsure.

## Recipes (and when to use each)
| Recipe | Use for |
|---|---|
| `tab-bar-app` | a tab-bar app — `TabView` with a `.tabItem` label per root screen |
| `navigationstack-master-detail` | a list → detail push flow — `NavigationStack` + `.navigationDestination` (type-safe push) |
| `sheet-detents` | a bottom-sheet flow — `.sheet` + `.presentationDetents([.medium, .large])` |
| `uiview-bridge` | wrap a UIKit `UIView` / `UIViewController` (the hardest thing to get right) |
| `widget-scaffold` | a home-screen widget — a `Widget` with a `TimelineProvider` and an entry view (WidgetKit) |
| `fullscreen-cover-flow` | an onboarding / immersive flow — `.fullScreenCover` (no drag-to-dismiss) |

Full index with the APIs each pulls in → `references/recipes.md`.

## Floors (iOS-17 baseline; iPad within iOS)
`TabView` + `.tabItem` and `.fullScreenCover` are pre-floor (iOS 13 / 14). `NavigationStack`, `.navigationDestination`,
and `.presentationDetents` landed iOS 16 — all available at the iOS-17 floor. `UIViewRepresentable` and `Widget` are
cross-framework (UIKit / WidgetKit), not gated by the SwiftUI floor. Confirm any shape with
`swiftui-ctx lookup <api> --platform ios`.

## Errors → actions
`3` not-found (bad recipe name) → `swiftui-ctx recipes` to list them. `5` no catalog → STOP, tell the user, don't fabricate.

## References
| File | Read when |
|---|---|
| `references/recipes.md` | You want the recipe index with the APIs each one composes. |
| `../../references/_shared/hig-design-rubric.md` | Design defaults for the scaffold (type/color/targets/nav) |
| `../../references/_shared/liquid-glass-design.md` | Liquid Glass placement when a scaffold has chrome |
