# Detection Lint Checklist (iOS SwiftUI)

Grep/scan tells: **WRONG pattern → correct iOS replacement**. Run before proposing code (agent
self-check) or wire as a `PreToolUse`/CI scan. The runnable version is
`${CLAUDE_PLUGIN_ROOT}/scripts/ios-swiftui-lint.sh`; this file is the human-readable source of truth.
Each rule maps to its deep reference doc. Every ✅ targets iOS/iPadOS (iOS-17 floor); macOS appears only
as a ❌ contrast.

## Version drift / deprecation → `version-and-hallucination.md`, `adaptive-navigation.md`
1. `NavigationView {` → `NavigationStack` (deprecated; `NavigationSplitView` **only when gated to regular width / iPad**). **[hard-fail]**
2. `.foregroundColor(` → `.foregroundStyle(` (deprecated; `.foregroundStyle` is iOS 15+).
3. `edgesIgnoringSafeArea(` → `.ignoresSafeArea(_:edges:)` (deprecated).
4. `.onChange(of:` with single-ident closure `{ newValue in }` / `{ value in }` → two-param `{ old, new in }` (iOS 17+).
5. `.tabItem {` → `Tab(...) { }` (note: `Tab {}` requires iOS 18.0+ — for iOS-17 targets keep `.tabItem` with gating).
6. `Text("a") + Text("b")` (the `Text` `+` operator) → **deprecated iOS 26.0**; use string interpolation `Text("a \(b)")`.
7. `.navigationBarTitle(` → `.navigationTitle` (+ `.navigationBarTitleDisplayMode(`) (deprecated).
8. `placement: .navigationBarLeading` / `.navigationBarTrailing` → `.topBarLeading`/`.topBarTrailing`/`.principal`/`.primaryAction` (deprecated placements).
9. `.accentColor(` → `.tint(_:)` (deprecated).
10. `.autocapitalization(` / `.disableAutocorrection(` → `.textInputAutocapitalization(` / `.autocorrectionDisabled(` (deprecated).
11. `MagnificationGesture` → `MagnifyGesture` (deprecated; `MagnifyGesture` is iOS 17+).
12. `RotationGesture` → `RotateGesture` (deprecated; `RotateGesture` is iOS 17+).
13. `.cornerRadius(` → prefer `.clipShape(.rect(cornerRadius: N))` / `.clipShape(RoundedRectangle(cornerRadius: N))` for clearer intent (not a hard deprecation on iOS — craft, not error).

