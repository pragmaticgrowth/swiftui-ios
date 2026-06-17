# Pickers, Transferable & Photos/Files Consent (dp-04 · dp-05 · dp-06 · dp-07)

The current SwiftUI idiom for letting the user choose a file or photo is `fileImporter`/`fileExporter`
(documents) and `PhotosPicker` (photos), not a raw UIKit picker bridge. For moving values in/out by
drag-drop it is the **`Transferable`** protocol (iOS 16.0+) with `.draggable` / `.dropDestination` and a
**`Sendable`** transferred type. AI trained on older, UIKit-shaped data reaches instead for
`UIDocumentPickerViewController` / `UIImagePickerController` / `PHPickerViewController` bridges and manual
`NSItemProvider` callbacks (which hop threads and fight Swift 6 isolation). Photos/Files access also
needs an Info.plist **usage string** the model frequently omits.

> Seam: the `loadTransferable` Swift-6 **Sendable race** is owned by
> `audit-swiftui-concurrency-safety` (isolation fix); this skill owns only the **file-consent** angle and
> `cross_ref`s it (dp-06). *Whether* a UIKit picker bridge should exist is `audit-swiftui-uikit-overuse`
> (the *how* of a kept bridge is `audit-swiftui-uikit-interop`); flag the smell here and `cross_ref` it
> (dp-04). The Info.plist usage *string* is owned by `audit-swiftui-privacy-permissions` (dp-07).

---

## dp-04 — raw UIKit picker bridge where SwiftUI fits

```swift
// ❌ SMELL — a raw UIDocumentPickerViewController bridge for a plain file choice
struct DocPicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forOpeningContentTypes: [.plainText])
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
}
```

```swift
// ✅ CORRECT — SwiftUI's native importer (and PhotosPicker for photos), no bridge to maintain
.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
    guard case let .success(url) = result, url.startAccessingSecurityScopedResource() else { return }
    defer { url.stopAccessingSecurityScopedResource() }
    handle(url)
}
// for photos:  PhotosPicker(selection: $item, matching: .images) { Text("Choose") }   // iOS 16.0+
```

A raw `UIDocumentPickerViewController` / `UIImagePickerController` / `PHPickerViewController` bridge where
SwiftUI's `fileImporter` / `PhotosPicker` is the native answer is a **whether-to-bridge** smell. This is
`advisory`/`flag-only`: the WHETHER verdict is owned by `audit-swiftui-uikit-overuse` and the bridge
*mechanics* (if kept) by `audit-swiftui-uikit-interop` — emit `cross_ref: audit-swiftui-uikit-overuse`.
A bridge is sometimes justified (e.g. `PHPickerViewController` filters SwiftUI doesn't expose) — name
it, don't blind-flag.

---

## dp-05 — manual `NSItemProvider` / `.onDrop` instead of `Transferable`

```swift
// ❌ WRONG — manual NSItemProvider callbacks hop threads and fight Swift 6 isolation
.onDrop(of: [.fileURL], isTargeted: nil) { providers in
    providers.first?.loadObject(ofClass: URL.self) { url, _ in /* off-main, isolation hazard */ }
    return true
}
```

```swift
// ✅ CORRECT — Transferable + .draggable / .dropDestination with a Sendable transferred type
struct Note: Codable, Transferable {                                  // iOS 16.0+
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }
}
view.draggable(note)
    .dropDestination(for: Note.self) { notes, _ in handle(notes); return true }
```

The manual `NSItemProvider` path is verbose, hops threads in its load callbacks, and fights Swift 6
isolation. The current idiom is `Transferable` + `.draggable` / `.dropDestination(for:)` with a
**`Sendable`** transferred type so the value crosses the drop's actor boundary cleanly. `swiftui-ctx
lookup dropDestination --platform ios` reports the consensus drop shape (`(for)` at 100%) and
`introduced_ios: 16.0`; fetch the permalinked example with
`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart`.

---

## dp-06 — `loadTransferable` picker item across an actor boundary (file-consent angle)

```swift
// ❌ Compiles pre-Swift-6, errors under the Swift 6 language mode
struct AddView: View {
    @State private var item: PhotosPickerItem?
    var body: some View {
        SomeView().task {
            let data = try? await item?.loadTransferable(type: Data.self)  // ❌ Swift 6 data-race
        }
    }
}
// error: "Sending main actor-isolated value of type 'PhotosPickerItem' with later accesses
//         to nonisolated context risks causing data races"
```

```swift
// ✅ CORRECT — own the item + the async work in an @Observable model held as @State
@Observable @MainActor final class PhotoLoader {
    var item: PhotosPickerItem?
    func load() async -> Data? { try? await item?.loadTransferable(type: Data.self) }
}
struct AddView: View {
    @State private var loader = PhotoLoader()
    var body: some View { SomeView().task { _ = await loader.load() } }
}
```

A main-actor-isolated value (a `PhotosPickerItem` born in a `@MainActor` view) read inside the
*nonisolated* `.task`/transfer closure is a hard error under Swift 6 strict concurrency. The fix is to
**move the state and the transfer work into a model** (created as `@State`), not to sprinkle
`MainActor.run`. **This isolation fix is owned by `audit-swiftui-concurrency-safety`** — when the hazard
is present, emit the finding with `cross_ref: audit-swiftui-concurrency-safety`; the file-consent
question (did the loaded data get persisted with a security-scoped bookmark if it was a file?) is this
skill's part. A fresh Xcode 26 target may ship *Default Actor Isolation = Main Actor*
(`-default-isolation MainActor`), which can pre-isolate and mask this — never assume that mode is on; it
is opt-in. Carry that assumption as `advisory`/`verify against Xcode 26 SDK`.

---

## dp-07 — Photos/Files API in use with no Info.plist usage string

```text
❌ WRONG — PHPickerViewController / UIImagePickerController / PHPhotoLibrary in the code, but the
           Info.plist has no NSPhotoLibraryUsageDescription → the system prompt is empty and iOS
           kills the app on access (or App Review rejects it).
```

```xml
<!-- ✅ CORRECT — declare the matching usage string in Info.plist (read by hand; not *.swift) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We add your chosen photos to the document.</string>
```

A Photos/Files API used with no matching Info.plist usage string is an `advisory` flag. The exact key
*per API* (`NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, etc.) and the privacy
manifest (`PrivacyInfo.xcprivacy`) are owned by **`audit-swiftui-privacy-permissions`** — flag the smell
here, read the `Info.plist` by hand in ORIENT, and emit `cross_ref: audit-swiftui-privacy-permissions`.
Carry as **advisory** with `source: verify against Xcode 26 SDK` — never assert an exact usage-string key
from memory. (Note: `fileImporter`/`UIDocumentPickerViewController` need **no** usage string — the picker
*is* the consent; dp-07 is about Photos/Camera/Files-library APIs, not the document picker.)

