# Reference — Availability Gating for Glass Symbols

The glass-specific gating playbook. This skill owns glass gating **in depth**; the blanket "is every
floored API gated" sweep belongs to `audit-swiftui-availability-gating`. The cross-cutting gating
*rule* (iOS arm, the `*` wildcard, the wrong-arm failure, reading multi-platform strings) is NOT
restated here — it lives in `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`, and floor
values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. This file adds the
glass-specific application: which symbols are floored, and the pre-26 fallback choice.

**As of:** 2026-06-16 · iOS 26.

---

## The fact that drives the gate

**Every glass symbol is `iOS 26.0+`** (per floors-master): `glassEffect`, `GlassEffectContainer`,
`.buttonStyle(.glass)` / `.glassProminent`, `glassEffectID`, `glassEffectUnion`, `glassEffectTransition`,
`backgroundExtensionEffect`, `scrollEdgeEffectStyle`, `scrollEdgeEffectHidden`,
`sharedBackgroundVisibility`, `Glass.identity`, `Glass.interactive`. If the project's
`IPHONEOS_DEPLOYMENT_TARGET` (or `Package.swift` `platforms:`) is **below iOS 26**, an ungated glass
call is a **compile error** — and iPhone/iPad users lag on upgrades, so shipping apps legitimately
target iOS 17 *and* 26. The deployment target is therefore load-bearing: glass-06/07 only fire when the
floor is **< 26**; on an iOS-26-only target the gate is unnecessary and the finding is suppressed (read
the target once in step ORIENT).

`Glass.interactive(_:)` **is available on iOS 26.0** (touch-driven on iPhone/iPad — the natural
modality for glass interactivity). Do not flag `.interactive()` as invented or platform-wrong — see
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` §2.

---

## The two gating defects

**glass-06 — ungated glass symbol under a <26 floor (hard-fail; fix_mode: flag-only).**
The correct fallback and gate granularity depend on the surrounding code, so this is flag-only with the
✅ pattern shown.
```swift
// ❌ ungated; IPHONEOS_DEPLOYMENT_TARGET = 17.0 → build error
controls.glassEffect()
// ✅ branch on the iOS arm with a pre-26 fallback
if #available(iOS 26.0, *) {
    controls.glassEffect()
} else {
    controls.background(.ultraThinMaterial)
}
```

**glass-07 — wrong-arm gate (hard-fail; fix_mode: auto).**
```swift
// ❌ the wildcard * already covers iOS, so this branch always runs and the iOS floor is
//    never enforced — the glass call ships unguarded on iPhone/iPad.
if #available(macOS 26.0, *) { controls.glassEffect() }
// ✅ pure arm correction
if #available(iOS 26.0, *) { controls.glassEffect() }
```
Safe to auto-fix because only the arm is wrong; floor and structure are otherwise correct. Per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`, a wrong-arm gate is a gating finding,
**not** a hallucination.

---

## The pre-26 fallback choice (glass-06 ✅ guidance)

When you need an `else` branch, pick the closest pre-26 material — or no glass at all:

| Glass intent | Pre-26 fallback | When |
|---|---|---|
| translucent floating control / toolbar backing | `.background(.ultraThinMaterial)` | the common case; lightest material |
| more opaque chrome panel | `.background(.regularMaterial)` | when the control needs more contrast pre-26 |
| glass was decorative only | omit entirely (plain view) | when pre-26 the surface is fine flat |

A reusable `glassIfAvailable()` helper that branches internally is acceptable; the auditor flags the
ungated call and shows the branch, but applying it is the dev's call (which fallback fits is a judgment).

> **Gate-floor reconciliation (go-beyond):** read the deployment target once; suppress glass-06/07 when
> the floor is already ≥ iOS 26, escalate them when it is < 26. Prevents false positives on
> iOS-26-only apps.

---

## Sources

- Floor values + gating rule: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` and
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` (toolkit-internal, both Apple-sourced
  via Sosumi, access 2026-06-16).
- Apple — `glassEffect(_:in:)` iOS 26.0+:
  `https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)` (via Sosumi, accessed
  2026-06-16).
- The Swift `#available` / `@available` language feature (`swift.org`).
