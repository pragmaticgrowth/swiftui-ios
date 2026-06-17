# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence haptics
claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI commands and the
JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the
haptics-specific *map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the practice layer (consensus + permalinks) is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi + swiftui-ctx references)

1. **Does it exist / its iOS floor?** For a SwiftUI symbol (`sensoryFeedback`, `SensoryFeedback`) fetch
   `https://sosumi.ai/documentation/swiftui/<path>` and read the `**Available on:** … iOS N+ …` line; cross
   it against `swiftui-ctx lookup sensoryFeedback --platform ios` (`introduced_ios`). For a **UIKit**
   generator / **Core Haptics** type, swiftui-ctx returns `introduced_ios: null` (outside the SwiftUI
   corpus) — fetch the UIKit / Core Haptics doc page instead and cite the well-known floor with
   `verify against Xcode 26 SDK`.
2. **What's the canonical shape?** `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup sensoryFeedback
   --platform ios --json` → `consensus` + `recommended` permalink; `examples sensoryFeedback` for more real
   call sites; `file <recommended.id> --smart` for the enclosing body.
3. Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.

---

## A. SwiftUI haptics symbol map (in the corpus — floor confirmable)

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`).

| Symbol | Path | iOS floor |
|---|---|---|
| `.sensoryFeedback(_:trigger:)` | `view/sensoryfeedback(_:trigger:)` | 17.0+ (at the floor → no gate) |
| `.sensoryFeedback(_:trigger:condition:)` | `view/sensoryfeedback(_:trigger:condition:)` | 17.0+ |
| `.sensoryFeedback(trigger:_:)` (computed flavour) | `view/sensoryfeedback(trigger:_:)` | 17.0+ |
| `SensoryFeedback` (the enum: `.impact`/`.success`/`.warning`/`.error`/`.selection`/…) | `sensoryfeedback` | 17.0+ |

## B. UIKit / Core Haptics symbol map (NOT in the SwiftUI corpus — `verify against Xcode 26 SDK`)

Human doc path = `developer.apple.com/documentation/uikit/<path>` (generators) or
`developer.apple.com/documentation/corehaptics/<path>` (fetch via `sosumi.ai/...`). swiftui-ctx returns
`introduced_ios: null` for all of these — cite the well-known floor, mark `verify against Xcode 26 SDK`.

| Symbol | Path | iOS floor (well-known) |
|---|---|---|
| `UIImpactFeedbackGenerator` + `.impactOccurred()` / `.prepare()` | `uikit/uiimpactfeedbackgenerator` | 10.0+ |
| `UINotificationFeedbackGenerator` + `.notificationOccurred(_:)` | `uikit/uinotificationfeedbackgenerator` | 10.0+ |
| `UISelectionFeedbackGenerator` + `.selectionChanged()` | `uikit/uiselectionfeedbackgenerator` | 10.0+ |
| `UIFeedbackGenerator` (the base class; `.prepare()`) | `uikit/uifeedbackgenerator` | 10.0+ |
| `CHHapticEngine` (advanced custom patterns) | `corehaptics/chhapticengine` | 13.0+ |

## C. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Playing haptics | `design/human-interface-guidelines/playing-haptics` (verify exact path) | when haptics are appropriate; don't overuse; respect the system |
| Sensory feedback in SwiftUI | `documentation/swiftui/sensoryfeedback` | the declarative idiom; trigger + condition |

## D. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| Session | Covers |
|---|---|
| WWDC23 — "What's new in SwiftUI" | introduces `.sensoryFeedback(_:trigger:)` (iOS 17) |
| WWDC — Core Haptics / "Practice audio haptic design" | `CHHapticEngine`, custom patterns (advanced) |

> WWDC ids drift year to year — resolve the exact id via the session index before citing; treat the video
> as corroboration, the doc page (via Sosumi) as the spec.

## E. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | Reliable for | Trust |
|---|---|---|
| Hacking with Swift — `sensoryFeedback` / haptics tutorials | the iOS-17 modifier + UIKit generator patterns | medium |
| swiftui-ctx corpus (`lookup sensoryFeedback --platform ios` / `examples` / `file --smart`) | real consensus shapes + permalinked iOS examples (the PRACTICE half) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- swiftui-ctx CLI contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- SwiftUI paths fetched via `https://sosumi.ai/...` (access 2026-06-16); `sensoryFeedback` floor (iOS 17.0)
  cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. UIKit generator (iOS
  10.0+) and `CHHapticEngine` (iOS 13.0+) floors are well-known introductions outside the SwiftUI corpus —
  `verify against Xcode 26 SDK`.
</content>
