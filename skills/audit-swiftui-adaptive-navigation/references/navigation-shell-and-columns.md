# Reference — Navigation Shell & Columns (nav-01/02/03/04/09)

The navigation shell of an iOS app: which container is the *shell*, the size-class/idiom **gate** on a
split view, two- vs three-column initializers, the `columnVisibility` binding, and sidebar `List`
styling. iPhone wants a **push/pop stack** (`NavigationStack`); iPad/regular-width wants a **multi-column**
`NavigationSplitView` — the containers exist on both but `NavigationStack` is the **primary** iOS shell,
and a split view must be **gated to regular width / iPad**, never used unconditionally. **Floor values are
the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — never restated
here.** Every ✅ shape is the **swiftui-ctx consensus** (run the `lookup` in step VERIFY for the live
permalink), not opinion.

---

## nav-01 · `NavigationView` is deprecated (hard-fail · auto)

`NavigationView` is deprecated (`swiftui-ctx lookup NavigationView --platform ios` →
`introduced_ios: 13.0`, `deprecated: true`, `migrate_to: NavigationStack`). Apple: "Use `NavigationStack`
and `NavigationSplitView` instead." `api-currency` owns the deprecation *flag*; **this skill owns the
structural migration** — emit `cross_ref: api-currency`.

```swift
// ❌ deprecated container
NavigationView {
    List(items) { Text($0.name) }
    Text("Detail")
}
```
```swift
// ✅ NavigationStack is the primary iOS shell — the swiftui-ctx consensus (NavigationStack { } +
// .navigationDestination for type-safe push). Real iOS call site (airbnb/lottie-ios, ★26763, min_ios 16):
// https://github.com/airbnb/lottie-ios/blob/906e79b0648c16f02ad5844e345481ae05a94afe/Example/Example/ExampleApp.swift#L22
// doc: https://sosumi.ai/documentation/swiftui/navigationstack
NavigationStack {
    List(items) { item in
        NavigationLink(item.name, value: item)
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
```

## nav-02 · Unconditional `NavigationSplitView` (no size-class / idiom gate)

`NavigationSplitView` (iOS 16.0+) is the **iPad / regular-width** shell. On a Universal or iPhone target
it must be **gated** to regular width (`horizontalSizeClass == .regular`) or to the iPad idiom — an
**unconditional** split view collapses to a stack on compact-width iPhone with surprising behavior
(`preferredCompactColumn` aside). The tell: a top-level `NavigationSplitView` with **no**
`horizontalSizeClass` / `userInterfaceIdiom` branch anywhere governing it. **READ the whole file** — a
split view that already lives behind a `if hSizeClass == .regular` branch (or in an iPad-only target) is
correct and must not be flagged. The size-class-gating *companion note* crosses into
`audit-swiftui-adaptive-layout` (cross_ref it); the structural nav decision stays here.

```swift
// ❌ unconditional split view — collapses oddly on iPhone, no adaptive branch
struct RootView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
    }
}
```
```swift
// ✅ adaptive: NavigationStack on compact (iPhone), NavigationSplitView on regular (iPad)
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    var body: some View {
        if hSizeClass == .compact {
            NavigationStack { SidebarView() }      // iPhone push stack
        } else {
            NavigationSplitView {                  // iPad multi-column
                SidebarView()
            } detail: {
                DetailView()
            }
        }
    }
}
```

> On an **iPad-only** target a bare `NavigationSplitView` is fine — read the target idiom in ORIENT before
> flagging. nav-02 is a **grep tell** (locates `NavigationSplitView {`); the agent READs the file for the
> presence/absence of a size-class/idiom gate.

## nav-03 · Two-column vs three-column confusion

The two initializers differ only by the middle `content:` closure. `init(sidebar:detail:)` is
two-column; `init(sidebar:content:detail:)` is three-column. A 3-col init with an `EmptyView()` /
placeholder `content:` → a dead middle column; it should be 2-col. (This is the one structural tell with
a tier-2 ast-grep rule — `lint/ast-grep/nav-03-empty-middle-column.yml`.)

```swift
// ❌ 3-col init for a plain master/detail app → empty middle column
NavigationSplitView {
    List(items, selection: $selected) { Text($0.name) }
} content: {
    EmptyView()                                    // dead column
} detail: { DetailView(item: selected) }
```
```swift
// ✅ 2-col for sidebar → detail
NavigationSplitView {
    List(items, selection: $selected) { Text($0.name) }
} detail: { DetailView(item: selected) }

// ✅ 3-col for sidebar → content list → detail (Mail / Files shape on iPad)
NavigationSplitView {
    SidebarView()
} content: {
    MessageList(folder: selectedFolder)
} detail: {
    MessageDetail(message: selectedMessage)
}
```

**swiftui-ctx grounding (run live in VERIFY):** `lookup NavigationSplitView --platform ios --json` →
`introduced_ios: 16.0`, `deprecated: false`, plus a `recommended` real iOS example. The trailing-closure
`{ }` form is the canonical shell; the `(columnVisibility)` variant is for nav-04.

