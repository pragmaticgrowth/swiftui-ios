# Common deprecated → modern iOS SwiftUI migrations

Confirm each against the live tool: `swiftui-ctx deprecated <api> --platform ios` (gives the replacement + a note), then
`swiftui-ctx lookup <replacement> --platform ios` for the real, current call shape. This table is the fast path; the CLI is truth.

| Deprecated | Use instead | Notes |
|---|---|---|
| `NavigationView` | `NavigationStack` / `NavigationSplitView` | Stack = single column (the iPhone standard); SplitView = sidebar+detail on iPad |
| `.foregroundColor(_:)` | `.foregroundStyle(_:)` | takes any `ShapeStyle` (colors, gradients, hierarchical) |
| `.edgesIgnoringSafeArea(_:)` | `.ignoresSafeArea(_:edges:)` | — |
| `.navigationBarTitle(_:)` | `.navigationTitle(_:)` | — |
| `.navigationBarItems(...)` | `.toolbar { ... }` | use `ToolbarItem`/`ToolbarItemGroup` with placements |
| `.tabItem { ... }` | `Tab(_:systemImage:content:)` | inside `TabView(selection:)` (newer API) |
| `Alert(...)` / `.alert(isPresented:content:)` | `.alert(_:isPresented:actions:message:)` | message/actions builder form |
| `.actionSheet(...)` | `.confirmationDialog(_:isPresented:)` | — |
| `presentationMode` (`@Environment`) | `@Environment(\.dismiss)` | call `dismiss()` to dismiss the view |
| `presentationMode` (`@Environment`) | `@Environment(\.isPresented)` | read-only `Bool` — query whether view is presented; cannot dismiss |
| `.accentColor(_:)` | `.tint(_:)` | — |
| `.autocapitalization(_:)` | `.textInputAutocapitalization(_:)` | iOS/iPadOS native text-input control |
| `.disableAutocorrection(_:)` | `.autocorrectionDisabled(_:)` | — |
| `sizeCategory` (`@Environment`) | `dynamicTypeSize` (`@Environment`) | Dynamic Type bucket; query/clamp with `DynamicTypeSize` |
| `.statusBar(hidden:)` | `.statusBarHidden(_:)` | — |

State-management modernization (not "deprecated" but stale):
- `class VM: ObservableObject { @Published … }` + `@StateObject`/`@ObservedObject` → `@Observable final class VM { … }`
  + `@State private var vm = VM()` (pass with `@Bindable` where a binding is needed). See `ios-app-patterns` recipe `observable-model`.

Always verify the replacement is available on the project's deployment target (the iOS-17 floor; the `doc:` sosumi link shows availability).
