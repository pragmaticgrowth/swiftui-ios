# Design-claims blacklist (shared design truth)

**Verified: 2026-06-16** against live HIG pages. The design analogue of [[hallucination-blacklist]]: widely-repeated "iOS design rules" that are **NOT in the current Apple HIG**. The reviewer (`audit-swiftui-design-review`) and the generator (`build-ios-swiftui`) must **never assert these as HIG**, and must not deduct Design Score for "violating" them. If a real concern is nearby, cite the *correct* fact + source from [[hig-design-rubric]] instead.

| ❌ Myth (do NOT assert as HIG) | ✅ Correct fact | Source |
|---|---|---|
| "iPhone tab bars must have **max 3–5 tabs**." | The HIG states only "**five or fewer**" for *user-customizable* tab sets, plus qualitative "fewer is easier." There is no hard 3–5 cap. Avoid overflow/More tabs because they hide content — that's the real rule. | https://developer.apple.com/design/human-interface-guidelines/tab-bars |
| "**Avoid pure black** backgrounds in Dark Mode." | Not stated on the HIG Dark Mode/Color pages for iOS. Use semantic colors and base-vs-elevated backgrounds; don't invent a pure-black prohibition. | https://developer.apple.com/design/human-interface-guidelines/dark-mode |
| "Body text should be **45–75 characters per line**." | No characters-per-line figure is stated in the HIG. It's typographic convention, not an Apple rule — don't cite HIG for it. | https://developer.apple.com/design/human-interface-guidelines/typography |
| "Standard animation is **0.3 s** / use easing curve X." | Apple publishes **no** numeric iOS animation duration or named easing curve. Judge motion qualitatively (purposeful, brief, gesture-following, Reduce-Motion-safe). | https://developer.apple.com/design/human-interface-guidelines/motion |
| "**Large titles only at the root** of a hierarchy." | Not stated. Large titles transition to inline on scroll; the HIG doesn't restrict them to root screens. | https://developer.apple.com/design/human-interface-guidelines/navigation-bars |
| "Use the **'chrome' material**." | There is no "chrome" material. iOS materials are **ultraThin / thin / regular (default) / thick**. Liquid Glass is a separate effect, not a material name. | https://developer.apple.com/design/human-interface-guidelines/materials |
| "The HIG mandates **16 pt side margins / an 8 pt spacing grid**." | These are **UIKit/SwiftUI API defaults** (`directionalLayoutMargins`, `readableContentGuide`) and a common design system, **not** the HIG Layout page. Use as a heuristic; attribute to the API, never to HIG. | https://developer.apple.com/design/human-interface-guidelines/layout |
| "Reduce Transparency has a dedicated HIG opaque-alternative rule." | Not a standalone HIG bullet; it's covered indirectly via system colors + Increase Contrast + the Liquid Glass adaptivity rules ([[liquid-glass-design]]). | https://developer.apple.com/design/human-interface-guidelines/accessibility |

**Posture:** when tempted to assert a number, check it's in [[hig-design-rubric]] with a URL. If it isn't there and isn't here as a corrected fact, do not assert it — flag the concern qualitatively and cite the nearest real rule.
