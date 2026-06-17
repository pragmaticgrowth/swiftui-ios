import SwiftUI

// Deliberate iOS touch-gesture violations for audit-swiftui-touch-gestures (lint self-test fixture).

// tg-01 / tg-02: deprecated pinch & rotate gestures (→ MagnifyGesture / RotateGesture, iOS 17).
struct ZoomView: View {
    @GestureState private var scale: CGFloat = 1
    @GestureState private var angle: Angle = .zero
    var body: some View {
        Image("photo")
            .gesture(MagnificationGesture().updating($scale) { v, s, _ in s = v })   // tg-01
            .gesture(RotationGesture().updating($angle) { v, s, _ in s = v })          // tg-02
    }
}

// tg-03: a continuous DragGesture with NO @GestureState / committed @State — the in-flight value is lost.
struct DeadDragView: View {
    var body: some View {
        Rectangle()
            .frame(width: 80, height: 80)
            .gesture(DragGesture())                                                    // tg-03
    }
}

// tg-05: a pointer-only affordance (.onHover) as the ONLY interaction — dead under a finger on iPhone.
struct HoverOnlyRow: View {
    @State private var highlighted = false
    var body: some View {
        Text("Open")
            .background(highlighted ? Color.accentColor.opacity(0.15) : .clear)
            .onHover { highlighted = $0 }                                             // tg-05
    }
}

// tg-06: a bare onTapGesture on a plain view with NO .accessibilityAction — unreachable by VoiceOver.
struct TapCard: View {
    let open: () -> Void
    var body: some View {
        VStack { Text("Card") }
            .onTapGesture { open() }                                                  // tg-06
    }
}

// tg-08: pointerStyle has NO iOS arm (macOS/visionOS only) — platform-wrong on iOS.
struct DragHandle: View {
    var body: some View {
        Capsule()
            .frame(width: 8, height: 40)
            .pointerStyle(.grabIdle)                                                  // tg-08
    }
}
