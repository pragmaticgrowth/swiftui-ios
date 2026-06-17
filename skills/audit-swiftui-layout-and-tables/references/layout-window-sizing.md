# Reference — Device-Frozen Frames & the fixedSize Trap (lt-02 · lt-04)

The two raw-arrangement defects: content pinned to a **literal device width**, and a blanket
`.fixedSize()` that clips on a small screen. Both are *flag-only* (the ✅ shape is shown; the size-class
restructuring is `adaptive-layout`'s). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The canonical shape for
any API is what shipping iOS apps write — fetch it with
`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (VERIFY) and back the
✅ with a `swiftui-ctx file <recommended.id> --smart` permalink (FIX).

**As of:** 2026-06-16 · iOS 26 · iOS-17 deployment floor · Swift 6.2.

---

## Why this is wrong on iOS

iOS has **no resizable window** — there is no min/ideal/max content frame, no `.defaultSize`, no
`.windowResizability` (those are **macOS-only, iOS-ABSENT**). But iOS has the **opposite** problem: many
*device classes and orientations* — iPhone portrait/landscape, iPad full/split, Slide Over, Stage Manager.
A layout frozen to one device's point dimensions breaks on all the others. The Mac-trained intuition
("declare fixed sizes") produces a screen pinned to `393` points that letter-boxes on iPad and clips in
landscape. Size content to **its container**, not to a literal number.

> **iOS-ABSENT — do NOT flag/suggest:** the scene-sizing modifiers `defaultSize(_:)` and
> `windowResizability(_:)` (no resizable window on iOS), and a "no min/ideal/max content frame" finding.
> Those are macOS concerns that have no iOS analogue.

---

## lt-02 — fixed full-screen `.frame(width: <literal>)` (warning, flag-only — **companion note**)

Pinning full-screen content to a literal device width letter-boxes on iPad and clips in landscape. The
**adaptive fix** (size to the container / branch on size class) is `adaptive-layout`'s — flag the raw
arrangement, emit `cross_ref: adaptive-layout`, and defer the size-class depth there.

```swift
// ❌ WRONG — content frozen to an iPhone-15 logical width; letter-boxes on iPad, clips in landscape
VStack { Hero(); Body() }
    .frame(width: 393)
```
```swift
// ✅ CORRECT — size to the container, not to a device literal (containerRelativeFrame is iOS 17.0+)
VStack { Hero(); Body() }
    .frame(maxWidth: .infinity)                                   // fill the available width
// or, to track a fraction of the container:
VStack { Hero(); Body() }
    .containerRelativeFrame(.horizontal) { w, _ in w * 0.9 }      // iOS 17.0+ (≥ project floor; no gate)
```
A `.frame(width:)` on a genuinely fixed-size element (an avatar, a badge, an icon) is fine — flag only
**full-screen / primary content** frozen to a device literal.

## lt-04 — blanket `.fixedSize()` on a container (advisory, flag-only)

Wrapping a whole subtree in `.fixedSize()` to "stop truncation" forces the view to its ideal size in
*both* axes and can overflow / clip on a small screen. The targeted fix for "which view gives up space
first" is `layoutPriority`; to stop a single label wrapping without freezing height, use single-axis
`fixedSize(horizontal:vertical:)`.

```swift
// ❌ WRONG — blanket both-axis fixedSize on a container; ignores the proposed size, clips on iPhone
HStack { Text(longTitle); Spacer(); Text(subtitle) }
    .fixedSize()
```
```swift
// ✅ CORRECT — layoutPriority decides who keeps space; single-axis fixedSize stops wrap only
HStack {
    Text(longTitle).layoutPriority(1)            // this Text keeps its space
    Spacer()
    Text(subtitle)                               // this one truncates first
}
Text(label).fixedSize(horizontal: false, vertical: true)   // stop wrap, don't freeze width
```

---

## The canonical exemplar (steer fixes toward this)

Container-relative, size-class-aware content that adapts across every iOS device class:

```swift
struct AdaptiveScreen: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Hero()
                Body()
            }
            .frame(maxWidth: .infinity)                              // fill available width, no device literal
            .containerRelativeFrame(.horizontal) { w, _ in           // iOS 17.0+; track the container
                hSizeClass == .regular ? min(w, 700) : w             // cap reading width on iPad
            }
        }
    }
}
```

**Rules:** (1) never pin full-screen content to a literal `.frame(width:)`; fill with `maxWidth: .infinity`
or track the container with `containerRelativeFrame` (iOS 17.0+). (2) prefer `layoutPriority` /
single-axis `fixedSize(horizontal:vertical:)` before a blanket `.fixedSize()`. (3) the size-class
branching depth is `adaptive-layout`'s — `cross_ref` it.

VERIFY a floor or signature with `swiftui-ctx lookup <api> --platform ios --json` + Sosumi (read the iOS
arm only).

---

## Sources

- Apple — `frame(maxWidth:maxHeight:alignment:)`: *"Positions this view within an invisible frame…"* —
  `iOS 13.0+`.
  `https://developer.apple.com/documentation/swiftui/view/frame(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:alignment:)`
  (via Sosumi, accessed 2026-06-16).
- Apple — `containerRelativeFrame(_:alignment:)`: *"Positions this view within an invisible frame with a
  size relative to the nearest container."* — `iOS 17.0+`.
  `https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:alignment:)` (via
  Sosumi, accessed 2026-06-16).
- Apple — `fixedSize()` / `layoutPriority(_:)`: `iOS 13.0+` (signatures long-stable).
  `https://developer.apple.com/documentation/swiftui/view/fixedsize()` ·
  `https://developer.apple.com/documentation/swiftui/view/layoutpriority(_:)` (via Sosumi, accessed
  2026-06-16).
- Apple — `horizontalSizeClass`:
  `https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass` (via Sosumi,
  accessed 2026-06-16).
