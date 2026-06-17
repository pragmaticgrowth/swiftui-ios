// Fixture — DELIBERATE iOS presentation/sheet/modal violations for audit-swiftui-presentation-sheets-modals.
// Each block trips exactly one grep tell in ../../skills/audit-swiftui-presentation-sheets-modals/lint/grep-tells.tsv.
// Expected firing rule_ids: tests/fixtures/presentation-sheets-modals.expect
import SwiftUI

struct TaskListScreen: View {
    @State private var showDetail = false
    @State private var showConfirm = false
    @State private var showInfo = false
    @State private var showFilters = false
    let task: Task

    var body: some View {
        List {
            Text("Tasks")
        }
        // ❌ psm-01 — content-rich .sheet with NO .presentationDetents → locked full-height (pre-iOS-16 modal)
        .sheet(isPresented: $showDetail) {
            TaskDetailView(task: task)   // a scrollable detail card; no detents in the chain
        }
        // ❌ psm-03 — .fullScreenCover wrapping a trivial dismissible confirmation → wrong modality (use .sheet)
        .fullScreenCover(isPresented: $showConfirm) {
            ConfirmDeleteView()          // a one-button dialog forced into a full-screen cover
        }
        // ❌ psm-04 — .popover with NO .presentationCompactAdaptation → opaque full-screen cover on iPhone
        .popover(isPresented: $showInfo) {
            InfoCard()                   // no compact adaptation; collapses on compact width
        }
        // ❌ psm-02 — a detented sheet with NO .presentationDragIndicator(.visible) → missing grab handle
        .sheet(isPresented: $showFilters) {
            FiltersView()
                .presentationDetents([.medium, .large])   // detents but no drag indicator
        }
    }
}

struct ClearBackgroundSheet: View {
    @State private var show = false
    var body: some View {
        Color.gray
            // ❌ psm-05 — presentationBackground(.clear) with nothing behind it; sheet content floats
            .sheet(isPresented: $show) {
                OverlayCard()
                    .presentationBackground(.clear)
            }
    }
}

// Minimal stand-ins so the fixture parses.
struct Task { let id = UUID() }
struct TaskDetailView: View { let task: Task; var body: some View { Text("Detail") } }
struct ConfirmDeleteView: View { var body: some View { Text("Delete?") } }
struct InfoCard: View { var body: some View { Text("Info") } }
struct FiltersView: View { var body: some View { Text("Filters") } }
struct OverlayCard: View { var body: some View { Text("Overlay") } }
