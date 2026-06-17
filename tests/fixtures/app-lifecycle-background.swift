// Fixture — deliberate iOS app-lifecycle & background violations (alb-01 … alb-07).
// Each grep tell in lint/grep-tells.tsv must fire at least once here. AUDIT-ONLY target; do not "fix".
import SwiftUI
import BackgroundTasks

// alb-01 — a scene reads @Environment(\.scenePhase) but NEVER saves on .background.
// The grep tell fires on the scenePhase read; READ confirms there is no onChange(of: scenePhase) save.
struct ComposeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft = ""              // mutable in-flight state, lost on suspension
    var body: some View {
        TextEditor(text: $draft)               // no .onChange(of: scenePhase) save → alb-01
    }
}

// alb-02 — BGTaskScheduler.submit with NO matching register(forTaskWithIdentifier:) anywhere.
// alb-03 — the BGAppRefreshTaskRequest identifier "com.fixture.refresh" is NOT in Info.plist
//           BGTaskSchedulerPermittedIdentifiers / UIBackgroundModes.
func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.fixture.refresh")  // alb-03 (undeclared)
    request.earliestBeginDate = Date().addingTimeInterval(3600)
    try? BGTaskScheduler.shared.submit(request)   // alb-02 (no register call) — throws at runtime
}

// alb-03 also covers BGProcessingTaskRequest identifiers with no plist declaration.
func scheduleHeavyWork() {
    let request = BGProcessingTaskRequest(identifier: "com.fixture.process")  // alb-03 (undeclared)
    try? BGTaskScheduler.shared.submit(request)
}

// alb-04 — @SceneStorage abused to hold large / non-UI model data (a serialized model blob).
struct LibraryView: View {
    @SceneStorage("itemsJSON") private var itemsJSON = ""   // model data does not belong here → alb-04
    var body: some View { Text(itemsJSON) }
}

@main
struct FixtureApp: App {
    // alb-07 — AppDelegate adaptor doing lifecycle work scenePhase / onOpenURL already cover.
    @UIApplicationDelegateAdaptor(FixtureAppDelegate.self) var delegate   // alb-07

    var body: some Scene {
        WindowGroup {
            ContentView()
                // alb-06 — scene-event entry; confirm the load/intent is routed: async-data / app-intents.
                // KEEP the trailing-closure form below: it is the dominant real-world onOpenURL usage and
                // is the regression guard for the alb-06 ERE. A paren-only tell would MISS the closure form,
                // so do NOT rewrite this to the perform: argument form — that would re-mask the false-negative.
                .onOpenURL { url in route(url) }                          // alb-06 trailing closure
                .onContinueUserActivity("com.fixture.activity") { _ in }  // alb-06
        }
        // alb-05 — .backgroundTask(.appRefresh) modifier with no registration / plist declaration in scope.
        .backgroundTask(.appRefresh("com.fixture.refresh")) {             // alb-05
            await refreshData()
        }
    }
}

// alb-07 — the over-reaching AppDelegate body: lifecycle/background work SwiftUI already expresses.
class FixtureAppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveEverything()        // should be a scenePhase == .background save (alb-01/alb-07)
    }
}

func route(_ url: URL) {}
func refreshData() async {}
func saveEverything() {}
struct ContentView: View { var body: some View { Text("Hi") } }
