---
name: build-ios-swiftui
description: Use skill if you are writing, reviewing, or refactoring SwiftUI for iOS/iPadOS — @Observable state, NavigationStack/NavigationSplitView, sheets with detents, tab bars, UIKit (UIViewRepresentable) bridging, Swift 6 concurrency, SwiftData, document/file access via security-scoped URLs, Dynamic Type, widgets/Live Activities, or iOS-gated Liquid Glass. Triggers include "write a SwiftUI view for iPhone/iPad", "tab bar app", "NavigationStack master-detail", "sheet with detents", "wrap a UIKit view in SwiftUI", "widget / Live Activity", "@Observable state isn't updating", "Dynamic Type", "SwiftData". NOT for macOS/Catalyst, visual-only HIG snapshot auditing, a single-API lookup (use swiftui-examples), recipe/template scaffolding (use ios-app-patterns), or a whole-codebase audit (use audit-ios-swiftui-full).
---

# Build iOS SwiftUI

Write correct, current, idiomatic **iOS** SwiftUI. This catalog encodes the mistakes AI makes on
iPhone & iPad and the current rule for each. The target is **always iOS/iPadOS** (iOS-17 floor; iPad
within iOS); macOS appears only as a ❌ contrast. Depth for any topic is one hop away in `references/`.

> **Write-time vs. audit.** This skill (+ its `swiftui-ios-reviewer` agent and the quick
> `scripts/ios-swiftui-lint.sh` — a write-time quick-lint) is the **write-time** authoring +
> review path. For a **deep, whole-codebase audit** of a finished project, use the
> **`audit-ios-swiftui-full`** orchestrator and the `audit-swiftui-*` skills (the separate, shared
> audit engine — grep + ast-grep tells, Sosumi + `swiftui-ctx`
> verification, findings written to `swiftui-audits/`). The two are complementary, not rivals.
>
> **Verify APIs against the live catalog.** Before emitting any non-trivial API, run `swiftui-ctx lookup <api> --platform ios`
> (the `swiftui-examples` skill) for the real consensus shape — `references/api-currency.md` is a curated summary,
> not a substitute for the live corpus.

## When to use / not use

**Use** for SwiftUI *code correctness* on iOS/iPadOS: state & data flow, app lifecycle & scenes,
adaptive navigation, UIKit bridging, concurrency, layout & tables, controls & touch input,
Liquid Glass, SwiftData, document/file access, previews.

