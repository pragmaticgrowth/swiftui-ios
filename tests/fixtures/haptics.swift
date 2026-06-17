// haptics.swift — deliberate iOS haptics violations for the audit-swiftui-haptics grep tells.
// Each tell (hap-01..hap-04) must fire at least once. Target is iOS 17 (so .sensoryFeedback fits).
import SwiftUI
import UIKit

// hap-01 + hap-03 + hap-02: a raw UINotificationFeedbackGenerator, instantiated INLINE at the call site
// (re-created per call), fired with no .prepare() in scope — where .sensoryFeedback(.success, trigger:) fits.
struct DownloadButton: View {
    let installed: Bool
    var body: some View {
        Button("Install") { startInstall() }
            .onChange(of: installed) { _, done in            // hap-04 candidate event
                if done {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
    }
    func startInstall() {}
}

// hap-03 + hap-02 + hap-01: inline UIImpactFeedbackGenerator with style arg, fired with no .prepare().
struct LikeButton: View {
    var body: some View {
        Button("Like") {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// hap-04 + hap-01 + hap-03 + hap-02: haptic fired on a continuous drag — fires dozens of times per second.
struct DraggableCard: View {
    var body: some View {
        Color.blue
            .gesture(
                DragGesture().onChanged { _ in              // hap-04: high-frequency event
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            )
    }
}

// hap-04: a haptic fired from a GeometryReader-driven per-frame recompute (overuse).
struct ScrollMeter: View {
    var body: some View {
        GeometryReader { proxy in                            // hap-04: per-frame candidate
            Color.clear
                .onChange(of: proxy.size.height) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        }
    }
}
