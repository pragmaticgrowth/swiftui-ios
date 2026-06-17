# iOS SwiftUI API Currency

Ground-truth, primary-source-verified snapshot of current vs. deprecated **iOS** SwiftUI APIs. Every other doc in this skill cross-checks symbol names, availability floors, and deprecation dates against this file.

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain** (verified Swift 6.2 introduced approachable concurrency; shipping toolchain at scrape time was the 6.3.x point line, which carries the same 6.2 concurrency model). All CONFIRMED facts scraped **2026-06-06** from `developer.apple.com`, `swift.org`, and WWDC25 session pages, with a **2026-06-07** correction pass against the `developer.apple.com` JSON availability endpoints and the iOS catalog. **iOS-only:** where Apple renders a multi-platform availability string, only the iOS arm is reproduced here.

---

## Current vs deprecated (dated)

Wrong = AI's stale training default. Right = current iOS idiom. Floor = lowest iOS the *right* API supports.

| Era boundary (date) | Wrong (stale) | Right (current) | iOS floor |
|---|---|---|---|
| **NavigationView deprecation** (WWDC22 / iOS 16, 2022; window closes 26.5) | `NavigationView { }` | `NavigationStack` (push, primary) / gated `NavigationSplitView` (iPad sidebar) | iOS 16.0+ |
| **`@Observable` macro** (WWDC23 / iOS 17, 2023) | `class VM: ObservableObject { @Published … }` + `@StateObject` | `@Observable class VM` + `@State` / `@Bindable` / `@Environment(Type.self)` | iOS 17.0+ |
| **Two-param `onChange`** (iOS 17, 2023) | `.onChange(of:) { newValue in }` | `.onChange(of:, initial:) { old, new in }` (or 0-param) | iOS 17.0+ |
| **`#Preview` / `@Previewable`** (Xcode 15, 2023 / Xcode 16, 2024) | `struct _Previews: PreviewProvider` | `#Preview { @Previewable @State … }` | iOS 17.0+ |
| **`@Entry` macro** (Xcode 16, 2024) | 3-part `EnvironmentKey` struct + `EnvironmentValues` extension | `@Entry var myKey: T = default` | iOS 13+ (back-deploys) |
| **Style deprecations** (rolling; deprecated through 26.5) | `.foregroundColor`, `.cornerRadius`, `tabItem`, inline-dest `NavigationLink` | `.foregroundStyle`, `.clipShape(.rect(cornerRadius:))`, `Tab(){}`, `.navigationDestination(for:)` | iOS 14–14+ |
| **`dropDestination(for:action:isTargeted:)` 3-arg deprecation** (iOS 26.5) | `dropDestination(for:action:isTargeted:)` (3-arg `Bool`-returning form) | `dropDestination(for:isEnabled:action:)` (iOS 26.0+ successor) | iOS 26.0+ |
| **Gesture renames** (iOS 26.5; successors iOS 17+) | `MagnificationGesture` · `RotationGesture` | `MagnifyGesture` · `RotateGesture` | iOS 17.0+ |
| **`Font.system(_:design:)` (design-only)** (iOS 26.5) | `Font.system(_:design:)` (design arg, no `weight:`) | `Font.system(_:design:weight:)` | same iOS floor as existing form |
| **`.accentColor(_:)` deprecation** (iOS 26.5; successor iOS 15+) | `.accentColor(_:)` | `.tint(_:)` | iOS 15.0+ |
| **Swift 6 strict concurrency default** (Swift 6.0, Sept 2024) | non-`Sendable` crossing actors; `DispatchQueue.main.async` | `Sendable`-correct types, `@MainActor` / `await MainActor.run`, `.task` | toolchain (all targets) |
| **Swift 6.2 "approachable concurrency"** (Sept 15, 2025) | assumes main-actor-by-default everywhere; invents `@concurrent` semantics | opt-in `-default-isolation MainActor` build mode; `@concurrent` is Swift 6.2+ only | toolchain 6.2+ |
| **Liquid Glass** (WWDC25 / iOS 26 Tahoe, 2025) | `.glassBackground()` / `.liquidGlass()` / `.material(.glass)` (hallucinated) | `glassEffect(_:in:)`, `GlassEffectContainer`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)` — `#available(iOS 26)`-gated | iOS 26.0+ |
| **In-app settings (iOS pattern)** | a hand-rolled "Settings" screen with raw `UserDefaults` reads scattered in views | a `Form` settings screen bound to `@AppStorage`; optionally surfaced in the system Settings app via a `Settings.bundle` | iOS 13.0+ |

---

## CONFIRMED APIs (primary-source verified)

