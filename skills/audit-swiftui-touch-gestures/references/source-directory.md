# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
touch/gesture claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the touch/gesture-specific
*map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the practice layer (consensus + permalinks)
is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi + swiftui-ctx references)

1. **Does it exist / its iOS floor?** Fetch `https://sosumi.ai/documentation/swiftui/<symbol-path>` and
   read the `**Available on:** … iOS N+ …` line. If **iOS is ABSENT** from the array the symbol is
   platform-wrong on iOS (tg-08, e.g. `pointerStyle`) — not under-gated.
2. **Is it deprecated in practice?** `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx deprecated <api>` →
   `deprecated`/`migrate_to` (tg-01/02). A `lookup --platform ios` **exit 3** corroborates a
   platform-wrong symbol.
3. **What's the canonical shape?** `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform
   ios --json` → `consensus` + `recommended` permalink; `file <recommended.id> --smart` for the real
   enclosing body.
4. Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.

---

## A. SwiftUI touch/gesture symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors
per floors-master (re-confirmed 2026-06-16).

| Symbol | Path | iOS floor |
|---|---|---|
| `onTapGesture(count:perform:)` | `view/ontapgesture(count:perform:)` | 13.0+ |
| `onLongPressGesture(...)` | `view/onlongpressgesture(minimumduration:maximumdistance:perform:onpressingchanged:)` | 13.0+ |
| `DragGesture` | `draggesture` | 13.0+ |
| `MagnifyGesture` | `magnifygesture` | 17.0+ (at the floor → no gate) |
| `RotateGesture` | `rotategesture` | 17.0+ (at the floor → no gate) |
| `SpatialTapGesture` | `spatialtapgesture` | 16.0+ |
| `@GestureState` | `gesturestate` | n/a (wrapper) |
| `.simultaneousGesture(_:)` / `.highPriorityGesture(_:)` | `view/simultaneousgesture(_:including:)` · `view/highprioritygesture(_:including:)` | 13.0+ |
| `SimultaneousGesture` / `ExclusiveGesture` / `.sequenced(before:)` | `simultaneousgesture` · `exclusivegesture` · `gesture/sequenced(before:)` | 13.0+ |
| `.contextMenu(menuItems:)` | `view/contextmenu(menuitems:)` | 13.0+ (touch-and-hold) |
| `.swipeActions(edge:allowsFullSwipe:content:)` | `view/swipeactions(edge:allowsfullswipe:content:)` | 15.0+ |
| `.refreshable(action:)` | `view/refreshable(action:)` | 15.0+ (pull-to-refresh) |
| `.accessibilityAction(_:_:)` | `view/accessibilityaction(_:_:)` | 13.0+ |
| `onHover(perform:)` | `view/onhover(perform:)` | 13.4+ (iPad-pointer-only) |
| `onContinuousHover(coordinateSpace:perform:)` | `view/oncontinuoushover(coordinatespace:perform:)` | 16.0+ (iPad-pointer-only) |
| `pointerStyle(_:)` / `PointerStyle` | `view/pointerstyle(_:)` · `pointerstyle` | **no iOS arm** (macOS/visionOS only) |

**Platform-wrong on iOS (never emit on an iOS target):** `pointerStyle(_:)` / `PointerStyle` (no iOS arm).
**Real-but-deprecated:** `MagnificationGesture` (→ `MagnifyGesture`), `RotationGesture` (→ `RotateGesture`).

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Gestures | `design/human-interface-guidelines/gestures` (verify exact path) | iOS gesture vocabulary; tap/long-press/swipe/pinch; touch-and-hold |
| HIG — Touchscreen gestures | `design/human-interface-guidelines/touchscreen-gestures` (verify exact path) | standard touch interactions; minimum touch-target size |
| Adding interactivity with gestures | `documentation/swiftui/adding-interactivity-with-gestures` | `@GestureState`/`.updating`; composing gestures (simultaneous/exclusive/sequenced) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| Session | Covers |
|---|---|
| WWDC — "What's new in SwiftUI" (per year) | gesture API renames (`MagnifyGesture`/`RotateGesture`), `.swipeActions`, `.refreshable` |
| WWDC — accessibility sessions | making custom gestures reachable (`.accessibilityAction`) |

> WWDC ids drift year to year — resolve the exact id via the session index before citing; treat the video
> as corroboration, the doc page (via Sosumi) as the spec.

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | Reliable for | Trust |
|---|---|---|
| Hacking with Swift — SwiftUI gesture tutorials | tap/long-press/drag/magnify patterns on iOS | medium |
| swiftui-ctx corpus (`lookup --platform ios` / `deprecated` / `file --smart`) | real consensus shapes + permalinked iOS examples (the PRACTICE half) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- swiftui-ctx CLI contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16); floors cross-checked
  against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.
- Practitioner sources as listed (trust labelled; corroboration only).
