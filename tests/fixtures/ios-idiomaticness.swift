import SwiftUI

// Deliberate iOS-idiom SMELLS for audit-swiftui-ios-idiomaticness (lint self-test fixture).
// Each violation is a candidate SITE the meta-scorer locates, READS, and ROUTES to an owner skill.

struct IdiomSmellsView: View {
    @State private var showSheet = false
    @State private var isHovered = false

    var body: some View {
        NavigationView {                                       // idi-01 — deprecated push shell
            VStack {
                Text("Card")
                    .onHover { isHovered = $0 }                // idi-02 — pointer-only affordance on touch surface
                    .frame(width: 390, height: 844)            // idi-03 — hard-coded full-screen device frame

                Table(rows) {                                  // idi-07 — multi-column grid, no compact fallback
                    TableColumn("Name", value: \.name)
                }

                Text("w=\(UIScreen.main.bounds.width)")        // idi-06 — UIScreen.main device metrics
            }
            .navigationBarTitle("Home")                        // idi-08 — deprecated title modifier
            .sheet(isPresented: $showSheet) {                  // idi-04 — modal, confirm detents/modality
                Text("no detents")
            }
        }
    }

    var rows: [Row] { [] }
}

struct RootTabs: View {
    var body: some View {
        TabView {                                              // idi-05 — confirm tabs are top-level peers
            IdiomSmellsView().tabItem { Label("One", systemImage: "1.circle") }
            IdiomSmellsView().tabItem { Label("Two", systemImage: "2.circle") }
        }
        .fullScreenCover(isPresented: .constant(false)) {      // idi-04 — fullScreenCover where a sheet may fit
            Text("cover")
        }
    }
}

struct WindowReach: View {
    var body: some View {
        // idi-09 — global window reach instead of a SwiftUI scene source
        let w = UIApplication.shared.windows.first
        return Text("\(String(describing: w))")
    }
}

struct Row: Identifiable { let id = UUID(); let name = "x" }
