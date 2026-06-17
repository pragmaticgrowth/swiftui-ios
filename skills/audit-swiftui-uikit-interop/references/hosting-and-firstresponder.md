# Reference — UIHostingController & First Responder (uik-05 · uik-06)

The reverse bridge (SwiftUI **inside** UIKit) and the programmatic-keyboard trap. Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

> **Grounding.** `swiftui-ctx lookup UIHostingController --platform ios` → consensus `(rootView)` at **100%**,
> recommended real use in `tuist/XcodeProj`
> <https://github.com/tuist/XcodeProj/blob/621eca8d091cc110a99adc23bb0d6618a65b4544/Fixtures/iOS/AppWithExtensions/AppWithExtensions/SceneDelegate.swift#L18>
> (`UIHostingController(rootView: contentView)`). It is a UIKit symbol (iOS 13.0-era) — verify against the
> Xcode 26 SDK; it sits below the iOS-17 project floor, so no gate is needed.

---

## uik-05 — `UIHostingController` embedded with no child-VC containment (advisory)

A `UIHostingController` is a **view controller**. Dropping just its `.view` into a parent with `addSubview`
skips view-controller containment, so lifecycle events (`viewWillAppear`, trait/size-class changes, safe-area
propagation) never reach the SwiftUI tree.

❌ **Wrong — bare addSubview:**
```swift
let hosting = UIHostingController(rootView: ProfileView())
parentVC.view.addSubview(hosting.view)   // no addChild / didMove → broken containment
```

✅ **Correct — full child-VC containment:**
```swift
let hosting = UIHostingController(rootView: ProfileView())
parentVC.addChild(hosting)
parentVC.view.addSubview(hosting.view)
hosting.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    hosting.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
    hosting.view.bottomAnchor.constraint(equalTo: parentVC.view.bottomAnchor),
    hosting.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
    hosting.view.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
])
hosting.didMove(toParent: parentVC)   // completes the containment handshake
```

---

## uik-06 — `becomeFirstResponder()` called before the view is in the window (advisory)

`becomeFirstResponder()` returns `false` and does nothing if the view is **not yet in the window**. AI often
calls it inside `makeUIView`, before the representable's view is installed in the SwiftUI hierarchy.

❌ **Wrong — in makeUIView (view not yet in the window):**
```swift
func makeUIView(context: Context) -> UITextField {
    let field = UITextField()
    field.becomeFirstResponder()   // no-op — the field isn't in a window yet
    return field
}
```

✅ **Correct — drive focus from `updateUIView` once the view is installed (and guarded so it runs once):**
```swift
func updateUIView(_ uiView: UITextField, context: Context) {
    if isFocused, uiView.window != nil, !uiView.isFirstResponder {
        uiView.becomeFirstResponder()
    }
}
```

> Programmatic keyboard focus (`becomeFirstResponder`) is **this skill**. VoiceOver focus
> (`AccessibilityFocusState` / `.accessibilityFocused`) is `audit-swiftui-accessibility` — different
> mechanism; `cross_ref`, don't conflate. On modern SwiftUI prefer `@FocusState` + `.focused($_)` where the
> field is native — flagging a bridge that exists only for keyboard focus is an `audit-swiftui-uikit-overuse`
> WHETHER call; `cross_ref` it.
