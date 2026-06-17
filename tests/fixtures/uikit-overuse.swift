// Fixture for audit-swiftui-uikit-overuse — DELIBERATE iOS UIKit-OVERUSE violations.
// Each grep tell (over-01 … over-07) must fire at least once, plus the tier-2 ast-grep structural rule
// (over-01-makeuiview-builds-native-control: a makeUIView that CONSTRUCTS a 1:1-native control).
// This is the WHETHER-to-bridge audit: every bridge below has a native SwiftUI answer.
// This file does NOT need to compile.
import SwiftUI
import UIKit

// over-01 (warn) + tier-2 structural: a UIViewRepresentable wrapping a TRIVIAL UILabel.
// `Text("…")` is the native SwiftUI answer (iOS 13+) — this whole type is overuse.
struct TitleLabel: UIViewRepresentable {
    var title: String

    func makeUIView(context: Context) -> UILabel {   // builds a 1:1-native control → over-01
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .title2)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.text = title
    }
}

// over-01 (warn): a representable wrapping a plain UISwitch — `Toggle(_:isOn:)` is native (iOS 13+).
struct SyncSwitch: UIViewRepresentable {
    @Binding var isOn: Bool

    func makeUIView(context: Context) -> UISwitch {   // 1:1-native control → over-01 (and tier-2)
        let sw = UISwitch()
        sw.isOn = isOn
        return sw
    }

    func updateUIView(_ sw: UISwitch, context: Context) { sw.isOn = isOn }
}

struct OveruseScreen: View {
    @State private var isOn = false
    @State private var note = ""

    var body: some View {
        VStack {
            TitleLabel(title: "Settings")
            SyncSwitch(isOn: $isOn)

            // over-02 (warn): UIScreen.main.bounds read for layout — deprecated iOS 16+.
            // Use GeometryReader / containerRelativeFrame(_:) (iOS 17+) / horizontalSizeClass.
            Color.blue
                .frame(width: UIScreen.main.bounds.width * 0.8)

            // over-05 (warn): a bridged UIVisualEffectView for blur/glass — use .glassEffect (iOS 26)
            // or a Material (.ultraThinMaterial, iOS 15).
            BlurBackground()

            // over-04 (advisory): hand-packing UIPasteboard for a model type — PasteButton (iOS 16+)
            // or .copyable + Transferable is the native path.
            Button("Copy") { UIPasteboard.general.string = note }

            // over-07 (advisory): a UITextView bridge for plain text on an iOS-26 floor — the native
            // TextEditor(text:selection:) may remove it. (Below iOS 26 / true rich text it is justified.)
            PlainNotesEditor(text: $note)
        }
        // over-03 (warn): reaching UIApplication.shared.windows for the active scene — use scenePhase /
        // UIWindowScene via the scene delegate.
        .onAppear { _ = UIApplication.shared.windows.first?.safeAreaInsets }
    }
}

// over-05 (warn): UIVisualEffectView + UIBlurEffect bridged where SwiftUI glass/material fits.
struct BlurBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
    func updateUIView(_ view: UIVisualEffectView, context: Context) {}
}

// over-07 (advisory): a UITextView bridge holding plain text — flaggable at an iOS-26 floor.
struct PlainNotesEditor: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.text = text
        return tv
    }
    func updateUIView(_ tv: UITextView, context: Context) { tv.text = text }
}

// over-06 (advisory): a reverse bridge wrapping a whole screen in a SwiftUI-first app —
// a NavigationStack/WindowGroup scene removes the UIHostingController plumbing entirely.
final class LegacyContainer {
    func install() {
        let host = UIHostingController(rootView: OveruseScreen())
        _ = host
    }
}
