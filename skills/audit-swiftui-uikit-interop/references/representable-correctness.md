# Reference — Representable Correctness (uik-01 · uik-02 · uik-03 · uik-04)

The HOW of a `UIViewRepresentable` / `UIViewControllerRepresentable` bridge: the four-part contract, the
two structural hard-fails, and the two value/wiring bugs. Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (read, never restate). Whether the bridge should
exist at all is `audit-swiftui-uikit-overuse` — this file assumes the bridge is justified.

> **Grounding.** `swiftui-ctx recipe uiview-bridge` → "Wrap a UIKit UIView or UIViewController in SwiftUI
> (931 real bridges across 182 repos)"; `swiftui-ctx bridges` → **1,007 bridges across 186 repos**
> (`UIViewRepresentable` 504 · `UIViewControllerRepresentable` 427). `UIViewRepresentable` itself
> `lookup`s as a **conformance pattern** (`"redirect": "recipe"`, no single floor symbol);
> `Coordinator`/`makeCoordinator` `lookup` **exit 3** — they are protocol-requirement names, not catalog
> symbols (expected, not a hallucination).

---

## The canonical four-part shape (the ✅ all examples build toward)

The consensus bridge is `makeUIView(context:)` → `updateUIView(_:context:)` → `makeCoordinator()` → a nested
`Coordinator`. `make…` builds the view **once**; `update…` is the **only** path SwiftUI state reaches it; the
`Coordinator` is the delegate target and the place to write a `@Binding` back.

```swift
struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator   // delegate → the Coordinator
        view.text = text                       // initial value
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }   // re-apply on every state change
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }   // REQUIRED because a delegate is set

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: GrowingTextView          // parent is a struct VALUE — no cycle
        init(_ parent: GrowingTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text       // write the @Binding back
        }
    }
}
```

**Source (canonical real bridge):** `1amageek/Toolbar` — `EditorBacking+iOS.swift`
<https://github.com/1amageek/Toolbar/blob/651c24079698401734dbca70c00632ef1498b295/Sources/Toolbar/Editor/EditorBacking+iOS.swift#L5>
(`swiftui-ctx recipe uiview-bridge` first example). Fetch the live body with
`swiftui-ctx file <id> --smart` at FIX time.

---

## uik-01 — no `updateUIView` body (hard-fail)

`make…` runs once; `update…` is the **only** channel for SwiftUI state. A representable with no
`updateUIView` (or an empty `{ }`) renders once and then ignores every `@State`/`@Binding` change above it.

❌ **Wrong — state can never propagate:**
```swift
struct CounterLabel: UIViewRepresentable {
    var count: Int
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.text = "\(count)"
        return label
    }
    // no updateUIView → when `count` changes, the label is frozen at its first value
}
```

✅ **Correct:**
```swift
func updateUIView(_ uiView: UILabel, context: Context) {
    uiView.text = "\(count)"   // re-apply on every change
}
```

## uik-02 — input read in `make…` but never re-applied in `update…` (warning)

The `updateUIView` body exists but doesn't re-assign a value that `makeUIView` set, so that value freezes.

❌ **Wrong — `text` set only in make:**
```swift
func makeUIView(context: Context) -> UITextView {
    let v = UITextView(); v.text = text; v.isEditable = isEditable; return v
}
func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.isEditable = isEditable   // re-applies isEditable but NOT text → text never updates
}
```

✅ **Correct:** re-apply every input that can change — `if uiView.text != text { uiView.text = text }` (the
guard avoids clobbering the cursor on no-op updates).

## uik-03 — delegate set with no `makeCoordinator` (hard-fail)

`view.delegate = context.coordinator` requires `makeCoordinator()` to *return* that Coordinator. Without it,
`context.coordinator` is never your object — the delegate callbacks are silently dead.

❌ **Wrong:**
```swift
struct PickerBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.delegate = context.coordinator   // ← but no makeCoordinator() exists
        return vc
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    // no makeCoordinator → context.coordinator is a default, delegate never fires
}
```

✅ **Correct:** add `func makeCoordinator() -> Coordinator { Coordinator(self) }` and a `Coordinator: NSObject,
UIImagePickerControllerDelegate, UINavigationControllerDelegate`.

## uik-04 — Coordinator strongly captures its parent (warning)

A `Coordinator` storing the **struct** `parent` is fine (it's a value copy). A retain cycle appears when a
*class* is captured strongly into a closure the Coordinator (or the UIKit view) retains — e.g.
`view.someHandler = { self.parent.doThing() }` where `self` is held by the view. Break it with `[weak self]`
or by routing through the value `parent`. `cross_ref: concurrency-safety` when the same capture also crosses
an actor boundary (a callback hopping off `@MainActor`).

---

See `hosting-and-firstresponder.md` for `UIHostingController` containment (uik-05) and the
`becomeFirstResponder` call-site trap (uik-06).
