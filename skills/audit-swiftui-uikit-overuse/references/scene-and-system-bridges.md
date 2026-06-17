# Reference — Screen, Window & System Bridges (over-02, over-03, over-04, over-06)

The system-level UIKit affordances that AI reaches for out of habit when SwiftUI ships a native geometry
proxy, environment value, or modifier. Each is overuse when its SwiftUI equal exists at the floor. The ✅
in a finding is the swiftui-ctx consensus shape + a real permalink, not a hand-written snippet.

**As of:** 2026-06-16 · iOS 26 · iOS 17 deployment floor.

---

## over-02 — `UIScreen.main` / `UIScreen.main.bounds` → SwiftUI geometry (deprecated iOS 16+)

Reading `UIScreen.main.bounds.width` (or `.size`, `.scale`) to size or position content is a classic
pre-SwiftUI habit — and `UIScreen.main` is **deprecated since iOS 16**: on an iPad in Split View / Stage
Manager or any multi-scene app it returns the *device* screen, not your window, so the layout is wrong.
The native answers:

- **Available size of the current container** → `GeometryReader { proxy in … proxy.size … }` (iOS 13+,
  consensus shape `{ }` at 99%), or for content that should track its scroll/container,
  `containerRelativeFrame(_:)` (iOS 17+).
- **iPhone-vs-iPad / compact-vs-regular layout branch** → `@Environment(\.horizontalSizeClass)` —
  the discipline lives in `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. Never branch layout
  on `UIDevice.current.userInterfaceIdiom`/`UIScreen.main` when a size class expresses the intent.
- **Display scale** → `@Environment(\.displayScale)` (iOS 13+).

`containerRelativeFrame` is iOS 17+ — confirm the floor before recommending it; below 17 use
`GeometryReader`. Cross_ref `adaptive-layout` when the real smell is a missing size-class branch.

## over-03 — `UIApplication.shared.windows` / `.keyWindow` → scene environment

Reaching `UIApplication.shared.windows.first` / `.keyWindow` to find the active window is fragile (it is
deprecated for multi-scene apps and returns the wrong window under Split View). In SwiftUI:

- **App foreground/background state** → `@Environment(\.scenePhase)` (iOS 14+). cross_ref
  `app-lifecycle-background`.
- **The current `UIWindowScene`** (when you genuinely need it, e.g. to present a UIKit controller or read
  `interfaceOrientation`) → reach it through the scene delegate / a `UIViewControllerRepresentable`'s
  `context`, not a global window walk.
- **Window size / safe area** → `GeometryReader` + `@Environment(\.safeAreaInsets)`-style modifiers, not
  `keyWindow.safeAreaInsets`.

## over-04 — `UIPasteboard.general` → `PasteButton` / `Transferable`

For copy/paste of a **model type**, `PasteButton(payloadType:)` (iOS 16+, consensus
`(supportedTypes, payloadAction)` / `(payloadType)`) and `.copyable(_:)` / `.pasteDestination(for:)` over
a `Transferable` conformance are the native path; you almost never need to read/write
`UIPasteboard.general.string` directly in SwiftUI. Use `swiftui-ctx recipe draggable-reorder` for the
`Transferable` pattern + real examples. Bridging raw pasteboard is justified only for a
legacy/heterogeneous flavor SwiftUI's `UTType` model can't express — note that explicitly. cross_ref
`document-picker-permissions` for drag-payload/consent correctness.

## over-06 — whole-screen / large-subtree bridges

Two shapes:
- **Reverse bridge in a SwiftUI-first app** — `UIHostingController` hosting the *entire* screen content
  pushed/presented from a hand-built `UINavigationController`/`UIViewController`. In a SwiftUI-first app a
  `NavigationStack`/`WindowGroup` scene removes the controller plumbing entirely (and `.searchable` only
  works inside a real SwiftUI navigation scene — see `audit-swiftui-uikit-interop`). cross_ref
  `adaptive-navigation`.
- **Over-wrapped representable** — a `makeUIView` returning a composed `UIStackView` / container that
  lays out several controls. That is several over-01 controls plus UIKit layout; prefer a SwiftUI
  `VStack`/`Form` of native controls and bridge nothing.

(`UIHostingController` is the *correct* bridge when embedding SwiftUI inside a genuinely UIKit-first app —
over-06 is about a SwiftUI-first app reaching for it needlessly. READ to confirm which app shape you are
in before flagging.)

## VERIFY + floors

Confirm each replacement's floor before flagging:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (`GeometryReader`/`scenePhase`/`displayScale`
13–14, `PasteButton` 16, `containerRelativeFrame` 17). Fetch protocol + paths:
`references/source-directory.md` + `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`. CLI
contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

---

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://developer.apple.com/documentation/uikit/uiscreen/main | primary-doc | high | `UIScreen.main` deprecated iOS 16 — returns device screen, not the window; use SwiftUI geometry. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/geometryreader | primary-doc | high | `GeometryReader` — container-relative size/position. iOS 13.0+. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:) | primary-doc | high | `containerRelativeFrame(_:)` — iOS 17.0+; sizes to the scroll/container, replaces `UIScreen.main.bounds`. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/scenephase | primary-doc | high | `@Environment(\.scenePhase)` — active/inactive/background, replaces `UIApplication.shared.windows` lifecycle reads. iOS 14.0+. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/pastebutton | primary-doc | high | `PasteButton` — iOS 16.0+; native clipboard paste over `Transferable`, replaces `UIPasteboard`. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/uihostingcontroller | primary-doc | high | Reverse bridge; correct only when hosting SwiftUI inside a genuinely UIKit-owned screen. Accessed 2026-06-16. |
