# Reference — Apple/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
document-picker / file-consent claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol
with the curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the picker/consent-specific
*map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the practice corpus (consensus shape +
permalinked example) is reached with
`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/<framework>/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. A `swiftui-ctx lookup --platform ios` **exit 3** (no iOS arm) corroborates a platform-wrong
   finding (no shipping iOS app uses the symbol).
2. **Need the precise per-platform array?** The raw `…/tutorials/data/documentation/<symbol>.json`
   `introducedAt` works when it resolves; it **404s** on parenthesized-symbol families — fall back to
   Sosumi. Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.
3. **Info.plist usage strings (dp-07)** are owned by `audit-swiftui-privacy-permissions` and read from the
   `Info.plist` by hand — never assert an exact `NS…UsageDescription` key from memory; verify against the
   Xcode 26 SDK.

---

## A. SwiftUI / Foundation file-access symbol map

Human doc path = `developer.apple.com/documentation/<framework>/<path>` (fetch via `sosumi.ai/...`).

| Symbol | Framework path | iOS floor (floors-master) |
|---|---|---|
| `fileImporter(...)` | `swiftui/view/fileimporter` | 14.0+ |
| `fileExporter(...)` | `swiftui/view/fileexporter` | 14.0+ |
| `PhotosPicker` / `PhotosPickerItem` | `photokit/photospicker` | 16.0+ |
| `UIDocumentPickerViewController` | `uikit/uidocumentpickerviewcontroller` | (UIKit) |
| `PHPickerViewController` | `photokitui/phpickerviewcontroller` | (UIKit) |
| `bookmarkData(options:...)` / `.withSecurityScope` | `foundation/url/bookmarkcreationoptions/withsecurityscope` | n/a (option) |
| `URL(resolvingBookmarkData:...)` | `foundation/url/init(resolvingbookmarkdata:options:relativeto:bookmarkdataisstale:)` | n/a |
| `startAccessingSecurityScopedResource()` | `foundation/url/startaccessingsecurityscopedresource()` | (ref-counted) |
| `Transferable` | `coretransferable/transferable` | 16.0+ |
| `.draggable(_:)` | `swiftui/view/draggable(_:)` | 16.0+ |
| `.dropDestination(for:isEnabled:action:)` | `swiftui/view/dropdestination(for:isenabled:action:)` | 16.0+ |

**Platform-wrong / smell (never emit as the iOS answer):** a raw `UIDocumentPickerViewController` /
`UIImagePickerController` / `PHPickerViewController` bridge where `fileImporter` / `PhotosPicker` fits
(whether-to-bridge → `audit-swiftui-uikit-overuse`); persisting a picked URL by `.path` or a plain
`bookmarkData()` (round-trips the path, not the scope). See
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.

## B. Photos/Files consent (dp-07 — owned by privacy-permissions)

Info.plist usage strings and the privacy manifest are read by hand and owned by
`audit-swiftui-privacy-permissions`. This skill flags the *use without a string*; the string itself is
verified there.

| Consent surface | Info.plist key (verify against Xcode 26 SDK) | Note |
|---|---|---|
| Photos library read (`PHPickerViewController`/`PHPhotoLibrary`) | `NSPhotoLibraryUsageDescription` | flagged dp-07 → privacy-permissions |
| Photos library add-only | `NSPhotoLibraryAddUsageDescription` | add-only variant |
| Camera (`UIImagePickerController` camera source) | `NSCameraUsageDescription` | flagged dp-07 → privacy-permissions |
| Document picker (`fileImporter`/`UIDocumentPickerViewController`) | **none** — the picker is the consent | no usage string required |

## C. Apple conceptual pages

| Page | Path | Anchors |
|---|---|---|
| Providing access to directories (security-scoped URLs) | `documentation/uikit/providing-access-to-directories` | the iOS security-scoped URL + `start/stopAccessing…` round-trip |
| Importing and exporting documents | `documentation/swiftui/importing-and-exporting-documents` | `fileImporter`/`fileExporter` SwiftUI flow |
| Selecting photos and videos in iOS | `documentation/photokit/selecting-photos-and-videos-in-ios` | `PhotosPicker`/`PHPickerViewController` consent |

## D. Practitioners (corroboration only — never primary; label `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Hacking with Swift | `hackingwithswift.com/example-code/system/how-to-use-security-scoped-bookmarks-to-access-the-file-system` | the `bookmarkData(options:.withSecurityScope)` ↔ `start/stopAccessing…` round-trip + stale re-create | high |
| r/swift (lived) | `reddit.com/r/swift/comments/1dk8ces/strict_concurrency_swift_6_causes/` | the Swift-6 `loadTransferable` `PhotosPickerItem` race + the `@Observable`-model fix (concurrency-safety owns) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- The practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16); floors cross-checked
  against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.
- Practitioner URLs as listed (trust labelled; corroboration only).
