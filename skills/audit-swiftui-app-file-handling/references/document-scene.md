# Reference — Document Scene Architecture (doc-04, doc-05, doc-11)

Depth for the scene layer: the right way to host a document app, the floor-gated launch scene, the
`fileImporter`-vs-raw-picker decision, and manual file IO that should be the document type's job. Floor
values are in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the iOS availability-gating rule
is `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. Verify via Sosumi + `swiftui-ctx`.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK.

---

## doc-04 — `UIDocument` / a raw `UIDocumentPickerViewController` does not belong in a SwiftUI app

A SwiftUI document app uses the **`DocumentGroup`** scene + `FileDocument`/`ReferenceFileDocument`, and a
SwiftUI file-import flow uses the **`.fileImporter` / `.fileExporter` / `.fileMover`** sheets. Reaching for
UIKit's `UIDocument` / `UIDocumentBrowserViewController`, or hand-bridging a
`UIDocumentPickerViewController` via `UIViewControllerRepresentable`, inside a SwiftUI lifecycle
(`@main struct App: App`) re-implements (and fights) the machinery SwiftUI already provides — the document
browser, open/import sheets, the recents list, autosave, the dirty state. **iOS has no `NSDocument` /
`NSDocumentController`** — those are AppKit-only; don't port them over. HOW a *justified* bridge is wired
(`makeUIViewController`/`Coordinator`) is owned by `audit-swiftui-uikit-interop`; emit doc-04 with
`cross_ref: uikit-interop`.

```swift
// ❌ doc-04 — a hand-bridged UIDocumentPickerViewController under a SwiftUI app
struct PickerBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController { … }
    func updateUIViewController(_: UIDocumentPickerViewController, context: Context) {}
}

// ✅ the SwiftUI sheet importer
.fileImporter(isPresented: $isPresented, allowedContentTypes: [.plainText]) { result in
    // handle the selected URL (consent/bookmark = document-picker-permissions)
}

// ✅ or a full document app
@main struct AcmeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { NoteDocument() }) { file in
            EditorView(document: file.$document)        // mutate via the binding (doc-10)
        }
    }
}
```

The canonical `DocumentGroup` shape from the practice corpus (`swiftui-ctx lookup DocumentGroup
--platform ios`, `recommended` `ex_296b66f771`) is `(newDocument:editor:)`, where the editor receives a
`FileDocumentConfiguration` exposing `file.$document` and `file.fileURL`.

---

## doc-05 — `DocumentGroupLaunchScene` is iOS 18.0+ — gate it above the project floor

`DocumentGroupLaunchScene` (the document-launch experience) **is a real iOS API** — but it was introduced in
**iOS 18.0** (confirm in `floors-master.md`: it sits in the iOS 18.0+ bucket; `swiftui-ctx lookup
DocumentGroupLaunchScene --platform ios` reports `introduced_ios: 18.0`). This toolkit's **project floor is
iOS 17**, so an **ungated** use won't compile/run on iOS 17 devices. This is **not** a "remove it" defect —
it is an availability-gating defect: wrap it in `if #available(iOS 18, *)` (or annotate the enclosing
declaration `@available(iOS 18, *)`) with a pre-18 fallback (a plain `DocumentGroup` already presents the
standard open/import flow). See `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. Emit doc-05 with
`cross_ref: app-lifecycle-background`.

```swift
// ❌ doc-05 — ungated on an iOS-17 floor
var body: some Scene {
    DocumentGroupLaunchScene { … }          // iOS 18.0+ symbol, no gate
    DocumentGroup(...) { … }
}

// ✅ gate it to its floor
var body: some Scene {
    if #available(iOS 18, *) {
        DocumentGroupLaunchScene { … }
    }
    DocumentGroup(...) { … }                 // pre-18 fallback: the standard launch flow
}
```

This is the document-domain instance of the toolkit's "floored scene API" trap: a scene type that exists on
iOS but above the project floor, distinct from a hallucinated name.

---

## doc-11 — manual file IO inside a document app

In a `DocumentGroup` app, opening/saving is the document type's responsibility (`init(configuration:)` /
`fileWrapper(...)`); in a non-document app, reaching files is `.fileImporter` / `.fileExporter`. Hand-rolled
`FileManager.default` reads/writes or `Data(contentsOf:)` invoked to load/save the *primary* document
duplicate that machinery and bypass autosave and security-scoped access. Equally, a `.fileImporter` whose
returned URL is read **without** consuming the security-scoped resource fails silently in a sandboxed app.
This is advisory (doc-11) — some manual IO is legitimate (writing into the app's own container, importing an
*auxiliary* asset). When the IO is for sandboxed user files (security-scoped URL,
`startAccessingSecurityScopedResource`, bookmark persistence), the correctness of that consent is owned by
`audit-swiftui-document-picker-permissions` — emit doc-11 with `cross_ref: document-picker-permissions`.
READ to confirm it is the primary document / a security-scoped URL before flagging.

---

## Sources

- Apple — fetched via Sosumi (access 2026-06-16):
  `https://developer.apple.com/documentation/swiftui/documentgroup`,
  `/documentation/swiftui/documentgrouplaunchscene`,
  `/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)`,
  `https://developer.apple.com/documentation/uikit/uidocument`.
- Apple — "Building a document-based app with SwiftUI"
  (`/documentation/swiftui/building-a-document-based-app-with-swiftui`), via Sosumi.
- Practice corpus — `swiftui-ctx lookup DocumentGroup --platform ios --json` (consensus `(newDocument)`;
  `recommended` `ex_296b66f771` →
  `https://github.com/nathanfallet/ocaml/blob/871ea233cc2f5a07d6c59ac1c225d2c3f27315f3/Shared/OCamlApp.swift#L48`);
  `swiftui-ctx lookup DocumentGroupLaunchScene --platform ios --json` (`introduced_ios: 18.0`).
