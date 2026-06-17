# UIKit Interop & First Responder (iOS)

When SwiftUI has no native equal of a real `UITextView` (rich text / precise text input), `WKWebView`,
`MKMapView`, `AVPlayerLayer`, `PHPickerViewController`, a camera preview, or any delegate-driven UIKit
control, you bridge to UIKit. The protocols are `UIViewRepresentable` / `UIViewControllerRepresentable`,
and the reverse bridge is `UIHostingController` / `UIHostingConfiguration`.

AI fails this three ways: (a) pretends a SwiftUI-only solution exists when one is genuinely needed; (b)
writes a representable that compiles but never reflects state because it omits `updateUIView` or
mismanages the `Coordinator`; (c) sets a UIKit delegate with **no `makeCoordinator()`** so callbacks are
silently dead, or **strongly captures the parent** in a Coordinator and leaks. The corpus is heavy with
*toy* representables that only `makeUIView` and stop, so AI routinely drops the `updateUIView` body and
the Coordinator a delegate needs.

Default: **stay in SwiftUI.** Bridge only the one control/subsystem that needs it; whether a bridge
should exist at all (a label → `Text`, a button → `Button`, a plain scroll → `ScrollView`) is the
`audit-swiftui-uikit-overuse` concern — this file is the **HOW** once a bridge is justified.

> iOS-only. macOS uses `NSViewRepresentable` / `NSHostingController` and a window-scoped responder chain;
> on iOS first responder is `UIResponder.becomeFirstResponder()` and SwiftUI's `@FocusState`. macOS
> appears only as a ❌ contrast.

---

## The four parts of a bridge (three are easy to forget)

`makeUIView(context:)` → `updateUIView(_:context:)` → `makeCoordinator()` → a nested `Coordinator`
(`swiftui-ctx recipe uiview-bridge`). The corpus shows 1,007 real bridges across 186 repos.

---

## The eight mistakes

### 1. Omitting `updateUIView` — state never propagates (most common)

`makeUIView(context:)` runs **once** at creation. SwiftUI calls `updateUIView(_:context:)` on every
relevant state change; without it, later changes to bound state never reach the UIKit view, which
silently freezes at its initial value. `UIViewRepresentable` declares **both** as core members.

❌ **WRONG** — set once, bridge is one-shot:
```swift
struct MyField: UIViewRepresentable {
    @Binding var text: String
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.text = text                 // set ONCE, never again
        return tv
    }
    // no updateUIView  ❌  later text changes never reach the view
}
```

✅ **CORRECT** — implement both halves:
```swift
struct MyField: UIViewRepresentable {                // iOS 13.0+
    @Binding var text: String
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        return tv
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }   // push SwiftUI -> UIKit
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: MyField
        init(_ parent: MyField) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {  // push UIKit -> SwiftUI
            parent.text = textView.text
        }
    }
}
```
Guard the write (`if uiView.text != text`): an unconditional `uiView.text = text` every update resets the
cursor/selection and can re-enter the change→update loop.

### 2. Setting a delegate with no `makeCoordinator()` — the callback direction is dead

UIKit controls report changes through delegate protocols (`UITextViewDelegate`,
`UITextFieldDelegate`, `WKNavigationDelegate`, `MKMapViewDelegate`). SwiftUI gives you `makeCoordinator()`
precisely to own a delegate reachable as `context.coordinator`. Set `tv.delegate = …` with no Coordinator
(or no delegate at all) and the UIKit→SwiftUI direction is dead: typing shows on screen but the `@Binding`
stays empty.

❌ **WRONG** — `@Binding` with no Coordinator, no delegate:
```swift
struct MyField: UIViewRepresentable {
    @Binding var text: String
    func makeUIView(context: Context) -> UITextField { UITextField() }   // delegate never set
    func updateUIView(_ uiView: UITextField, context: Context) { uiView.text = text }
    // no makeCoordinator()  ❌  edits never flow back to `text`
}
```

✅ **CORRECT** — Coordinator owns the delegate; bound value written back from the callback:
```swift
func makeUIView(context: Context) -> UITextField {
    let tf = UITextField()
    tf.delegate = context.coordinator                 // wire the delegate
    tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)),
                 for: .editingChanged)
    return tf
}
func makeCoordinator() -> Coordinator { Coordinator(self) }
final class Coordinator: NSObject, UITextFieldDelegate {
    let parent: MyField
    init(_ parent: MyField) { self.parent = parent }
    @objc func editingChanged(_ tf: UITextField) {
        parent.text = tf.text ?? ""                   // UIKit -> SwiftUI
    }
}
```

### 3. A Coordinator that strongly captures its parent — retain cycle / stale closure

