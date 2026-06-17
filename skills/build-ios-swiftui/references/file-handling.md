# File Handling, Document Picker & Security-Scoped Access (iOS)

> **iOS-only.** On iOS an app reads/writes freely inside its own container, but a file the user picks from
> **Files / iCloud Drive / another app's container** is reachable only through a user-driven picker that
> mints a temporary **security-scoped** grant — and that grant does **not** survive relaunch without a
> security-scoped bookmark. macOS appears only as a ❌ contrast. There is **no App-Sandbox `.entitlements`
> fork and no Hardened Runtime** here — the iOS equivalents are the document-picker grant, the
> security-scoped bookmark, and the **privacy usage strings** in `Info.plist`.

The corpus is full of desktop-style "read this path" code and manual `NSItemProvider` callbacks. On iOS
that yields code that compiles, looks right, and then **silently fails at runtime** because the URL was
never granted, or leaks the security-scoped grant, or trips Swift 6 isolation at the transfer boundary.

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain.** Cross-checked against `references/api-currency.md`.

---

## The container fork (the one architectural fact)

- **Inside the app's own container** (`FileManager.default.urls(for: .documentDirectory, …)`, the
  App-Group container, the temp dir) — free read/write, no grant needed.
- **Outside it** (a file in Files, iCloud Drive, another app) — reachable only via a picker
  (`.fileImporter` / `UIDocumentPickerViewController`) that returns a **security-scoped** URL; the grant
  is temporary and must be wrapped in `start`/`stopAccessingSecurityScopedResource()`, and persisted with
  a security-scoped bookmark to survive relaunch.

---

## The five mistakes (❌ WRONG → ✅ CORRECT)

### 1. Reading a hard-coded / out-of-container path with no picker grant

```swift
// ❌ WRONG — a literal/typed path outside the container; fails at runtime
let text = try String(contentsOf: URL(fileURLWithPath: "/var/mobile/.../notes.txt"))
```
```swift
// ✅ CORRECT — the URL comes from a user-driven picker that grants access to that file
.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
    guard case let .success(url) = result else { return }
    guard url.startAccessingSecurityScopedResource() else { return }
    defer { url.stopAccessingSecurityScopedResource() }     // balance the grant
    persist(try? String(contentsOf: url))
}
```
Outside the app container, the URL is reachable **only** because the user chose it through the picker.
`.fileImporter` / `.fileExporter` (SwiftUI) or `UIDocumentPickerViewController` (UIKit, bridged) is how you
get it. Writing back outside the container uses `.fileExporter` or a `FileDocument`/`ReferenceFileDocument`
+ `DocumentGroup` scene.

### 2. Re-opening a user-chosen file next launch with no security-scoped bookmark

```swift
// ❌ WRONG — persist the path/URL, re-open next launch → unreachable, the grant is gone
UserDefaults.standard.set(url.path, forKey: "lastFile")          // path string
UserDefaults.standard.set(try? url.bookmarkData(), forKey: "x")  // plain bookmark, NOT security-scoped

// ❌ ALSO WRONG — start without a balancing stop → the grant leaks; LATER access is denied
_ = url.startAccessingSecurityScopedResource()                   // ignored Bool; no defer/stop
return try String(contentsOf: url)                               // never stops → ref-count leak
```
```swift
// ✅ CORRECT — mint a SECURITY-SCOPED bookmark, persist the Data, wrap re-access in start/stop
func persist(_ url: URL) throws {
    let bookmark = try url.bookmarkData(options: .minimalBookmark,   // iOS: security scope is implicit
                                        includingResourceValuesForKeys: nil, relativeTo: nil)
    UserDefaults.standard.set(bookmark, forKey: "lastFile")
}
func reopen() throws -> String {
    let data = UserDefaults.standard.data(forKey: "lastFile")!
    var stale = false
    let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
    guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
    defer { url.stopAccessingSecurityScopedResource() }   // ALWAYS balance start with stop
    if stale { try persist(url) }                         // re-mint while access is held
    return try String(contentsOf: url)
}
```
The grant for a user-selected file **does not survive relaunch**. *Holding the URL is not the same as being
allowed to open it.* Persist a bookmark, resolve it next launch, and balance every `start` with a `stop`
(use `defer`) — security-scoped access is **ref-counted**, so an unbalanced `start` leaks and later access
is denied.

### 3. Missing the privacy usage string for a system file/data source

When the file/data comes from a **system privacy-gated** source — the Photos library, the camera, Contacts,
a media library — the corresponding `Info.plist` usage string is **mandatory** or the app crashes the
moment it asks. (The picker `.fileImporter` itself needs no usage string; `PhotosPicker` since iOS 16 needs
none for the picker UI, but direct `PHPhotoLibrary` access does.)

```text
❌ WRONG — read the Photos library / capture from the camera with no usage string → instant crash on request.
✅ CORRECT — declare the matching key in Info.plist:
   NSPhotoLibraryUsageDescription / NSCameraUsageDescription / NSContactsUsageDescription / …
```
> The full privacy-manifest / usage-string correctness is a broader domain
> (`audit-swiftui-privacy-permissions`); this is the file-access slice. `PhotosPicker` (iOS 16+) is the
> privacy-preserving way to import images **without** library access.

### 4. `loadTransferable` / `PhotosPickerItem` that trips Swift 6 isolation

