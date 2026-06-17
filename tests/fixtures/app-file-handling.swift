import SwiftUI
import UniformTypeIdentifiers

// Deliberate iOS violations for audit-swiftui-app-file-handling (lint self-test fixture).
// Each tagged line corresponds to a rule_id in app-file-handling.expect.

// doc-02: a CLASS conforming to the value-type FileDocument protocol (should be ReferenceFileDocument).
final class NoteDocument: FileDocument {                       // doc-02
    static var readableContentTypes: [UTType] { [.plainText] } // doc-07 locator (no writableContentTypes)
    var text: String = ""

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents!      // doc-09: force-unwrap → data loss
        text = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

// doc-03: a ReferenceFileDocument with NO snapshot(contentType:) — does not satisfy the protocol.
final class CanvasDocument: ReferenceFileDocument, ObservableObject {  // doc-12 locator
    @Published var shapes: [String] = []
    static var readableContentTypes: [UTType] { [.json] }
    // MISSING: func snapshot(contentType:) throws -> [String]        // doc-03

    init(configuration: ReadConfiguration) throws {}
    func fileWrapper(snapshot: [String], configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data())
    }
}

struct ImportView: View {
    @State private var isImporterPresented = false
    // doc-01: @FocusedDocument is NOT a real symbol.
    @FocusedDocument var focused: NoteDocument?                  // doc-01

    var body: some View {
        Button("Import") { isImporterPresented = true }
            // doc-13: .fileImporter with NO allowedContentTypes → empty/locked picker.
            .fileImporter(isPresented: $isImporterPresented) { result in   // doc-13
                _ = result
            }
    }
}

@main struct AcmeApp: App {
    var body: some Scene {
        // doc-05: DocumentGroupLaunchScene is iOS 18.0+ — ungated above the iOS-17 floor.
        DocumentGroupLaunchScene {                               // doc-05
            Text("Launch")
        }
        DocumentGroup(newDocument: { NoteDocument() }) { file in
            Text(file.document.text)
        }
    }
}