## Hallucination / gating → `liquid-glass.md`, `api-currency.md`
14. `.glassBackground(` · `.liquidGlass(` · `.material(.glass` · `LiquidGlassView` → **hard-fail** (don't exist); real = `.glassEffect()`.
15. `.glassBackgroundEffect(` on an iOS target → visionOS-only; flag. On iOS use `.glassEffect(_:in:)`.
16. `glassEffect`/`GlassEffectContainer`/`.buttonStyle(.glass`/`glassEffectID`/`glassEffectUnion`/`backgroundExtensionEffect`/`scrollEdgeEffectStyle` with no enclosing `#available(iOS 26` (deployment < 26) → add iOS-arm gate.
17. `@Observable`/`@Bindable`/two-param `onChange`/`MagnifyGesture`/`RotateGesture` below iOS 17 with no `@available`/`#available` → gate. (Note: `#Preview { }` itself back-deploys and needs no gate; only `@Previewable` inside its body needs an iOS-17 gate.)
18. `#available(macOS …` / `@available(macOS …` used as the gate in iOS-target code → **wrong arm** (the `*` wildcard already covers iOS, so the branch always fires and the iOS floor is never enforced); use `#available(iOS …)`.
19. Any unfamiliar modifier that "reads right" but isn't in `api-currency.md`/Apple docs → treat as hallucinated until verified.

## macOS-only primitives ported to iOS (won't compile) → `app-lifecycle.md`, `uikit-interop.md`
20. `MenuBarExtra` / `Settings {` / `.commands {` / `CommandMenu` / `CommandGroup` in an iOS target → **don't exist on iOS**; use `Menu` / `.contextMenu` / `.swipeActions` / App Intents; settings = `Form` + `@AppStorage`. **[hard-fail]**
21. `: NSViewRepresentable` / `: NSViewControllerRepresentable` / `NSHostingController` / `NSHostingView` → AppKit; on iOS use `UIViewRepresentable` / `UIViewControllerRepresentable` / `UIHostingController`. **[hard-fail]**
22. `NSStatusItem` / `NSPasteboard` / `NSOpenPanel` → AppKit-only; on iOS there is no menu-bar status item; use `UIPasteboard` / `fileImporter`.
23. `.formStyle(.grouped)` → the macOS knob; on iOS `Form` is already grouped — drop it.

## State & observation → `state-and-observation.md`
24. `@ObservedObject var <name> = <Type>(` (initializer present) → `@StateObject`/`@State`. **[hard-fail]**
25. `@ObservedObject var <x>: <T>` where `<T>` is an `@Observable` type → compile error (`@ObservedObject` needs `ObservableObject`); use a plain stored property.
26. `@Observable` class `… : ObservableObject` → remove the conformance. **[hard-fail]**
27. `@Published` inside an `@Observable` class → remove. **[hard-fail]**
28. `@StateObject` on a type that is not `: ObservableObject` (struct or `@Observable`) → wrong owner wrapper.
29. `@EnvironmentObject` where the model is `@Observable` → `@Environment(Type.self)`.
30. `$someObservable.prop` where the var is plain/`@Environment(Type.self)` with no nearby `@Bindable` → add `@Bindable`.
31. `private var <name>: some View {` computed prop reading an `@Observable` model → extract to a child `View` type.

## Concurrency → `concurrency.md`
32. `DispatchQueue.main.async` in async/SwiftUI code → `@MainActor` / `await MainActor.run`.
33. `Task {` inside `.onAppear`/`onChange` → `.task {}` / `.task(id:)`. **[advisory]** (Exception: intentionally long-lived tasks — background upload/analytics.)
34. `@Sendable` closure whose body reads `self.`/a `@MainActor` property → isolate the closure or capture-by-value.
35. `Task.detached {` capturing a non-`Sendable` class → boundary violation.
36. `@concurrent` present → confirm toolchain is Swift 6.2+.

## App lifecycle & scenes → `app-lifecycle.md`
37. A scene with a mutable `@State`/`@Bindable` model and **no** `onChange(of: scenePhase)` save on `.background` → iOS terminates suspended apps; pending edits lost.
38. `@SceneStorage` holding JSON / an array / model data instead of small UI state → wrong tool.
39. `applicationDidEnterBackground` / `applicationWillResignActive` doing work `scenePhase` covers → use `onChange(of: scenePhase)`.
40. A view-level URL parser with no `.onOpenURL` / `.onContinueUserActivity` on the scene.

## Adaptive navigation → `adaptive-navigation.md`
41. `NavigationSplitView` with **no** size-class / `userInterfaceIdiom` gate → collapses oddly on compact-width iPhone; gate to regular width / iPad.
42. `NavigationLink(` with `destination:` inside a `List`/`ForEach` → value-based `.navigationDestination(for:)`.

## UIKit interop → `uikit-interop.md`
43. `: UIViewRepresentable`/`: UIViewControllerRepresentable` with no `updateUIView`/`updateUIViewController` → state staleness. **[hard-fail]**
44. Representable with a `@Binding` but no `makeCoordinator()`/`delegate = context.coordinator` → broken UIKit→SwiftUI direction.
45. A `Coordinator` that **strongly captures the parent** → retain cycle / leak; weak-capture.
46. Observers/KVO added in `makeUIView` with no `dismantleUIView` → teardown leak.

## Layout / controls / touch → `layout-and-tables.md`, `controls-and-touch.md`
47. `Table(` outside regular width (iPad) → on iPhone use a `List` (a `Table` is iPad/macOS-shaped).
48. Custom interactive view with a touch target smaller than 44×44 pt → not reliably tappable.
49. Row/item view with no `.contextMenu` / `.swipeActions` → missing iOS interaction affordances.
50. Sheet/cover where a partial-height sheet is wanted with no `.presentationDetents([.medium, .large])` (+ `.presentationDragIndicator`).
51. Fixed `Font.system(size:)` / hardcoded point sizes everywhere → breaks Dynamic Type; use semantic styles + `@ScaledMetric`.
52. `.onHover` / `.help(` used as the **only** path to an action → pointer-only; provide a touch path.

## SwiftData → `swiftdata.md`
53. `let ` immediately before an `@Relationship`/another-`@Model`-typed property → runtime crash. **[hard-fail]**
54. `self.<relationship> =` inside a `@Model` `init` body → data vanishes on relaunch.
55. `try ModelContainer(` followed by `catch { fatalError(` in non-preview code → handle gracefully.
56. `@Model class` with stored props but no `init(` → incomplete Apple-doc copy.
57. `@Relationship(.cascade)` → **compile-time type error**: `.cascade` is a `DeleteRule`; use `@Relationship(deleteRule: .cascade)`.
58. Indexing a relationship array (`.items[0]`) with no `SortDescriptor`/`@Query(sort:)` → unordered.
59. Background `Task {}` mutating `@Environment(\.modelContext)` results with no `@ModelActor` → off-thread mutation.
60. A mutation path with no `try modelContext.save()` anywhere (and no `scenePhase == .background` save) → silent data loss.

## Document / file access → `file-handling.md`
61. `URL(fileURLWithPath:`/`Data(contentsOf:`/`FileManager` against a literal/typed path with no preceding `fileImporter`/`UIDocumentPickerViewController` → consent violation. **[hard-fail]** (Exception: does NOT apply to `Bundle.main.url(forResource:)` resource reads or paths inside the app's own container — those need no consent.)
62. Picked `URL` saved to `UserDefaults`/disk without `bookmarkData(options: .minimalBookmark)` → no re-access next launch.
63. Resolved/picked URL used with no surrounding `start/stopAccessingSecurityScopedResource()`.
64. `com.apple.security.app-sandbox` entitlement / `.withSecurityScope` → those are **macOS**; on iOS files are container + user-picked-URL only.
65. `NSPasteboard` in iOS code → `UIPasteboard` / `Transferable` + `.dropDestination`.

## Previews → `previews.md`
66. `struct *_Previews: PreviewProvider` → `#Preview { }`.
67. `@State`/`@Binding`/`@Bindable` directly inside a `#Preview { }` body without `@Previewable` → compile error.
68. `struct *Key: EnvironmentKey` + `extension EnvironmentValues` computed prop → single `@Entry var`.
69. `#Preview` of a `@Query`/SwiftData view with no `.modelContainer(... inMemory: true)` → preview crash.
70. `#Preview` of a view reading `@Environment(SomeModel.self)` with no `.environment(...)` injection → crash/empty.

## Positive checks (an iOS app/view SHOULD honor these)
- A `NavigationSplitView` is **size-class / idiom gated**, never unconditional on iPhone.
- `#available(iOS …` gating wherever an iOS-17+/26+ API is used.
- Dynamic Type honored (semantic text styles / `@ScaledMetric`), not fixed point sizes.

## Sources
Consolidated iOS-SwiftUI detection rules. Each rule's deep treatment (with ❌/✅ code and Apple-doc
citations) is in the reference doc named in its group header above; this list mirrors
`scripts/ios-swiftui-lint.sh`.
