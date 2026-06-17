# Reference — iOS-ABSENT Symbols & Floor Quirks (gate-06 · gate-08)

Two ways a gate goes wrong that are *not* "wrong floor": a symbol that has no iOS arm at all (so it can
never be gated onto iPhone/iPad — it must be replaced), and a floor that the docs render misleadingly (so
the gate value you'd read is wrong). The canonical iOS-ABSENT / invented-name list is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read it, do not restate it here.

**As of:** 2026-06-16 · iOS 26 SDK.

---

## gate-06 — iOS-ABSENT symbol wrapped in an iOS gate (hard-fail; fix_mode: flag-only)

An `iOS ABSENT` symbol has no iOS arm in its availability string — it is a macOS-/visionOS-only name
(an AppKit type, a Mac menu-bar API, or a visionOS effect). Wrapping it in `#available(iOS …)` is doubly
wrong: the gate cannot summon a symbol the iOS SDK does not ship, and on an iOS target the call is a
compile error or a no-op. The fix is to **replace** it with the iOS equivalent — never to gate it. Per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` §4, if iOS is absent from the array the symbol
is *platform-wrong*, not under-gated. A `swiftui-ctx lookup <api> --platform ios` **exit 3** corroborates
the absence.

| iOS-ABSENT symbol | iOS equivalent |
|---|---|
| `.glassBackgroundEffect()` (visionOS) | `.glassEffect(_:in:)` (iOS 26.0+, gated) |
| `MenuBarExtra` (macOS menu bar) | no iOS analogue — use a `Menu` / toolbar item, or drop it on iOS |
| `WindowStyle.volumetric` (visionOS) | not applicable on iOS — remove; use the iOS scene/`WindowGroup` default |
| `NSViewRepresentable` / `NSViewControllerRepresentable` (AppKit) | `UIViewRepresentable` / `UIViewControllerRepresentable` (iOS 13.0+) |
| `NSHostingController` / `NSHostingView` (AppKit) | `UIHostingController` (iOS 13.0+) |
| `Settings { … }` scene (macOS) | no iOS analogue — present settings as a pushed/`sheet` SwiftUI view |

```swift
// ❌ gating a symbol that has no iOS arm — it will never resolve on iPhone/iPad
if #available(iOS 26.0, *) { editorView /* NSViewRepresentable */ }
// ✅ replace with the UIKit bridge (UIViewRepresentable is iOS 13.0+ — no gate needed)
struct EditorView: UIViewRepresentable { /* makeUIView / updateUIView */ }
```

flag-only: which equivalent fits is a design call. **Polarity inversion vs. a macOS audit:** on macOS the
ABSENT set is iOS-/visionOS-only names like `WheelPickerStyle`, `.topBarLeading`,
`navigationBarTitleDisplayMode`, `.bottomBar` — but **those are all valid on iOS** (introduced iOS 13–14),
so on iOS they are *never* gate-06; the iOS-ABSENT set is the AppKit/visionOS/Mac-only names instead.

---

## gate-08 — the DocC type-property floor quirk (advisory; fix_mode: flag-only)

A type-property's DocC page can render the **type's** availability, not the **property's** — so the floor
you'd copy into a gate is wrong. The headline case carried in floors-master: a property introduced later
than its enclosing type, or a static member whose page inherits the type's "first available" badge.
Always re-confirm a **type-property** floor against Sosumi (and `swiftui-ctx … --platform ios`, reading
`introduced_ios`) rather than trusting the page's top-of-page availability badge. Carry an unconfirmable
type-property floor as `advisory` with `source: verify against Xcode 26 SDK`.

There is no flat lint tell for gate-08 — it surfaces during the VERIFY floor cross-check whenever a
gate-01/gate-03 candidate is a type-property whose floor you cannot place from memory.

**Sosumi fetch caution (`.task`-family):** some doc paths — notably `.task(_:)` / `.task(id:_:)` and a
few modifier overload pages — return an SPA shell rather than rendered content on first fetch. Retry, or
use the JSON availability endpoint per `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`,
before concluding a floor "couldn't be confirmed."

---

## Sources

- The iOS-ABSENT / invented-name list + iOS equivalents:
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` and the reading-the-string rule
  in `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` §4 (toolkit-internal, Apple-sourced
  via Sosumi, access 2026-06-16).
- Floor values + the type-property quirk: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.
- Apple — `UIViewRepresentable` / `UIHostingController` iOS availability (iOS 13.0+):
  `https://developer.apple.com/documentation/swiftui/uiviewrepresentable` (via Sosumi, accessed
  2026-06-16).
- The Swift `#available` / `@available` language feature (`swift.org`).
