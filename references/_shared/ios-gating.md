# Shared Reference — iOS Availability Gating Discipline

The rule for writing and auditing availability gates in this **iOS-first** toolkit. Every skill that
emits a gate fix points here; do not restate the rule locally. Floor values come from
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16.

---

## 1. The rule

Gate a floored API on the **iOS arm**:

```swift
if #available(iOS 17, *) {
    someView.scrollClipDisabled()
} else {
    someView   // pre-17 fallback — feature unavailable
}
```

- The platform name is **`iOS`**, and the floor is the **iOS** floor from `floors-master.md`.
- The trailing `*` wildcard is **required** — it covers every other platform (macOS, tvOS, watchOS,
  visionOS) the code may compile against. Omitting it is a compile error.
- For a property/parameter that needs the gate, use `@available(iOS NN, *)` on the declaration, or
  `if #available(iOS NN, *)` at the use site.
- The **project floor is iOS 17** — any symbol with `introduced_ios` ≤ 17 needs no gate. Gate only
  symbols above the project floor.

---

## 2. Idiom checks (iPhone vs. iPad)

iOS runs on both iPhone (compact) and iPad (regular). Prefer SwiftUI environment values over
UIKit-level checks:

```swift
// Preferred — SwiftUI environment
@Environment(\.horizontalSizeClass) private var hSizeClass

var body: some View {
    if hSizeClass == .compact {
        compactLayout
    } else {
        wideLayout
    }
}

// Acceptable — UIKit idiom (only when SwiftUI environment is insufficient)
if UIDevice.current.userInterfaceIdiom == .pad {
    // iPad-specific path
}
```

Rules:
- **`horizontalSizeClass`** is the correct SwiftUI idiom for layout branching — compact = iPhone
  portrait / iPad split-view; regular = iPhone landscape large / iPad full.
- **`UIDevice.current.userInterfaceIdiom == .pad`** works but bypasses SwiftUI's environment. Use
  only when you need a structural (non-layout) iPad-vs-iPhone distinction.
- Never gate on `UIDevice.current.model` — fragile and App Store disallowed.
- `VerticalSizeClass` (`.compact`) also available; use for tall/short landscape detection.

---

## 3. The wrong-arm failure mode

Gating an iOS-floored API on the **macOS arm** when building for iOS is the wrong-arm bug:

```swift
// WRONG — gated on macOS; on iPhone/iPad this branch's availability is wrong.
if #available(macOS 14, *) {
    view.scrollClipDisabled()
}
```

A wrong-arm gate either fails to compile on iOS or silently never runs on device. Flag it as a
gating finding, not a hallucination.

---

## 4. Reading a multi-platform availability string

Apple renders strings like `iOS 17.0+ · macOS 14.0+ · watchOS 10.0+`. In this toolkit:

- **Read only the iOS arm.** If iOS is present, that floor is the gate value.
- **If iOS is ABSENT from the array**, the symbol has no iOS arm — it is **platform-wrong**, not
  under-gated. Do not wrap a platform-wrong symbol in `#available(iOS …)` — replace it with the iOS
  equivalent or omit it.
- Beware the **macOS floor being lower than iOS** — gating on the macOS number under-gates iOS.

---

## 5. iOS-17 floor policy

The corpus targets **iOS 17** as the deployment floor. This means:

- All symbols with `introduced_ios: "13.0"` through `"17.0"` are **unconditionally available** — no
  gate required.
- Symbols introduced after iOS 17 (18.0, 18.1, 18.2, 26.0, etc.) require a gate or a minimum
  deployment target bump.
- When auditing: check `introduced_ios` from `floors-master.md`. If the value is > 17.x, a gate is
  required unless the file's deployment target is already at or above the floor.

---

## 6. Audit checklist

1. Every floored API (per `floors-master.md`) with floor > iOS 17 has a gate, or the project's
   deployment target is at or above the floor.
2. The gate names **`iOS`**, not `macOS`/`*`-only.
3. The gate's floor matches `floors-master.md`.
4. No iOS-ABSENT symbol is wrapped in an iOS gate; it is replaced, not gated.
5. The `else` fallback (where one is needed) uses a real pre-floor API.
6. Layout branching uses `horizontalSizeClass`, not model-string checks.

---

## Sources

- Apple availability strings per `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`
  (generated from `sdk_catalog.json` `introduced_ios` field).
- The Swift `#available` / `@available` language feature (`swift.org` / `developer.apple.com`).
- SwiftUI `horizontalSizeClass` / `VerticalSizeClass` environment values — Apple docs.
