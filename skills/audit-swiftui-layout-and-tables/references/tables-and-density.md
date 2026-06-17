# Reference — Table on iPhone, Sort & Control Density (lt-01 · lt-03)

`Table` is an **iPad/Mac control**: multi-column, sortable, header-clickable. On **iOS / iPhone (compact
width) it collapses to a single squished column** — so shipping a `Table` as the *primary* collection with
no size-class fallback is the defect. `List` is the iPhone primary. These are *flag-only* defects. Floors
live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is
the swiftui-ctx **consensus shape** (`lookup --platform ios`) backed by a real iOS permalink, not opinion.

**As of:** 2026-06-16 · iOS 26 · iOS-17 deployment floor · Swift 6.2.

---

## Why this is wrong on iOS

The training corpus carries a lot of Mac code where `Table` *is* the default data grid. On iOS that
intuition is inverted: a `Table` is a regular-width (iPad / Mac) control, and on compact width (iPhone
portrait, iPad split-view) it renders as one cramped column with no headers. The iOS-correct pattern is a
`List` outright, or — on a Universal target — a **width-gated split**: `Table` on regular width, `List` on
compact. `Table` is iOS 16.0+ (confirm in `floors-master.md`); the project floor is iOS 17, so no gate.

---

## lt-01 — `Table` as the primary collection with no compact `List` fallback (warning, flag-only)

A `Table` used as the screen's main list collapses to a single squished column on iPhone. Either use a
`List`, or gate on `horizontalSizeClass` — `Table` on regular, `List` on compact. The **structure** is
this skill; the **size-class branching depth** is `adaptive-layout`'s (emit `cross_ref: adaptive-layout`).

```swift
// ❌ WRONG — Table as the screen's primary collection; one squished column on iPhone
struct PeopleScreen: View {
    let people: [Person]
    var body: some View {
        Table(people) {
            TableColumn("Name") { Text($0.name) }
            TableColumn("Age")  { Text("\($0.age)") }
        }
    }
}
```
```swift
// ✅ CORRECT — width-gated: Table on regular (iPad), List on compact (iPhone)
struct PeopleScreen: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    let people: [Person]
    var body: some View {
        if hSizeClass == .regular {
            Table(people) {
                TableColumn("Name") { Text($0.name) }
                TableColumn("Age")  { Text("\($0.age)") }
            }
        } else {
            List(people) { person in            // iPhone primary: a List, not a collapsed Table
                VStack(alignment: .leading) {
                    Text(person.name)
                    Text("\(person.age)").foregroundStyle(.secondary)
                }
            }
        }
    }
}
```
A `Table` inside an **iPad-only detail column** (e.g. the detail of a `NavigationSplitView` that is itself
gated to regular width) is correct — judge the target family and the size-class context before flagging.

**Grounded in the corpus.** `swiftui-ctx lookup Table --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 16.0`, `deprecated: false`, and consensus shapes `(_, selection)` 27% · `(_)` 27% ·
`(_, sortOrder)` 13% · `(_, selection, sortOrder)` 13%. Its `co_occurs_with` is `TableColumn`, `onHover`,
`NavigationSplitView`, `CommandGroup`, `commands` — i.e. real shipping `Table` call sites sit in
**regular-width / Mac-Catalyst** contexts, confirming `Table` is not the iPhone primary. The recommended
iOS example is `Table($hostNetworks, selection: $selectedID)` in a settings split-view —
`https://github.com/utmapp/UTM/blob/fb61bfe86a2cc39bb3bc884636fa55414f317acb/Platform/macOS/SettingsView.swift#L382`.

## lt-03 — `Table` on iPad/regular with no `sortOrder` (advisory, flag-only)

When a `Table` *is* correctly shown on regular width, users expect sortable column headers. Drive sorting
with `sortOrder: $binding` to `[KeyPathComparator]`; columns built with `value:` become sortable
automatically. On a compact-only collection this is moot — flag only where the `Table` is genuinely shown.

```swift
// ❌ WRONG — Table on iPad with no sortOrder; headers don't sort
Table(people) {
    TableColumn("Name") { Text($0.name) }
}
```
```swift
// ✅ CORRECT — sortOrder + value: columns + onChange (the one wiring)
@State private var people: [Person] = Person.sample
@State private var sortOrder = [KeyPathComparator(\Person.name)]

Table(people, sortOrder: $sortOrder) {
    TableColumn("Name", value: \.name)                      // value: => sortable header
    TableColumn("Age",  value: \.age) { Text("\($0.age)") } // sortable + custom cell
    TableColumn("Notes") { Text($0.notes) }                 // no value: => intentionally non-sortable
}
.onChange(of: sortOrder) { _, newOrder in people.sort(using: newOrder) }
```

> **iOS-ABSENT — do NOT suggest these on iOS:** `TableColumnForEach` (variable column count) and
> `alternatingRowBackgrounds` are **macOS-only** (`swiftui-ctx lookup … --platform ios` exits 3). There is
> **no `tableStyle(.inset(alternatesRowBackgrounds:))` deprecation rule on iOS** — that is a macOS-26.5
> concern that does not apply here.

## Control density on iOS (the seam, not a rule)

`controlSize(_:)` exists on iOS (15.0+), but its `.small`/`.mini` densities are a **pointer-driven Mac
idiom**. On iPhone, touch targets must stay at or above the **44pt minimum** — shrinking controls to
`.mini` to fit "more in a pane" is a Mac habit that fails Apple's touch guidance. There is **no iOS rule**
telling you to shrink density (the macOS lt-05 "use `.small` in a dense pane" is inverted away). When the
real issue is a control's *style* (`.buttonStyle`/`.pickerStyle`/`.textFieldStyle`), that is
`controls-forms` — `cross_ref controls-forms`, don't own it here.

---

## iOS-specific notes

- **`Table` collapses to one column on compact width** (iOS 16.0+). A `TableColumn` built with `value:` is
  sortable; one with only a content closure is not.
- **Scale at size.** SwiftUI `List`/`Table` past ~5,000 rows or with heavy custom cells is a render-cost
  concern owned by `view-performance` (and the `UITableView`/`UICollectionView` bridge decision is
  `uikit-interop`'s) — note it in one line and `cross_ref view-performance`, don't own it here.

---

## Sources

- Apple — `Table`: *"A container that presents rows of data arranged in one or more columns…"* —
  iOS arm: `iOS 16.0+` (read only the iOS arm). *"On iOS, tables collapse to a single column on a compact size class."*
  `https://developer.apple.com/documentation/swiftui/table` (via Sosumi, accessed 2026-06-16).
- Apple — `controlSize(_:)`: *"Sets the size for controls within this view."* — `iOS 15.0+`.
  `https://developer.apple.com/documentation/swiftui/view/controlsize(_:)` (via Sosumi, accessed 2026-06-16).
- Apple — `horizontalSizeClass` (the width-gate idiom): *"The horizontal size class of this environment."*
  `https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass` (via Sosumi,
  accessed 2026-06-16).
- Apple HIG — Layout / minimum 44pt touch targets:
  `https://developer.apple.com/design/human-interface-guidelines/layout` (via Sosumi, accessed 2026-06-16).
- Practice corpus (the ✅ permalink): `swiftui-ctx lookup Table --platform ios` →
  `https://github.com/utmapp/UTM/blob/fb61bfe86a2cc39bb3bc884636fa55414f317acb/Platform/macOS/SettingsView.swift#L382`
  (iOS catalog, `introduced_ios`, SwiftSyntax; accessed 2026-06-16).
