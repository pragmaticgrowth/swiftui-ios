# HIG design rubric (shared design truth)

**Verified: 2026-06-16** against live `developer.apple.com/design/human-interface-guidelines` pages (iOS 26 / Liquid Glass HIG).

**Grounding rule (same discipline as `floors-master.md`):** every quantified design rule below cites the Apple page it came from. **Never assert a design number from memory.** When a widely-repeated number is *not* in the HIG (it comes from a UIKit/SwiftUI API default, or is a community myth), it is marked `(API default, NOT HIG)` or routed to references/_shared/design-claims-blacklist.md — do not attach a HIG URL to it. Design rules cite HIG; API shapes/floors cite `swiftui-ctx`; Apple-doc API prose cites Sosumi — never crossed.

This rubric is the checkable backbone of references/_shared/design-finding-schema.md; the reviewer (references/_shared/ux-smell-catalog.md for the qualitative layer, this file for the measurable layer) scores each category 0–100 against it. Liquid Glass design rules live in references/_shared/liquid-glass-design.md.

---

## Layout & spacing

- Respect safe areas, system margins, and layout guides — keeps layout adaptable across rotation/resize and avoids system features. https://developer.apple.com/design/human-interface-guidelines/layout
- Inset buttons/controls from screen edges; avoid full-width buttons on iOS — buttons feel native when they respect system margins and align with hardware curvature. https://developer.apple.com/design/human-interface-guidelines/layout
- Extend backgrounds/scroll content edge-to-edge; let bars and sidebars float over content (the content layer flows behind the Liquid Glass chrome). https://developer.apple.com/design/human-interface-guidelines/layout
- Align components with one another — makes screens scannable and communicates hierarchy. https://developer.apple.com/design/human-interface-guidelines/layout
- Place the most important items top + leading; group related items with negative space/separators; account for RTL. https://developer.apple.com/design/human-interface-guidelines/layout
- Don't crowd controls; give essential information room — crowded/unrelated controls are hard to tell apart and tap. https://developer.apple.com/design/human-interface-guidelines/layout
- On iPad, design full-screen first and test halves/thirds/quadrants window sizes; defer compact layout until content no longer fits. https://developer.apple.com/design/human-interface-guidelines/layout
- "16 pt side margins / 8 pt spacing grid / readable content width / 45–75 chars per line" — `(API default, NOT HIG)`: these come from UIKit/SwiftUI (`directionalLayoutMargins`, `readableContentGuide`) or typographic convention, not the HIG Layout page. Use as a heuristic; attribute to the API, never to HIG. See references/_shared/design-claims-blacklist.md.

## Typography

