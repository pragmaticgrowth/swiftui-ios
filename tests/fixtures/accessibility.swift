// accessibility.swift — DELIBERATE iOS accessibility violations (a11y-01 … a11y-12).
// Each block is engineered so this skill's tier-1 grep tells (and the tier-2 Chart rule) fire.
// Shipped on an iOS-17 universal target — so these omissions are real defects, not deliberate design.
import SwiftUI
import Charts

// a11y-10 — INVENTED accessibility APIs (hard-fail). None of these exist; swiftui-ctx lookup → exit 3.
struct InventedNames: View {
    var body: some View {
        VStack {
            Image(systemName: "gear")
                .voiceOverLabel("Settings")          // a11y-10: invented → .accessibilityLabel
            Image(systemName: "bell")
                .accessibilityText("Alerts")         // a11y-10: invented → .accessibilityLabel
            Text("Save")
                .a11yLabel("Save document")          // a11y-10: invented → .accessibilityLabel
        }
    }
}

// a11y-11 — LEGACY combined .accessibility(...) modifier (deprecated → split into per-aspect modifiers).
struct LegacyCombinator: View {
    var body: some View {
        Button { add() } label: { Image(systemName: "plus") }
            .accessibility(label: Text("Add"))       // a11y-11: legacy → .accessibilityLabel
            .accessibility(addTraits: .isButton)     // a11y-11: legacy → .accessibilityAddTraits
    }
    func add() {}
}

// a11y-01 — icon-only Button with NO .accessibilityLabel (VoiceOver reads "plus.circle" or nothing).
struct IconOnlyButton: View {
    var body: some View {
        HStack {
            Button { compose() } label: {
                Image(systemName: "square.and.pencil")   // a11y-01: sole content, no label anywhere
            }
            Button { delete() } label: {
                Label("Delete", systemImage: "trash")    // NOT a finding — visible text label
            }
        }
    }
    func compose() {}
    func delete() {}
}

// a11y-12 — icon-only tab items with NO .accessibilityShowsLargeContentViewer (unreadable at AX sizes).
struct IconOnlyTabs: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem { Image(systemName: "house") }        // a11y-12: icon-only, no large-content viewer
            Text("Profile")
                .tabItem { Image(systemName: "person.crop.circle") } // a11y-12: icon-only tab
        }
    }
}

// a11y-08 — custom gesture on a non-Button: VoiceOver has no trait AND cannot perform the gesture.
struct CustomGestureRow: View {
    @State private var done = false
    var body: some View {
        HStack {
            Text("Mark complete")
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
        }
        .onTapGesture { done.toggle() }   // a11y-08: no .accessibilityAddTraits/.accessibilityAction
        .swipeActions { Button("Archive") { archive() } } // a11y-08: custom swipe unreachable to VoiceOver
    }
    func archive() {}
}

// a11y-03 — composite List row that reads as four separate VoiceOver swipes (no grouping).
struct UngroupedRow: View {
    let name = "Folder"; let detail = "12 items"
    var body: some View {
        HStack {
            Image(systemName: "folder")
            VStack(alignment: .leading) { Text(name); Text(detail) }
            Spacer()
            Image(systemName: "chevron.right")
        }                                   // a11y-03: no .accessibilityElement(children: .combine)
    }
}

// a11y-04 — hand-rolled value control (star rating) with NO .accessibilityValue.
struct StarRating: View {
    let rating = 3
    var body: some View {
        HStack {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
            }
        }                                   // a11y-04: custom value control announces no value
        Slider(value: .constant(0.5))       // native — exposes value automatically (not a finding)
    }
}

// a11y-05 — connection state shown by COLOR ALONE (fails Differentiate-Without-Color).
struct StatusDot: View {
    let isOnline = true
    var body: some View {
        Circle()
            .fill(.green)                     // a11y-05: color-only status, no symbol/label fallback
            .foregroundColor(.red)            // a11y-05: error state by color alone
            .frame(width: 10, height: 10)
    }
}

// a11y-06 — animation that always runs, ignoring Reduce Motion.
struct PulsingBadge: View {
    @State private var pulse = false
    var body: some View {
        Circle()
            .scaleEffect(pulse ? 1.3 : 1.0)
            .onAppear {
                withAnimation(.easeInOut.repeatForever()) { pulse = true } // a11y-06: no accessibilityReduceMotion branch
            }
    }
}

// a11y-07 — Chart with NO accessibility representation (opaque blob to VoiceOver). Tier-2 structural rule.
struct SalesChart: View {
    let data = [("Jan", 10), ("Feb", 20), ("Mar", 15)]
    var body: some View {
        Chart {
            ForEach(data, id: \.0) { month, value in
                BarMark(x: .value("Month", month), y: .value("Sales", value))
            }
        }                                   // a11y-07: no .accessibilityChartDescriptor / per-mark a11y
    }
}

// a11y-09 — AccessibilityFocusState declared but NEVER driven (focus never moves on validation).
struct LoginForm: View {
    @AccessibilityFocusState private var focused: Bool   // a11y-09: declared but no .accessibilityFocused use
    @State private var email = ""
    var body: some View {
        Form {
            TextField("Email", text: $email)
        }
    }
}

// a11y-02 — purely-decorative image not hidden from VoiceOver (adds clutter).
struct DecorativeDivider: View {
    var body: some View {
        VStack {
            Text("Section")
            Image("sparkle-divider")        // a11y-02: decorative, should be .accessibilityHidden(true)
        }
    }
}
