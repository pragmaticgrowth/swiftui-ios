# Shared Reference — Hallucination Blacklist (nonexistent APIs → real replacements)

The canonical list of invented/nonexistent or platform-wrong API names that AI models emit as
plausible-looking SwiftUI, each with the **real** iOS/cross-platform replacement. A match on any blacklisted
name is **always a hard-fail** (it will not compile or is a silent no-op). This is shared *data*:
`api-currency` owns authoring it, the pre-ship gate's hallucination sweep reads it, and
`liquid-glass`, `charts`, `touch-gestures` consume the relevant rows. Do not restate this list
inside a skill's own `references/`.

To confirm a symbol's existence/availability before flagging, fetch the Apple page via
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`. Floors for the *real* replacements
live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (iOS `introduced_ios`).

**As of:** 2026-06-16 · iOS 18 / iOS 26 · Xcode 26 SDK · deployment floor iOS 17.

---

## 1. Liquid Glass — invented modifiers & types

| Hallucinated / wrong | Why it's wrong | Real replacement |
|---|---|---|
| `.glassBackground()` | Does not exist. | `.glassEffect(_:in:)` (iOS 26.0+) |
| `.liquidGlass()` | Does not exist — marketing name, not an API. | `.glassEffect(_:in:)` (iOS 26.0+) |
| `LiquidGlassView` | No such view type. | `GlassEffectContainer { … }` (iOS 26.0+) |
| `.material(.glass)` | `Material` has no `.glass` case. | `.glassEffect(.regular, in:)` or `.background(.ultraThinMaterial)` for pre-26 fallback |
| `.glassEffect(.liquid)` | `Glass` has no `.liquid` static. | `Glass.regular` / `.clear` / `.identity` (iOS 26.0+) |
| `GlassContainer` | Wrong name. | `GlassEffectContainer` (iOS 26.0+) |
| `.buttonStyle(.liquidGlass)` | No such style. | `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` (iOS 26.0+) |
| `.glassBackgroundEffect()` on an iOS path | Real symbol, but **visionOS-only — iOS ABSENT** (not in the iOS corpus). | `.glassEffect(_:in:)` on iOS 26.0+ |

> **`.interactive()` is real on iOS.** `Glass.interactive(_:)` IS available on iOS 26.0+. Do not flag
> it as a hallucination; flag a *wrong-arm gate* if it is gated on `#available(macOS 26, *)` in an
> iOS path (see `ios-gating.md`).

---

## 2. Focus / document — phantom property wrappers

| Hallucinated / wrong | Why it's wrong | Real replacement |
|---|---|---|
| `@FocusedDocument` | **Not a real Apple symbol.** | A custom `FocusedValues` key: `@Entry var focusedDocument: …` (on `FocusedValues`) + `@FocusedValue(\.focusedDocument)`. |
| `@FocusedBinding` used as a wrapper that does not exist | (`@FocusedBinding` *does* exist — iOS 14.0+) — verify the key exists before flagging. | confirm via Sosumi; real keys come from `FocusedValueKey` / `@Entry` on `FocusedValues`. |

---

## 3. Pointer / gesture — stale or invented case names

> **iPad-pointer caveat.** `PointerStyle` / `.pointerStyle(_:)` / `.onHover` are **not in the iOS
> SwiftUI corpus as primary APIs** — they are iPad-with-trackpad-pointer affordances only, never a
> touch primitive. The `.grabbing` entries below stay blacklisted (the *case names* are invented
> regardless of platform), but on an iPhone-only target a `pointerStyle`/`onHover` call is an
> idiom smell, routed to `touch-gestures` / `ios-idiomaticness`, **not** a hallucination.

| Hallucinated / wrong | Why it's wrong | Real replacement |
|---|---|---|
| `PointerStyle.grabbing` | Stale/invented case name (and pointer APIs are iPad-only on iOS). | `PointerStyle.grabActive` / `.grabIdle` — pointer-only; prefer a touch gesture on iPhone. |
| `pointerStyle(.grabbing)` | Same — no `.grabbing` case. | `.pointerStyle(.grabActive)` — pointer-only; prefer a touch gesture on iPhone. |
| `MagnificationGesture` as the *current* API | Real (iOS 13.0+) but **deprecated** (26.5). | `MagnifyGesture` (iOS 17.0+) |
| `RotationGesture` as the *current* API | Real (iOS 13.0+) but **deprecated** (26.5). | `RotateGesture` (iOS 17.0+) |

