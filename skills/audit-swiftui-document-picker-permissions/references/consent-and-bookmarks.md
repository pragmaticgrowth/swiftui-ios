# Consent & Security-Scoped Bookmarks (dp-01 · dp-02 · dp-03)

On iOS every app is sandboxed unconditionally — there is **no entitlement plist** to declare and no
`NSOpenPanel`. The app reads its own container (`Documents/`, `Caches/`, `Bundle.main`) freely. The trap
is a file **outside** the container: a URL the user chose through `fileImporter` /
`UIDocumentPickerViewController`, or a folder/file from the Files provider, is **security-scoped**. A
model reasoning purely about Swift sees a plain `URL` and writes `String(contentsOf:)` exactly as it
would for an in-container path — the URL is valid, the file exists, and the read **still fails at
runtime** with a permission error because the app never *entered the security scope*. The governing rule:
**a picked URL is security-scoped — holding it is NOT the same as being allowed to open it.**

> Scope note: the `loadTransferable` Swift-6 Sendable race that lives next to a picker is **not** here —
> `audit-swiftui-concurrency-safety` owns the isolation fix; this skill owns the file-consent angle and
> `cross_ref`s it (see `pickers-and-transferable.md`, dp-06). *Whether* a UIKit picker bridge should
> exist is `audit-swiftui-uikit-overuse`; security-scope correctness *once* a picker/importer is chosen
> is here. The Info.plist usage string is `audit-swiftui-privacy-permissions` (dp-07).

---

## dp-01 — reading a picked URL with no security scope (most common)

```swift
// ❌ WRONG — a picked, out-of-container URL read with NO startAccessingSecurityScopedResource()
.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
    guard case let .success(url) = result else { return }
    let text = try? String(contentsOf: url, encoding: .utf8)   // ❌ throws at runtime — scope never entered
}
```

A picked URL sits outside the app container. Reading it without entering the security scope fails at
runtime even though the URL is valid and the file exists. Your **own** container
(`FileManager.default.url(for: .documentDirectory …)`, `Bundle.main.url(forResource:…)`) needs no scope —
the trap is the *picked, out-of-container* URL.

**✅ Correct (consensus + the iOS-load-bearing line).** `swiftui-ctx lookup fileImporter --platform ios`
reports the canonical shape (`(isPresented, allowedContentTypes, allowsMultipleSelection)` 40%,
`(…, onCompletion)` 28%, `(isPresented, allowedContentTypes)` 23%). The picked URL is reachable **only
inside** a `start`/`stop` scope:

```swift
// ✅ CORRECT — enter the security scope, guard the Bool grant, balance start with stop via defer
.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
    guard case let .success(url) = result else { return }
    guard url.startAccessingSecurityScopedResource() else { return }   // ← the iOS-load-bearing line
    defer { url.stopAccessingSecurityScopedResource() }
    let text = try? String(contentsOf: url, encoding: .utf8)           // reachable ONLY inside the scope
    // try? persist(url)  // to re-open next launch → .withSecurityScope bookmark (dp-02)
}
```

`fileImporter` / `fileExporter` are iOS 14.0+; SwiftUI's importer wraps `UIDocumentPickerViewController`.

---

## dp-02 — re-opening a user-chosen file next launch with no security-scoped bookmark

```swift
// ❌ WRONG — persist the path/URL; re-open next launch → unreachable, the scope is gone
UserDefaults.standard.set(url.path, forKey: "lastFile")          // path string
UserDefaults.standard.set(try? url.bookmarkData(), forKey: "x")  // plain bookmark, NOT security-scoped
```

The security scope for a picked file **does not survive relaunch**. A plain `bookmarkData()` (no
`.withSecurityScope`) round-trips the *path* but not the *scope*.

```swift
// ✅ CORRECT — mint a SECURITY-SCOPED bookmark, persist the Data, resolve with .withSecurityScope
func persist(_ url: URL) throws {
    let bookmark = try url.bookmarkData(options: .withSecurityScope,
                                        includingResourceValuesForKeys: nil, relativeTo: nil)
    UserDefaults.standard.set(bookmark, forKey: "lastFile")
}
```

If `bookmarkDataIsStale == true` on resolve, **re-create the bookmark while you still have access**.

