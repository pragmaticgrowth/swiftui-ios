// layout-and-tables.swift — DELIBERATE iOS layout/Table violations (lt-01 … lt-05).
// Each block is engineered so this skill's tier-1 grep tells + tier-2 ast-grep rules fire. Shipped on a
// Universal (iPhone + iPad) target — so a Table-as-primary-collection and a device-frozen frame are real
// iOS defects, not deliberate single-device designs. NOTE: this file intentionally NEVER branches on the
// SwiftUI width environment, so the file-level lt-01 ast-grep (Table present + no size-class branch) fires.
import SwiftUI

struct Person: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let notes: String
}

// lt-01 + lt-03 — Table as the SCREEN'S PRIMARY collection with no compact List fallback, AND no sortOrder.
// On iPhone (compact width) this Table collapses to one squished column; on iPad it can't even sort.
struct PeopleScreen: View {
    let people: [Person]
    var body: some View {
        Table(people) {                         // lt-01: primary Table, no size-class branch in file
            TableColumn("Name") { Text($0.name) }   // lt-03: no sort binding → non-sortable on iPad
            TableColumn("Age")  { Text("\($0.age)") }
            TableColumn("Notes") { Text($0.notes) }
        }
        .navigationTitle("People")
    }
}

// lt-02 — full-screen content pinned to a literal iPhone-logical width.
struct FixedWidthHero: View {
    var body: some View {
        VStack {
            Text("Welcome")
            Text("Full-screen hero content")
        }
        .frame(width: 393)              // lt-02: device-frozen; letter-boxes on iPad, clips in landscape
        .frame(maxHeight: .infinity)
    }
}

// lt-04 — blanket both-axis .fixedSize() on a container; freezes both axes, clips on a small iPhone screen.
struct OverflowingRow: View {
    let longTitle = "A very long title that wants to truncate gracefully"
    let subtitle = "subtitle"
    var body: some View {
        HStack {
            Text(longTitle)
            Spacer()
            Text(subtitle)
        }
        .fixedSize()                    // lt-04: both-axis fixedSize on a container — prefer layoutPriority
    }
}

// lt-05 — custom Layout conformance that just stacks two columns; Grid/HStack already does this.
struct TwoColumnLayout: Layout {        // lt-05: a built-in (Grid/ViewThatFits) covers this on iOS 16
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.minY), proposal: proposal)
            x += bounds.width / CGFloat(max(subviews.count, 1))
        }
    }
}

struct TwoColumnUsage: View {
    var body: some View {
        TwoColumnLayout {
            Text("Left")
            Text("Right")
        }
    }
}
