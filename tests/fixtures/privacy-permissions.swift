// Fixture for audit-swiftui-privacy-permissions — DELIBERATE iOS privacy/permission violations.
// Each grep tell (pp-01 … pp-06) must fire at least once on the .swift side. The OTHER half of every
// finding lives in Info.plist + PrivacyInfo.xcprivacy (read by hand) — this fixture stands in for a
// project whose config files DECLARE NONE of these, so every .swift use below is an actual defect.
// This file does NOT compile.
import SwiftUI
import AVFoundation
import AppTrackingTransparency
import UserNotifications
import StoreKit
import Photos
import PhotosUI
import Contacts
import CoreLocation

struct CaptureView: View {
    @State private var item: PhotosPickerItem?
    @AppStorage("seenIntro") private var seenIntro = false   // pp-03: required-reason UserDefaults via @AppStorage

    var body: some View {
        Text("Capture")
            // pp-05 (adv): a universal-link entry with no apple-app-site-association / Associated Domains.
            .onOpenURL { url in
                _ = url   // pp-05: deep-link surface, no AASA declaration
            }
            // pp-02 (warn): a Photos API in use — needs NSPhotoLibraryUsageDescription in Info.plist.
            .photosPicker(isPresented: .constant(false), selection: $item)   // PhotosPicker
            .task {
                // pp-01 (hard): camera access with NO NSCameraUsageDescription → hard crash on first use.
                let granted = await AVCaptureDevice.requestAccess(for: .video)   // pp-01: camera, no usage string
                _ = granted
                // pp-01 also: microphone via AVAudioSession record permission, no NSMicrophoneUsageDescription.
                AVAudioSession.sharedInstance().requestRecordPermission { _ in }   // pp-01

                // pp-04 (hard): ATT with no NSUserTrackingUsageDescription / unfilled NSPrivacyTracking*.
                let status = await ATTrackingManager.requestTrackingAuthorization()   // pp-04: tracking, no string
                _ = status

                // pp-06 (adv): notification authorization request (confirm a registered delegate).
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])   // pp-06
            }
    }
}

// pp-01 (hard): contacts + location APIs with no NSContactsUsageDescription / NSLocationWhenInUseUsageDescription.
final class PermissionGate {
    let store = CNContactStore()                       // pp-01: contacts, no usage string
    let location = CLLocationManager()

    func ask() {
        store.requestAccess(for: .contacts) { _, _ in }            // pp-01
        location.requestWhenInUseAuthorization()                   // pp-01: location, no usage string
    }
}

// pp-01 (hard): a raw camera UIImagePickerController with no NSCameraUsageDescription.
struct LegacyCamera: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {   // pp-01
        let picker = UIImagePickerController()
        picker.sourceType = .camera   // needs NSCameraUsageDescription in Info.plist (read by hand)
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
}

// pp-03 (warn): required-reason API surface — raw UserDefaults + a disk-space query, no manifest entry.
func recordState() {
    UserDefaults.standard.set(true, forKey: "launched")   // pp-03: required-reason API, no NSPrivacyAccessedAPITypes
    let url = URL(fileURLWithPath: "/")
    let free = try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey])   // pp-03: disk space (required-reason)
    _ = free
}

// pp-06 (adv): a StoreKit 2 purchase with no Transaction.updates listener / unfinished transaction.
func buy(_ product: Product) async throws {
    let result = try await product.purchase()   // pp-06: no Transaction.updates listener wired
    _ = result
    // (no `for await update in Transaction.updates { ... transaction.finish() }` anywhere)
}
