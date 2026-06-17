# State & Observation (iOS)

Where state lives and how it's observed is the single most error-dense area of AI-written SwiftUI. The data-flow rules changed in **iOS 17** (the `@Observable` macro), and a lot of LLM training data predates that split — so AI defaults to the legacy `ObservableObject` + `@Published` + `@StateObject` world, mixes the two worlds illegally, and pairs the wrong wrapper with each model type. Two distinct failure shapes result: **silent runtime state resets** (wrong-but-legal ownership wrapper on a real `ObservableObject`) and **hard compiler errors** (a legacy wrapper that requires `ObservableObject` conformance placed on an `@Observable` type, which does not conform). Knowing which shape a given mismatch produces is half the fix.

Every example here compiles on an **iOS target** (iOS 17+ unless noted). The wrappers are semantically identical cross-platform; macOS appears only as a ❌ contrast. The iOS-17 deployment floor means `@Observable` is *the* default — there is rarely a back-deployment reason to stay on `ObservableObject`.

## The two worlds — pick one per model

- **Modern (default).** `@Observable final class` — **no** `@Published`, **no** `ObservableObject` conformance. Field-granular observation: a view invalidates only when the property it actually reads changes. Own it with `@State`, bind with `@Bindable`, inject with `.environment(_:)` + `@Environment(Type.self)`.
- **Legacy (only for Combine publishers / back-deployment below iOS 17).** `class: ObservableObject` + `@Published`. Whole-object `objectWillChange` over-renders. Own it with `@StateObject`, observe with `@ObservedObject`, inject with `@EnvironmentObject`. **Not deprecated** — but not the idiom for new iOS code.

```swift
// ✅ CORRECT — modern world, the default for new iOS code (iOS 17+)
@available(iOS 17, *)
@Observable final class DocumentModel {            // no ObservableObject, no @Published
    var title = "Untitled"
    var isDirty = false
}
```

## Mistake 1 — Wrong ownership wrapper (two failure shapes: silent reset vs compile error)

A view-owned model paired with the wrong wrapper fails one of two ways depending on the model kind. Both stem from the same root cause — **`@ObservedObject` does not own or persist its object** — but they surface completely differently, so diagnose by which one you're looking at.

**Shape A — silent state reset (legacy `ObservableObject`, created in place).** `@ObservedObject var x = SomeObservableObject()` compiles fine: `SomeObservableObject` *is* an `ObservableObject`, so the wrapper accepts it. But `@ObservedObject` does not own the instance — when the parent re-renders, SwiftUI rebuilds the struct, the initializer runs again, and all accumulated state silently resets to defaults. No compile error, no crash, just a counter that "won't count." The fix is the owning wrapper: `@StateObject` (legacy) or `@State` (modern).

```swift
// ❌ WRONG (silent reset) — real ObservableObject, but created+owned under @ObservedObject
struct CounterView: View {
    @ObservedObject var model = CounterModel()     // CounterModel: ObservableObject — compiles,
    var body: some View { Text("\(model.count)") } // but recreated on every parent re-render
}
```

**Shape B — compile error (`@Observable` type under a legacy wrapper).** `@ObservedObject` and `@StateObject` *require* their wrapped object to conform to `ObservableObject`. An `@Observable` type does **not** conform, so the compiler rejects it outright. Per Apple's `@ObservedObject` docs: *"Attempting to wrap an Observable object with @ObservedObject may cause a compiler error, because it requires that its wrapped object conform to the ObservableObject protocol."* The fix is `@State` (owned) or `@Bindable` (passed in).

```swift
// ❌ WRONG (compile error) — @Observable type cannot satisfy @ObservedObject's ObservableObject requirement
@available(iOS 17, *)
struct CounterView2: View {
    @ObservedObject var model = CounterModel()     // CounterModel is @Observable → does NOT compile
    var body: some View { Text("\(model.count)") }
}
```

```swift
// ✅ CORRECT — modern @Observable owned by the view → @State (iOS 17+)
@available(iOS 17, *)
@Observable final class CounterModel { var count = 0 }

@available(iOS 17, *)
struct CounterView: View {
    @State private var model = CounterModel()       // stable, SwiftUI-managed lifetime
    var body: some View { Text("\(model.count)") }
}

// ✅ CORRECT — legacy ObservableObject owned by the view → @StateObject
struct LegacyCounterView: View {
    @StateObject private var model = LegacyCounterModel() // LegacyCounterModel: ObservableObject
    var body: some View { Text("\(model.count)") }
}
```