Built-in iOS/iPadOS text styles at the default (Large) content size — **all stated on the HIG Typography page** (https://developer.apple.com/design/human-interface-guidelines/typography):

| Style | Weight | Size pt | Leading pt |
|---|---|---|---|
| Large Title | Regular | 34 | 41 |
| Title 1 | Regular | 28 | 34 |
| Title 2 | Regular | 22 | 28 |
| Title 3 | Regular | 20 | 25 |
| Headline | Semibold | 17 | 22 |
| Body | Regular | 17 | 22 |
| Callout | Regular | 16 | 21 |
| Subhead | Regular | 15 | 20 |
| Footnote | Regular | 13 | 18 |
| Caption 1 | Regular | 12 | 16 |
| Caption 2 | Regular | 11 | 13 |

- Use built-in text styles instead of hardcoded sizes — they give consistent hierarchy AND auto-support Dynamic Type + accessibility sizes. https://developer.apple.com/design/human-interface-guidelines/typography
- Honor per-platform default/minimum sizes — iOS/iPadOS default **17 pt**, minimum **11 pt**. https://developer.apple.com/design/human-interface-guidelines/typography
- Avoid Light/Ultralight/Thin weights (prefer Regular/Medium/Semibold/Bold); thin weights only at larger sizes — thin weights are hard to read, especially small. https://developer.apple.com/design/human-interface-guidelines/typography
- Convey hierarchy with weight/size/color; minimize the number of typefaces. https://developer.apple.com/design/human-interface-guidelines/typography
- Avoid tight leading for passages of 3+ lines; don't hardcode tracking (the system font auto-adjusts tracking per point size). https://developer.apple.com/design/human-interface-guidelines/typography
- Custom fonts must implement Dynamic Type + Bold Text (system fonts do this automatically). https://developer.apple.com/design/human-interface-guidelines/typography

## Color & contrast

- Minimum text contrast: **4.5:1** for text up to 17 pt; **3:1** at 18 pt or for bold text (WCAG AA; what Accessibility Inspector uses). https://developer.apple.com/design/human-interface-guidelines/accessibility
- For custom foreground/background colors aim for **7:1** (especially small text); never below 4.5:1. https://developer.apple.com/design/human-interface-guidelines/dark-mode
- Prefer system/semantic colors over custom; don't hardcode system color values — they auto-adapt to light/dark, vibrancy, and accessibility settings, and their values change between releases. https://developer.apple.com/design/human-interface-guidelines/color
- Don't rely on color alone to convey meaning, state, or interactivity — add text/glyph/shape. https://developer.apple.com/design/human-interface-guidelines/color
- Don't reuse one color for different meanings or repurpose semantic colors (e.g. separator color as text). https://developer.apple.com/design/human-interface-guidelines/color
- Custom colors must ship light + dark + increased-contrast variants (supports Increase Contrast and Liquid Glass adaptivity). https://developer.apple.com/design/human-interface-guidelines/color
- Dark Mode: use semantic colors (they adapt, not just invert); use base vs. elevated backgrounds for depth; soften white image fields so they don't glow; test both appearances; don't add an in-app appearance toggle. https://developer.apple.com/design/human-interface-guidelines/dark-mode
- Materials (ultraThin/thin/regular(default)/thick): use vibrant system label colors on top of any material; avoid lowest-vibrancy (quaternary) on the two thinnest materials. There is no "chrome" material — see references/_shared/design-claims-blacklist.md. https://developer.apple.com/design/human-interface-guidelines/materials
- "Avoid pure black backgrounds in Dark Mode" — `(NOT HIG)`, see references/_shared/design-claims-blacklist.md.

## Hit targets & controls

- Minimum tappable hit region **44×44 pt** (absolute floor 28×28 pt). https://developer.apple.com/design/human-interface-guidelines/buttons
- Spacing between targets: ~**12 pt** padding around bezeled elements, ~**24 pt** around the visible edges of borderless elements. https://developer.apple.com/design/human-interface-guidelines/accessibility
- Use *style*, not size, to distinguish the preferred button; keep prominent buttons to 1–2 per view. https://developer.apple.com/design/human-interface-guidelines/buttons
- Custom buttons must have a visible pressed state. https://developer.apple.com/design/human-interface-guidelines/buttons
- Don't assign the primary/default role to a destructive action. https://developer.apple.com/design/human-interface-guidelines/buttons
- Use a switch only in a list row (elsewhere use a toggling button); use standard controls for their intended jobs (segmented = mutually exclusive, slider/stepper = ranges). https://developer.apple.com/design/human-interface-guidelines/toggles

## SF Symbols

- Prefer SF Symbols over custom glyphs; map standard actions to standard symbols (Share `square.and.arrow.up`, Delete `trash`, Search `magnifyingglass`, Add `plus`, More `ellipsis`). https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- Match symbol weight and scale to adjacent text (9 weights, 3 scales relative to cap height). https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- Pick one rendering mode (monochrome / hierarchical / palette / multicolor) per context; use system colors so symbols adapt to Dark Mode, vibrancy, accessibility. https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- Interface icons in one app share size, detail, stroke weight, and perspective. https://developer.apple.com/design/human-interface-guidelines/icons

## Navigation & structure

- Tab bar = flat, peer top-level sections; keep it persistent/visible; navigation, not actions; each tab needs an icon + short label. For user-customizable tab sets aim for "five or fewer." (The "max 3–5 tabs" rule is NOT in the current HIG — see references/_shared/design-claims-blacklist.md.) https://developer.apple.com/design/human-interface-guidelines/tab-bars
- Navigation bar / stack = hierarchical drill-down; use the standard symbol-only Back/Close (don't relabel); concise title **under 15 characters**; don't use the app name as the title; don't crowd the bar. https://developer.apple.com/design/human-interface-guidelines/navigation-bars
- Sidebar = complex hierarchy on larger displays; show **no more than 2 levels** (deeper → split view); prefer a tab bar when space is tight; adapt tab bar ↔ sidebar by size class. https://developer.apple.com/design/human-interface-guidelines/sidebars
- Modality only with clear benefit; keep modal tasks short; always give an obvious dismiss; don't nest deep hierarchies in a modal; **never show more than one alert at once**. https://developer.apple.com/design/human-interface-guidelines/modality
- Toolbar = actions on the current content (distinct from a tab bar); aim for **max 3 groups** and **exactly 1 primary action** on the trailing side; don't overload or hand-build overflow menus. https://developer.apple.com/design/human-interface-guidelines/toolbars

## Motion

- Add motion purposefully; avoid gratuitous/excessive animation and motion on frequent interactions (the system already animates standard elements). https://developer.apple.com/design/human-interface-guidelines/motion
- Keep feedback animations brief and precise; make them follow the triggering gesture; never make motion the only channel for important info; let people cancel/skip animations. https://developer.apple.com/design/human-interface-guidelines/motion
- Honor Reduce Motion: replace x/y/z transitions with cross-dissolve, tighten springs, avoid parallax/blur/z-axis animation. https://developer.apple.com/design/human-interface-guidelines/accessibility
- A specific numeric duration (e.g. "0.3 s") or named easing curve is **NOT published** by Apple for iOS — do not assert one. See references/_shared/design-claims-blacklist.md.

## Accessibility (visual)

- Contrast meets 4.5:1 (≤17 pt) / 3:1 (18 pt or bold) in BOTH light and dark; provide a higher-contrast scheme for Increase Contrast. https://developer.apple.com/design/human-interface-guidelines/accessibility
- Support enlarging text **≥200%** (AX1–AX5); layout must not clip/truncate at the largest accessibility sizes (iOS AX1 Body = 28 pt, Large Title = 44 pt). https://developer.apple.com/design/human-interface-guidelines/accessibility
- Every control and meaningful image has a descriptive VoiceOver label; decorative images are hidden; use unique titles/section headings. https://developer.apple.com/design/human-interface-guidelines/voiceover
- Don't rely on color alone — add shape/icon/text. https://developer.apple.com/design/human-interface-guidelines/accessibility
- Respect Reduce Transparency and Reduce Motion; offer onscreen alternatives to gestures; avoid auto-dismissing/time-boxed UI. https://developer.apple.com/design/human-interface-guidelines/accessibility

## States

- Never show a blank screen while loading — use placeholder text/graphics/skeletons and replace as content arrives. https://developer.apple.com/design/human-interface-guidelines/loading
- Launch screen nearly identical to the first screen; match orientation + light/dark; no text/logos/branding. https://developer.apple.com/design/human-interface-guidelines/launching
- Restore previous state on relaunch (scroll position, navigation). https://developer.apple.com/design/human-interface-guidelines/launching
- Prefer a determinate progress indicator when duration is known; keep it moving; offer Cancel; never switch circular↔bar mid-operation. https://developer.apple.com/design/human-interface-guidelines/progress-indicators
- Use alerts sparingly, only for essential and ideally actionable info; avoid alerts at launch. https://developer.apple.com/design/human-interface-guidelines/alerts
- Error/alert: clear jargon-free title (not "Error 329347"), title ≤ 2 lines; ≤ 3 buttons with 1–2-word verb titles; default on trailing/top, Cancel on leading/bottom; avoid bare "OK" except for purely informational alerts. https://developer.apple.com/design/human-interface-guidelines/alerts
- Make feedback multi-channel (color + text + sound + haptics) and surface status in context near the items it describes. https://developer.apple.com/design/human-interface-guidelines/feedback
