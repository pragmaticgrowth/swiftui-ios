// Fixture for audit-swiftui-uikit-interop — DELIBERATE iOS UIKit-bridge violations.
// Each grep tell (uik-01 … uik-06) must fire at least once. This file does NOT need to compile.
import SwiftUI
import UIKit

// uik-01 (hard): UIViewRepresentable conformance with NO updateUIView body — state can never propagate.
struct CounterLabel: UIViewRepresentable {
    var count: Int

    func makeUIView(context: Context) -> UILabel {   // uik-02: input read here, must be re-applied in update
        let label = UILabel()
        label.text = "\(count)"
        return label
    }
    // BUG (uik-01): no updateUIView(_:context:) — `count` freezes at its initial value.
}

// uik-03 (hard): a delegate wired to context.coordinator with NO makeCoordinator() in the type.
struct PhotoPicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.delegate = context.coordinator   // uik-03: but makeCoordinator() is missing below
        return vc
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    // BUG (uik-03): no makeCoordinator() — context.coordinator is never our object, delegate is dead.
}

// uik-04 (warn): a Coordinator capturing its parent / self into a retained closure (cycle risk).
struct EditableField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.text = text
        field.becomeFirstResponder()   // uik-06: no-op — field isn't in the window yet
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EditableField   // uik-04: stored parent + closure capture below is the cycle risk
        init(_ parent: EditableField) {
            self.parent = parent     // uik-04
        }
    }
}

// uik-05 (adv): a UIHostingController embedded via bare addSubview — no addChild / didMove(toParent:).
final class LegacyContainerVC: UIViewController {
    func embedSwiftUI() {
        let hosting = UIHostingController(rootView: Text("Hello"))
        view.addSubview(hosting.view)   // uik-05: no addChild(hosting) / hosting.didMove(toParent:)
    }
}