## Mistake 2 — Treating `@Observable` as a literal drop-in (keeps `@StateObject` / `@Published`)

The migration is **not** a mechanical rename. Under `@Observable` you do **not** write `@Published` (the macro tracks property access automatically), do **not** conform to `ObservableObject`, and own the instance with `@State`, **not** `@StateObject`. Mixing the worlds compiles but is semantically wrong.

**Transitional note (don't over-flag):** Apple deliberately lets `@StateObject` and `@EnvironmentObject` accept a *plain* `@Observable` type (one without redundant `ObservableObject` conformance) so a codebase can migrate incrementally — `@StateObject var x: SomeObservableType` is a **migration smell to finish converting to `@State`**, not a hard error. The genuinely wrong part below is the redundant `: ObservableObject` + `@Published`, which contradicts the `@Observable` macro.

```swift
// ❌ WRONG — @Observable class but still ObservableObject-era wrappers
@Observable class ViewModel: ObservableObject {    // redundant/contradictory conformance
    @Published var items: [Item] = []              // @Published is meaningless under @Observable
}
struct ListView: View {
    @StateObject private var vm = ViewModel()       // wrong owner wrapper for @Observable
}
```
```swift
// ✅ CORRECT — no ObservableObject, no @Published, owned with @State (iOS 17+)
@available(iOS 17, *)
@Observable final class ViewModel {
    var items: [Item] = []
}
@available(iOS 17, *)
struct ListView: View {
    @State private var vm = ViewModel()
    var body: some View { List(vm.items) { item in Text(item.title) } }  // iOS-primary list
}
```

## Mistake 3 — `@ObservedObject` / `@Binding` where a non-owned `@Observable` property needs binding (should be `@Bindable`)

An `@Observable` class held in a plain property (passed in, injected, or any non-owning reference) has **no projected value**, so `$counter.count` does not exist. `@Bindable` is the wrapper that adds binding projection to an `@Observable` object the view does **not** own.

```swift
// ❌ WRONG — can't form $counter.count from a plain @Observable property
struct InspectorView: View {
    var counter: MyCounter = MyCounter()           // @Observable, but not bindable
    var body: some View {
        Stepper("Count", value: $counter.count)    // error: Cannot find '$counter' in scope
    }
}
```
```swift
// ✅ CORRECT — non-owning view that needs two-way bindings → @Bindable (iOS 17+)
@available(iOS 17, *)
@Observable final class MyCounter { var count = 0 }

@available(iOS 17, *)
struct InspectorView: View {
    @Bindable var counter: MyCounter               // passed in, not owned here
    var body: some View {
        Stepper("Count", value: $counter.count)    // now compiles
    }
}
```

## Mistake 4 — `@EnvironmentObject` for an injected `@Observable` (should be `@Environment(Type.self)`)

`@EnvironmentObject` / `.environmentObject(_:)` belong to the **legacy** world. The `@Observable` world injects through the **type-keyed** environment: `.environment(instance)` to inject, `@Environment(Type.self)` to retrieve. To then bind an injected `@Observable`, re-wrap it **locally inside `body`** with `@Bindable var x = x`. On iOS this injection is typically at the **`App` / `WindowGroup` scene** level (or the root view) so the whole view tree of the single foreground scene sees the shared model.

```swift
// ❌ WRONG — @EnvironmentObject only works with ObservableObject
@Observable class Library { var books: [Book] = [] }
struct RootView: View {
    var body: some View { LibraryView().environmentObject(Library()) }  // type mismatch under @Observable
}
struct LibraryView: View { @EnvironmentObject var library: Library }     // wrong wrapper
```
```swift
// ✅ CORRECT — inject by type at scene level, retrieve by type, bind locally (iOS 17+)
@available(iOS 17, *)
@Observable final class Book { var title = "Sample Book Title" }

@available(iOS 17, *)
@main struct DemoApp: App {
    @State private var book = Book()               // owned once, @State at App scope
    var body: some Scene {
        WindowGroup { TitleEditView() }
            .environment(book)                     // the whole scene's tree sees it
    }
}
@available(iOS 17, *)
struct TitleEditView: View {
    @Environment(Book.self) private var book       // read-only by type
    var body: some View {
        @Bindable var book = book                  // local re-wrap to project $book.title
        TextField("Title", text: $book.title)
    }
}
```

## Mistake 5 — `@StateObject` for a value type, or `@State`/`@StateObject` mismatched to the model kind

`@StateObject` is constrained to **reference types** — a `struct` cannot be a `@StateObject` (hard compile error). It accepts a plain `@Observable` class (Apple allows this for migration), but doing so leaves you on the legacy wrapper: a **migration smell**, not the idiom. Match the model kind to its owner wrapper.

```swift
// ❌ WRONG (compile error) — @StateObject needs a reference type; a struct is not one
struct V: View { @StateObject private var settings = SettingsStruct() }  // value type → error
// ⚠️ SMELL (compiles) — @Observable accepted by @StateObject, but should be @State
struct W: View { @StateObject private var model = ModelObservable() }    // finish migrating → @State
```
```swift
// ✅ CORRECT — match the model kind to its owner wrapper (iOS 17+ for @Observable)
@available(iOS 17, *)
struct CorrectOwners: View {
    @State private var settings = SettingsStruct()  // value type owned by view → @State
    @State private var model = ModelObservable()    // @Observable owned by view → @State
    var body: some View { /* … */ }
}
```

| Model kind | Own it with | Bind with | Inject / read with |
|---|---|---|---|
| value type (`struct`, `enum`) | `@State` | `@Binding` | `@Environment(\.key)` (custom env value) |
| `ObservableObject` class (legacy) | `@StateObject` | `@ObservedObject`'s `$`, `@Binding` | `@EnvironmentObject` |
| `@Observable` class (modern) | `@State` | `@Bindable` | `.environment(_:)` + `@Environment(Type.self)` |

## Mistake 6 — Hiding `@Observable` reads inside computed `some View` properties (kills invalidation granularity)

Not a correctness bug — a real **performance regression** specific to `@Observable`. Observation tracks per-property access at the granularity of a `View` `body`. A computed `some View` property folds into the **parent's** body, so a change to any tracked property re-evaluates the whole parent. Extract into a real child `View` **type** (its own `body`), passing only the data it needs.

```swift
// ❌ WRONG (perf) — AI splits the view into a computed property to "tidy" it
@available(iOS 17, *)
struct DashboardView: View {
    @State private var vm = DashboardModel()
    var body: some View { header; list }
    private var list: some View { /* reads vm.items */ Text("…") }  // computed, not a View type
    private var header: some View { Text("…") }
}
```
```swift
// ✅ CORRECT — extract into a real child View type (iOS 17+)
@available(iOS 17, *)
struct DashboardView: View {
    @State private var vm = DashboardModel()
    var body: some View { Header(); ItemList(items: vm.items) }
}
@available(iOS 17, *)
struct ItemList: View { let items: [Item]; var body: some View { /* … */ } }
```

## `@Observable` essentials AI omits

Four model-level facts that don't fit the wrapper-mismatch frame but bite once the wrappers are right.

**Exclude a property from tracking — `@ObservationIgnored` (iOS 17).** The `@Observable` macro tracks every stored property by default. Mark caches, back-pointers, or non-UI bookkeeping with `@ObservationIgnored` so mutating them never invalidates a view.

```swift
// ✅ CORRECT — UI-relevant fields tracked; a private cache opts out (iOS 17+)
@available(iOS 17, *)
@Observable final class SearchModel {
    var query = ""                       // tracked: typing redraws results
    @ObservationIgnored private var cache: [String: [Result]] = [:]  // never triggers invalidation
}
```

**`@State var model = Model()` re-instantiates on every view evaluation.** Apple's `@State` docs warn the default value is created *each time SwiftUI instantiates the view* — SwiftUI keeps the original stored instance, but a fresh `Model()` is constructed and thrown away on every re-evaluation, and any `init()` side-effects (timers, observers, network kick-offs, log lines) re-run each time. For app/scene-scoped models, declare them at `App`/`Scene` level (owned once) or defer heavy init into `.task`; don't put expensive construction in the `@State` default of a frequently-re-evaluated view.

```swift
// ❌ WRONG — expensive init re-runs on every parent re-render (throwaway instances linger)
@available(iOS 17, *)
struct RowView: View {
    @State private var model = HeavyModel()   // HeavyModel() side-effects fire each re-evaluation
    var body: some View { Text(model.title) }
}
// ✅ CORRECT — own heavy/app-wide models once at App scope, inject down
@available(iOS 17, *)
@main struct DemoApp: App {
    @State private var model = HeavyModel()   // constructed once for the app
    var body: some Scene { WindowGroup { RootView() }.environment(model) }
}
```

**Swift 6.2 — "Default Actor Isolation = Main Actor."** With that build setting on, types (including `@Observable` classes) are already `@MainActor`-isolated, so **no explicit `@MainActor` is needed**; without it (the older default), annotate an `@Observable` class `@MainActor` when it is only ever touched from views, to keep mutations on the main actor.

**Observe changes *outside* `body` — `Observations` async sequence (iOS 26 / Swift 6.2).** `struct Observations<Element, Failure>` streams transactional changes to `@Observable` properties as an `AsyncSequence`, for driving non-view logic (logging, sync, side-effects) off a model without a manual `withObservationTracking` loop. View-`body` invalidation does **not** need this — it's for code that lives outside SwiftUI's evaluation.

```swift
// ✅ iOS 26 — react to @Observable changes outside a view body
@available(iOS 26, *)
func mirror(_ model: SearchModel) async {
    for await q in Observations({ model.query }) {   // emits on each transactional change
        await persist(q)
    }
}
```

## Detection tells

Grep/scan signals that flag the mistakes above:

- **`@ObservedObject var <name> = <Type>(`** — initializer on an `@ObservedObject` ⇒ view is *creating* what it doesn't own ⇒ should be `@StateObject` (legacy) or `@State` (modern). `@ObservedObject` is almost always passed in, never initialized in place.
- **`@Observable` class … `: ObservableObject`** — contradictory dual conformance; drop `ObservableObject`.
- **`@Published` inside an `@Observable`-annotated class** — meaningless; remove it.
- **`@StateObject` on a `struct`/`enum`** — hard compile error (needs a reference type); should be `@State`. **`@StateObject` on a plain `@Observable` class** — compiles (Apple allows it for migration) but is a smell; finish converting to `@State`.
- **`@EnvironmentObject` in a file whose model is `@Observable`** — should be `@Environment(Type.self)`.
- **`$someObservable.property`** where `someObservable` is a plain or `@Environment(Type.self)` property with **no `@Bindable` re-wrap nearby** — missing `@Bindable`.
- **`private var <name>: some View {`** computed property reading an `@Observable` model — extract to a child `View` type (perf).
- **iOS smell:** app-wide state hoisted into a `static let shared` singleton instead of `@State` at `App` scope + `.environment(_:)`. Own app-wide state once at the `App` and inject by type; keep per-screen state (`NavigationPath`, a selected tab, sheet flags) as `@State` in the screen's root, not in a global object.

## Canonical pattern

Quote this block verbatim when prescribing the rules:

```
STATE & OBSERVATION — CANONICAL RULES (iOS 17+/iOS 17+ era)

1. Pick ONE world per model:
   • Modern (default): @Observable class — NO @Published, NO ObservableObject.
   • Legacy (only if you need Combine publishers): class: ObservableObject + @Published.

2. Ownership → wrapper:
   • Value type owned by view ............. @State
   • @Observable class owned by view ...... @State
   • ObservableObject owned by view ....... @StateObject
   • NEVER initialize a model inside @ObservedObject/@Bindable — those are for
     objects owned elsewhere and passed in. (@ObservedObject = SILENT reset on a
     real ObservableObject; @ObservedObject/@StateObject on an @Observable type =
     COMPILE ERROR — it isn't an ObservableObject.)

3. Bindings:
   • Binding into a value owned by another view ........... @Binding ($value)
   • Binding to a property of a non-owned @Observable ..... @Bindable (then $obj.prop)

4. Dependency injection:
   • Modern: .environment(instance)  +  @Environment(Type.self)
             (re-wrap locally with `@Bindable var x = x` to make bindings)
   • Legacy: .environmentObject(instance)  +  @EnvironmentObject

5. Perf: extract subviews into separate View TYPES, not computed `some View`
   properties — only real View types get @Observable's per-property invalidation.

6. Model hygiene:
   • @ObservationIgnored on stored props that must NOT invalidate views (caches, back-refs).
   • @State default value is re-created on every view evaluation — keep heavy init()
     OUT of frequently-evaluated views; own app/scene models once at App/Scene scope.
   • Swift 6.2 "Default Actor Isolation = Main Actor" → @Observable needs no @MainActor;
     without it, annotate @MainActor when the model is only used from views.
```

**iOS injection addendum:** own app-wide state once at `App` scope with `@State private var appState = AppState()` and inject at the **scene/root** with `.environment(appState)` so the whole foreground tree sees it — never `static let shared`. Per-screen concerns (the current `NavigationPath`, the selected `Tab`, `@SceneStorage` UI restoration state, `NavigationSplitViewVisibility` on iPad) stay as `@State` in that screen's root view, not in the global object.

## Sources

All API/availability claims carry a verbatim quote against the Apple docs snapshot of 2026-06-07. No UNVERIFIED symbols apply to the state/observation core — `@Observable`, `@ObservationIgnored`, `@Bindable`, `@State`, `@Binding`, `@Environment(Type.self)`, `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` are all body-confirmed against Apple docs; `Observations` is gated `@available(iOS 26, *)`.

- **Apple — `Observable()` macro.** Availability `iOS 17.0+` (and iOS 17.0+). https://developer.apple.com/documentation/observation/observable() — scraped 2026-06-06.
- **Apple — `ObservationIgnored()` macro.** Availability `iOS 17.0+`. Disables observation tracking for a stored property of an `@Observable` type. https://developer.apple.com/documentation/observation/observationignored() — accessed 2026-06-07.
- **Apple — `ObservedObject`.** "*Attempting to wrap an Observable object with @ObservedObject may cause a compiler error, because it requires that its wrapped object conform to the ObservableObject protocol.*" https://developer.apple.com/documentation/swiftui/observedobject — accessed 2026-06-07.
- **Apple — `State`.** Warns the default value is instantiated every time SwiftUI instantiates the view; recommends app/scene-scoped models live at `App`/`Scene` level. https://developer.apple.com/documentation/swiftui/state — accessed 2026-06-07.
- **Apple — `Observations`.** `struct Observations<Element, Failure>`, an `AsyncSequence` of transactional `@Observable` changes; availability `iOS 26.0+` (Swift 6.2). https://developer.apple.com/documentation/observation/observations — accessed 2026-06-07.
- **Apple — `Bindable`.** Availability `iOS 17.0+`. "*A property wrapper type that supports creating bindings to the mutable properties of observable objects.*" Overview carries the `@Environment(Book.self) private var book` + `@Bindable var book = book` injection example. https://developer.apple.com/documentation/swiftui/bindable — scraped 2026-06-06.
- **Apple — Migrating from the Observable Object protocol to the Observable macro.** `@State`/`@Bindable`/`@Environment` mapping. https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro — accessed 2026-06-06.
- **Jesse Squires — "SwiftUI's `@Observable` macro is not a drop-in replacement for `ObservableObject`," 2024-09-09.** "*Use the `@StateObject` property wrapper with `ObservableObject` and use the `@State` property wrapper with `@Observable`.*" https://www.jessesquires.com/blog/2024/09/09/swift-observable-macro/ — accessed 2026-06-06.
- **Donny Wals — "What's the difference between @Binding and @Bindable," upd. 2024-04-23.** Own → `@State`, non-owned → `@Bindable`; `$counter` error without `@Bindable`. https://www.donnywals.com/whats-the-difference-between-binding-and-bindable/ — accessed 2026-06-06.
- **Paul Hudson — "What to fix in AI-generated Swift code," 2025-12-09.** Replace `ObservableObject` → `@Observable`; computed-property views defeat `@Observable` invalidation. https://www.hackingwithswift.com/articles/281/what-to-fix-in-ai-generated-swift-code — accessed 2026-06-06.
