# Model lifecycle & iOS app-scoped ownership (state-09, state-10, state-12)

Three facts about *when* a model is constructed and *where* it lives. They don't fit the wrapper-mismatch
frame but bite once the wrappers are right. All `advisory`, `flag-only`.

## state-09 — heavy `init()` in a `@State` default of a frequently-re-evaluated view

Apple's `@State` docs warn the default value is created **each time SwiftUI instantiates the view**:
SwiftUI keeps the original stored instance, but a fresh `Model()` is constructed and thrown away on every
re-evaluation, and any `init()` side-effects (timers, observers, network kick-offs, log lines) **re-run**
each time. For app/scene-scoped models, declare them at `App`/`Scene` level (owned once) or defer heavy
init into `.task`; don't put expensive construction in the `@State` default of a row/cell/frequently-
evaluated view.

```swift
// ❌ WRONG — expensive init re-runs on every parent re-render (throwaway instances linger)
@available(iOS 17, *)
struct RowView: View {
    @State private var model = HeavyModel()   // HeavyModel() side-effects fire each re-evaluation
    var body: some View { Text(model.title) }
}
// ✅ CORRECT — own heavy / app-wide models ONCE at App scope, inject down (iOS 17+)
@available(iOS 17, *)
@main struct iOSApp: App {
    @State private var model = HeavyModel()   // constructed once for the app
    var body: some Scene { WindowGroup { RootView() }.environment(model) }
}
```

**Detection nuance:** `@State var x = Type()` is the *normal, correct* idiom for a cheap view-local model —
the grep tell LOCATES every one. **READ** to judge: report only when the `init()` is genuinely heavy
(side-effects / I/O) **and** the view is re-evaluated often (a row, a cell, a `ForEach` body). A cheap
struct default is not a finding.

## state-10 — `static let shared` singleton / global app state forced into a singleton (the iOS smell)

On iOS, `WindowGroup` is typically single-window, but app-wide state hoisted into a `static let
shared` singleton still breaks the SwiftUI ownership model: mutations bypass the `@State` graph,
making the model invisible to SwiftUI's re-render tracking. Own app-wide state **once** at `App`
scope with `@State private var appState = AppState()` and inject at the **scene** with
`.environment(appState)` so all views see it; keep per-screen concerns as `@State` in the
screen's root view — **never** `static let shared`.

```swift
// ❌ WRONG — global singleton bypasses @State graph, invisible to SwiftUI re-render tracking
final class AppState { static let shared = AppState(); var selection: Item? }
// ✅ CORRECT — own once at App scope, inject at the scene (iOS 17+)
@available(iOS 17, *)
@main struct iOSApp: App {
    @State private var appState = AppState()
    var body: some Scene { WindowGroup { RootView() }.environment(appState) }
}
```

## state-12 — view-only `@Observable` with no `@MainActor` (older default-isolation builds)

**Swift 6.2 "Default Actor Isolation = Main Actor":** with that build setting on, types (including
`@Observable` classes) are already `@MainActor`-isolated, so **no explicit `@MainActor` is needed**. Without
it (the older default), annotate an `@Observable` class `@MainActor` when it is only ever touched from views,
to keep mutations on the main actor. **Read the build setting in ORIENT** (`SWIFT_DEFAULT_ACTOR_ISOLATION`
= `MainActor`) — if it is on, do **not** flag a missing `@MainActor`. **Seam:** real Sendable / isolation
*hazards* are `audit-swiftui-concurrency-safety`; this is only the one-line view-only-model hygiene note →
emit `cross_ref: audit-swiftui-concurrency-safety` (and do not assert `swift_era`, which is concurrency's
additive field, not this skill's).

```swift
// ✅ The corpus consensus already pairs them — recommended Observable example ex_8a9e39b23c is
//    `@Observable @MainActor final class …` (rrroyal/Harbour, a screen view-model), via swiftui-ctx lookup Observable.
```

## ✅ grounded in swiftui-ctx

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup State --platform ios --json        # @State re-instantiation idiom; recommended example
bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup Observable --platform ios --json   # recommended ex_8a9e39b23c = @Observable @MainActor
bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file ex_8a9e39b23c --smart # the @MainActor model, live from GitHub
```

`lookup Observable --platform ios` (accessed 2026-06-16): recommended `ex_8a9e39b23c` (`rrroyal/Harbour`) is
`@Observable @MainActor final class` — the canonical own-once, main-actor shape. Cite that permalink.

## Severity & fix mode

All `advisory`, `fix_mode: flag-only`. state-09 `failure_shape: over-render`; state-10 `failure_shape:
lost-restoration` (app state bypasses `@State` graph / shared singleton); state-12 `failure_shape: over-render` (with the
`cross_ref` to concurrency-safety). `model_kind` per the model.

## Sources

- **Apple — `State`.** Default value is instantiated every time SwiftUI instantiates the view; recommends
  app/scene-scoped models live at `App`/`Scene` level.
  https://developer.apple.com/documentation/swiftui/state — accessed 2026-06-07 (via Sosumi).
- **Apple — `WindowGroup` / `Scene`.** On iOS, inject shared models at the scene so all views
  see them. https://developer.apple.com/documentation/swiftui/windowgroup — accessed 2026-06-07 (via Sosumi).
- **Swift Evolution — SE-0466 "Default actor isolation."** The "Default Actor Isolation = MainActor"
  build mode (Swift 6.2). https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md
  — accessed 2026-06-07.
