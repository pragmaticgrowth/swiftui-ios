# Liquid Glass design language (iOS 26 — shared design truth)

**Verified: 2026-06-16** against HIG Materials/Layout, Technology Overviews (Liquid Glass + Adopting Liquid Glass), and WWDC25 sessions 219 (Meet Liquid Glass), 356 (Get to know the new design system), 323 (Build a SwiftUI app with the new design), 284 (Build a UIKit app with the new design).

**Scope:** this is the *design language* (the rules), not the API surface. API names (`glassEffect`, `GlassEffectContainer`, `glassEffectID`, `ToolbarSpacer`, `scrollEdgeEffectStyle`, `UIDesignRequiresCompatibility`) appear **only** where they make a design rule concretely checkable. The *how-to-build-it-correctly* API audit lives in `skills/audit-swiftui-liquid-glass/` — this file complements it (the WHETHER/design layer), it does not replace it. Cite-don't-assert: every rule carries its Apple source. Liquid Glass is gated **iOS 26** (references/_shared/floors-master.md, references/_shared/ios-gating.md). Cross-refs: references/_shared/hig-design-rubric.md (materials/color), references/_shared/ux-smell-catalog.md, references/_shared/cross-ref-graph.md.

---

## Core principle

- Treat Liquid Glass as a distinct functional/navigation layer that **floats above the content layer** — never as content itself. It establishes hierarchy between functional elements and content. https://developer.apple.com/design/human-interface-guidelines/materials
- It must stay visually clear and **defer to the content underneath**, never stealing focus. https://developer.apple.com/videos/play/wwdc2025/219/
- Glass separates by **lensing** (bending/concentrating light) rather than scattering/filling — content shines through beneath it. https://developer.apple.com/videos/play/wwdc2025/219/
- Express hierarchy through layout + grouping, not decoration (backgrounds/borders) — with the new system appearance such customizations are unnecessary. https://developer.apple.com/videos/play/wwdc2025/356/

## Where glass belongs

- Reserve glass for the **navigation layer**: tab bars, sidebars, toolbars, navigation bars, and floating controls/accessories. https://developer.apple.com/videos/play/wwdc2025/219/
- **Do NOT use glass in the content layer** (tables/lists/backgrounds/large fills) — it creates unnecessary complexity and a confusing hierarchy. https://developer.apple.com/design/human-interface-guidelines/materials
- Use standard materials (ultraThin/thin/regular/thick), not glass, for app backgrounds and content surfaces. https://developer.apple.com/design/human-interface-guidelines/materials
- Apply glass **sparingly** — limit it to the most important functional elements; apply the material directly to the control, not its inner views. https://developer.apple.com/videos/play/wwdc2025/284/
- Tab-bar accessory views are for persistent, app-wide features only (e.g. media playback) — screen-specific actions belong with their content, not in the navigation layer. https://developer.apple.com/videos/play/wwdc2025/356/

## Concentricity & containers

- Nested shapes (controls, sheets, popovers) must be **concentric** with their container — share a common corner center. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- Use the correct corner shape (fixed / capsule / concentric); wrong types pinch or flare corners and break balance. Prefer a concentric shape that computes inner radii automatically; **don't hardcode corner radii**. https://developer.apple.com/videos/play/wwdc2025/356/
- Group multiple custom glass elements inside a single `GlassEffectContainer` — **glass cannot sample other glass**, so separate containers produce inconsistent refraction. https://developer.apple.com/videos/play/wwdc2025/323/
- Group bar/toolbar items by function and frequency, separated by explicit spacers; don't group a symbol button with a text button (reads as one control); use standard spacing and don't overcrowd. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass

## Morphing

- Glass should **morph/flow** between states rather than hard-cut, staying on a singular floating plane. https://developer.apple.com/videos/play/wwdc2025/219/
- Control interactions morph (slider/toggle knobs become glass during interaction; buttons morph into menus/popovers from the tap point); menus/action sheets spring from their source element, not always the screen bottom. https://developer.apple.com/videos/play/wwdc2025/356/
- Animate glass via **materialize/dematerialize** (effect on/off), **not** by animating `alpha`/opacity. https://developer.apple.com/videos/play/wwdc2025/284/
- As glass grows (button → menu), it reads as thicker (deeper shadow, more lensing); use a shared identity (`glassEffectID` + namespace within a `GlassEffectContainer`) for fluid absorb/emit transitions. https://developer.apple.com/videos/play/wwdc2025/323/

## Tinting