## nav-04 · No `columnVisibility` binding (frame hacks to hide a column)

Column show/hide is driven by the `columnVisibility:` initializer parameter bound to a
`NavigationSplitViewVisibility`, **not** by frame tricks. Cases: `.all` (all columns of a 3-col split),
`.doubleColumn` (content+detail in 3-col, or sidebar+detail in 2-col), `.detailOnly` (detail only),
`.automatic` (default). On compact-width iPhone the split view collapses regardless — treat the cases as
hints on regular width.

```swift
// ❌ boolean + frame collapse → dead space, no real relayout (the nav-04 frame hack)
@State private var sidebarShown = true
HStack {
    if sidebarShown { SidebarView() }
    DetailView()
}
.frame(maxWidth: sidebarShown ? .infinity : 0)     // canvas never re-lays-out
```
```swift
// ✅ drive the columnVisibility binding
@State private var columnVisibility: NavigationSplitViewVisibility = .all
NavigationSplitView(columnVisibility: $columnVisibility) {
    SidebarView()
} content: { ContentView() } detail: { DetailView() }
// toggle from a toolbar button: columnVisibility = .detailOnly
```

> nav-04 is kept a **grep tell** (locates `.frame(...width: 0)`); the boolean↔frame↔container co-pattern
> can't be tied into one validated ast-grep rule without heavy false positives — READ the context.

## nav-09 · Sidebar `List` missing `.listStyle(.sidebar)`

On the iPad split-view sidebar, apply `.listStyle(.sidebar)` to the `NavigationSplitView` sidebar `List`
for the correct sidebar material and source-list selection highlight. The material is semantic — it
auto-adapts Light/Dark and respects "Reduce Transparency." Use `selection: $binding` for single-selection
navigation; add `.badge(_:)` on a `Label` for unread counts. *Sidebar `List` density / control styling
crosses into `audit-swiftui-controls-forms` — flag the style here, cross_ref the craft.*

```swift
// ✅ sidebar List with the correct style + selection + badge
List(folders, selection: $selectedFolder) { folder in
    Label(folder.name, systemImage: folder.icon).badge(folder.unread)
}
.listStyle(.sidebar)
```

---

## The column-map artifact (optional go-beyond)

`swiftui-audits/adaptive-navigation/_column-map.md`: one row per navigation container —
`file:line · role (shell | column-drilldown) · column-count (2 | 3) · size-class-gate (✅/❌) ·
sidebar-style (✅/❌)`. A `column-drilldown` `NavigationStack` is correct; an **unconditional** `shell`
`NavigationSplitView` is nav-02; a 3-column row with an empty `content:` is nav-03; a shell that hides a
column by frame is nav-04. Two runs over the same code produce an identical map.

---

## iOS notes (carry into the READ)

- **Default IA is a stack, not columns.** The iPhone norm is `NavigationStack` with
  `.navigationDestination` for type-safe push; `NavigationSplitView` is the *adaptive* iPad choice.
- **`NavigationSplitView` auto-collapses** to a stack-style layout in compact width — which is exactly why
  an *unconditional* one is a smell on a Universal target (nav-02): the iPhone path is implicit and often
  surprising. Make the adaptation explicit with a `horizontalSizeClass` branch.
- **`preferredCompactColumn:`** (a real init variant) controls which column shows when collapsed; it does
  not replace an explicit size-class branch.

## Sources

All Apple docs fetched via Sosumi (protocol: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`);
access 2026-06-16. Floors live in `floors-master.md`; the live consensus shape + permalink come from
`swiftui-ctx lookup NavigationStack` / `lookup NavigationSplitView`
(see `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`).

- `NavigationStack` + `navigationDestination(for:)` (the primary iOS shell, iOS 16.0+): https://developer.apple.com/documentation/swiftui/navigationstack
- `NavigationSplitView` (2-/3-col inits, `columnVisibility:` / `preferredCompactColumn:` variants, iOS 16.0+): https://developer.apple.com/documentation/swiftui/navigationsplitview
- `NavigationSplitViewVisibility` (`.all`/`.doubleColumn`/`.detailOnly`/`.automatic`): https://developer.apple.com/documentation/swiftui/navigationsplitviewvisibility
- `NavigationView` (deprecated → `NavigationStack`/`NavigationSplitView`): https://developer.apple.com/documentation/swiftui/navigationview
- Migrating to new navigation types: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
- `horizontalSizeClass` (compact = iPhone / iPad split; regular = iPad full): https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass
- `SidebarListStyle` (`.sidebar`): https://developer.apple.com/documentation/swiftui/sidebarliststyle
- HWS — two-/three-column `NavigationSplitView` (auto-collapse to stack in compact width): https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-two-column-or-three-column-layout-with-navigationsplitview