---

## iOS picker / drag-drop facts

- The SwiftUI document picker is **`fileImporter`/`fileExporter`** (iOS 14.0+); it wraps
  `UIDocumentPickerViewController`. The photo picker is **`PhotosPicker`** + `PhotosPickerItem`
  (iOS 16.0+), wrapping `PHPickerViewController`.
- A picked URL is **security-scoped** (see `consent-and-bookmarks.md`) — the picker is the consent, not
  an entitlement plist (iOS has none).
- `Transferable` / `.draggable` / `.dropDestination` are iOS 16.0+; drag-drop on iOS works with both
  touch and (on iPad) a pointer.

---

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://developer.apple.com/documentation/coretransferable/transferable | primary-doc | high (symbol) | `Transferable` protocol — current SwiftUI drag-drop/paste model. iOS 16.0+. Body JS-rendered. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/view/draggable(_:) | primary-doc | high (symbol) | `.draggable(_:)` — the source side, iOS 16.0+. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/photokit/photospicker | primary-doc | high (symbol) | `PhotosPicker` — the SwiftUI photo picker, iOS 16.0+; wraps `PHPickerViewController`. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller | primary-doc | high (symbol) | `UIDocumentPickerViewController` — the UIKit document picker `fileImporter` wraps. Accessed 2026-06-16. |
| https://www.reddit.com/r/swift/comments/1dk8ces/strict_concurrency_swift_6_causes/ | forum (lived) | high | Error verbatim *"Sending main actor-isolated value of type 'PhotosPickerItem' …"*; fix = move the item + `loadTransferable` into an `@Observable` view-model held as `@State`. Accessed 2026-06-16. |
| swiftui-ctx `lookup dropDestination --platform ios` (iOS corpus) | practice | high | consensus drop shape `(for)` 100%; `introduced_ios: 16.0`; `deprecated: false`; `doc:` https://sosumi.ai/documentation/swiftui/view/dropdestination. Run 2026-06-16. |

Floors are cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`
(`Transferable`/`draggable`/`dropDestination`/`PhotosPicker` iOS 16.0+; `fileImporter` iOS 14.0+) and the
platform-wrong list in `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`; pages
fetched via Sosumi (access 2026-06-16). Apple doc bodies render via JavaScript — symbols and availability
confirmed; where exact body prose or a Swift-6 build setting matters, **verify against Xcode 26 SDK**.
