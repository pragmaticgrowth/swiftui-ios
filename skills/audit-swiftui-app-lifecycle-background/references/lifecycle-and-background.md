# Reference — App Lifecycle & Background Patterns (alb-01 … alb-07)

The defects that lose user state on suspension or never run scheduled background work: a scene that **never
saves on `.background`**, a background task **submitted without registration**, an **identifier missing from
the plist**, **`@SceneStorage` abused as a model store**, an unwired **`.backgroundTask` modifier**, a
**scene-event entry** with no load/intent routing, and an **over-reaching AppDelegate**. All are *flag-only*
(the fix is a judgment call: what to persist, where to register, which identifier the plist needs). Floors
live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** (`lookup --platform ios`) backed by a real iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK. iPad is modeled within `ios`.

> **Floor honesty.** `scenePhase` / `SceneStorage` / `onOpenURL` / `onContinueUserActivity` /
> `UIApplicationDelegateAdaptor` are **iOS 14.0**; `.backgroundTask` / `BackgroundTask` is **iOS 16.0**
> (confirmed via `swiftui-ctx lookup --platform ios`). `BGTaskScheduler`, `BGAppRefreshTaskRequest`,
> `BGProcessingTaskRequest` are the UIKit **BackgroundTasks** framework — **not in the SwiftUI catalog**, so
> swiftui-ctx returns exit 3. They shipped in iOS 13.0 (well known) but mark findings
> `availability: verify against Xcode 26 SDK`; never fabricate a catalog floor.

---

## alb-01 — a scene with mutable state and no `scenePhase` save on `.background` (warning, flag-only)

iOS suspends a backgrounded app and may terminate it without any further callback. If unsaved in-flight
state (a draft, edits, a counter) is only in memory, it is **lost** unless `scenePhase` transitioning to
`.background` drives a save. Nothing else fires that save.

```swift
// ❌ WRONG — draft lives only in @State; backgrounding the app loses it
struct ComposeView: View {
    @State private var draft = ""
    var body: some View {
        TextEditor(text: $draft)         // no scenePhase, no save — gone on suspension
    }
}
```
```swift
// ✅ CORRECT — read scenePhase and persist when the scene drops to .background
struct ComposeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft = ""
    var body: some View {
        TextEditor(text: $draft)
            .onChange(of: scenePhase) { _, phase in   // 2-param closure (iOS 17); 1-param is deprecated
                if phase == .background { saveDraft(draft) }   // the SAVE shape is swiftdata's domain
            }
    }
}
```

> **Seam.** The *trigger* (scenePhase → save) is this skill. The *save shape* (`modelContext.save()`,
> `@ModelActor`) is `audit-swiftui-swiftdata` — `cross_ref: swiftdata`. **Judge before flagging:** a
> read-only scene, or one whose every edit is already persisted synchronously, is not a defect.

## alb-02 — `BGTaskScheduler.submit` with no matching `register` (warning, flag-only)

`BGTaskScheduler.shared.submit(_:)` schedules a request whose identifier **must** have been registered at
launch with `register(forTaskWithIdentifier:using:launchHandler:)`. A `submit` with no `register` **throws**
(`unavailable` / launch handler not found) and the task never runs. `BGTaskScheduler` is UIKit
(BackgroundTasks) — `swiftui-ctx lookup BGTaskScheduler` returns exit 3, which is expected; the floor is
`verify against Xcode 26 SDK`.

```swift
// ❌ WRONG — submit with no register; throws at runtime, the task is never launched
func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = .now.addingTimeInterval(3600)
    try? BGTaskScheduler.shared.submit(request)      // no register(forTaskWithIdentifier:) anywhere
}
```
```swift
// ✅ CORRECT — register the handler at launch, THEN submit
@main
struct MyApp: App {
    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.app.refresh", using: nil) { task in
            handleRefresh(task as! BGAppRefreshTask)
        }
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = .now.addingTimeInterval(3600)
    try? BGTaskScheduler.shared.submit(request)
}
```

## alb-03 — `BG*TaskRequest` identifier not declared in the plist (warning, flag-only)

Every identifier passed to `BGAppRefreshTaskRequest` / `BGProcessingTaskRequest` must appear in `Info.plist`
under `BGTaskSchedulerPermittedIdentifiers`, and the matching background mode must be listed in
`UIBackgroundModes` (e.g. `fetch`, `processing`). An undeclared identifier is **rejected at register time**.

```xml
<!-- ✅ CORRECT — Info.plist declares the identifier and the mode -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array><string>com.app.refresh</string></array>
<key>UIBackgroundModes</key>
<array><string>fetch</string><string>processing</string></array>
```

> **Seam.** The wiring (identifier ↔ plist) is this skill; broader manifest/usage-string hygiene is
> `audit-swiftui-privacy-permissions` — `cross_ref` it. Mark `availability: verify against Xcode 26 SDK`.

## alb-04 — `@SceneStorage` holding large or non-UI model data (advisory, flag-only)

