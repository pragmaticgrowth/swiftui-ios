# Reference — Inspector & Detail-Column Width (nav-08/12)

Detail-column width is **not fully controllable** in pure SwiftUI, and an empty detail must use the
native empty-state component. **Floor values are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — never restated here.**

---

## nav-08 · `navigationSplitViewColumnWidth` on the detail column (warning · flag · UNVERIFIED)

`.navigationSplitViewColumnWidth(min:ideal:max:)` (`swiftui-ctx lookup navigationSplitViewColumnWidth
--platform ios` → `introduced_ios: 16.0`) constrains *leading* columns, **not** the detail column — the
detail grows past the stated max, and animating its frame to width 0 leaves the canvas un-relaid-out. This
is a **practitioner-confirmed limitation** — carry the finding as `source: verify against Xcode 26 SDK`,
never as fact.

```swift
// ❌ no-op on the detail column; inspector ignores the max and won't collapse cleanly
NavigationSplitView {
    SidebarView()
} detail: {
    InspectorView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 270, max: 400)  // ignored on detail
}
```

The correct shape on iOS:

```swift
// ✅ first-party .inspector for a contextual metadata panel (iOS 17.0+)
@State private var showInspector = true
ContentView()
    .inspector(isPresented: $showInspector) {
        InspectorView()
            .inspectorColumnWidth(min: 200, ideal: 225, max: 400)   // 225 pt per Apple examples
    }
```

**iOS note:** `.inspector(isPresented:)` places under the toolbar on regular width (iPad) and
**auto-presents as a sheet in compact width** (iPhone) — that adaptive sheet behavior is correct on iOS,
not a defect. For a user-resizable structural pane on iPad, a `UISplitViewController` bridge is an option,
but its *whether-to-bridge* decision routes to `audit-swiftui-uikit-overuse` and the *how* to
`audit-swiftui-uikit-interop`.

**Inspector standard width: 225 pt (Apple-documented examples); 270 pt is a community-observed value —
`verify against Xcode 26 SDK`** (floors-master open item). `.inspector` / `inspectorColumnWidth` are
iOS 17.0+.

## nav-12 · Empty detail is a blank view, not `ContentUnavailableView` (advisory)

An empty / no-selection detail column should be `ContentUnavailableView` (iOS 17.0+), never a blank
`Text("")` or `EmptyView()` — it is the native empty-state component and matches system apps (Mail, Notes,
Files).

```swift
// ❌ blank detail when nothing is selected
NavigationSplitView { SidebarView() } detail: {
    if let item = selected { DetailView(item: item) } else { Text("") }   // blank
}
```
```swift
// ✅ ContentUnavailableView is the native empty state
NavigationSplitView { SidebarView() } detail: {
    if let item = selected {
        DetailView(item: item)
    } else {
        ContentUnavailableView("No Selection", systemImage: "sidebar.left")
    }
}
```

> nav-12 is grep-located on the `detail:` closure; READ the body to confirm the empty branch is blank
> rather than a real placeholder before reporting.

---

## Sources

All Apple docs fetched via Sosumi (protocol:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`); access 2026-06-16. Floors live in
`floors-master.md`; verify the detail no-op + inspector width against the Xcode 26 SDK.

- `navigationSplitViewColumnWidth(min:ideal:max:)` (constrains leading columns; iOS 16.0+): https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:)
- `inspector(isPresented:content:)` + `inspectorColumnWidth(_:)` (iOS 17.0+; compact → sheet): https://developer.apple.com/documentation/swiftui/view/inspector(ispresented:content:)
- `ContentUnavailableView` (iOS 17.0+): https://developer.apple.com/documentation/swiftui/contentunavailableview
- WWDC 2023 Session 10161 "Inspectors in SwiftUI" (`.inspector(isPresented:)`; 225 pt per Apple examples / 270 pt community-observed — verify against Xcode 26 SDK; compact → sheet): https://developer.apple.com/videos/play/wwdc2023/10161
- Michael Sena — *Three Column Editors in SwiftUI* (`navigationSplitViewColumnWidth` no-op on detail; 2023-03-30): https://msena.com/posts/three-column-swiftui-macos/
