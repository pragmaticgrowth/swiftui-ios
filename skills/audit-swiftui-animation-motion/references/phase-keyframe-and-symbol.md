# Phase / keyframe / symbol motion (anim-05 · anim-06 · anim-07)

The motion primitives that retire hand-rolled animation loops: **`PhaseAnimator`** (iOS 17),
**`KeyframeAnimator`** (iOS 17), **`.symbolEffect`** (iOS 17), and the value-aware **`.contentTransition`**
(iOS 16). **All ship at or below the iOS-17 project floor — so none of these defects is an availability
break on iOS; each is a *native-idiom* judgment.** Floor values are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

## anim-05 — hand-rolled loop where `PhaseAnimator` / `KeyframeAnimator` fits (iOS 17, ≤ floor)

A `Timer`, an `onAppear` that toggles `@State` to drive `.repeatForever`, or a chain of nested
`withAnimation(completion:)` calls to sequence steps is the old way to build multi-step motion. iOS 17
replaced it:

- **`PhaseAnimator`** — cycles a view through an ordered set of discrete phases (pulse, shake, attention).
- **`KeyframeAnimator`** — animates multiple properties along independent timelines from real keyframes.

Both ship at iOS 17, **at the project floor**, so no gate is needed. Advisory — whether the motion is better
expressed as phases is a judgment, so flag the ✅.

```swift
// ⚠️ hand-rolled repeating pulse
.scaleEffect(pulsing ? 1.1 : 1.0)
.animation(.easeInOut.repeatForever(autoreverses: true), value: pulsing)
.onAppear { pulsing = true }
// ✅ PhaseAnimator (iOS 17, at floor — no gate)
.phaseAnimator([1.0, 1.1]) { view, scale in view.scaleEffect(scale) }
```

## anim-06 — hand-animated SF Symbol where `.symbolEffect` fits (iOS 17, ≤ floor)

`.symbolEffect(_:options:value:)` / `(_:options:isActive:)` is **iOS 17.0+ — at the project floor, so no
gate.** The defect on iOS is purely idiomatic: an SF Symbol is animated by hand (rotation/opacity
`withAnimation`) where a built-in `.symbolEffect` (`.bounce`, `.pulse`, `.variableColor`, `.rotate`) is the
native, accessibility-aware path. (The macOS skill's "ungated under a sub-floor → gate it" arm does **not**
apply on the iOS-17 floor.)

- **swiftui-ctx** (`swiftui-ctx lookup symbolEffect --platform ios --json`): `introduced_ios` **17**;
  consensus spreads across `(_)`, `(_, options)`, `(_, value)`, `(_, isActive)` — pick the value/isActive
  form that matches the trigger state.

## anim-07 — value change without `.contentTransition` (iOS 16, ≤ floor)

A `Text` showing a number/score, a counter, or a swapped SF Symbol that changes value with no
`.contentTransition(_:)` cross-fades crudely. `.contentTransition(.numericText())` (digit roll), `.opacity`,
`.interpolate`, and `.symbolEffect` ship at **iOS 16 — below the floor, no gate.** Advisory — flag where a
value mutation animates without it.

```swift
// ✅ rolling numeric text on value change (iOS 16, below floor — no gate)
Text(score, format: .number)
    .contentTransition(.numericText())
    .animation(.snappy, value: score)
```

## VERIFY (step 5)

- Practice: `swiftui-ctx lookup symbolEffect --platform ios --json` (floor 17, consensus shapes,
  `recommended` permalink); `swiftui-ctx lookup contentTransition --platform ios --json`. FIX cites the
  consensus shape + a `file <id> --smart` GitHub permalink as the ✅.
- Spec: Sosumi for `PhaseAnimator` / `KeyframeAnimator` / `symbolEffect` floors; cross-check `floors-master.md`.

## Sources

- Floors: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (Apple-sourced via Sosumi, 2026-06-16).
- Apple — `PhaseAnimator`: `https://developer.apple.com/documentation/swiftui/phaseanimator` (via Sosumi,
  2026-06-16).
- Apple — `KeyframeAnimator`: `https://developer.apple.com/documentation/swiftui/keyframeanimator` (via
  Sosumi, 2026-06-16).
- Apple — `View.symbolEffect(_:options:value:)`:
  `https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:value:)` (via Sosumi,
  2026-06-16).
- Apple — `View.contentTransition(_:)`:
  `https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)` (via Sosumi, 2026-06-16).
