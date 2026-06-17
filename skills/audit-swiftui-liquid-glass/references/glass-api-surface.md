# Reference — The Real Liquid Glass API Surface (iOS 26)

The canonical allow-list of real SwiftUI Liquid Glass symbols on iOS 26, plus the hallucination
blacklist this skill detects. This is the spine the other references cite. Per-platform floor *values*
are not restated here — they live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (the
single source of availability truth). This file carries the **signatures, the existence allow-list,
the invented-name detection content, and the ❌→✅ rewrites**.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK.

---

## Why AI gets this wrong

Liquid Glass shipped at WWDC25 (June 2025). Almost no pre-mid-2025 training data holds its real API
surface, so this is the highest API-hallucination domain in the toolkit. Two failure shapes:

1. **Invention.** The model emits a plausible name in Apple's usual shape — `.glassBackground()`,
   `.liquidGlass()`, `LiquidGlassView`, `.material(.glass)`, `.background(.glass)`. None exist; they
   fail to compile. The real-but-platform-wrong cousin `.glassBackgroundEffect()` is **visionOS-only
   (absent on iOS)**.
2. **Real name, broken discipline.** The model knows `glassEffect()` but ignores the rules Apple
   attaches (navigation-layer-only, no glass-on-glass, group in a container, gate on the iOS arm).
   This compiles but looks wrong — invisible to a build, caught only by audit. See
   `design-rules-and-placement.md` and `availability-gating-glass.md`.

---

## The real symbol allow-list (these exist on iOS 26)

Confirm any floor against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; verify any
uncertain symbol via Sosumi (`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`).

| Symbol | Role | Apple doc path (`/documentation/swiftui/…`) |
|---|---|---|
| `glassEffect(_:in:)` | apply glass to a custom navigation-layer view | `view/glasseffect(_:in:)` |
| `GlassEffectContainer` | group sibling glass so they sample together + can morph | `glasseffectcontainer` |
| `.buttonStyle(.glass)` / `GlassButtonStyle` | the glass button style | `glassbuttonstyle` |
| `.buttonStyle(.glassProminent)` / `GlassProminentButtonStyle` | the tinted primary-action style | `glassprominentbuttonstyle` |
| `Glass` (struct) | the variant descriptor passed to `glassEffect` | `glass` |
| `Glass.regular` / `.clear` / `.identity` | variants (`.clear` requires a dimming layer beneath for legibility) | `glass/regular` etc. |
| `Glass.interactive(_:)` | touch-driven elastic feel on iPhone/iPad — **iOS 26.0+, the natural glass interactivity modality** | `glass/interactive(_:)` |
| `Glass.tint(_:)` | tint the glass (one primary action per screen) | `glass/tint(_:)` |
| `glassEffectID(_:in:)` | morph identity across a state change | `view/glasseffectid(_:in:)` |
| `glassEffectUnion(id:namespace:)` | merge siblings of the **same shape + variant + tint** | `view/glasseffectunion(id:namespace:)` |
| `glassEffectTransition(_:)` | transition style for appearing/disappearing glass | `view/glasseffecttransition(_:)` |
| `GlassEffectTransition.identity` | the identity (no-op) transition case | `glasseffecttransition/identity` |
| `GlassEffectTransition.matchedGeometry` | the matched-geometry transition case | `glasseffecttransition/matchedgeometry` |
| `GlassEffectTransition.materialize` | the materialize transition case | `glasseffecttransition/materialize` |
| `backgroundExtensionEffect()` | extend content under a sidebar/inspector | `view/backgroundextensioneffect()` |
| `scrollEdgeEffectStyle(_:for:)` | style the scroll edge (`.automatic`/`.soft`/`.hard`) | `view/scrolledgeeffectstyle(_:for:)` |
| `scrollEdgeEffectHidden(_:for:)` | hide a scroll edge effect | `view/scrolledgeeffecthidden(_:for:)` |
| `ToolbarContent.sharedBackgroundVisibility(_:)` | group/hide the toolbar's shared glass background | `toolbarcontent/sharedbackgroundvisibility(_:)` |
| `DefaultGlassEffectShape` | the default shape used by `glassEffect` (a capsule) | (named in the `glassEffect(_:in:)` signature) |

**Verbatim signatures (Xcode 26 SDK):**

```swift
func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
func interactive(_ isEnabled: Bool = true) -> Glass            // Glass.interactive — iOS 26.0+
func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View
@MainActor @preconcurrency struct GlassEffectContainer<Content> : View
```

`backgroundExtensionEffect()` is also visionOS 26.0+. `toolbarBackground(_:for:)` (distinct
from the glass calls, used in chrome fixes) is **iOS 16.0+** — see floors-master.

---

## Hallucination blacklist (detect + replace)

These never exist on an iOS target. The canonical shared list (consumed across skills) is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`; the glass-specific ❌→✅ rewrites
this skill applies are below.

| ❌ Hallucinated / platform-wrong | Why wrong | ✅ Correct (iOS 26) |
|---|---|---|
| `.glassBackground()` | does not exist | `.glassEffect()` (default `.regular`, `DefaultGlassEffectShape()`) |
| `.liquidGlass()` | marketing name, not an API | `.glassEffect()` |
| `LiquidGlassView` | no such type | `GlassEffectContainer { … }` |
| `.material(.glass)` | `Material` has no `.glass` case | `.glassEffect(.regular, in:)` (or `.background(.ultraThinMaterial)` as a pre-26 fallback) |
| `.background(.glass)` | no `.glass` background style | `.glassEffect(.regular, in:)` |
| `.glassEffect(.liquid)` | `Glass` has no `.liquid` | `Glass.regular` / `.clear` / `.identity` |
| `GlassContainer` | wrong name | `GlassEffectContainer` |
| `.buttonStyle(.liquidGlass)` | no such style | `.buttonStyle(.glass)` / `.glassProminent` |
| `.glassBackgroundEffect()` on an iOS path | real but **visionOS-only (iOS ABSENT)** | `.glassEffect(_:in:)` on iOS 26.0+ |

**`.interactive()` is NOT a hallucination and NOT platform-wrong.** `Glass.interactive(_:)` is iOS 26.0+
(touch-driven on iPhone/iPad — the natural glass interactivity modality). Do not flag `.interactive()`
as invented. If it appears under an `#available(macOS 26, *)` gate in an iOS path, that is a *wrong-arm
gate* (glass-07), not a hallucination — see `availability-gating-glass.md`.

---

## Detection tells (for DETECT; the deterministic version is `scripts/glass-lint.sh`)

- Invented names (glass-01): `\.glassBackground\(` · `\.liquidGlass\(` · `LiquidGlassView` · `\.material\(\.glass` · `\.background\(\.glass` · `GlassContainer\b` · `\.buttonStyle\(\.liquidGlass`
- visionOS-only on Mac (glass-02): `\.glassBackgroundEffect\(`

---

## Sources

- Apple — SwiftUI Liquid Glass symbol pages, fetched via Sosumi (access 2026-06-16):
  `https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)`,
  `/documentation/swiftui/glasseffectcontainer`, `/documentation/swiftui/glass/interactive(_:)`,
  `/documentation/swiftui/view/scrolledgeeffecthidden(_:for:)`,
  `/documentation/swiftui/view/glasseffectunion(id:namespace:)`,
  `/documentation/swiftui/view/backgroundextensioneffect()`.
- WWDC25 — "Meet Liquid Glass" (`/videos/play/wwdc2025/219`), "Build a SwiftUI app with the new
  design" (`/videos/play/wwdc2025/323`), via Sosumi.
