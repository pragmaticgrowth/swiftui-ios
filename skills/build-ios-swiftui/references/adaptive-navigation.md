# Adaptive Navigation, Stacks, Sidebars & Toolbars (iOS)

> **iOS-only.** The iPhone wants a **push/pop stack** (`NavigationStack`); the iPad (regular width) wants
> a **multi-column** `NavigationSplitView`. Both containers exist on iOS, but `NavigationStack` is the
> **primary** shell and `NavigationSplitView` is the *adaptive* choice that must be **gated to regular
> width / iPad idiom** — never unconditional, because on compact-width iPhone it collapses to a stack
> with surprising behavior. macOS appears only as a ❌ contrast.

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain.** Cross-checked against `references/api-currency.md`.

## Why AI gets this wrong

The corpus is full of `NavigationView` (deprecated) and macOS-shaped split views. AI either ships the
deprecated container, ships an **unconditional** `NavigationSplitView` that mis-collapses on iPhone, hides
columns with `.frame(maxWidth: 0)` hacks instead of the `columnVisibility` binding, or carries the
**deprecated** `.navigationBarLeading`/`.navigationBarTrailing` placements and `navigationBarTitle`.

---

## The three non-negotiable iOS rules

1. **iPhone shell = `NavigationStack`; iPad/regular-width shell = a *gated* `NavigationSplitView`.**
   `NavigationView` is deprecated; `NavigationStack` (iOS 16.0+) is the primary push/pop shell. An
   **unconditional** `NavigationSplitView` (no `horizontalSizeClass` / `userInterfaceIdiom` gate) is the
   defect — it collapses oddly on iPhone.
2. **Drive columns with the binding, never the frame.** Column show/hide is the `columnVisibility:`
   initializer parameter bound to a `NavigationSplitViewVisibility` — not a boolean + `.frame(maxWidth: 0)`
   hack.
3. **The iOS navigation bar is real — use it.** `.topBarLeading`/`.topBarTrailing`/`.bottomBar` are the
   **correct** iOS placements; `.navigationBarLeading`/`.navigationBarTrailing` are **deprecated** (→
   `.topBarLeading`/`.topBarTrailing`); `navigationBarTitle` is **deprecated** (→ `navigationTitle`).
   `navigationBarTitleDisplayMode(.inline/.large)` is iOS-only and **correct** — keep it.

---

## The six mistakes (❌ WRONG → ✅ CORRECT)

### 1. `NavigationView` (deprecated) instead of `NavigationStack`

```swift
// ❌ WRONG — deprecated iOS 13–26.5
NavigationView { List(items) { row($0) } }
// ✅ CORRECT — the iOS-primary push/pop shell
NavigationStack { List(items) { row($0) } }
```
`NavigationStack` (iOS 16.0+) is the drill-down container; pair it with value-based navigation
(`.navigationDestination(for:)`) — never an inline-destination `NavigationLink` inside a `List`/`ForEach`.

### 2. Unconditional `NavigationSplitView` (mis-collapses on iPhone)

A split view used on every device collapses to a stack on compact-width iPhone with surprising behavior.
Gate it to regular width / iPad; keep a `NavigationStack` path for compact.

```swift
// ❌ WRONG — unconditional split view; collapses oddly on iPhone
NavigationSplitView { Sidebar() } detail: { Detail() }

// ✅ CORRECT — gate the split view to regular width; stack on compact
@Environment(\.horizontalSizeClass) private var hSize
var body: some View {
    if hSize == .regular {                          // iPad / regular width
        NavigationSplitView { Sidebar() } detail: { Detail() }
    } else {                                        // compact iPhone
        NavigationStack { Sidebar() }               // drill-down
    }
}
```

### 3. Two- vs three-column confusion, and frame-hack column hiding

`NavigationSplitView` has a 2-column `init(sidebar:detail:)` and a 3-column
`init(sidebar:content:detail:)`. Column show/hide is the `columnVisibility:` binding — not a frame hack.

```swift
// ❌ WRONG — hide a column by zeroing its frame
NavigationSplitView { Sidebar().frame(maxWidth: showSidebar ? 320 : 0) } detail: { Detail() }

// ✅ CORRECT — drive columns with the binding
@State private var columnVisibility: NavigationSplitViewVisibility = .all
NavigationSplitView(columnVisibility: $columnVisibility) {
    Sidebar()
} content: {
    MiddleColumn()
} detail: {
    Detail()
}
```

### 4. Deprecated / wrong toolbar placements

```swift
// ❌ WRONG — deprecated placements
.toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Edit") {} } }   // deprecated
.toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Add") {} } }   // deprecated

// ✅ CORRECT — current iOS placements
.toolbar {
    ToolbarItem(placement: .topBarLeading)  { Button("Edit") {} }
    ToolbarItem(placement: .topBarTrailing) { Button("Add", systemImage: "plus") {} }
    ToolbarItem(placement: .bottomBar)      { Spacer(); Button("Compose") {} }
}
```
`.topBarLeading` / `.topBarTrailing` / `.bottomBar` are iOS 14.0+ and current. On iOS 26 use `ToolbarSpacer`
to separate glass toolbar groups (→ `liquid-glass.md`).

