// adaptive-layout.swift — DELIBERATE iOS adaptive-layout violations (adl-01 … adl-07).
// Each block is engineered so this skill's tier-1 grep tells fire. Shipped on a Universal
// (iPhone + iPad) target — so non-adaptive layout is a real defect, not a deliberate single design.
import SwiftUI

// adl-01 — full-screen content pinned to a literal iPhone width.
struct FixedWidthHero: View {
    var body: some View {
        VStack {
            Text("Welcome")
            Text("Full-screen hero content")
        }
        .frame(width: 393)          // adl-01: device-frozen; letter-boxes on iPad, clips in landscape
        .frame(maxHeight: .infinity)
    }
}

// adl-02 — UIScreen.main.bounds used as a layout-width oracle (deprecated iOS 16+).
struct ScreenBoundsLayout: View {
    var body: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { _ in
                Color.blue
                    .frame(width: UIScreen.main.bounds.width)   // adl-02 (also adl-06 fraction below)
            }
        }
    }
}

// adl-03 — NavigationSplitView with NO horizontalSizeClass branch anywhere in this file.
struct UnconditionalSplit: View {
    var body: some View {
        NavigationSplitView {       // adl-03: regular-width split shipped onto compact iPhone
            List(0..<5, id: \.self) { Text("Row \($0)") }
        } detail: {
            Text("Detail")
        }
    }
}

// adl-04 — device-dependent arrangement that READS the size class but only stores it (no branch).
struct ReadsButDoesNotBranch: View {
    @Environment(\.horizontalSizeClass) private var sizeClass   // adl-04: read present; confirm it branches
    var body: some View {
        // BUG: sizeClass is captured but the layout is the same HStack regardless.
        HStack {
            Sidebar()
            Content()
        }
    }
}

// adl-05 — manual width-threshold ladder where ViewThatFits is the idiom.
struct ManualWidthLadder: View {
    var body: some View {
        GeometryReader { geo in
            if geo.size.width > 600 {       // adl-05: mutually-exclusive fixed layouts → ViewThatFits
                HStack { Sidebar(); Content() }
            } else {
                VStack { Sidebar(); Content() }
            }
        }
    }
}

// adl-06 — fractional-of-screen width by arithmetic instead of containerRelativeFrame.
struct FractionalArithmetic: View {
    var body: some View {
        GeometryReader { proxy in
            Color.green
                .frame(width: proxy.size.width / 2)   // adl-06: use containerRelativeFrame (iOS 17)
        }
    }
}

// adl-07 — GeometryReader wrapped only to make a width-threshold decision.
struct GeometryForThreshold: View {
    var body: some View {
        GeometryReader { proxy in          // adl-07: this is a size-class decision, not real geometry
            Group {
                if proxy.size.width > 700 {
                    WideLayout()
                } else {
                    NarrowLayout()
                }
            }
        }
    }
}

private struct Sidebar: View { var body: some View { Text("Sidebar") } }
private struct Content: View { var body: some View { Text("Content") } }
private struct WideLayout: View { var body: some View { Text("Wide") } }
private struct NarrowLayout: View { var body: some View { Text("Narrow") } }
