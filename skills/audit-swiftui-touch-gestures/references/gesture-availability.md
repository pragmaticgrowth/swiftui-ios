# Gesture/affordance availability gating (tg-08, tg-09)

This skill owns **gesture/affordance** gating in this domain; the blanket "is every floored API gated"
sweep is `audit-swiftui-availability-gating`'s (cross_ref it when a gate miss is incidental). The *rule*
for writing an iOS gate, the wrong-arm failure mode, and reading a multi-platform availability string are
the **single shared copy** in `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` — read it, do not
restate it here. Floor *values* live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

---

## Almost nothing in this domain needs a gate at the iOS-17 floor

The toolkit deployment floor is **iOS 17**. Read the value from `floors-master.md`, never assert it:

- `MagnifyGesture` / `RotateGesture` — **iOS 17.0+**: exactly at the floor → **no gate**.
- `.swipeActions` / `.refreshable` — iOS 15.0+ → below the floor → no gate.
- `onContinuousHover` — iOS 16.0+ → below the floor → no gate (but it is iPad-pointer-only → tg-05).
- `onTapGesture` / `onLongPressGesture` / `DragGesture` / `contextMenu` / `.accessibilityAction` — iOS
  13.0+ → no gate.

So the gating defects in this domain are **not** "an ungated above-floor gesture" — they are the two
**platform** errors below.

## tg-08 — `pointerStyle(_:)` on an iOS target (platform-wrong, hard-fail)

`pointerStyle(_:)` / `PointerStyle` has **no iOS arm** — it is macOS / visionOS only.
`swiftui-ctx lookup pointerStyle --platform ios` **exits 3** (no iOS-arm record). Wrapping it in
`#available(iOS …)` does **not** make it real on iOS — the symbol simply does not exist there. This is a
*platform-wrong* finding, not an under-gate: **replace** the cursor affordance with a touch interaction
(or drop it), never gate it.

```swift
// ❌ WRONG — pointerStyle does not exist on iOS; an #available(iOS …) wrapper cannot conjure it
if #available(iOS 18, *) { handle.pointerStyle(.grabIdle) }   // still no iOS arm — won't compile / no-op
```
```swift
// ✅ CORRECT on iOS — express the affordance with touch (a drag handle is dragged, not cursor-shaped)
handle.gesture(DragGesture().updating($drag) { v, s, _ in s = v.translation })
```
Reading a multi-platform availability string (the iOS-ABSENT case): the shared
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` §4. `fix_mode: flag-only` (the replacement is a
judgment, not a mechanical rename).

## tg-09 — a gesture/affordance gated on the `macOS` arm in an iOS target (wrong arm, hard-fail, auto)

Gating an iOS gesture/affordance on the **`macOS`** arm is the central gating bug ported from
cross-platform code: on iOS the branch's availability is wrong, so it either fails to compile or silently
never runs on device. The symbol is fine; the **arm** is wrong — flag it as a gating finding, not a
hallucination, and rewrite to `#available(iOS NN, *)` (or drop the gate when the symbol is at/under the
iOS-17 floor). `fix_mode: auto`. The tier-2 ast-grep rule `tg-09-macos-arm-gates-gesture.yml` proves the
`if #available(macOS …)` block body actually uses a gesture/affordance symbol (the gate *scope*), not
merely that the `macOS` string appears.

```swift
// ❌ WRONG — gated on macOS; on iPhone/iPad this branch's availability is wrong, the gesture never runs
if #available(macOS 14, *) { content.gesture(MagnifyGesture()) }
```
```swift
// ✅ CORRECT — MagnifyGesture is iOS 17 (the floor): no gate needed at all
content.gesture(MagnifyGesture())
// …or, if a sub-floor symbol genuinely needs gating, name the iOS arm:
if #available(iOS 17, *) { content.gesture(MagnifyGesture()) }
```

Full rule (iOS arm, the required `*`, reading a multi-platform string, the iOS-ABSENT case): the shared
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`.

---

## Detection tells (what LOCATE surfaces; you READ and judge)

- `.pointerStyle(` present in an iOS target → tg-08 (platform-wrong; `swiftui-ctx lookup pointerStyle
  --platform ios` exits 3 corroborates).
- `#available(macOS …)` whose block body uses a gesture/affordance symbol → tg-09 (tier-2 proves the
  scope).

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/view/pointerstyle(_:) | `pointerStyle(_:)` — macOS/visionOS only, **no iOS arm** (platform-wrong on iOS) | high |
| https://developer.apple.com/documentation/swiftui/magnifygesture | `MagnifyGesture` — iOS 17.0+ (at the toolkit floor → no gate) | high |
| swiftui-ctx `lookup pointerStyle --platform ios` | **exit 3** — no iOS-arm record | high |

Apple availability strings cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`
and fetched via Sosumi (access 2026-06-16). The iOS-arm gating *rule* itself is the shared
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` — not restated here.