Eight clusters, each with the exact iOS availability string and a verbatim signature scraped 2026-06-06.

### 1. Navigation — `NavigationView` is DEPRECATED
- iOS availability: **`iOS 13–26.5 Deprecated`** (deprecation window closes at OS 26.5)
- Signature: `struct NavigationView<Content> where Content : View`
- Apple guidance (verbatim): *"Use `NavigationStack` and `NavigationSplitView` instead. For more information, see Migrating to new navigation types."*
- Also deprecated on the same page: `NavigationViewStyle`, `navigationViewStyle(_:)`.
- Current: `NavigationStack` (push/stack IA) and `NavigationSplitView` (2–3-column sidebar IA — the iPad/regular-width sidebar IA — gate it, never unconditional).
- **`Tab`** — iOS availability: **`iOS 18.0+`**. `struct Tab` is the current value-based `TabView` content primitive (`Tab("Label", systemImage:) { … }`); it replaces the deprecated `.tabItem` builder on `TabView`.

### 2. Observation — `@Observable` macro
- iOS availability: **`iOS 17.0+`**
- Signature: `@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation), named(shouldNotifyObservers)) @attached(memberAttribute) @attached(extension, conformances: Observable) macro Observable()`
- Verbatim: *"Defines and implements conformance of the Observable protocol."*
- `ObservableObject` / `@StateObject` / `@ObservedObject` / `@EnvironmentObject` are **NOT** marked deprecated (no `@available(deprecated)` annotation) — valid for back-deployment, but `@Observable` is the current default. Own with `@State`, bind with `@Bindable`, inject with `.environment(_)` + `@Environment(Type.self)`. No `@Published` and no `: ObservableObject` inside an `@Observable` class.

### 3. `onChange` — two-parameter `(oldValue, newValue)`
- iOS availability: **`iOS 17.0+`**
- Signature:
  ```swift
  nonisolated
  func onChange<V>(
      of value: V,
      initial: Bool = false,
      _ action: @escaping (V, V) -> Void
  ) -> some View where V : Equatable
  ```
- Verbatim example: `.onChange(of: playState) { oldState, newState in ... }`
- The single-param `onChange(of:perform:)` (zero/one-arg closure) is the deprecated form AI emits.

### 4. Liquid Glass — VERIFIED names (iOS 26)
All `iOS 26.0+`. Gate every use with `if #available(iOS 26.0, *)` when the deployment target is below 26.

- **`glassEffect(_:in:)`** — iOS availability: `iOS 26.0+`
  ```swift
  nonisolated
  func glassEffect(
      _ glass: Glass = .regular,
      in shape: some Shape = DefaultGlassEffectShape()
  ) -> some View
  ```
  Verbatim: *"Applies the Liquid Glass effect to a view."*
- **`GlassEffectContainer`** — iOS availability: `iOS 26.0+`
  - Signature: `@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View`
  - Verbatim: *"A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another."* Glass cannot sample glass — group adjacent glass here.
- **`GlassButtonStyle`** + **`.buttonStyle(.glass)`** — iOS availability: `iOS 26.0+`
  - `struct GlassButtonStyle`; *"A button style that applies glass border artwork based on the button's context."*
  - Shorthand: `@MainActor @preconcurrency static func glass(_ glass: Glass) -> Self` — so `.buttonStyle(.glass)` and `.buttonStyle(.glass(.clear))` are real.
- **`GlassProminentButtonStyle`** + **`.buttonStyle(.glassProminent)`** — iOS availability: `iOS 26.0+` *(upgraded UNVERIFIED→CONFIRMED; corroborated by the Liquid Glass iOS-26 availability table — `.glassProminent` = Yes on iOS)*. Accent-tinted glass platter; the iOS-26 replacement for `.borderedProminent` on primary actions.
- **`Glass` statics** (all `iOS 26.0+`): `Glass.regular`, `Glass.clear`, and **`Glass.identity`** (opts a view out of the Liquid Glass effect while keeping the `glassEffect` modifier in place — the no-op variant). Configure with `Glass.tint(_:)`.
- **`Glass.interactive(_:)`** — iOS availability: **`iOS 26.0+`** (NOT iOS-only). It IS available on iOS 26; on iOS it is touch-driven (the elastic, springy response under a finger); the API is present and functional.
- **`scrollEdgeEffectStyle(_:for:)`** — iOS availability: **`iOS 26.0+`**
  ```swift
  func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View
  ```
  Sibling toggle: **`scrollEdgeEffectHidden(_:for:)`** (`iOS 26.0+`) — hides the scroll-edge effect for the given edges.
