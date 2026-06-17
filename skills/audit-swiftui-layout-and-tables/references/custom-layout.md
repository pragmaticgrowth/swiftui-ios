# Reference — Custom `Layout` vs a Built-in Container (lt-05)

This skill **owns** the custom-layout context (per `finding-schema.md` and `cross-ref-graph.md`). The
defect is *flag-only*: a hand-rolled `Layout`-protocol conformance where a built-in container would do the
same job with less code, fewer bugs, and free adaptivity. Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate.

**As of:** 2026-06-16 · iOS 26 · iOS-17 deployment floor · Swift 6.2.

---

## Why this is wrong on iOS

The `Layout` protocol (**iOS 16.0+**) lets you compute `sizeThatFits` / `placeSubviews` by hand. It is a
real, correct tool — for genuinely custom arrangements (radial menus, flow layouts, masonry). But AI
reaches for it to reproduce things a **built-in already does**, paying the cost of a bespoke geometry
engine for no gain — and on iOS the built-ins (`Grid`, `ViewThatFits`, `containerRelativeFrame`) carry the
size-class adaptivity a hand-rolled `Layout` throws away.

```swift
// ❌ OFTEN UNNECESSARY — a custom Layout that just stacks two columns
struct TwoColumnLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize { /* … */ }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) { /* … */ }
}
```
```swift
// ✅ CORRECT — a built-in container expresses the same intent (all iOS 16/17, ≥ project floor; no gate)
Grid { GridRow { LeftPane(); RightPane() } }                       // iOS 16.0 — aligned rows/columns
ViewThatFits { WideLayout(); NarrowLayout() }                      // iOS 16.0 — first child that fits
SomePane().containerRelativeFrame(.horizontal) { w, _ in w * 0.4 } // iOS 17.0 — size relative to container
```

**Decision test — keep the custom `Layout` only if all are true:** (1) the arrangement is genuinely not a
stack/grid/`ViewThatFits`; (2) it needs cross-subview measurement a built-in can't express; (3) the code
is simpler or more correct than composing built-ins. Otherwise flag it toward the built-in.

**Grounded in the corpus.** `swiftui-ctx lookup Layout --platform ios --json` (run 2026-06-16):
`introduced_ios: 16.0`, `deprecated: false` — very few shipping iOS apps hand-roll `Layout`, which is
itself the signal that most uses are unnecessary. `swiftui-ctx lookup ViewThatFits --platform ios` returns
the built-in's consensus shape (`(in)` 53% · `{ }` 48%) + a real iOS permalink for the ✅ —
`https://github.com/Dimillian/IceCubesApp/blob/9c05a720597b3ff13de2e241bf58d3fba0863c09/Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowMediaPreviewView.swift#L209`.
In FIX, put the built-in's consensus shape in `## Correct` and that permalink in `## Source`.

---

## Seam — `GeometryReader` vs `Layout` vs `Canvas`

`cross-ref-graph.md` splits these precisely; apply it:

- A `GeometryReader` / `Layout` doing **layout arrangement** (positioning sibling views) → **this skill**.
- A `GeometryReader` **feeding a `Canvas`** (drawing geometry, not view placement) →
  `audit-swiftui-drawing-canvas`; note it in one line and `cross_ref drawing-canvas`, don't own it.
- A `Layout` whose real cost is **render performance** under many subviews → `cross_ref view-performance`.

A `GeometryReader` used merely to read width for a **compact-vs-regular decision** is the
`adaptive-layout` smell (use `@Environment(\.horizontalSizeClass)`); one reading a size for a one-off
`.frame` is often replaceable by `containerRelativeFrame` (iOS 17.0+). Flag toward the simpler tool, but
only when the read is genuinely doing layout.

---

## Sources

- Apple — `Layout`: *"A type that defines the geometry of a collection of views."* — `iOS 16.0+`.
  `https://developer.apple.com/documentation/swiftui/layout` (via Sosumi, accessed 2026-06-16).
- Apple — `ViewThatFits`: *"A view that adapts to the available space by providing the first child view
  that fits."* — `iOS 16.0+`.
  `https://developer.apple.com/documentation/swiftui/viewthatfits` (via Sosumi, accessed 2026-06-16).
- Apple — `Grid` / `GridRow`: *"A container view that arranges other views in a two-dimensional layout."*
  — `iOS 16.0+`. `https://developer.apple.com/documentation/swiftui/grid` (via Sosumi, accessed
  2026-06-16).
- Apple — `containerRelativeFrame(_:alignment:)` — `iOS 17.0+`.
  `https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:alignment:)` (via
  Sosumi, accessed 2026-06-16).
- Practice corpus: `swiftui-ctx lookup Layout --platform ios` ·
  `swiftui-ctx lookup ViewThatFits --platform ios` →
  `https://github.com/Dimillian/IceCubesApp/blob/9c05a720597b3ff13de2e241bf58d3fba0863c09/Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowMediaPreviewView.swift#L209`
  (iOS catalog; accessed 2026-06-16).
