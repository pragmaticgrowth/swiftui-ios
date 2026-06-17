// Fixture for audit-swiftui-document-picker-permissions — DELIBERATE iOS file-consent violations.
// Each grep tell (dp-01 … dp-07) must fire at least once; the structural ast-grep rules
// (dp-03 start-without-stop, dp-05 itemprovider-in-onDrop) must also fire. This file does NOT compile.
import SwiftUI
import UIKit
import PhotosUI

struct ImportView: View {
    @State private var importing = false
    @State private var item: PhotosPickerItem?

    var body: some View {
        Text("Import")
            // dp-01 (warn): a PICKED, out-of-container URL read with NO startAccessingSecurityScopedResource().
            .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
                guard case let .success(url) = result else { return }
                let text = try? String(contentsOf: url, encoding: .utf8)   // dp-01: scope never entered
                _ = text
                persistBad(url)
            }
            // dp-05 (warn, structural): manual NSItemProvider loadObject INSIDE an .onDrop closure.
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in   // dp-05 grep + ast-grep
                providers.first?.loadObject(ofClass: URL.self) { url, _ in   // dp-05: off-main, isolation hazard
                    _ = url
                }
                return true
            }
            // dp-06 (warn): loadTransferable on a @MainActor-born PhotosPickerItem inside a nonisolated .task.
            .task {
                let data = try? await item?.loadTransferable(type: Data.self)   // dp-06: Swift-6 data race
                _ = data
            }
    }
}

// dp-02 (warn): a picked URL persisted by .path AND by a plain bookmarkData() with no .withSecurityScope.
func persistBad(_ url: URL) {
    UserDefaults.standard.set(url.path, forKey: "lastFile")            // dp-02: path string, scope gone
    UserDefaults.standard.set(try? url.bookmarkData(), forKey: "bm")   // dp-02: plain bookmark, NOT scoped
}

// dp-03 (warn, structural): startAccessingSecurityScopedResource() with NO balancing stop in this function.
func readLeaky(_ url: URL) throws -> String {
    _ = url.startAccessingSecurityScopedResource()   // dp-03: ignored Bool, no defer/stopAccessing… → leak
    return try String(contentsOf: url)               // dp-01 also: a picked URL read; never balanced
}

// dp-04 (adv): a raw UIDocumentPickerViewController bridge where SwiftUI fileImporter fits.
struct DocPicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {   // dp-04
        UIDocumentPickerViewController(forOpeningContentTypes: [.plainText])
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
}

// dp-07 (adv): a Photos/Camera API in use — VERIFY a matching Info.plist usage string exists.
struct LegacyCamera: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {   // dp-07 (+ dp-04 picker bridge)
        let picker = UIImagePickerController()
        picker.sourceType = .camera   // needs NSCameraUsageDescription in Info.plist (read by hand)
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
}
