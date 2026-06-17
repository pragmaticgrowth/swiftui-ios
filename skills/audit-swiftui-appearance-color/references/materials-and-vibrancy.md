# Reference — Materials, Vibrancy & the Material-vs-Glass Boundary (ac-06)

When chrome should breathe with a `Material` instead of an opaque `Color`, and where the boundary to
Liquid Glass lies. Floor values: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (read, never
restate). Get the ✅ shape from the corpus: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup
<api> --platform ios --json`.

**As of:** 2026-06-16 · iOS 17+ (iPhone & iPad) · Xcode 26 SDK.

---

## ac-06 — opaque `Color` where a `Material` (or system background) belongs

Chrome behind content — overlays, popovers, sheet/toolbar-adjacent fills, HUD panels — reads as native
when it samples the content behind it through a **`Material`** (`.ultraThinMaterial`, `.thinMaterial`,
`.regularMaterial`, `.thickMaterial`, `.ultraThickMaterial` — all iOS 15+). An opaque `Color` fill
flattens that depth and freezes one appearance.

❌ `.background(Color(white: 0.12))` on a floating panel — flat, dark-broken.
✅ `.background(.regularMaterial)` — adapts to appearance and samples the backdrop. The exact ✅ + a
permalinked real example come from `swiftui-ctx lookup regularMaterial --platform ios --json` (or
`lookup Material`) + `swiftui-ctx file <recommended.id> --smart`. The iOS corpus consensus material is
`regular` (8,174 uses via `valueBuilders`); reserve `.ultraThinMaterial` for a genuinely thin overlay.

**Material vs. a flat system surface.** A `Material` is for chrome *over content* (it samples a backdrop).
For a plain panel/grouped surface that is NOT over scrolling content, the right iOS fix is often a
**system background color** — `Color(.systemBackground)`, `.secondarySystemBackground`, or the
`.systemGroupedBackground` family — not a material. READ to tell a backdrop-sampling surface (material)
from a flat grouped surface (system color). See `colors-semantic-and-assets.md`.

**This is advisory and READ-gated.** A `Color` background is correct for *content* surfaces (a card, a
chart plate, a deliberate solid panel). Only flag it when the surface is **chrome over content**. The
grep tell over-locates every `.background(Color…)`; confirm the role in READ.

## The Material-vs-Glass boundary (cross_ref: liquid-glass)

iOS 26 adds **Liquid Glass** (`glassEffect`, `.glass`/`.glassProminent` button styles,
`GlassEffectContainer`). Stay in lane:

- A **plain `Material`** that is the right fill for a non-glass surface → stays **here** (ac-06).
- A surface that should be a **glass** navigation layer (floating toolbar, glass control cluster), or any
  `glassEffect`/glass-button question → route to **`audit-swiftui-liquid-glass`**; emit
  `cross_ref: liquid-glass` and do not audit glass placement here.
- A `Material` used as the **pre-26 fallback** for a gated glass call (iOS 26 floor) is the liquid-glass
  skill's concern, not this one.

Seam authority: `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` (appearance-color ↔
liquid-glass: "materials, Dark-Mode contrast").

## Vibrancy note (UIKit bridge out of scope)

`Material` *is* the SwiftUI vibrancy surface. A reach for UIKit `UIVisualEffectView` (a `UIBlurEffect`
wrapped in a `UIViewRepresentable`) to get vibrancy is **out of scope** — note it in one line and point to
`audit-swiftui-uikit-overuse` (whether to bridge — a `Material` usually replaces it) /
`audit-swiftui-uikit-interop` (how, when the bridge is justified). Do not audit the `UIViewRepresentable`
here. Emit `cross_ref: uikit-overuse`.

---

## Sources

- Sosumi (fetched via `https://sosumi.ai/...`, access 2026-06-16): `documentation/swiftui/material`,
  `documentation/swiftui/shapestyle/ultrathinmaterial`, `documentation/swiftui/view/background(_:in:fillstyle:)`.
- Apple HIG — Materials (iOS): `developer.apple.com/design/human-interface-guidelines/materials`.
- Corpus consensus/recommended examples via `swiftui-ctx lookup Material --platform ios` /
  `lookup regularMaterial --platform ios` / `valueBuilders`, accessed 2026-06-16.
