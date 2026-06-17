# Reference — Toolbar Placements & Titles (nav-06/07/10/11)

iOS **has a navigation bar** — toolbar items use the **bar placements** and the title shows in the
navigation bar. The current iOS placements are correct; only the *old* `navigationBar*` placement and
title spellings are deprecated. **Floor values are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — never restated here**. Every ✅ shape is the
**swiftui-ctx consensus** (run the `lookup` in step VERIFY), not opinion.

---

## INVERTED FROM macOS — `.topBarLeading` / `.topBarTrailing` / `.bottomBar` are CORRECT on iOS

On macOS this skill (as nav-05) flagged `.topBarLeading` / `.topBarTrailing` as a **compile error**
(macOS-absent). **On iOS that is wrong** — those placements are the current, idiomatic iOS bar slots:

- `swiftui-ctx lookup topBarLeading --platform ios` → `introduced_ios: 14.0`, `deprecated: false`.
- `lookup topBarTrailing --platform ios` → `introduced_ios: 14.0`, `deprecated: false`.
- `lookup bottomBar --platform ios` → `introduced_ios: 14.0`, `deprecated: false`.

So **nav-05 is retired here**: a `.topBarLeading` / `.topBarTrailing` / `.bottomBar` placement is **never**
a finding on an iOS target. Use them freely. `.principal` (centered title area) and `.primaryAction`
(trailing on iOS) are also current.

## nav-06 · `.navigationBarLeading` / `.navigationBarTrailing` (hard-fail · auto)

The **old** spellings `.navigationBarLeading` / `.navigationBarTrailing` are **deprecated**
(`swiftui-ctx deprecated navigationBarLeading` / `navigationBarTrailing` → `deprecated: true`;
`lookup … --platform ios` → `introduced_ios: 14.0`, `deprecated: true`). Apple's current spellings are
`.topBarLeading` / `.topBarTrailing`. Mechanical rename.

```swift
// ❌ deprecated placement spellings
.toolbar {
    ToolbarItem(placement: .navigationBarLeading)  { Button("Back") {} }  // nav-06 deprecated
    ToolbarItem(placement: .navigationBarTrailing) { Button("Add")  {} }  // nav-06 deprecated
}
```
```swift
// ✅ current iOS bar placements
.toolbar {
    ToolbarItem(placement: .topBarLeading)  { Button("Back") {} }   // current iOS leading
    ToolbarItem(placement: .topBarTrailing) { Button("Add")  {} }   // current iOS trailing
    ToolbarItem(placement: .bottomBar)      { Button("Edit") {} }   // bottom toolbar
}
```

## nav-07 · `navigationBarTitle` is deprecated → `navigationTitle` (hard-fail · auto)

`navigationBarTitle(_:)` is **deprecated** (`swiftui-ctx lookup navigationBarTitle --platform ios` →
`introduced_ios: 13.0`, `deprecated: true`, `migrate_to: navigationTitle`). The current modifier is
`navigationTitle(_:)` (iOS 13.0+). **Keep `navigationBarTitleDisplayMode`** — it is iOS-only and **NOT
deprecated** (`lookup navigationBarTitleDisplayMode --platform ios` → `introduced_ios: 14.0`,
`deprecated: false`); `.inline` / `.large` / `.automatic` are the correct iOS title modes.

```swift
// ❌ deprecated title modifier
.navigationBarTitle("Inbox")                          // nav-07 deprecated → navigationTitle
```
```swift
// ✅ navigationTitle + navigationBarTitleDisplayMode (the latter is iOS-only and correct — keep it)
.navigationTitle("Inbox")
.navigationBarTitleDisplayMode(.inline)               // iOS-only, current — NOT a defect
```

**swiftui-ctx grounding (run live in VERIFY):** `lookup toolbar --platform ios --json` →
`co_occurs_with: ["ToolbarItem","ToolbarItemGroup", …]`, `recommended` a high-authority iOS
`.toolbar { … }` example. The trailing-closure `{ }` form is the canonical toolbar shape; the auto-fix's
✅ in `## Correct` is that consensus shape backed by `file <recommended.id> --smart`.

## nav-10 · `.searchable` on a column, not the navigation container (advisory)

`.searchable` goes on the `NavigationStack` / `NavigationSplitView` itself, **not** on a column — otherwise
it lands in the wrong bar slot. `searchToolbarBehavior(_:)` (iOS 26.0+) tunes the field; gate it if the
floor is below 26. `.minimize` (iOS/iPadOS 26.0+) is the iOS minimizing behavior.

```swift
// ✅ searchable on the navigation container (right bar slot)
NavigationStack { ListView() }
    .searchable(text: $query)
```

## nav-11 · `ToolbarSpacer` / `SpacerSizing` ungated under a < iOS 26 floor (warning · flag)

`ToolbarSpacer(_:placement:)` + `SpacerSizing` (`.fixed` for a single system-standard gap, `.flexible`
to push items toward opposite ends of a region) are **iOS 26.0+**
(`swiftui-ctx lookup ToolbarSpacer --platform ios` → `introduced_ios: 26.0`). Under a deployment target
below 26 they must sit behind `#available(iOS 26, *)` (the **iOS** arm — see
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`). If the project floor is already ≥ 26, nav-11
does not fire — read the floor in ORIENT.

```swift
if #available(iOS 26, *) {
    ToolbarSpacer(.fixed, placement: .topBarTrailing)      // system-standard gap
    ToolbarSpacer(.flexible, placement: .topBarTrailing)   // pushes following items apart
}
```

The `ToolbarSpacer` *glass era* crosses into `audit-swiftui-liquid-glass` — gate it here, cross_ref the
glass-adoption angle there.

---

## Sources

All Apple docs fetched via Sosumi (protocol:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`); access 2026-06-16. Floors live in
`floors-master.md`; the live consensus shape + permalink come from `swiftui-ctx lookup toolbar` (see
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`).

- `ToolbarItemPlacement` (`.topBarLeading`/`.topBarTrailing`/`.bottomBar`/`.principal`/`.primaryAction` current on iOS; `.navigationBarLeading`/`.navigationBarTrailing` deprecated): https://developer.apple.com/documentation/swiftui/toolbaritemplacement
- `ToolbarSpacer` + `SpacerSizing` (iOS 26; `.fixed`/`.flexible` toolbar gaps): https://developer.apple.com/documentation/swiftui/toolbarspacer
- `navigationTitle(_:)` (iOS 13.0+): https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)-43srq
- `navigationBarTitleDisplayMode(_:)` (iOS-only, `.inline`/`.large`/`.automatic`, iOS 14.0+ — current): https://developer.apple.com/documentation/swiftui/view/navigationbartitledisplaymode(_:)
- `searchable(text:placement:prompt:)`: https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)-18a8f
- `searchToolbarBehavior(_:)` (iOS 26.0+; `.minimize` iOS/iPadOS 26.0+): https://developer.apple.com/documentation/swiftui/view/searchtoolbarbehavior(_:)