A `Coordinator` that holds the representable `struct` (a value type) is fine, but a Coordinator captured
**into a long-lived UIKit closure or a child object that also points back** can form a retain cycle, and
a Coordinator that stashes a stale copy of the parent reads outdated bindings. Hold the parent, but route
writes through the *current* binding, and break any cycle with `weak`.

❌ **WRONG** — a child object strongly capturing the Coordinator's parent in a closure that outlives it:
```swift
final class Coordinator: NSObject {
    let parent: MyView
    var observer: NSObjectProtocol?
    init(_ parent: MyView) {
        self.parent = parent
        observer = NotificationCenter.default.addObserver(forName: .x, object: nil, queue: .main) { _ in
            self.parent.value = 1            // ❌ strong self capture in a long-lived observer → leak
        }
    }
}
```

✅ **CORRECT** — `[weak self]`, and tear the observer down in `dismantleUIView`:
```swift
observer = NotificationCenter.default.addObserver(forName: .x, object: nil, queue: .main) { [weak self] _ in
    self?.parent.value = 1
}
static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
    if let o = coordinator.observer { NotificationCenter.default.removeObserver(o) }  // cleanup
}
```

### 4. Reaching for `UIViewRepresentable` when you need `UIViewControllerRepresentable`

`UIView` and `UIViewController` are different bridge surfaces. When the UIKit thing is controller-shaped
(lifecycle, child-VC containment, `viewDidAppear`, a presented picker) — `PHPickerViewController`,
`UIImagePickerController`, `SFSafariViewController`, an `AVPlayerViewController`, a camera capture VC —
wrapping it as a bare `UIView` loses all of that. The right protocol is `UIViewControllerRepresentable`,
whose required members are `makeUIViewController(context:)` / `updateUIViewController(_:context:)`
(`makeCoordinator()` available identically).

❌ **WRONG** — flatten a controller-shaped component to a bare view:
```swift
struct PickerBridge: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        PHPickerViewController(configuration: .init()).view   // ❌ VC deallocated; presentation lost
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
```

✅ **CORRECT** — use the controller representable:
```swift
struct PickerBridge: UIViewControllerRepresentable {        // iOS 13.0+
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let p = PHPickerViewController(configuration: .init())
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate { /* … */ }
}
```

### 5. Hosting SwiftUI inside UIKit — `UIHostingController`

In a mostly-UIKit app, AI tries to instantiate SwiftUI views by hand or claims SwiftUI "can't be
embedded" in an existing `UIViewController`. The sanctioned bridge is `UIHostingController` (a
`UIViewController` whose content is a SwiftUI `rootView`) — that's how you push a SwiftUI screen onto a
`UINavigationController`, drop one in a `UITabBarController`, or use `UIHostingConfiguration` for a SwiftUI
cell in a `UICollectionView`/`UITableView`.

❌ **WRONG** — claim it can't be done / hand-instantiate:
```swift
let v = MySwiftUIView()              // ❌ a View is not a UIView; nothing to add as a subview
viewController.view.addSubview(v)    // ❌ does not compile / nothing renders
```

✅ **CORRECT** — host through the UIKit bridge type:
```swift
let host = UIHostingController(rootView: MySwiftUIView())    // iOS 13.0+
navigationController.pushViewController(host, animated: true)
// or as a child VC:
addChild(host); view.addSubview(host.view); host.didMove(toParent: self)
// or a SwiftUI cell (iOS 16+):
cell.contentConfiguration = UIHostingConfiguration { MyCellContent(item: item) }
```

### 6. Swift-6 bridge-concurrency: a `@Sendable` Coordinator callback touching main-actor state

The Coordinator boundary is exactly where Swift 6's strict data-race checking bites. `updateUIView`,
Coordinator delegate callbacks, and `UIControl` action targets are `@MainActor` UIKit surfaces. Route a
callback out through a closure typed `@Sendable` (or hop off-main in a delegate) and the compiler errors:
a `@Sendable` closure can run on any thread, so synchronously reading/writing main-actor state inside it
is a data race — *"Main actor-isolated property '…' can not be referenced from a Sendable closure."* This
is a hard **error** under the Swift 6 language mode. (A fresh Xcode 26 iOS target often ships *Default
Actor Isolation = Main Actor*, which can mask this — but never assume that opt-in mode is on; verify
against your Xcode 26 SDK.)

❌ **WRONG** — read main-actor state inside a `@Sendable` closure, or GCD-hop to dodge the checker:
```swift
final class Coordinator: NSObject, WKNavigationDelegate {
    let parent: WebBridge
    init(_ parent: WebBridge) { self.parent = parent }
    func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
        runOffMain { self.parent.isLoading = false }   // ❌ Sendable closure can't touch main-actor `parent`
    }
    func runOffMain(_ work: @Sendable @escaping () -> Void) { /* ... */ }
}
// also wrong: DispatchQueue.main.async { self.parent.isLoading = false }  // ❌ side-steps Swift 6 checking
```

