# Reference — The Gating Defects (gate-01 · gate-02 · gate-03 · gate-04 · gate-05 · gate-07)

The depth for the blanket availability sweep. This skill is the toolkit's **net**: every API floored
above the project's deployment target must be gated on the iOS arm, at the right floor, with a real
fallback. The cross-cutting *rule* (the iOS arm, the required `*` wildcard, the wrong-arm failure,
reading multi-platform strings) is **not** restated here — it lives in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. Floor *values* are the reconciled truth
in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — that table **is** this skill's floor
map. This file adds the per-defect application and the ❌→✅ rewrites.

**As of:** 2026-06-16 · iOS 26 SDK · corpus floor iOS 17 (iPad modeled within iOS).

---

## The fact that drives every finding: the deployment target

Read it once in ORIENT (`IPHONEOS_DEPLOYMENT_TARGET` in `project.pbxproj`, or `platforms:` in
`Package.swift`). A symbol floored at iOS NN is a finding **only** when the target is **below NN**.
iPhone/iPad users lag on OS upgrades, so shipping apps legitimately target an older iOS *and* iOS 26 —
that dual target is exactly why the gate is required. A symbol whose floor is ≤ the target is **not** a
finding; suppress it (under the iOS-17 default floor, `@Observable`/`symbolEffect`/`scrollClipDisabled`
at floor 17.0 are not findings).

---

## gate-01 — ungated above-floor symbol (hard-fail; fix_mode: flag-only)

The symbol is used with no `#available`/`@available` guard, and its floor (per floors-master) is above
the deployment target → the build breaks on the older iOS the project claims to support. flag-only
because the right `else` fallback is a judgment.

```swift
// ❌ IPHONEOS_DEPLOYMENT_TARGET = 17.0; glassEffect is iOS 26.0+ → build error on iOS 17/18
controls.glassEffect()
// ✅ iOS arm + a pre-floor fallback (the consensus gated shape — see ## Source)
if #available(iOS 26.0, *) {
    controls.glassEffect(in: .capsule)
} else {
    controls.background(.ultraThinMaterial, in: Capsule())
}
```

Confirm the floor with `swiftui-ctx lookup <api> --platform ios --json` (`introduced_ios`) and Sosumi
before reporting. If the symbol is *also* deprecated, it is an **api-currency** finding — `cross_ref` it,
don't double-report (per `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`). If it is a glass
symbol, `cross_ref: audit-swiftui-liquid-glass` (it owns glass gating in depth).

---

## gate-02 — wrong-arm gate (hard-fail; fix_mode: auto)

```swift
// ❌ on iPhone/iPad the macOS arm is never true, so the iOS floor is never enforced — the call
//    either fails to compile for iOS or its branch silently never runs on device.
if #available(macOS 26.0, *) { controls.glassEffect() }
// ✅ pure arm correction — gate on the iOS arm
if #available(iOS 26.0, *) { controls.glassEffect() }
```

Safe to auto-fix because only the arm is wrong; floor and structure are otherwise correct. Per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` §3 this is a gating finding, **not** a
hallucination — `glassEffect()` and the like are real on iOS 26.0; the arm is the bug. **Note the
inversion from a macOS audit:** there the wrong arm is `iOS`; here, in an iOS target, the wrong arm is
`macOS`.

---

## gate-03 — floor mismatch (warning; fix_mode: flag-only)

A `#available(iOS NN, *)` gate exists but `NN` ≠ the symbol's floor in floors-master. Two shapes:

- **Over-gating** — `NN` higher than the floor needlessly excludes devices that support the symbol (e.g.
  gating `scrollClipDisabled` at `iOS 26` when it is `iOS 17.0+` — reading the macOS arm number, or a
  guessed floor, over-gates iOS per ios-gating §4).
- **Under-gating** — `NN` lower than the floor still breaks the build (e.g. `glassEffect` gated at
  `iOS 18`). flag-only: the dev picks whether to raise the gate or change the API.

Always read the **iOS** arm of the availability string — never the macOS number (it can be lower, which
under-gates iOS). Verify with `swiftui-ctx lookup <api> --platform ios` (`introduced_ios`) + Sosumi.

---

## gate-04 — missing else fallback (warning; fix_mode: flag-only; no flat lint tell)

An `if #available(iOS NN, *)` with **no `else`** is legal Swift, but if the gated branch produces a
*view the layout depends on*, the pre-floor OS renders nothing there. A missing `else` is structural
absence ast-grep cannot positively match, so there is no flat tell — you decide in READ from each
gate-03 hit (every located `#available(iOS …)`): does this branch contribute a control/surface the UI
needs pre-floor? If yes, a fallback is required.

```swift
// ❌ pre-26 the pill simply vanishes on an iOS-17 device
if #available(iOS 26.0, *) { pill.glassEffect(in: .capsule) }
// ✅ a real pre-floor fallback
if #available(iOS 26.0, *) {
    pill.glassEffect(in: .capsule)
} else {
    pill.background(.ultraThinMaterial, in: Capsule())
}
```

A purely additive decoration (the surface is fine flat pre-floor) needs no `else` — don't over-report.

---

## gate-05 — @available decl vs #available use mismatch (warning; fix_mode: flag-only)

`@available(iOS NN, *)` on a `type`/`func`/`var` gates the *declaration*; the **use site** still needs
its own `#available` (or an `@available` on its container). The defects:

- a type/function annotated `@available(iOS 26, *)` is *called* from an ungated context;
- a use site `#available(iOS 26, *)` whose declaration carries **no** `@available`, so the symbol is
  reachable from a sub-floor caller;
- the decl and use floors **disagree** (`@available(iOS 26)` decl, `#available(iOS 18)` use).

```swift
// ✅ both layers agree, on the iOS arm
@available(iOS 26.0, *)
struct GlassPill: View { var body: some View { … } }

if #available(iOS 26.0, *) { GlassPill() } else { LegacyPill() }
```

flag-only: which layer to move (raise the use gate vs add a decl gate) is a design call.

---

## gate-07 — missing `*` wildcard (hard-fail; fix_mode: auto)

```swift
if #available(iOS 26.0) { … }    // ❌ compile error — no trailing wildcard
if #available(iOS 26.0, *) { … } // ✅
```

The `*` covers every *other* platform the code may compile against (macOS, watchOS, tvOS, visionOS) and
is mandatory. Auto-fixable: append `, *` inside the condition. Same for `@available(iOS 26.0)` →
`@available(iOS 26.0, *)`.

---

## Sources

- The gating rule, the `*` wildcard, the wrong-arm failure, multi-platform strings:
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` (toolkit-internal, Apple-sourced via
  Sosumi, access 2026-06-16).
- Floor values: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (generated from
  `sdk_catalog.json` `introduced_ios`).
- Apple — `glassEffect(_:in:)` iOS 26.0+:
  `https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)` (via Sosumi, accessed
  2026-06-16).
- Consensus gated example: `swiftui-ctx lookup glassEffect --platform ios` → `recommended`
  `1amageek/Toolbar` `Sources/Toolbar/ToolbarContainer.swift#L109` (`min_ios: 26`):
  `https://github.com/1amageek/Toolbar/blob/651c24079698401734dbca70c00632ef1498b295/Sources/Toolbar/ToolbarContainer.swift#L109`
  (accessed 2026-06-16).
- The Swift `#available` / `@available` language feature (`swift.org`).