- **`GlassEffectTransition.materialize`** — iOS availability: **`iOS 26.0+`** (real). `GlassEffectTransition`'s three cases are **`.identity`**, **`.matchedGeometry`**, and **`.materialize`**.
- **`ToolbarSpacer`** — iOS availability: **`iOS 26.0+`**. `struct ToolbarSpacer`; the no-arg `ToolbarSpacer()` defaults to flexible. Sizing is `SpacerSizing` with cases **`.fixed`** and **`.flexible`** (e.g. `ToolbarSpacer(.fixed)` / `ToolbarSpacer(.flexible)`).
- **`searchToolbarBehavior(_:)`** — iOS availability: **`iOS 26.0+`**. The correct case is **`.minimize`** (not `.minimized`): `.searchToolbarBehavior(.minimize)` collapses the search field into the toolbar until invoked.
- Verified sibling symbols (names confirmed in topic lists; bodies not individually scraped): `glassEffectID(_:in:)`, `glassEffectUnion(id:namespace:)`, `glassEffectTransition(_:)`, `DefaultGlassEffectShape`, `.backgroundExtensionEffect()`.

### 5. Scene & lifecycle — `WindowGroup` / `scenePhase` / `SceneStorage`
- **`WindowGroup`** — iOS availability: **`iOS 14.0+`**. The standard iOS app scene (`@main struct App: App { var body: some Scene { WindowGroup { RootView() } } }`). `Settings {}` and `MenuBarExtra` are **macOS-only** — do **not** emit them in an iOS app; the iOS settings idiom is a `Form` bound to `@AppStorage` (and an optional `Settings.bundle`).
- **`scenePhase`** — the environment value `@Environment(\.scenePhase) private var scenePhase` (current `ScenePhase` is `.active` / `.inactive` / `.background`). Drive a save on `onChange(of: scenePhase)` to `.background` — iOS suspends/terminates the app and an unsaved edit is lost. → `app-lifecycle.md`.
- **`SceneStorage`** — iOS availability: **`iOS 14.0+`**. `@SceneStorage("key") var x` persists **small per-scene UI restoration state** across relaunch (a selected tab, a search string) — never the data model. Verbatim: *"A property wrapper type that reads and writes to persisted, per-scene storage."*
- **`backgroundTask`** — the scene modifier `.backgroundTask(.appRefresh("id")) { … }` for background work; the `id` must also be declared in `Info.plist` `BGTaskSchedulerPermittedIdentifiers`. → `app-lifecycle.md`.

### 6. `Table` — multi-column data view (iPad / regular width)
- iOS availability: **`iOS 16.0+`**
- Signature: `struct Table<Value, Rows, Columns> where Value == Rows.TableRowValue, Rows : TableRowContent, Columns : TableColumnContent, Rows.TableRowValue == Columns.TableRowValue`
- Verbatim: *"A container that presents rows of data arranged in one or more columns, optionally providing the ability to select one or more members."*
- On iOS, **`List` is the primary collection** — reach for `Table` only on **iPad / regular width**, where multi-column sortable rows make sense (it renders single-column on compact-width iPhone). Related symbols: `TableColumn`, `TableRow`, `TableColumnForEach`, `TableColumnCustomization`. Pair with `sortOrder:` + `KeyPathComparator` for sortable headers. → `layout-and-tables.md`.

### 7. Swift 6.2 concurrency — "Approachable Concurrency"
- Source: `swift.org/blog/swift-6.2-released/` (Holly Borla, **September 15, 2025**)
- Verbatim (single-threaded by default): *"Run your code on the main thread without explicit `@MainActor` annotations using the new option to isolate code to the main actor by default. This option is ideal for scripts, UI code, and other executable targets."*
- Verbatim (`@concurrent`): *"Introduce code that runs concurrently using the new `@concurrent` attribute."*
- Build-mode header (verbatim): `// In '-default-isolation MainActor' mode`.
- **Critical nuance:** main-actor-by-default is an **opt-in build mode** (`-default-isolation MainActor` / "Approachable Concurrency" + "Default Actor Isolation = Main Actor" build settings), NOT an unconditional language default. The Swift 6 *language mode* makes strict data-race-safety checking the default; the main-actor-isolation default is the new 6.2 ergonomic opt-in. Do not assume it everywhere; do not sprinkle `DispatchQueue.main.async`.

### 8. SwiftData — current first-party persistence
- iOS availability: **`iOS 17.0+`**
- Core surface (doc-index confirmed): `@Model` macro, `ModelContainer`, `ModelContext`, `@Query`, `.modelContainer(for:)`. WWDC24 added `#Index`, `#Unique`, history.
- SwiftData is the current persistence layer; Core Data is legacy-but-supported. Pitfalls: `var` (not `let`) on bidirectional relationships; assign relationships after `insert`, never in `init`; call `try modelContext.save()` at boundaries.

