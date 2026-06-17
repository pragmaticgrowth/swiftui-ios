import SwiftUI

// Deliberate violations for audit-swiftui-availability-gating (lint self-test fixture).
// Project deployment target is iOS 17 (the corpus floor). Every symbol used below whose iOS floor
// is > 17 must be gated on the iOS arm at the correct floor — these are deliberately wrong.

struct GatingViolations: View {
    @State private var amount = 0.0

    var body: some View {
        VStack {
            // gate-01: glassEffect is iOS 26.0+ used with NO #available gate under an iOS-17 target.
            Text("Glass")
                .padding()
                .glassEffect(in: .capsule)                      // gate-01

            // gate-01: MeshGradient is iOS 18.0+, ungated under an iOS-17 target.
            MeshGradient(                                       // gate-01
                width: 2, height: 2,
                points: [[0, 0], [1, 0], [0, 1], [1, 1]],
                colors: [.red, .blue, .green, .yellow]
            )
            .frame(height: 80)

            // gate-02: WRONG ARM. backgroundExtensionEffect is iOS 26.0+ but gated on the macOS arm —
            // on iPhone/iPad the macOS arm never enforces the iOS floor (dead branch / compile error).
            if #available(macOS 26.0, *) {                      // gate-02 (fix: swap to iOS 26.0)
                Color.clear.backgroundExtensionEffect()
            }

            // gate-03: FLOOR MISMATCH. scrollEdgeEffectStyle is iOS 26.0+ but gated at iOS 18 (under-gate
            // → still breaks on 18-25). gate-04 lives here too: no else fallback for the gated surface.
            if #available(iOS 18.0, *) {                        // gate-03 (floor should be 26.0)
                ScrollView { Text("edge") }
                    .scrollEdgeEffectStyle(.soft, for: .top)
            }

            // gate-07: MISSING WILDCARD. navigationSubtitle is iOS 26.0+; the gate omits the `, *`
            // (compile error) — and the arm is correct, only the wildcard is missing.
            if #available(iOS 26.0) {                           // gate-07 (append , *)
                Text("Detail").navigationSubtitle("subtitle")
            }
        }
    }
}

// gate-06: iOS-ABSENT symbol wrapped in an iOS gate. NSViewRepresentable is an AppKit bridge with NO
// iOS arm — it can never resolve on iPhone/iPad. Replace with UIViewRepresentable, do NOT gate it.
@available(iOS 17.0, *)
struct LegacyBridge: View {
    var body: some View {
        if #available(iOS 26.0, *) {                           // gate-06 (absent symbol in the body)
            NSViewRepresentableWrapper()
        }
    }
}
