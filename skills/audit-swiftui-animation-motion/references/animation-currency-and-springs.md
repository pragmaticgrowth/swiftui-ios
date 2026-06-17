# Animation currency & spring presets (anim-01 · anim-02 · anim-03 · anim-04)

The currency layer of motion: the **deprecated implicit `.animation(_)`**, the **missing/wrong `value:`**,
**raw durations where a spring preset belongs**, and the **spring-preset floor quirk**. Floor *values* are
the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate.

## anim-01 — implicit single-arg `.animation(_)` (the deprecated implicit form)

`.animation(_:)` with one argument is the **deprecated implicit form**: it implicitly animates *every*
upstream change, which is unpredictable. The fix is the **value-scoped** form `.animation(_:value:)` or an
explicit `withAnimation`. The production corpus agrees overwhelmingly.

- **swiftui-ctx consensus** (`swiftui-ctx lookup animation --platform ios --json`): **61 % `(_, value)`**,
  only **18 % `(_)`**. The modern value-scoped form is the consensus shape — get it live, don't paste a
  stale one.

```swift
// ❌ implicit — animates any change reaching this view (deprecated implicit form)
Circle().scaleEffect(scale).animation(.easeInOut)

// ✅ value-scoped — the swiftui-ctx consensus shape `(_, value)` (61 %); fetch the recommended real
//    example with `swiftui-ctx lookup animation --platform ios --json` → `recommended.id` →
//    `swiftui-ctx file <id> --smart`
//    doc: https://sosumi.ai/documentation/swiftui/view/animation
Circle().scaleEffect(scale)
    .animation(.easeInOut(duration: 0.3), value: scale)
```

For animations that must coordinate a multi-property state change, prefer the imperative `withAnimation`
around the mutation instead of an implicit modifier.

## anim-02 — animating a constant, or `withAnimation` over no observed change

`.animation(_:value:)` only fires when `value` actually changes. Two real defects: (a) `value:` bound to a
**constant** or a value the body never reads → the animation is dead; (b) `withAnimation { … }` whose body
mutates **no `@State`/observed** property → nothing animates. READ the surrounding state to confirm the
`value` is the property the visual actually depends on.

## anim-03 — raw duration curve where a spring preset fits

Hand-tuned `.linear(duration:)` / `.easeInOut(duration:)` for interactive, physical motion (drags, toggles,
appearance) reads non-native. SwiftUI's **named spring presets** `.bouncy` / `.smooth` / `.snappy` adapt to
interruption and read native. Advisory — the curve is a judgment, so flag the ✅, don't auto-apply.

```swift
// ⚠️ raw curve for a physical interaction
withAnimation(.easeInOut(duration: 0.35)) { isExpanded.toggle() }
// ✅ a spring preset
withAnimation(.smooth) { isExpanded.toggle() }
```

## anim-04 — spring preset native-idiom (no gate on iOS — the DocC quirk is moot)

`Animation.bouncy` / `.smooth` / `.snappy` are the **WWDC23 "Animate with springs" vocabulary**. The shipped
DocC renders `iOS 13.0` for them — a **type-property-inheritance quirk** (the property inherits its enclosing
`Animation` type's floor). **On iOS this is moot:** the project floor is **iOS 17**, so the presets are
unconditionally available whether you read the rendered 13 or the WWDC23 17 — **there is no gating finding
here.** anim-04 is therefore a pure *native-idiom advisory* (a raw curve where a preset reads more native),
identical in spirit to anim-03. Only if a project's deployment target is **below iOS 16** would a genuine
availability question arise — in that case route a real gate finding to `audit-swiftui-availability-gating`
per `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`; never gate from this skill on the iOS-17 floor.

> Carry the WWDC23 provenance only to describe the presets honestly — never to gate them on the iOS-17 floor.

## VERIFY (step 5)

- Practice: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup animation --platform ios --json` — read
  `consensus` (the 61 % `(_, value)` shape), `deprecated`, `introduced_ios`, `recommended` (the canonical
  permalink).
- Spec: Sosumi `https://sosumi.ai/documentation/swiftui/view/animation` for the deprecation badge + the
  `animation(_:value:)` signature; the spring-preset floor against `floors-master.md`.

## Sources

- Floor/deprecation values: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (Apple-sourced via
  Sosumi, access 2026-06-16).
- Apple — `View.animation(_:value:)`:
  `https://developer.apple.com/documentation/swiftui/view/animation(_:value:)` (via Sosumi, 2026-06-16).
- Apple — deprecated `View.animation(_:)`:
  `https://developer.apple.com/documentation/swiftui/view/animation(_:)` (via Sosumi, 2026-06-16).
- Apple — `Animation.bouncy/.smooth/.snappy` (WWDC23 "Animate with springs"):
  `https://developer.apple.com/documentation/swiftui/animation/smooth` (via Sosumi, 2026-06-16).
