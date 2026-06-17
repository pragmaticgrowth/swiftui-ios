import SwiftUI

// Deliberate iOS controls/forms violations for audit-swiftui-controls-forms (lint self-test fixture).
// Each tagged line is a tell the shared runner's grep tier (lint/grep-tells.tsv) must LOCATE.
// NOTE: an iOS Form is grouped by default — a missing .formStyle is NOT a defect here (inverted from macOS),
// and .pickerStyle(.wheel) is a NATIVE iOS control, never platform-wrong.

struct PaymentForm: View {
    @State private var amount = ""
    @State private var email = ""
    @State private var password = ""
    @State private var sort = 0

    var body: some View {
        VStack {
            // cf-01 — numeric field with no .keyboardType → full QWERTY for an amount
            // cf-03 — free-standing field (not in a Form/List) with no .textFieldStyle(.roundedBorder)
            TextField("Amount", text: $amount)

            // cf-02 — email field with no .textInputAutocapitalization(.never)/.autocorrectionDisabled()
            // cf-04 — multi-field form, no .submitLabel on the Return key
            TextField("Email", text: $email)

            SecureField("Password", text: $password)

            // cf-05 — a 3-option Picker left at the default style (wants .segmented)
            Picker("Sort", selection: $sort) {
                Text("Name").tag(0)
                Text("Date").tag(1)
                Text("Size").tag(2)
            }

            // cf-07 — a prominent action whose .controlSize density is questionable in this context
            Button("Pay") { }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
        }
    }
}

// cf-06 — a custom focus-taking View that uses TextFields but wires NONE of
// @FocusState / .focused / .onSubmit → the keyboard can't be advanced or dismissed.
struct LoginCard: View {
    @State private var user = ""
    @State private var pass = ""
    var body: some View {
        VStack {
            TextField("Username", text: $user)   // cf-01/cf-02/cf-03/cf-04 also locate here
            SecureField("Password", text: $pass)
        }
    }
}
