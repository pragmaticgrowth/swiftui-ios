# Reference — Source Directory (VERIFY step)

The Apple/WWDC/practitioner source map for this domain, fetched via **Sosumi** (`curl -sSL
https://sosumi.ai/<apple-path>`; protocol in `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`
— never `WebFetch` `developer.apple.com`). Paired with the practice corpus via `swiftui-ctx lookup <api>
--platform ios --json` (`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`). Use this to
resolve a ≤70%-confidence finding in step 5.

**As of:** 2026-06-16 · iOS 26.

---

## Apple primary docs (per defect)

| Defect | Apple path (prefix `https://developer.apple.com`) |
|---|---|
| doc-01 (`@FocusedDocument`) | `/documentation/swiftui/focusedvalues` · `/documentation/swiftui/focusedvalue` · `/documentation/swiftui/view/focusedscenevalue(_:_:)` |
| doc-02/03 (value vs reference) | `/documentation/swiftui/filedocument` · `/documentation/swiftui/referencefiledocument` · `/documentation/swiftui/referencefiledocument/snapshot(contenttype:)` |
| doc-04 (UIDocument / raw picker) | `/documentation/swiftui/documentgroup` · `/documentation/uikit/uidocument` · `/documentation/uikit/uidocumentpickerviewcontroller` |
| doc-05 (launch scene, iOS 18 floor) | `/documentation/swiftui/documentgrouplaunchscene` |
| doc-06/07/13 (content types) | `/documentation/swiftui/filedocument/readablecontenttypes` · `/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)` · `/documentation/uniformtypeidentifiers/uttype` · `/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app` |
| doc-08 (MainActor serialization) | `/documentation/swiftui/building-a-document-based-app-with-swiftui` |
| doc-09 (FileWrapper) | `/documentation/foundation/filewrapper` |
| doc-10 (binding) | `/documentation/swiftui/filedocumentconfiguration` |
| doc-11 (manual IO / importer URL) | `/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)` · `/documentation/foundation/url/startaccessingsecurityscopedresource()` |
| doc-12 (undo) | `/documentation/swiftui/environmentvalues/undomanager` |

## WWDC

- WWDC20 — "Build document-based apps in SwiftUI" (`/videos/play/wwdc2020/10039`).
- WWDC24 — document-launch / `DocumentGroupLaunchScene` notes (cross-check the iOS-18 floor), via Sosumi.

## Practice corpus (swiftui-ctx)

- `swiftui-ctx lookup DocumentGroup --platform ios --json` — consensus call shape + `recommended` permalink.
- `swiftui-ctx lookup fileImporter --platform ios --json` — the importer consensus shape (every shape carries
  `allowedContentTypes`).
- `swiftui-ctx lookup UTType --platform ios --json` — real custom-type call sites.
- `swiftui-ctx lookup FocusedDocument --platform ios --json` — returns `not_found` (corroborates the doc-01
  hallucination).
- `swiftui-ctx lookup DocumentGroupLaunchScene --platform ios --json` — reports `introduced_ios: 18.0`
  (corroborates the doc-05 floor gate).
- `swiftui-ctx file <recommended.id> --smart` — fetch the full enclosing view for the ✅ in `## Source`.

---

## Sources

This file is a routing index; every path above resolves to an Apple primary doc fetched via Sosumi (access
2026-06-16). No private or non-Apple URLs.