---

## Hallucination blacklist (DO NOT EMIT — these don't exist)

AI invents plausible-but-wrong Liquid Glass names. None of these are real SwiftUI APIs. Hard-fail on sight and substitute the ✅ replacement.

| ❌ Hallucinated (does NOT exist) | ✅ Real replacement |
|---|---|
| `.glassBackground()` | `.glassEffect(_:in:)` |
| `.liquidGlass()` | `.glassEffect(_:in:)` |
| `LiquidGlassView` | `GlassEffectContainer` (grouping) / `.glassEffect()` (single view) |
| `.material(.glass)` / `.background(.glass)` | `.glassEffect(.regular, in: shape)` |

**Real but platform-wrong:** `.glassBackgroundEffect()` **is a real symbol but visionOS-only** — flag it on any iOS target. On iOS use `.glassEffect(_:in:)`. Also flag the **macOS-only** scene primitives `Settings {}`, `SettingsLink`, `MenuBarExtra`, and `.commands {}` if they appear in an iOS app — they have no iOS analogue (use a `Form`/`@AppStorage` settings screen, `contextMenu`, and `AppIntents`/`Menu` instead). (Note: `Glass.interactive(_:)` is NOT platform-wrong — it is `iOS 26.0+` and touch-driven on iOS; see CONFIRMED §4.)

---

## UNVERIFIED (verify against your Xcode 26 SDK before asserting)

Named in the doc index / practitioner code but page body NOT scraped this round. Flag, do not assert as fact. **Mark every uncertain symbol "— verify against your Xcode 26 SDK".** (`GlassProminentButtonStyle` / `.glassProminent`, `menuBarExtraStyle` cases, `scrollEdgeEffectStyle(_:for:)`, `ToolbarSpacer`/`SpacerSizing`, `searchToolbarBehavior(_:)`, `GlassEffectTransition.materialize`, and the `Tab` struct were all here but are now CONFIRMED above.)

- **`WindowGroup` exact availability string** — present in the Scenes index at iOS 14.0+ (WWDC20); not body-confirmed this round — verify against your Xcode 26 SDK.
- **iOS-26-specific SwiftData deltas** — any 2025-era schema/migration additions beyond `#Index`/`#Unique`/history — verify against your Xcode 26 SDK.
- **Scroll-edge effect DEFAULT style** (behavior, not the API): the API `scrollEdgeEffectStyle(_:for:)` is CONFIRMED above, but the per-edge default (`.soft` on iOS) is observed behavior, not a scraped fact — verify against your Xcode 26 SDK.

---

## Sources

All scraped 2026-06-06 unless dated otherwise.

- NavigationView (deprecation): https://developer.apple.com/documentation/swiftui/navigationview
- Migrating to new navigation types: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
- `@Observable` macro: https://developer.apple.com/documentation/observation/observable()
- Observation migration: https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro
- `onChange(of:initial:_:)`: https://developer.apple.com/documentation/SwiftUI/View/onChange(of:initial:_:)-4psgg
- `glassEffect(_:in:)`: https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- `GlassEffectContainer`: https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- `GlassButtonStyle`: https://developer.apple.com/documentation/swiftui/glassbuttonstyle
- `.glass(_:)` shorthand: https://developer.apple.com/documentation/SwiftUI/PrimitiveButtonStyle/glass(_:)
- `GlassProminentButtonStyle`: https://developer.apple.com/documentation/swiftui/glassprominentbuttonstyle
- Adopting Liquid Glass: https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- Applying Liquid Glass to custom views: https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views
- `WindowGroup`: https://developer.apple.com/documentation/swiftui/windowgroup
- `ScenePhase`: https://developer.apple.com/documentation/swiftui/scenephase
- `SceneStorage`: https://developer.apple.com/documentation/swiftui/scenestorage
- Scenes index: https://developer.apple.com/documentation/swiftui/scenes
- `Table`: https://developer.apple.com/documentation/swiftui/table
- Swift 6.2 released (2025-09-15): https://swift.org/blog/swift-6.2-released/
- SwiftData: https://developer.apple.com/documentation/swiftdata · `@Model`: https://developer.apple.com/documentation/swiftdata/model()
- WWDC: "Meet Liquid Glass" (219), "Build a SwiftUI app with the new design" (323, 2025-06-09), "What's new in SwiftUI" (256), "Discover Observation in SwiftUI" (wwdc2023/10149), "What's new in SwiftData" (wwdc2024/10137)