**Not for** (say so and stop — these are other concerns, not this skill's job):
- macOS / Mac Catalyst / visionOS / watchOS SwiftUI.
- Visual HIG judgement or snapshot auditing (typography/spacing/color review).
- Liquid Glass *aesthetic* design choices; app packaging, codesigning, App Store submission.
- SwiftLint / SwiftFormat configuration.

## Operating contract (non-negotiable)

1. **iOS is the target.** Every snippet must compile on an iOS target. Never emit an AppKit symbol
   (`NSView`/`NSViewRepresentable`/`MenuBarExtra`/`Settings {}`/`.commands {}`) or a macOS-only scene
   primitive as the answer.
2. **Trust `references/api-currency.md`, not your prior.** If an API is not there or in Apple docs,
   **say so and offer a safe alternative — do not invent it.** The most *probable* token for an unknown
   API is a plausible hallucination (`.glassBackground()` does not exist).
3. **Gate on the iOS arm.** Above-floor APIs need `#available(iOS 26, *)` / `@available(iOS 17, *)`
   — never gate on the macOS arm (`#available(macOS 26, *)` never fires on iOS because the `*` wildcard
   already covers iOS, so the floor is never enforced — the single mistake even good artifacts make).
4. **Run the lint before proposing code** (see Detection). Fix every hard-fail.
5. **Output Contract.** Claim only the verification rung you reached:
   (1) read · (2) lint/types · (3) unit · (4) integration · (5) ran/observed · (6) user-confirmed.
   The compile hook (below) is how you legitimately reach rung 2+. Don't imply a higher rung.
6. **No architecture mandate.** Teach plain `@Observable final class` owned at the App level. Do not
   force MVVM/VIPER.

## Design defaults (HIG + Liquid Glass)

Generated UI is HIG-idiomatic and Liquid-Glass-modern **by default**, not as an afterthought. Unless the
user overrides, every screen you write:

- **Type** — built-in text styles (`.title`, `.headline`, `.body`, `.caption`); **never** `.font(.system(size:))` (it defeats Dynamic Type). Hierarchy via weight/size/color, not new typefaces.
- **Color** — system/semantic colors (`.primary`, `.secondary`, `Color(.systemBackground)`, `.tint`) that adapt to Dark Mode + Increase Contrast; **never** hardcode `.black`/`.white`/raw RGB for foreground. Custom colors ship light + dark + increased-contrast variants.
- **Targets** — interactive controls ≥ **44×44 pt**; icon-only buttons get an `.accessibilityLabel`.
- **Navigation** — tab bar for peer top-level sections, `NavigationStack` for drill-down, `NavigationSplitView` gated by size class; standard symbol-only Back; concise titles (< 15 chars).
- **Liquid Glass (iOS 26, gated)** — only on the navigation/chrome layer, never on content; one `GlassEffectContainer`; emphasis-tint a **single** primary action; never glass-on-glass. Adopt by removing custom bar/sheet backgrounds, not by adding glass everywhere.
- **SF Symbols** for standard actions (`square.and.arrow.up`, `trash`, `magnifyingglass`, `plus`, `ellipsis`).
- **States** — real empty / loading (skeleton or `ProgressView`) / error states; never a blank screen.

Ground every choice in `${CLAUDE_PLUGIN_ROOT}/references/_shared/hig-design-rubric.md` and
`liquid-glass-design.md`; **never assert a design number from memory** or a myth from
`${CLAUDE_PLUGIN_ROOT}/references/_shared/design-claims-blacklist.md` (no "max 3–5 tabs", "0.3 s
animation", "16 pt HIG margin", …). **Optional self-check:** after writing a screen, render it with
`${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-capture.sh` and critique it via `audit-swiftui-design-review`.

## The Core Catalog — ranked failure modes

Ordered by frequency × impact × iOS-uniqueness. `Sev`: **C**=critical (broken/net-negative),
**H**=high (wrong-but-compiles / non-idiomatic), **M**=med (stale-but-works). `→` is the deep doc.

| # | Symptom (what AI emits) | Correct iOS rule | Sev | → |
|---|---|---|---|---|
| 1 | `NavigationView { … }` for new code | `NavigationStack` (iPhone primary), or `NavigationSplitView` **gated to regular width / iPad** | C | adaptive-navigation.md |
| 2 | Invents `.glassBackground()` / `.liquidGlass()` / `.material(.glass)` / `LiquidGlassView` | Real API: `glassEffect(_:in:)`, `GlassEffectContainer`, `.buttonStyle(.glass)` — the rest don't exist | C | liquid-glass.md |
| 3 | iOS-26/17-only API with no `#available`/`@available` gate | Gate every above-floor API on the **iOS arm** (`#available(iOS 26, *)`) | C | version-and-hallucination.md |
| 4 | `@ObservedObject var x = Model()` — view creates what it doesn't own | Owner uses `@State` (`@Observable`) or `@StateObject` (`ObservableObject`); else silent state reset | C | state-and-observation.md |
| 5 | `@Observable` kept as `: ObservableObject` + `@Published` + `@StateObject` | Under `@Observable`: no `@Published`, no conformance, own with `@State` | C | state-and-observation.md |
| 6 | `.commands {}` / `MenuBarExtra` / `Settings {}` ported to an iOS scene | None exist on iOS → `Menu`, `.contextMenu`, `.swipeActions`, App Intents; settings = `Form`+`@AppStorage` | C | app-lifecycle.md |
| 7 | Unconditional `NavigationSplitView` on iPhone | Gate the split view to regular width / iPad; compact-width iPhone wants a `NavigationStack` | C | adaptive-navigation.md |
| 8 | SwiftData `let` on a bidirectional relationship | Use `var`; `let` compiles but crashes at runtime | C | swiftdata.md |
| 9 | Non-`Sendable` class crossing a `@MainActor`→background `Task` boundary | Swift 6 = strict data-race checking by default (error): make it `Sendable` / actor-isolate / stay on-actor | C | concurrency.md |
| 10 | `UIViewRepresentable` with no `updateUIView` | Implement `updateUIView` or SwiftUI state never reaches the UIKit view | C | uikit-interop.md |
| 11 | `.foregroundColor(_:)` | Deprecated → `.foregroundStyle(_:)` (iOS 15+) | H | version-and-hallucination.md |
| 12 | Single-param `.onChange(of:) { newValue in }` | Two-param `{ old, new in }` (+ optional `initial:`) (iOS 17+) | H | version-and-hallucination.md |
| 13 | `DispatchQueue.main.async` in async/SwiftUI code | `@MainActor` / `await MainActor.run` — GCD bypasses isolation checking | H | concurrency.md |
| 14 | `$obs.prop` on a non-owned `@Observable` with no `@Bindable` | Re-wrap with `@Bindable` to project `$` | H | state-and-observation.md |
| 15 | Arbitrary file paths in an iOS app (no consent) | `fileImporter`/`UIDocumentPickerViewController` grant; raw paths outside the container silently fail | C | file-handling.md |
| 16 | Re-opening a user-picked file next launch with no bookmark | Persist `bookmarkData(.minimalBookmark)` + `start/stopAccessingSecurityScopedResource()` | H | file-handling.md |
| 17 | `placement: .navigationBarLeading/.navigationBarTrailing` | Deprecated → `.topBarLeading`/`.topBarTrailing`/`.principal`/`.primaryAction` | H | adaptive-navigation.md |
| 18 | `.navigationBarTitle(_:)` | Deprecated → `.navigationTitle(_:)` (+ `.navigationBarTitleDisplayMode`) | M | adaptive-navigation.md |
| 19 | bare `Task {}` in `.onAppear` for view-lifecycle async | `.task {}` / `.task(id:)` — auto-cancelled on disappear | H | concurrency.md |
| 20 | Glass effect on content (lists/cards/backgrounds) | Liquid Glass is **navigation-layer-only** — never on content | H | liquid-glass.md |
| 21 | `@Sendable` closure body touches `self.`/a main-actor property | Isolate the closure `@MainActor` or capture-by-value for reads | H | concurrency.md |
| 22 | Old `tabItem {}` / inline-destination `NavigationLink` in lists | `Tab(...) {}` (iOS 18+) and value-based `.navigationDestination(for:)` | M | version-and-hallucination.md |
| 23 | SwiftData relationship assigned inside `init` | Assign after inserting into the context, not in `init` (data vanishes on relaunch) | H | swiftdata.md |
| 24 | `#Preview` of a SwiftData/`@Query` view with no in-memory container | `.modelContainer(for: …, inMemory: true)` or the canvas crashes | H | previews.md |
| 25 | Splitting an `@Observable`-reading view into computed `var x: some View` | Extract into separate `View` **types** — computed props lose per-property invalidation | H | state-and-observation.md |
| 26 | No save on `scenePhase == .background` | iOS suspends & terminates — `onChange(of: scenePhase)` `try modelContext.save()` or pending edits are lost | H | app-lifecycle.md |
| 27 | `@EnvironmentObject` for an injected `@Observable` dependency | `.environment(instance)` + `@Environment(Type.self)` | H | state-and-observation.md |
| 28 | `.cornerRadius(_:)` | Prefer `.clipShape(.rect(cornerRadius:))` / `RoundedRectangle` (clearer intent) | M | version-and-hallucination.md |
| 29 | Copying Apple's `fatalError`-on-`ModelContainer` / `@Model` with no `init` | Handle container failure gracefully; supply a real initializer | H | swiftdata.md |
| 30 | `loadTransferable`/drag-drop that compiled pre-Swift-6 now errors | Make `Transferable` conformances/closures `Sendable`-correct; `.draggable`/`.dropDestination` | H | file-handling.md |
| 31 | Sheet/cover with no `.presentationDetents` where a partial-height sheet is wanted | `.presentationDetents([.medium, .large])` (+ `.presentationDragIndicator`) (iOS 16+) | H | controls-and-touch.md |
| 32 | `PreviewProvider` struct + hand-rolled `EnvironmentKey` boilerplate | `#Preview { }`, `@Previewable @State`, one-line `@Entry var` | M | previews.md |
| 33 | Blanket `@MainActor` spam OR assuming main-actor-by-default is automatic | It's an **opt-in** Swift 6.2 build mode (`-default-isolation MainActor`), not the language default | M | concurrency.md |
| 34 | `.formStyle(.grouped)` ported from macOS | On iOS `Form` is already grouped — drop it; `.formStyle(.grouped)` is the macOS knob | M | controls-and-touch.md |
| 35 | Representable with `@Binding` but no `makeCoordinator()`/delegate wiring | Add a `Coordinator` + `delegate = context.coordinator`; weak-capture the parent | H | uikit-interop.md |
| 36 | `@Model` relationship arrays treated as ordered; off-thread mutation | Sort explicitly (`@Query(sort:)`/`SortDescriptor`); mutate on the context's actor (`@ModelActor`) | H | swiftdata.md |
| 37 | Glass-on-glass / sibling glass with no `GlassEffectContainer` | Never nest glass; group siblings in a `GlassEffectContainer` (glass can't sample glass) | M | liquid-glass.md |
| 38 | Mutating SwiftData but never saving; relying on auto-save | `try modelContext.save()` at meaningful boundaries — auto-save is unreliable | H | swiftdata.md |
| 39 | Custom touch target smaller than 44×44 pt / interactive-only on hover | iOS is touch — 44 pt hit target; `.contextMenu`/`.swipeActions`, not `.onHover`/`.help` | H | controls-and-touch.md |
| 40 | Fixed point sizes / `Font.system(size:)` everywhere — breaks Dynamic Type | Semantic text styles (`.font(.body)`), `@ScaledMetric`, support the largest accessibility sizes | H | controls-and-touch.md |
| 41 | `edgesIgnoringSafeArea(_:)` | Deprecated → `.ignoresSafeArea(_:edges:)` | M | version-and-hallucination.md |
| 42 | `Text("a") + Text("b")` (the `Text` `+` operator) | Deprecated iOS 26.0 → string interpolation `Text("a \(b)")` | M | version-and-hallucination.md |
| 43 | Heavy work in `body`/`init`, `.id(UUID())`, `AnyView`, filter-in-`ForEach` | Hoist formatters; stable ids; `@ViewBuilder` not `AnyView`; derive collections upstream | H | view-performance.md |
| 44 | Widget / Live Activity timeline view doing async work / non-static rendering | Widgets render from a `TimelineProvider` snapshot; Live Activities (`ActivityKit`, iOS 16.1+) are static-per-update | H | app-lifecycle.md |

## Currency cliffs (dated wrong → right)

The era-boundaries where a pre-2024 prior is stale. Full detail + availability strings in
`references/api-currency.md`.

| Era boundary | Wrong (stale default) | Right (current) | iOS floor |
|---|---|---|---|
| NavigationView deprecation (2022) | `NavigationView {}` | `NavigationStack` / `NavigationSplitView` | iOS 16 |
| `@Observable` macro (2023) | `class VM: ObservableObject { @Published }` + `@StateObject` | `@Observable class VM` + `@State`/`@Bindable`/`@Environment(Type.self)` | iOS 17 |
| Two-param `onChange` (2023) | `.onChange(of:) { newValue in }` | `.onChange(of:, initial:) { old, new in }` | iOS 17 |
| `#Preview`/`@Previewable`/`@Entry` (2023–24) | `PreviewProvider` + manual `EnvironmentKey` | `#Preview { @Previewable @State }`, `@Entry var` | iOS 17 |
| Style deprecations (rolling) | `.foregroundColor`, `edgesIgnoringSafeArea` | `.foregroundStyle`, `.ignoresSafeArea` | iOS 15 |
| `tabItem` → `Tab(){}` | `tabItem {}` / `TabView` without `Tab` | `Tab("Label", systemImage:) {}` inside `TabView` | iOS 18 |
| Sheet detents (2022) | full-height `.sheet` only | `.presentationDetents([.medium, .large])` | iOS 16 |
| Swift 6 strict concurrency (2024) | non-`Sendable` across actors; `DispatchQueue.main.async` | `Sendable`-correct, `@MainActor`, `.task` | toolchain |
| Swift 6.2 approachable concurrency (2025) | assume main-actor-by-default everywhere | opt-in `-default-isolation MainActor` build mode | toolchain 6.2 |
| Liquid Glass (2025) | `.glassBackground()` / `.liquidGlass()` (invented) | `glassEffect(_:in:)`, `GlassEffectContainer`, `.buttonStyle(.glass)` — `#available(iOS 26)` | iOS 26 |

## iOS-shaped surfaces AI gets wrong (or reaches for the macOS shape)

An AI trained on a cross-platform corpus reaches for the macOS scene/menu/pointer vocabulary that
**doesn't exist on iOS**, or forgets the iOS-specific affordances. These are what make code feel native:

- **App lifecycle & scenes** — `WindowGroup` is the iOS app scene; **no `Settings {}` / `MenuBarExtra`
  / `.commands {}`**. Use `onChange(of: scenePhase)` for background save, `@SceneStorage` for small UI
  restoration, `.onOpenURL`/`.onContinueUserActivity`, `BGTaskScheduler` for background work. → app-lifecycle.md
- **Menus on iOS** — `Menu { }` (pull-down), `.contextMenu { }` (long-press), `.swipeActions` on a list
  row, App Intents to reach Shortcuts/Spotlight/Action button. **Never `.commands {}`/`CommandMenu`.** → app-lifecycle.md
- **Touch affordances** — 44 pt hit targets, `.contextMenu`/`.swipeActions`, haptics; `.onHover`/`.help`
  are pointer-only (iPad pointer is an enhancement, never the only path). → controls-and-touch.md
- **Dynamic Type** — semantic text styles, `@ScaledMetric`, support the largest accessibility sizes
  (the single most-skipped iOS requirement). → controls-and-touch.md
- **Sheets & presentation** — `.presentationDetents`, `.presentationDragIndicator`,
  `.presentationBackground`, `fullScreenCover`. → controls-and-touch.md
- **UIKit interop** — `UIViewRepresentable`/`UIViewControllerRepresentable` (+ `updateUIView`/
  `Coordinator`/`dismantleUIView`), the `UIHostingController`/`UIHostingConfiguration` reverse bridge. → uikit-interop.md
- **Adaptive navigation** — `NavigationStack` (iPhone primary) and **size-class-gated**
  `NavigationSplitView` (iPad regular width); `columnVisibility`; `.navigationDestination(for:)`. → adaptive-navigation.md
- **Document & file access** — `fileImporter`/`UIDocumentPickerViewController`; security-scoped
  bookmarks; **no App-Sandbox `.entitlements`** — iOS files are container + user-picked-URL only. → file-handling.md
- **Widgets & Live Activities** — `WidgetKit` `TimelineProvider`, `ActivityKit` Live Activities (iOS
  16.1+), Dynamic Island. → app-lifecycle.md
- **Liquid Glass (iOS 26)** — `glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass/.glassProminent)`,
  `glassEffectID`/`glassEffectUnion`. → liquid-glass.md

## Per-domain rules + router

Load the named reference when you touch that area. Each block lists the always-true rules; the doc has
the ❌/✅ code.

**State & observation** — `@Observable final class` for reference models; **own** with `@State`, bind a
non-owned one with `@Bindable`, inject by type via `.environment(x)` + `@Environment(T.self)`. No
`@Published`/`ObservableObject`/`@StateObject` for new code. Never `@ObservedObject var x = T()`. Split
big views into `View` **types**, not computed `var`s. → `references/state-and-observation.md`

**Version drift & hallucination** — Cross-check every API against `references/api-currency.md`. Bans:
`NavigationView`, `.foregroundColor`, `edgesIgnoringSafeArea`, single-param `onChange`, `tabItem`. Never
emit an API you can't cite; gate new APIs on the **iOS** arm. → `references/version-and-hallucination.md`

**App lifecycle & scenes** — `WindowGroup` is the iOS app scene (no `Settings`/`MenuBarExtra`/
`.commands`). Save on `onChange(of: scenePhase) == .background`; `@SceneStorage` for small UI state;
`.onOpenURL`/`.onContinueUserActivity`; `BGTaskScheduler`; widgets & Live Activities. → `references/app-lifecycle.md`

**Adaptive navigation** — `NavigationStack` is the iPhone primary shell; `NavigationSplitView` is the
**adaptive** choice that must be **gated to regular width / iPad**, never unconditional. Value-based
`.navigationDestination(for:)`; `columnVisibility`; toolbar placements `.topBarLeading`/`.topBarTrailing`/
`.principal`/`.primaryAction`; `.navigationTitle`. → `references/adaptive-navigation.md`

**UIKit interop** — `UIViewRepresentable` needs `makeUIView`/`updateUIView`/`makeCoordinator` and
`dismantleUIView` for teardown; delegates round-trip through the `Coordinator` (weak-capture the parent);
first responder is `UIResponder.becomeFirstResponder()` / SwiftUI `@FocusState`. Watch the Swift-6
Sendable-closure boundary. → `references/uikit-interop.md`

**Concurrency** — Swift 6 default = strict data-race **checking**; main-actor-by-default is an **opt-in**
6.2 build mode. `.task`/`.task(id:)` not `Task {}` in lifecycle; no `DispatchQueue.main.async`; make
cross-actor types `Sendable`. → `references/concurrency.md`

**Layout & tables** — adaptive layout with size classes / `ViewThatFits` / `Grid`; `List` is the iOS
primary (a `Table` is iPad/macOS-shaped — use it only in regular width). → `references/layout-and-tables.md`

**Controls & touch** — 44 pt hit targets; `.contextMenu`/`.swipeActions`; `.presentationDetents`;
Dynamic Type (`@ScaledMetric`, semantic styles); on iOS `Form` is already grouped (drop `.formStyle`).
`.onHover`/`.help` are pointer-only enhancements, never the only path. → `references/controls-and-touch.md`

**Liquid Glass (iOS 26)** — Real names only (`glassEffect(_:in:)`, `GlassEffectContainer`,
`.buttonStyle(.glass/.glassProminent)`). Glass on the **navigation layer only**, never content, never
glass-on-glass; group siblings in `GlassEffectContainer`; gate `#available(iOS 26, *)` with an
`.ultraThinMaterial` fallback. `Glass.interactive()` is iOS 26 too (touch-driven on iOS). → `references/liquid-glass.md`

**SwiftData** — `var` (never `let`) relationships; assign relationships after insert, not in `init`;
in-memory container for previews; handle `ModelContainer` errors (no `fatalError`); explicit
`try modelContext.save()` — and save on `scenePhase == .background` (iOS terminates suspended apps). → `references/swiftdata.md`

**Document & file access** — Holding a URL ≠ being allowed to open it. `fileImporter`/
`UIDocumentPickerViewController` consent; security-scoped bookmarks for re-access (no `.entitlements`
on iOS); `Transferable`/`.dropDestination` (Sendable-correct) for drag-drop; `UIPasteboard` not
`NSPasteboard`. → `references/file-handling.md`

**Previews** — `#Preview {}` not `PreviewProvider`; `@Previewable @State` inside previews; `@Entry`
for environment values; in-memory container for SwiftData previews; inject `@Environment` models.
→ `references/previews.md`

**View rendering performance** — avoid heavy work in `body`/`init`, `.id(UUID())`, `AnyView`, and
filter/sort inside `ForEach`; lazy stacks/grids for long scrolls; know the iOS device-cost of glass and
large `List`s. → `references/view-performance.md`

## Detection

Before proposing code, run the grep lint and fix every hard-fail:
`bash ${CLAUDE_PLUGIN_ROOT}/scripts/ios-swiftui-lint.sh <files-or-dir>`. The full rule list
(WRONG → correct, mapped to each doc) is `references/lint-checklist.md`.

## Verification & enforcement

This skill ships a closed loop — use it to legitimately claim rung 2+ of the Output Contract:
- **Lint** (`scripts/ios-swiftui-lint.sh`) — fast grep self-check; hard-fails exit non-zero.
- **Compile hook** — a `PostToolUse` hook (`hooks/hooks.json` → `swiftui-build-check.sh`) builds the
  enclosing project for an **iOS Simulator** destination after each Swift edit and **blocks on compile
  errors**. It needs Xcode + the iOS 26 SDK and a real Xcode/SwiftPM project; it no-ops elsewhere.
- **Reviewer** — the `swiftui-ios-reviewer` subagent audits a diff against this catalog and reports
  `FILE / RULE / LINE / VIOLATION / FIX`. Invoke it before declaring a change done.

State the verification rung you actually reached. "Compiles" requires the hook/build to have run green.

## Guardrails / non-goals

- iOS/iPadOS only. If the user wants macOS/Catalyst, say this skill is iOS-scoped and stop.
- Don't invent APIs. Unverified → mark "verify against your Xcode 26 SDK" (see `api-currency.md`).
- Don't enforce an app architecture. Teach data flow, not layering.
- Out of scope: visual HIG auditing, Liquid Glass aesthetics, packaging/codesigning/submission,
  lint/format config. Don't attempt them — say so.

## Reference index

| File | Read when |
|---|---|
| `references/api-currency.md` | Any concrete API — the real-vs-deprecated-vs-hallucinated ground truth |
| `references/state-and-observation.md` | @Observable / @State / @Bindable / @Environment, ownership, re-render bugs |
| `references/version-and-hallucination.md` | Deprecations, hallucinated modifiers, `#available(iOS)` gating |
| `references/app-lifecycle.md` | WindowGroup, scenePhase save, @SceneStorage, onOpenURL, BGTaskScheduler, widgets/Live Activities, iOS menus |
| `references/adaptive-navigation.md` | NavigationStack / size-class-gated NavigationSplitView, navigationDestination, toolbar placements |
| `references/uikit-interop.md` | UIViewRepresentable, Coordinator, first responder, UIHostingController |
| `references/concurrency.md` | Swift 6 / 6.2, @MainActor, Sendable, `.task` vs Task |
| `references/layout-and-tables.md` | Adaptive layout, size classes, ViewThatFits/Grid, List vs Table |
| `references/controls-and-touch.md` | Touch targets, context menus, swipe actions, sheet detents, Dynamic Type |
| `references/liquid-glass.md` | iOS 26 glass: real APIs, navigation-layer rule, iOS-arm gating |
| `references/swiftdata.md` | @Model relationships, container, previews, save, scenePhase save |
| `references/file-handling.md` | Document picker, security-scoped URLs/bookmarks, Transferable, UIPasteboard |
| `references/previews.md` | #Preview / @Previewable / @Entry, SwiftData/env preview crashes |
| `references/view-performance.md` | Rendering anti-patterns, lazy stacks/grids, large-List cost, device glass cost |
| `references/lint-checklist.md` | The grep tells (mirrors the lint script) |
| `../../references/_shared/hig-design-rubric.md` | Design defaults — type scale, contrast, 44 pt, spacing, nav limits (cited HIG) |
| `../../references/_shared/liquid-glass-design.md` | Liquid Glass *design* placement/tint/adoption (complements `references/liquid-glass.md` API) |
| `../../references/_shared/design-claims-blacklist.md` | Debunked design myths to never assert |
