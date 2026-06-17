# Gesture currency, live state & composition (tg-01 … tg-04)

The gesture half of the domain: the deprecated pinch/rotate **rename mechanics** (tg-01/02), missing live
`@GestureState` on a continuous gesture (tg-03), and gesture composition (tg-04). The *flag* that
`MagnificationGesture`/`RotationGesture` are deprecated is owned by `audit-swiftui-api-currency`; **this
skill owns the rewrite** — emit `cross_ref: api-currency` on tg-01/tg-02. Gesture-driven *animation
timing* is `animation-motion`'s.

Floor values are NOT restated — read them from
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. The deprecated-rename rows are in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. The ✅ shape is the swiftui-ctx
**consensus** + a permalinked example — `lookup … --platform ios` / `deprecated` before you cite.

---

## tg-01 / tg-02 — `MagnificationGesture` / `RotationGesture` deprecated

Both are real but **deprecated**; the replacements `MagnifyGesture` / `RotateGesture` ship at **iOS
17.0+** — which is the toolkit's deployment floor, so the rewrite needs **no `#available` gate**.
`swiftui-ctx deprecated MagnificationGesture` returns `deprecated:true`, `migrate_to: MagnifyGesture` —
corroborate every flag with it. The value carrier renames too: `MagnifyGesture.Value.magnification` (was
`.magnitude`) and `RotateGesture.Value.rotation`.

```swift
// ❌ WRONG — deprecated
@GestureState private var scale: CGFloat = 1
content.gesture(MagnificationGesture().updating($scale) { v, s, _ in s = v })
```
```swift
// ✅ CORRECT — MagnifyGesture (iOS 17+, at the floor → no gate). consensus shape is MagnifyGesture()
//    (67% of real uses); verify: swiftui-ctx lookup MagnifyGesture --platform ios → recommended permalink
@GestureState private var scale: CGFloat = 1
content.gesture(
    MagnifyGesture().updating($scale) { v, s, _ in s = v.magnification }   // .rotation for RotateGesture
)
```

Because tg-01/02 are a deprecation flag, `cross_ref: api-currency` and let api-currency own the currency
angle; this skill carries the mechanics. (If a project's deployment floor were below iOS 17 the rewrite
would also need an `#available(iOS 17, *)` gate — see `gesture-availability.md` — but at the iOS-17
toolkit floor it does not.)

## tg-03 — continuous gesture with no live `@GestureState`

A `DragGesture` / `MagnifyGesture` / `RotateGesture` is *continuous*: it streams a value while in flight.
Without `@GestureState` (`.updating`) — or a committed `@State` written in `.onChanged`/`.onEnded` — the
in-flight value is never read and the interaction feels frozen until release. `@GestureState`
**auto-resets** to its initial value when the gesture ends, which is why it is the idiomatic carrier for
*transient* drag/scale/rotation; persist the committed result to `@State` in `.onEnded`. swiftui-ctx shows
`DragGesture` `co_occurs_with` `onChanged` and the composition operators — read those to confirm.

```swift
// ❌ WRONG — drag with no live state: nothing moves until you let go (and then jumps)
content.gesture(DragGesture())
```
```swift
// ✅ CORRECT — transient offset via @GestureState (auto-resets), committed in .onEnded
@GestureState private var drag: CGSize = .zero
@State private var offset: CGSize = .zero
content
    .offset(x: offset.width + drag.width, y: offset.height + drag.height)
    .gesture(
        DragGesture()
            .updating($drag) { v, s, _ in s = v.translation }     // live, transient
            .onEnded { offset.width += $0.translation.width        // commit
                       offset.height += $0.translation.height }
    )
```
The `DragGesture` consensus shape per `swiftui-ctx lookup DragGesture --platform ios` is `()` (56%) /
`(minimumDistance)` (31%) — back the ✅ with its `recommended` permalink.

## tg-04 — `.gesture` where `.simultaneousGesture` / `.highPriorityGesture` is needed (advisory)