---

## 4. Charts — invented mark/plot names

| Hallucinated / wrong | Why it's wrong | Real replacement |
|---|---|---|
| `PieMark` | No such mark — pie/donut is built from sectors. | `SectorMark` (iOS 17.0+) |
| `DonutMark` | No such mark. | `SectorMark` with `innerRadius:` (iOS 17.0+) |
| `ScatterMark` | No such mark. | `PointMark` (iOS 16.0+) |
| `ColumnMark` | No such mark. | `BarMark` (iOS 16.0+) |

---

## 5. Toolbar / navigation / bridge — platform-wrong placements

| Hallucinated / wrong | Why it's wrong | Real replacement |
|---|---|---|
| `ToolbarItemPlacement.navigationBarLeading` as the *current* spelling | Real but deprecated; the modern iOS spelling differs. | `.topBarLeading` / `.topBarTrailing` (iOS 14.0+) — these are **CORRECT on iOS**, do not flag them. |
| `ToolbarItemPlacement.principal` misused for a leading button | Wrong slot — `.principal` is the title center. | `.topBarLeading` / `.topBarTrailing` / `.bottomBar` (iOS 14.0+) |
| `NSViewRepresentable` in an iOS target | **iOS ABSENT — AppKit bridge, not the UIKit one.** Out-of-scope of the iOS SwiftUI corpus. | **`UIViewRepresentable`** (iOS 13.0+) — use `UIViewRepresentable` / `UIViewControllerRepresentable` on iOS. |
| `NSHostingController` / `NSHostingView` in an iOS target | AppKit hosting types — **iOS ABSENT.** | `UIHostingController` (iOS 13.0+) |
| `.navigationBarTitleDisplayMode(...)` flagged as macOS-wrong | It is **valid on iOS** (iOS 14.0+) — only ABSENT on macOS. | keep it on iOS; do not flag. (On a macOS path it would have no arm — but this is an iOS toolkit.) |

> **iOS inversion.** The macOS edition flagged `.topBarLeading` / `.topBarTrailing` and
> `.navigationBarTitleDisplayMode` as platform-wrong (macOS ABSENT). On iOS the polarity flips:
> these are the **native, correct** spellings. The hallucination here is reaching for the *AppKit*
> bridge (`NSViewRepresentable`, `NSHostingController`) inside an iOS target.

---

## How to use this list

1. **Sweep, case-sensitive.** A literal match on a left-column name is a finding.
2. **Always hard-fail.** Hallucinated APIs do not compile or silently no-op; severity is
   `hard-fail` with `fix_mode: auto` only when the replacement is a mechanical 1:1 rename.
3. **Verify before flagging a near-miss.** If a name *looks* invented but might be a real new
   symbol, confirm via Sosumi (`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`) or
   `swiftui-ctx lookup <api> --platform ios --json` before emitting — never assert nonexistence
   from memory. `exit 3` / `ok:false` from `swiftui-ctx` means not-in-corpus (likely no iOS arm).
4. **Pointer/hover rows are conditional.** Invented case names (`.grabbing`) hard-fail always; a
   *valid* `pointerStyle`/`onHover` on an iPhone-only target is an idiom smell, not a hallucination.

---

## Sources

- `developer.apple.com` SwiftUI / Charts symbol pages + JSON availability endpoints (access date
  **2026-06-07**), fetched via Sosumi — confirming the *real* replacement symbols exist and the
  blacklisted names do not.
- `swiftui-ctx lookup … --platform ios` against the iOS corpus (`sdk_catalog.json` `introduced_ios`)
  for every floor in this file (glass family 26.0; `MagnifyGesture`/`RotateGesture`/`SectorMark`
  17.0; `PointMark`/`BarMark` 16.0; `navigationBarTitleDisplayMode` 14.0; `UIViewRepresentable` 13.0;
  `NSViewRepresentable` reported out-of-scope `appkit_uikit`).
- WWDC25 Liquid Glass sessions (via Sosumi) for the glass API surface.
