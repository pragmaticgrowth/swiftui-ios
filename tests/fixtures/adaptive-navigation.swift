import SwiftUI

// Deliberate violations for audit-swiftui-adaptive-navigation (lint self-test fixture, iOS).
// NOTE: .topBarLeading / .topBarTrailing are CORRECT on iOS — they are NOT flagged here.

struct OldNav: View {
    var body: some View {
        NavigationView {                                  // nav-01: deprecated → NavigationStack
            Text("detail")
                .navigationBarTitle("Title")              // nav-07: deprecated → navigationTitle
                .toolbar {
                    // deprecated placement spelling → .topBarLeading
                    ToolbarItem(placement: .navigationBarLeading) { EmptyView() }   // nav-06
                    // .topBarTrailing is CORRECT on iOS — present to prove it is NOT flagged
                    ToolbarItem(placement: .topBarTrailing) { Button("Add") {} }
                }
        }
    }
}

// Unconditional NavigationSplitView with no horizontalSizeClass / userInterfaceIdiom gate →
// collapses oddly on iPhone (nav-02). No size-class branch anywhere in this view.
struct RootShell: View {
    var body: some View {
        NavigationSplitView {                             // nav-02
            Text("sidebar")
        } detail: {
            Text("detail")
        }
    }
}