- Tint glass **only to emphasize a primary element/action** (one call-to-action), never decoratively. https://developer.apple.com/videos/play/wwdc2025/219/
- Don't tint all/most glass — when everything is tinted, nothing stands out; if you want color, put it in the content layer. https://developer.apple.com/videos/play/wwdc2025/219/
- A tint should produce a brightness-mapped range of tones (like real colored glass), not a flat overlay; use system colors, or a custom color with light+dark+increased-contrast variants. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- Use system vibrant colors for text/symbols over glass; don't choose a material for the apparent color it imparts. https://developer.apple.com/design/human-interface-guidelines/materials

## Legibility & accessibility

- Keep clear separation between glass controls and content — controls sit on the glass/material surface, not directly on content. https://developer.apple.com/videos/play/wwdc2025/356/
- Don't fight the automatic scroll-edge effect under bars/floating controls; apply exactly one per view, don't stack/mix styles — it is functional, not decorative. https://developer.apple.com/videos/play/wwdc2025/356/
- Glass must respond to **Reduce Transparency** (frostier), **Increase Contrast** (mostly black/white + border), and **Reduce Motion** (less intensity, no elastic) — free with the standard material; **custom glass must preserve these**. https://developer.apple.com/videos/play/wwdc2025/219/
- Symbols/glyphs on glass flip light/dark with the glass for contrast; clear glass over bright media needs a dimming layer (~35%). https://developer.apple.com/design/human-interface-guidelines/materials
- Test custom elements/colors/animations across transparency, contrast, motion, appearance, and Dynamic Type. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass

## Light/dark & adaptivity

- Don't hardcode the appearance of small glass elements (nav/tab bars) — they continuously adapt and flip light↔dark based on what's behind them. https://developer.apple.com/videos/play/wwdc2025/219/
- Large glass elements (menus, sidebars) adapt to context but must **NOT** flip light↔dark (flipping a large surface is distracting). https://developer.apple.com/videos/play/wwdc2025/219/
- Use the right variant: **Regular** (fully adaptive, default, self-legible — text-heavy alerts/sidebars/popovers) vs. **Clear** (permanently transparent, only over bold/bright media + a dimming layer); never mix variants in one element. https://developer.apple.com/design/human-interface-guidelines/materials
- Don't hardcode control/bar sizes or set custom bar/sheet/popover backgrounds (`UIBarAppearance`/`backgroundColor`/`presentationBackground`) — bars are transparent by default; custom backgrounds fight the material + scroll-edge effect. https://developer.apple.com/videos/play/wwdc2025/284/
- Extend content edge-to-edge so it flows behind the floating glass; use a background-extension effect where content doesn't span full width. https://developer.apple.com/design/human-interface-guidelines/layout

## Anti-patterns (design smells to flag)

- **Glass on glass** — stacking/overlapping glass surfaces. Always avoid; use fills/vibrancy on the top element. https://developer.apple.com/videos/play/wwdc2025/219/
- **Glass in the content layer** — glass on a table/list/background/large fill. https://developer.apple.com/design/human-interface-guidelines/materials
- **Too many glass surfaces** — glass beyond the most important functional elements. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- **Over-tinting** — every/most elements tinted, or tint used decoratively. https://developer.apple.com/videos/play/wwdc2025/219/
- **Ungated/separate glass containers** — multiple custom glass elements not in one `GlassEffectContainer`. https://developer.apple.com/videos/play/wwdc2025/323/
- **Hardcoded corner radii / non-concentric corners**; **hardcoded control/bar sizes & overridden spacing**. https://developer.apple.com/videos/play/wwdc2025/356/
- **Custom bar/sheet/popover backgrounds or darkening behind bar items**; **fading glass with alpha** instead of materialize/dematerialize. https://developer.apple.com/videos/play/wwdc2025/284/
- **Symbol+text grouped as one control; screen-specific actions in the tab/accessory layer; decorative or stacked scroll-edge effects.** https://developer.apple.com/videos/play/wwdc2025/356/

## Adoption

- Adopt by rebuilding with the latest Xcode and letting **standard system components** pick up glass automatically — don't reinvent the app. https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass
- Good adoption = **removing** custom chrome (bar/sheet/popover backgrounds, borders, darkening), not adding glass everywhere; net deletions are a positive signal. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- A half-migrated app shows the smells: legacy opaque bars mixed with glass, leftover custom backgrounds fighting the material, hardcoded radii/sizes, glass on content, over-tinting. https://developer.apple.com/videos/play/wwdc2025/356/
- `UIDesignRequiresCompatibility` (Info.plist) intentionally **opts OUT** of the new design while building on new SDKs — flag it as deliberate non-adoption, not a fix. https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