✅ **CORRECT** — isolate to the main actor, or capture by value for a read:
```swift
// You own the receiving function: mark the closure @MainActor so reading main-actor state is legal.
func runOnMain(_ work: @Sendable @MainActor @escaping () -> Void) { /* ... */ }
// Hopping back to the main actor from a nonisolated context — annotation, not GCD:
await MainActor.run { parent.isLoading = false }
```
Capture-by-value works for **reads only**; mutating main-actor state from a `@Sendable` closure needs an
`await` / `MainActor.run` hop. (The isolation angle of a captured Coordinator is co-owned with
`concurrency.md` / `audit-swiftui-concurrency-safety`.)

### 7. `becomeFirstResponder()` called where it has no effect (keyboard won't show)

On iOS, focus/keyboard is `UIResponder.becomeFirstResponder()`. AI calls it in `makeUIView` (the view is
not yet in a window — it silently fails) or on a SwiftUI value (there is no such call on a `View`). For
SwiftUI-native controls use `@FocusState` (iOS 15.0+); for a bridged UIKit text view, call
`becomeFirstResponder()` from `updateUIView`, guarded by a flag, once the view is in the hierarchy.

❌ **WRONG** — first-responder in `makeUIView`, or on a SwiftUI value:
```swift
func makeUIView(context: Context) -> UITextField {
    let tf = UITextField()
    tf.becomeFirstResponder()        // ❌ not in a window yet → no-op, keyboard never shows
    return tf
}
someView.becomeFirstResponder()      // ❌ not a thing on a SwiftUI value
```

✅ **CORRECT** — drive focus from `updateUIView` (guarded), or use `@FocusState` for SwiftUI controls:
```swift
func updateUIView(_ uiView: UITextField, context: Context) {
    if shouldFocus, !uiView.isFirstResponder { uiView.becomeFirstResponder() }
}
// SwiftUI-native field:
@FocusState private var focused: Bool
TextField("Name", text: $name).focused($focused)
```

### 8. Reporting size: let UIKit's intrinsic content size flow, or use `sizeThatFits`

A bridged UIKit view that reports no intrinsic size collapses to zero or expands to fill, surprising the
SwiftUI layout. Let the UIKit view set `intrinsicContentSize` / content-hugging + compression-resistance,
or implement the optional `sizeThatFits(_:uiView:context:)` (iOS 16.0+) to propose the view's ideal size
to SwiftUI's layout. On a target below iOS 16, fall back to `.frame` / intrinsic content size.

```swift
// ✅ iOS 16+ — propose the UIKit view's ideal size to SwiftUI's layout
func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
    uiView.sizeThatFits(CGSize(width: proposal.width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
}
```

---

## Detection tells

- A `: UIViewRepresentable` / `: UIViewControllerRepresentable` type with **no** `func updateUIView` /
  `func updateUIViewController` → state-staleness bug (mistake 1).
- `makeUIView` that sets `.text` / `.image` / data once, and a body with no `updateUIView` writing the
  same property back.
- A representable with a `@Binding` but **no** `makeCoordinator()` and no `.delegate = context.coordinator`
  → broken UIKit→SwiftUI direction (mistake 2).
- A `Coordinator` capturing `self`/`parent` strongly inside a long-lived closure/observer with no
  `[weak self]` and no `dismantleUIView` cleanup → retain cycle / stale closure (mistake 3).
- A `UIViewController`-backed component (`PHPickerViewController`, `SFSafariViewController`,
  `AVPlayerViewController`) wrapped as a bare `UIView` via `vc.view` → wrong protocol (mistake 4).
- Hand-instantiated SwiftUI views in UIKit code with no `UIHostingController` / `UIHostingConfiguration`
  (mistake 5).
- A `@Sendable` closure parameter (or `Task.detached`, `DispatchQueue.main.async`) in/around a Coordinator
  whose body reads `self.parent.…` / a `@MainActor` property → Swift-6 isolation error (mistake 6).
- `becomeFirstResponder()` called in `makeUIView`, or on a SwiftUI value (mistake 7).
- Observers / KVO / timers added in `makeUIView` with no `static func dismantleUIView(_:coordinator:)`
  → leaks across view-identity changes (cleanup belongs in `dismantleUIView`).

---

## Canonical pattern

```swift
// iOS UIKit -> SwiftUI bridge — the canonical shape (iOS 13.0+)
struct UIKitField: UIViewRepresentable {
    @Binding var text: String
    var shouldFocus: Bool

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)),
                     for: .editingChanged)
        return tf
    }
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }                  // SwiftUI -> UIKit
        if shouldFocus, !uiView.isFirstResponder { uiView.becomeFirstResponder() }  // guarded focus
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    static func dismantleUIView(_ uiView: UITextField, coordinator: Coordinator) { }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: UIKitField
        init(_ parent: UIKitField) { self.parent = parent }
        @objc func editingChanged(_ tf: UITextField) {                 // UIKit -> SwiftUI
            parent.text = tf.text ?? ""
        }
    }
}

// Reverse bridge: SwiftUI inside UIKit
navigationController.pushViewController(UIHostingController(rootView: MySwiftUIView()), animated: true)
```