### 5. `navigationBarTitle` instead of `navigationTitle`

```swift
// ❌ WRONG — deprecated
.navigationBarTitle("Items", displayMode: .inline)
// ✅ CORRECT — current; displayMode is a separate iOS-only modifier
.navigationTitle("Items")
.navigationBarTitleDisplayMode(.inline)        // iOS-only and correct — keep it
```

### 6. `navigationSplitViewColumnWidth` on the detail column (no-op)

`navigationSplitViewColumnWidth(_:)` sizes the **sidebar / content** columns, not the detail column —
applying it to detail does nothing. Size the leading columns; let detail flex.

```swift
// ✅ CORRECT — width on the sidebar column, detail flexes
NavigationSplitView {
    Sidebar().navigationSplitViewColumnWidth(min: 200, ideal: 250)
} detail: {
    Detail()
}
```

---

## iOS notes

- **`NavigationStack` + a typed `NavigationPath`.** Drive programmatic navigation with
  `@State private var path = NavigationPath()` bound into `NavigationStack(path:)`, and
  `.navigationDestination(for:)` per value type. Persist it across launches with `@SceneStorage` (codable
  path) — see `app-lifecycle.md`.
- **`NavigationSplitView` is adaptive, not the default.** It is the *iPad / regular-width* sidebar shell.
  Always behind a `horizontalSizeClass == .regular` (or `userInterfaceIdiom == .pad`) branch; on
  compact-width iPhone the primary shell is `NavigationStack`.
- **Search lives in the nav bar.** `.searchable(text:)` integrates with the navigation bar; on iOS 26
  `.searchToolbarBehavior(.minimize)` collapses it into the toolbar until invoked.
- **Boundary:** UIKit `UINavigationController` / `UISplitViewController` internals are out of scope —
  bridge concerns go to `uikit-interop.md`. The push-vs-modal decision (`.sheet` vs a push) is the
  presentation concern.

---

## Detection tells

- `NavigationView {` — deprecated; replace with `NavigationStack` / gated `NavigationSplitView`.
- `NavigationSplitView` with **no** nearby `horizontalSizeClass` / `userInterfaceIdiom` gate →
  unconditional split view (mistake 2).
- `.frame(maxWidth: 0)` / a boolean width to hide a split-view column instead of `columnVisibility:`
  (mistake 3).
- `.navigationBarLeading` / `.navigationBarTrailing` placements → deprecated → `.topBarLeading` /
  `.topBarTrailing` (mistake 4).
- `.navigationBarTitle(` / `.navigationBarTitle(_:displayMode:)` → deprecated → `.navigationTitle(` +
  `.navigationBarTitleDisplayMode(` (mistake 5).
- `navigationSplitViewColumnWidth` on a detail-column view → no-op (mistake 6).
- `NavigationLink(destination:` inside a `List`/`ForEach` → inline destination; use
  `.navigationDestination(for:)`.

---

## Canonical pattern

```swift
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var path = NavigationPath()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        if hSize == .regular {                                  // iPad / regular width
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarList()
            } detail: {
                NavigationStack { DetailView() }
            }
        } else {                                               // compact iPhone
            NavigationStack(path: $path) {
                SidebarList()
                    .navigationTitle("Items")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: Item.self) { ItemDetail(item: $0) }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) { Button("Add", systemImage: "plus") {} }
                    }
            }
        }
    }
}
```

**Rules:** (1) `NavigationStack` is the primary iOS shell; `NavigationSplitView` is a *gated* iPad/regular
adaptation. (2) Drive columns with `columnVisibility:`, never a frame hack. (3) Use `.topBarLeading` /
`.topBarTrailing` / `.bottomBar`; `.navigationTitle` + `.navigationBarTitleDisplayMode`. (4) Value-based
`.navigationDestination(for:)`, never inline `NavigationLink(destination:)` in a list.

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/navigationstack | push/pop container — iOS 16.0+ | high |
| https://developer.apple.com/documentation/swiftui/navigationsplitview | 2-/3-column sidebar; `columnVisibility:` init param; iOS 16.0+ | high |
| https://developer.apple.com/documentation/swiftui/navigationview | **deprecated** iOS 13–26.5; *"Use NavigationStack and NavigationSplitView instead."* | high |
| https://developer.apple.com/documentation/swiftui/toolbaritemplacement | `.topBarLeading`/`.topBarTrailing`/`.bottomBar` current; `.navigationBarLeading`/`.navigationBarTrailing` deprecated | high |
| https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:) | current title modifier; `navigationBarTitle` deprecated | high |
| https://developer.apple.com/documentation/swiftui/view/navigationbartitledisplaymode(_:) | iOS-only `.inline`/`.large`/`.automatic` — current | high |
| https://developer.apple.com/documentation/swiftui/navigationpath | type-erased programmatic navigation path | high |
