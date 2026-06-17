// safe-area-keyboard.swift — DELIBERATE iOS safe-area / keyboard violations (sak-01 … sak-05).
// Each block is engineered so this skill's tier-1 grep tells fire. Shipped on a notch / Dynamic-Island /
// home-indicator iPhone — so overlapping a system inset or trapping the keyboard is a real defect.
import SwiftUI

// sak-01 — blanket .ignoresSafeArea() on FOREGROUND content (no edges/regions argument).
struct BlanketIgnore: View {
    var body: some View {
        VStack {
            Text("Account").font(.largeTitle)   // runs under the Dynamic Island
            Text("Profile content")
        }
        .ignoresSafeArea()                       // sak-01: blanket; should scope or move to a background
    }
}

// sak-02 — a scrolling input Form with text fields and NO .scrollDismissesKeyboard.
struct TrappedKeyboardForm: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        Form {
            TextField("Name", text: $name)       // sak-02: input control in a scroll container
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
        }
        // BUG: no .scrollDismissesKeyboard(.interactive) — keyboard traps the lower fields.
    }
}

// sak-03 — a fixed bottom bar pinned with a bottom .overlay and NO safeAreaInset(edge: .bottom).
struct PinnedBottomBar: View {
    @State private var draft = ""
    var body: some View {
        ScrollView {
            ForEach(0..<20, id: \.self) { Text("Message \($0)") }
        }
        .overlay(alignment: .bottom) {           // sak-03: bottom bar overlaps the home indicator
            HStack {
                TextField("Message", text: $draft)
                Button("Send") {}
            }
            .padding()
            .background(.bar)
        }
    }
}

// sak-04 — the DEPRECATED .edgesIgnoringSafeArea (replaced iOS 14.0 by .ignoresSafeArea).
struct DeprecatedEdges: View {
    var body: some View {
        Image("hero")
            .resizable()
            .edgesIgnoringSafeArea(.all)         // sak-04: deprecated; replace with .ignoresSafeArea(edges:)
    }
}

// sak-05 — a hand-rolled keyboardWillShow observer instead of SwiftUI auto-avoidance.
struct ManualKeyboardAvoidance: View {
    @State private var name = ""
    @State private var keyboardHeight: CGFloat = 0
    var body: some View {
        Form {
            TextField("Name", text: $name)
        }
        .padding(.bottom, keyboardHeight)
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification)) { note in   // sak-05
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            keyboardHeight = frame?.height ?? 0
        }
    }
}