> Platform note: on iOS the `bookmarkData` option is `.withSecurityScope` (Foundation, cross-platform);
> there is **no** iOS entitlement to pair it with — the scope is granted by the picker, not a plist key.

---

## dp-03 — `start` access with no balancing `stop` (ref-count leak)

```swift
// ❌ WRONG — start without a balancing stop → the scope leaks; LATER file access is denied
_ = url.startAccessingSecurityScopedResource()      // ignored Bool, no defer/stop
return try String(contentsOf: url)                  // never calls stopAccessing… → ref-count leak
```

```swift
// ✅ CORRECT — resolve, guard the Bool grant, balance start with stop via defer
func reopen() throws -> String {
    let data = UserDefaults.standard.data(forKey: "lastFile")!
    var stale = false
    let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope,
                      relativeTo: nil, bookmarkDataIsStale: &stale)
    guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
    defer { url.stopAccessingSecurityScopedResource() }   // ALWAYS balance start with stop
    return try String(contentsOf: url)
}
```

`startAccessingSecurityScopedResource()` returns a `Bool` grant and is **ref-counted** — every `start`
needs exactly one balancing `stop` (use `defer`), or you leak the scope and a later access is denied.
Ignoring the returned `Bool` hides the denial.

---

## The consent test (the audit's core judgment)

Trace each out-of-container file URL back to its origin:

| Origin in source | Verdict |
|---|---|
| a picker (`fileImporter`/`fileExporter`/`UIDocumentPickerViewController`) **read inside** a `start`/`stop` scope | **granted** (temporary) |
| a resolved `.withSecurityScope` bookmark inside `start`/`stop` | **granted** (persisted) |
| the app's own container (`Documents/`, `Caches/`) or a `Bundle.main` URL | **granted** (no scope needed) |
| a picked URL **read with no** `startAccessingSecurityScopedResource()` | **ungranted → dp-01** |
| a `.path`/`.absoluteString` from `UserDefaults` | **ungranted → dp-02** |
| a plain `bookmarkData()` (no `.withSecurityScope`) | **ungranted → dp-02** |

**Optional `_consent-map.md` artifact:** classify every out-of-container file URL in the project by
origin and mark its consent state; score consent coverage = scoped-or-in-container URLs / total file
URLs. Two runs over the same code produce identical maps.

> iOS-specific contrast: macOS additionally gates this with an App Sandbox *entitlement* plist
> (`com.apple.security.files.user-selected.*`) and `NSOpenPanel`; iOS has **neither** — the scope is
> granted entirely by the picker and persisted only by a `.withSecurityScope` bookmark. Drop any
> entitlement reasoning when auditing an iOS target.

---

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource() | primary-doc | high (symbol) | Returns a `Bool` grant and is **ref-counted** — each call must be balanced by one `stopAccessingSecurityScopedResource()`. iOS arm present. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/foundation/url/bookmarkcreationoptions/withsecurityscope | primary-doc | high (symbol) / medium (body) | `.withSecurityScope` bookmark option — the flag that makes a bookmark re-grantable across launches on iOS. Symbol confirmed; body JS-rendered. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/view/fileimporter | primary-doc | high (symbol) | `fileImporter` — the SwiftUI document picker; wraps `UIDocumentPickerViewController`. iOS 14.0+. Body JS-rendered. Accessed 2026-06-16. |
| https://www.hackingwithswift.com/example-code/system/how-to-use-security-scoped-bookmarks-to-access-the-file-system | practitioner | high | The canonical `bookmarkData(options: .withSecurityScope)` ↔ `startAccessingSecurityScopedResource()` round-trip, incl. the stale-bookmark re-create. Accessed 2026-06-16. |
| swiftui-ctx `lookup fileImporter --platform ios` (iOS corpus) | practice | high | consensus `(isPresented, allowedContentTypes, allowsMultipleSelection)` 40% / `(…, onCompletion)` 28% / `(isPresented, allowedContentTypes)` 23%; `introduced_ios: 14.0`; `doc:` https://sosumi.ai/documentation/swiftui/view/fileimporter. Run 2026-06-16. |

Floors are cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`
(`fileImporter`/`fileExporter` iOS 14.0+) and fetched via Sosumi (access 2026-06-16). The Apple doc
bodies render via JavaScript — symbol names, page identities, and availability are confirmed; verbatim
body prose was not captured. Where exact prose matters, **verify against Xcode 26 SDK**.