`@SceneStorage` (iOS 14.0) round-trips **small per-scene UI state** for restoration — a selected tab, a
search string, a serialized `NavigationPath`. It is keyed per scene and persisted by the system; stuffing
large blobs or the data model into it is wrong (slow restoration, scene-scoped duplication).

```swift
// ❌ WRONG — the data model serialized into per-scene UI storage
@SceneStorage("items") private var itemsJSON = ""     // model data does not belong in scene storage
```
```swift
// ✅ CORRECT — tiny UI state in @SceneStorage; the model lives in its own store
@SceneStorage("selectedTab") private var selectedTab = 0
@SceneStorage("navPath") private var navData = Data()   // serialized NavigationPath for restoration
// model data → SwiftData / a repository, observed via @Query or @Observable
```

> **Seam.** "Where should this state live" overlaps `audit-swiftui-state-observation` (`cross_ref`);
> `NavigationPath` restoration via `@SceneStorage` also touches `audit-swiftui-adaptive-navigation`.

## alb-05 — `.backgroundTask(.appRefresh`/`.urlSession)` modifier with no wiring (advisory, flag-only)

The SwiftUI scene modifier `.backgroundTask(_:action:)` (`BackgroundTask`, iOS 16.0) is the SwiftUI-native
way to handle background work, but it **still** requires the task identifier registered (for `.appRefresh`
the matching `BGAppRefreshTaskRequest` must be scheduled and the identifier declared in the plist) — the
modifier alone schedules nothing.

```swift
// ✅ CORRECT — the scene modifier handles the work; scheduling + plist declaration still required
WindowGroup { ContentView() }
    .backgroundTask(.appRefresh("com.app.refresh")) {
        await refreshData()
    }
// elsewhere: schedule a BGAppRefreshTaskRequest("com.app.refresh"); declare it in BGTaskSchedulerPermittedIdentifiers
```

## alb-06 — `onOpenURL` / `onContinueUserActivity` scene-event entry (advisory, flag-only)

`onOpenURL(perform:)` and `onContinueUserActivity(_:perform:)` (iOS 14.0) are the SwiftUI scene-lifecycle
entry points for deep links and Handoff. This skill owns that the **lifecycle wiring exists**; the load it
triggers and the intent behind it are siblings.

```swift
// ✅ CORRECT — the scene event resolves the route; the LOAD and the INTENT are routed to siblings
WindowGroup { ContentView() }
    .onOpenURL { url in
        router.resolve(url)                  // the actual fetch → audit-swiftui-async-data
    }                                        // a Shortcuts-exposed deep link → audit-swiftui-app-intents
```

> **Seam.** Load → `async-data`; deep-link-as-intent → `app-intents`. `cross_ref` both as relevant.

## alb-07 — `@UIApplicationDelegateAdaptor` overuse (advisory, flag-only)

`@UIApplicationDelegateAdaptor` (iOS 14.0) bridges a `UIApplicationDelegate` into the SwiftUI `App`. It is
correct for the few things SwiftUI lacks (remote-push registration, certain SDK initialization). It is
**overuse** when the adaptor handles lifecycle/background work that `scenePhase`, `.backgroundTask`, or
`onOpenURL` already express natively.

```swift
// ❌ WRONG — AppDelegate doing what scenePhase / onOpenURL already cover
class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) { saveEverything() }  // use scenePhase
    func application(_ app: UIApplication, open url: URL, options: ...) -> Bool { route(url); return true } // use onOpenURL
}
```
```swift
// ✅ CORRECT — keep the adaptor for the SwiftUI-less work only; lifecycle stays in SwiftUI
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken token: Data) { … }
}
@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { WindowGroup { ContentView() }.onOpenURL { router.resolve($0) } }
}
```

---

## Canonical exemplar — the wired lifecycle scene

```swift
@main
struct NotesApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = NoteStore()
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .onOpenURL { store.open($0) }                       // alb-06: scene-event entry
        }
        .onChange(of: scenePhase) { _, phase in                    // alb-01: save on .background
            if phase == .background { store.persist() }
        }
        .backgroundTask(.appRefresh("com.notes.sync")) {           // alb-05: registered + plist-declared
            await store.syncInBackground()
        }
    }
}
```

This is the consensus shape from `swiftui-ctx lookup scenePhase --platform ios` /
`lookup backgroundTask --platform ios` (the `(withName)` consensus shape, 76%); fetch a real iOS permalink
with `swiftui-ctx file <recommended.id> --smart` to cite in a finding's `## Source`.

---

## Sources

- `scenePhase` — `https://sosumi.ai/documentation/swiftui/environmentvalues/scenephase` (access 2026-06-16).
- `backgroundTask(_:action:)` — `https://sosumi.ai/documentation/swiftui/scene/backgroundtask(_:action:)`.
- `BGTaskScheduler` (UIKit BackgroundTasks) —
  `https://sosumi.ai/documentation/backgroundtasks/bgtaskscheduler` (floor verify against Xcode 26 SDK).
- Floors reconciled in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; practice corpus contract
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`; Sosumi fetch protocol
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