```swift
// ❌ WRONG — main-actor value crosses into the nonisolated .task / transfer closure → data race
struct AddView: View {
    @State private var item: PhotosPickerItem?
    var body: some View {
        SomeView().task {
            let data = try? await item?.loadTransferable(type: Data.self)  // ❌ Swift 6 error
        }
    }
}
// "Sending main actor-isolated value of type 'PhotosPickerItem' with later accesses
//  to nonisolated context risks causing data races"
```
```swift
// ✅ CORRECT — own the item + the async work in an @Observable model; relocate state off the view boundary
@Observable @MainActor final class PhotoLoader {
    var item: PhotosPickerItem?
    func load() async -> Data? { try? await item?.loadTransferable(type: Data.self) }
}
struct AddView: View {
    @State private var loader = PhotoLoader()
    var body: some View {
        PhotosPicker(selection: $loader.item) { Text("Pick") }
            .task(id: loader.item) { _ = await loader.load() }
    }
}
```
Under the Swift 6 language mode strict concurrency is on by default. A main-actor `PhotosPickerItem` read
inside a *nonisolated* transfer closure is a hard error. The fix is to **move the state and the transfer
work into a model**, not to sprinkle `MainActor.run`. (A fresh Xcode 26 target may ship *Default Actor
Isolation = Main Actor*, which can mask this — never assume it's on; verify against your Xcode 26 SDK.)

### 5. Manual `NSItemProvider` / `UIPasteboard` strings instead of `Transferable`

```swift
// ❌ WRONG — manual NSItemProvider callbacks (hop threads, fight Swift 6) for drag-drop
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

// raw clipboard on iOS:
UIPasteboard.general.string = "hi"      // iOS clipboard (no NSPasteboard on iOS)
```
The manual `NSItemProvider` path is verbose, hops threads in its callbacks, and fights Swift 6 isolation.
The current SwiftUI idiom is `Transferable` + `.draggable` / `.dropDestination(for:)` with a **`Sendable`**
transferred type so the value crosses the drop's actor boundary cleanly. For the raw clipboard use
`UIPasteboard.general` (iOS) — `NSPasteboard` is macOS-only.

---

## Detection tells

- `URL(fileURLWithPath:` / `Data(contentsOf:` / a `FileManager` read against a **literal or out-of-container
  path** with no preceding `.fileImporter` / `UIDocumentPicker` → mistake 1.
- A picked `URL` saved to `UserDefaults`/disk via `.path` **or** a plain `bookmarkData()` resolved next
  launch with **no** `start`/`stopAccessingSecurityScopedResource()` → mistake 2.
- A `start...` with no balancing `stop`/`defer` → leaked security-scoped grant (mistake 2).
- `PHPhotoLibrary` / `AVCaptureDevice` / `CNContactStore` access with no matching `Info.plist` usage
  string → mistake 3 (crash on request).
- `PhotosPickerItem` / `loadTransferable` read inside a nonisolated `.task` closure on a `@MainActor` view
  → Swift-6 sending error (mistake 4).
- `.onDrop(of:` with manual `NSItemProvider` / `loadObject(ofClass:)` callbacks instead of `Transferable`
  + `.dropDestination(for:)` (mistake 5). `NSPasteboard` in an iOS target → won't compile (use
  `UIPasteboard`).

---

## Canonical pattern

```swift
struct DocumentReader: View {
    @State private var importing = false
    @State private var content = ""

    var body: some View {
        VStack { Text(content) }
            .toolbar { Button("Open") { importing = true } }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
                guard case let .success(url) = result else { return }
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }   // balance the grant
                content = (try? String(contentsOf: url)) ?? ""
                try? persistBookmark(url)                             // survive relaunch
            }
    }

    func persistBookmark(_ url: URL) throws {
        let data = try url.bookmarkData()                            // security scope implicit on iOS
        UserDefaults.standard.set(data, forKey: "lastDoc")
    }
}
```

**Rules:** (1) Files outside the app container come through a picker that grants access — never a hard-coded
path. (2) Persist a **security-scoped bookmark** to re-open next launch; balance every `start` with a
`stop` (`defer`); re-mint a stale bookmark. (3) Declare the matching `Info.plist` usage string for any
privacy-gated source. (4) Move `PhotosPickerItem`/`loadTransferable` work into an `@Observable @MainActor`
model to satisfy Swift 6. (5) Use `Transferable` + `.draggable`/`.dropDestination` (Sendable type) and
`UIPasteboard` — not manual `NSItemProvider` / `NSPasteboard`.

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:) | SwiftUI file import picker → security-scoped URL | high |
| https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource() | ref-counted; must be balanced with `stopAccessing…` | high |
| https://developer.apple.com/documentation/foundation/nsurl/bookmarkdata(options:includingresourcevaluesforkeys:relativeto:) | bookmark to re-open a granted file across launches | high |
| https://developer.apple.com/documentation/photokit/phpicker | `PhotosPicker` (iOS 16+) imports images without library access | high |
| https://developer.apple.com/documentation/coretransferable/transferable | `Transferable` + `.draggable`/`.dropDestination` — iOS 16.0+ | high |
| https://developer.apple.com/documentation/uikit/uipasteboard | iOS clipboard (no `NSPasteboard` on iOS) | high |
| https://developer.apple.com/documentation/bundleresources/information-property-list | `NS…UsageDescription` keys required for privacy-gated sources | high |
