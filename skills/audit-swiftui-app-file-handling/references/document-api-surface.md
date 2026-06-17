# Reference — The Real Document / File-Handling API Surface (iOS)

The allow-list of real SwiftUI document- and file-handling symbols, plus the one phantom this skill detects
(`@FocusedDocument`). This is the spine the other references cite. Per-platform floor *values* are not
restated here — they live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (the single source
of availability truth). This file carries the **signatures, the existence allow-list, and the
`@FocusedDocument` ❌→✅ rewrite**.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK.

---

## Why AI gets this wrong

The document API (`DocumentGroup`/`FileDocument`/`ReferenceFileDocument`) shipped at WWDC20 (iOS 14.0+) but
is thinly represented in training data — most SwiftUI sample code is single-screen, not document-based. The
sheet importers (`fileImporter`/`fileExporter`/`fileMover`, iOS 14.0+) are more common but AI often forgets
their required `allowedContentTypes`, or reaches for a raw `UIDocumentPickerViewController` bridge instead.
Three failure shapes:

1. **The value/reference confusion.** `FileDocument` is a **value** (struct) protocol; `ReferenceFileDocument`
   is a **reference** (class) protocol with extra requirements (`snapshot(contentType:)`). The model mixes
   them — a `class … : FileDocument` (doc-02) or a `ReferenceFileDocument` with no `snapshot` (doc-03).
2. **Invention by analogy.** SwiftUI has `@FocusedValue`, `@FocusedBinding`, `@FocusedObject` — so the model
   invents `@FocusedDocument` to read the focused document. **It does not exist.**
3. **UIKit reflex.** The model bridges `UIDocumentPickerViewController` / `UIDocument` (doc-04) where SwiftUI
   already offers `.fileImporter` / `DocumentGroup`.

---

## The real symbol allow-list (these exist on iOS)

Confirm any floor against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; verify any uncertain
symbol via Sosumi (`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`) and via `swiftui-ctx
lookup <api> --platform ios --json` (the practice corpus).

| Symbol | Role | Apple doc path (`/documentation/swiftui/…`) |
|---|---|---|
| `DocumentGroup` | the document scene; `(newDocument:)`/`(viewing:)`/`(editing:migrationPlan:)` | `documentgroup` |
| `FileDocument` | **value** document protocol (struct) | `filedocument` |
| `ReferenceFileDocument` | **reference** document protocol (class, `Sendable`) — requires `snapshot(contentType:)` | `referencefiledocument` |
| `FileDocumentConfiguration` | gives the `$document` **binding** + `fileURL` + `isEditable` | `filedocumentconfiguration` |
| `ReferenceFileDocumentConfiguration` | the reference-document equivalent | `referencefiledocumentconfiguration` |
| `static readableContentTypes: [UTType]` | the types the document can open | `filedocument/readablecontenttypes` |
| `static writableContentTypes: [UTType]` | the types the document can save | `filedocument/writablecontenttypes` |
| `init(configuration:)` | the read path | `filedocument/init(configuration:)` |
| `fileWrapper(configuration:)` | the write path (FileDocument) | `filedocument/filewrapper(configuration:)` |
| `fileWrapper(snapshot:configuration:)` | the write path (ReferenceFileDocument) | `referencefiledocument/filewrapper(snapshot:configuration:)` |
| `func snapshot(contentType:)` | reference-doc: capture a value to serialize off-main | `referencefiledocument/snapshot(contenttype:)` |
| `.fileImporter(isPresented:allowedContentTypes:…)` | the SwiftUI import sheet (iOS 14.0+) | `view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)` |
| `.fileExporter(…)` / `.fileMover(…)` | the SwiftUI export / move sheets (iOS 14.0+) | `view/fileexporter(...)` · `view/filemover(...)` |
| `FileWrapper` (Foundation) | the on-disk representation (regular file or directory) | (Foundation `filewrapper`) |
| `UTType(exportedAs:)` / `(importedAs:)` | a custom content type backed by an `Info.plist` declaration | (UniformTypeIdentifiers) |

`DocumentGroup`'s consensus call shape from the practice corpus (`swiftui-ctx lookup DocumentGroup
--platform ios`) is `(newDocument)` (100%), with `(newDocument:editor:)` as the `recommended` permalinked
example (`nathanfallet/ocaml` `OCamlApp.swift#L48`). To wire a focused-document command, use
`focusedSceneValue` / `focusedValue` / a custom `FocusedValues` key — see the `@FocusedDocument` rewrite
below.

**`DocumentGroupLaunchScene` is a real iOS API but iOS 18.0+** — above this toolkit's iOS-17 project floor,
so it must be availability-gated (doc-05; see `document-scene.md`).

---

## The phantom: `@FocusedDocument` (detect + replace)

`@FocusedDocument` is **not a real Apple symbol** (the canonical entry is in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`). A `swiftui-ctx lookup
FocusedDocument --platform ios` returns `ok:false`, `error.class: not_found` (with a did-you-mean
`suggestion`) — no shipping iOS app uses it. To expose the active document to menu/command surfaces, define a
custom `FocusedValues` key:

```swift
// ❌ phantom
@FocusedDocument var document: MyDocument?

// ✅ custom FocusedValues @Entry key (@Entry is iOS 14.0+ in floors-master; needs Xcode 16+/Swift 5.9+ to expand — confirm against floors-master.md)
extension FocusedValues {
    @Entry var focusedDocument: MyDocument?
}
// in the document view:
.focusedSceneValue(\.focusedDocument, document)
// in a command/menu body:
@FocusedValue(\.focusedDocument) private var document: MyDocument?
```

Confirm the `@Entry` floor against `floors-master.md` before annotating; pre-`@Entry` projects write the
explicit `FocusedValueKey` conformance instead.

---

## Detection tells (for DETECT; the deterministic version is `lint/grep-tells.tsv`)

- Phantom (doc-01): `@FocusedDocument`
- Value/reference confusion (doc-02): `class\s+\w+[^{]*:\s*[^{]*\bFileDocument\b`
- Importer with no allowed types (doc-13): `\.fileImporter\(` without an `allowedContentTypes:` argument

---

## Sources

- Apple — SwiftUI document-app symbol pages, fetched via Sosumi (access 2026-06-16):
  `https://developer.apple.com/documentation/swiftui/documentgroup`,
  `/documentation/swiftui/filedocument`, `/documentation/swiftui/referencefiledocument`,
  `/documentation/swiftui/filedocumentconfiguration`, `/documentation/swiftui/focusedvalues`,
  `/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)`.
- Apple — "Building a document-based app with SwiftUI"
  (`/documentation/swiftui/building-a-document-based-app-with-swiftui`), via Sosumi.
- WWDC20 — "Build document-based apps in SwiftUI" (`/videos/play/wwdc2020/10039`), via Sosumi.
- Practice corpus — `swiftui-ctx lookup DocumentGroup --platform ios` (consensus `(newDocument)`;
  `recommended` `ex_296b66f771` →
  `https://github.com/nathanfallet/ocaml/blob/871ea233cc2f5a07d6c59ac1c225d2c3f27315f3/Shared/OCamlApp.swift#L48`).