**Rules:** (1) implement BOTH `makeUIView` and `updateUIView` (guard the write). (2) Use `makeCoordinator()`
+ `context.coordinator` as the delegate for the UIKit→SwiftUI direction. (3) Break Coordinator retain
cycles with `[weak self]` and tear observers down in `dismantleUIView`. (4) Controller-shaped UIKit →
`UIViewControllerRepresentable`. (5) SwiftUI-in-UIKit → `UIHostingController` / `UIHostingConfiguration`.
(6) At the Coordinator boundary, a closure that touches main-actor state must be `@MainActor`-isolated (or
`await MainActor.run` to hop) — never `DispatchQueue.main.async` to dodge the Swift-6 checker. (7)
Programmatic focus belongs in `updateUIView` (guarded), or use `@FocusState` for SwiftUI controls.

Recurring reasons to bridge at all on iOS: a real rich-text/precise-input `UITextView`, a `WKWebView`,
`MKMapView`, an `AVPlayerLayer` / camera preview, `PHPickerViewController`/`UIImagePickerController`,
`SFSafariViewController`, or a high-density `UICollectionView` grid past the SwiftUI `List`/`Table`
ceiling (→ `view-performance.md`).

---

## Sources

| URL | Type | Confidence | Key fact / verbatim |
|---|---|---|---|
| https://developer.apple.com/documentation/swiftui/uiviewrepresentable | primary-doc | high | *"A wrapper for a UIKit view that you use to integrate that view into your SwiftUI view hierarchy."*; required `func makeUIView(context:) -> UIViewType` + `func updateUIView(_:context:)`; `static func dismantleUIView(_:coordinator:)`; `iOS 13.0+`. Accessed 2026-06-07. |
| https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable | primary-doc | high | Sibling protocol; required `makeUIViewController(context:)` / `updateUIViewController(_:context:)`; `iOS 13.0+`. Accessed 2026-06-07. |
| https://developer.apple.com/documentation/swiftui/uihostingcontroller | primary-doc | high | *"A UIKit view controller that manages a SwiftUI view hierarchy."* (`init(rootView:)`); `iOS 13.0+`. Accessed 2026-06-07. |
| https://developer.apple.com/documentation/swiftui/uihostingconfiguration | primary-doc | high | *"A content configuration suitable for hosting a hierarchy of SwiftUI views."* — SwiftUI cells in `UICollectionView`/`UITableView`; `iOS 16.0+`. Accessed 2026-06-07. |
| https://developer.apple.com/documentation/swiftui/uiviewrepresentable/sizethatfits(_:uiview:context:) | primary-doc | high | Optional representable member (`iOS 16.0+`): a representable proposes its own size to SwiftUI layout. Accessed 2026-06-07. |
| https://developer.apple.com/documentation/swiftui/focusstate | primary-doc | high | `@FocusState` (`iOS 15.0+`) drives focus/keyboard for SwiftUI-native controls. Accessed 2026-06-07. |
| https://developer.apple.com/videos/play/wwdc2022/10072/ | primary-doc (WWDC22 "Use SwiftUI with UIKit") | high | Representables are the sanctioned interop path: implement `updateUIView` + a `Coordinator` to feed SwiftUI state into UIKit and route delegate callbacks back. Accessed 2026-06-07. |
| https://www.donnywals.com/solving-main-actor-isolated-property-can-not-be-referenced-from-a-sendable-closure-in-swift/ | practitioner | high | The error text; fix depends on ownership: `@Sendable @MainActor` closure when you own the API; capture-by-value for reads; mutation needs an `await`/`Task` hop. Accessed 2026-06-06. |
| https://swift.org/blog/swift-6.2-released/ | primary-doc | high | "main actor by default" is the opt-in `-default-isolation MainActor`, not the unconditional default. Accessed 2026-06-06. |

**Availability note (Apple docs / iOS catalog, 2026-06-07):** the core representable/hosting types
(`UIViewRepresentable`, `UIViewControllerRepresentable`, `UIHostingController`) are `iOS 13.0+`.
`@FocusState` is `iOS 15.0+` (SwiftUI controls only). `UIHostingConfiguration` and the optional
`sizeThatFits(_:uiView:context:)` member are `iOS 16.0+` — a target below iOS 16 cannot use either.
`@concurrent` and `-default-isolation MainActor` are toolchain-gated to **Swift 6.2+**. Verify the
deployment target and toolchain/build settings against your Xcode 26 SDK before relying on these.