A plain `.gesture(...)` attached to a view that **already has a built-in gesture** (a `Button`'s tap, a
`Slider`'s drag, a `ScrollView`'s pan/scroll, a `List` row's selection or swipe) can swallow or be
swallowed by that built-in. Two plain `.gesture(...)` chained onto one receiver also conflict — the later
wins. The fix is to declare intent:

- `.simultaneousGesture(_:)` — your gesture runs **alongside** the built-in (both fire).
- `.highPriorityGesture(_:)` — your gesture runs **instead of** the built-in (yours wins).
- Compose explicitly with `SimultaneousGesture` / `ExclusiveGesture` / `.sequenced(before:)` when you need
  a defined relationship (these appear in `DragGesture`'s `co_occurs_with`).

This is **advisory** and control-specific: whether the built-in actually conflicts depends on the host
control's gesture, which differs across SwiftUI versions — `source: verify against Xcode 26 SDK`. The
tier-2 ast-grep rule `tg-04-stacked-gestures.yml` catches the chained `.gesture().gesture()` form
structurally; the grep tell catches the plain-`.gesture(` presence for the agent to judge. On iOS the
`ScrollView`-pan conflict is the most common: a `DragGesture` inside a scroll view often needs
`.simultaneousGesture` to let scrolling continue.

```swift
// ❌ WRONG — a drag on a row that also swipes/selects: the two fight, the built-in may break
row.gesture(DragGesture().onChanged { … })
```
```swift
// ✅ CORRECT — declare it runs alongside the built-in
row.simultaneousGesture(DragGesture().onChanged { … })       // or .highPriorityGesture to override
```

---

## Detection tells (what LOCATE surfaces; you READ and judge)

- `MagnificationGesture` anywhere → tg-01 (deprecated → `MagnifyGesture`, `cross_ref` api-currency).
- `RotationGesture` anywhere → tg-02 (deprecated → `RotateGesture`, `cross_ref` api-currency).
- `DragGesture(` / `MagnifyGesture(` / `RotateGesture(` with no `@GestureState` / `.updating` /
  committed `@State` → tg-03.
- A plain `.gesture(` on a built-in-gesture control, or two `.gesture()` chained on one receiver → tg-04.

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/magnifygesture | `MagnifyGesture` — iOS 17.0+; `Value.magnification`; replaces deprecated `MagnificationGesture` | high |
| https://developer.apple.com/documentation/swiftui/magnificationgesture | `MagnificationGesture` — deprecated → `MagnifyGesture` | high |
| https://developer.apple.com/documentation/swiftui/rotategesture | `RotateGesture` — iOS 17.0+; `Value.rotation`; replaces deprecated `RotationGesture` | high |
| https://developer.apple.com/documentation/swiftui/gesturestate | `@GestureState` — transient gesture value that auto-resets when the gesture ends | high |
| https://developer.apple.com/documentation/swiftui/view/simultaneousgesture(_:including:) | `.simultaneousGesture` / `.highPriorityGesture` — compose with a built-in gesture | high |
| https://developer.apple.com/documentation/swiftui/draggesture | `DragGesture` — iOS 13.0+; `.translation` value; `.updating`/`.onChanged`/`.onEnded` | high |
| swiftui-ctx `deprecated MagnificationGesture` | `deprecated:true`, `migrate_to: MagnifyGesture` | high |
| swiftui-ctx `lookup MagnifyGesture --platform ios` | consensus `()` 67% / `(minimumScaleDelta)` 33%; recommended `mastodon/mastodon-ios` `PageableZoomableView.swift#L365` permalink (iOS 17) | high |
| swiftui-ctx `lookup DragGesture --platform ios` | consensus `()` 56% / `(minimumDistance)` 31%; recommended `mainframecomputer/fullmoon-ios` `ContentView.swift#L54`; `co_occurs_with` onChanged / SimultaneousGesture / ExclusiveGesture / sequenced | high |

Apple availability strings cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`
and fetched via Sosumi (access 2026-06-16). tg-04's built-in-gesture conflict is control-specific —
`verify against Xcode 26 SDK`. Cite the swiftui-ctx `recommended` permalink in each finding's `## Source`,
not the static snippet.
