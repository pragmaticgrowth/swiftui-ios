# App Lifecycle, Scene Phase & Background (iOS)

> **iOS-only.** This domain absorbs the old macOS scenes/windows + menu-bar concerns into the iOS scene
> model. iOS apps **suspend and terminate** — unsaved state is lost at suspension unless `scenePhase`
> drives a save; a background task must be **registered before** it can be submitted (and declared in the
> plist); `@SceneStorage` is for small per-scene UI restoration, not the data model. macOS appears only
> as a ❌ contrast. There is **no `Settings {}` scene, no `MenuBarExtra`, no `.commands {}` menu bar on
> iOS** — the iOS equivalents are an in-app `Form`/`@AppStorage` settings screen, `contextMenu`, `Menu`,
> and App Intents.

The training corpus is overwhelmingly one-shot SwiftUI views that launch, render, and never get
suspended — so AI never learns that iOS *will* background and terminate the app. The result compiles and
looks correct in the preview but silently drops edits on every background, never runs its background
refresh, and fails state restoration.

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain.** Cross-checked against `references/api-currency.md`.

---

## The iOS scene vocabulary

- **`WindowGroup { RootView() }`** (iOS 14.0+) — the standard app scene. `@main struct App: App`.
- **`@Environment(\.scenePhase) var scenePhase`** — `.active` / `.inactive` / `.background`. The save
  trigger.
- **`@SceneStorage("key") var x`** (iOS 14.0+) — small per-scene UI restoration state (selected tab,
  search text, the current `NavigationPath` codable). **Not** the data model.
- **`.backgroundTask(.appRefresh("id")) { … }`** (iOS 16.0+) / `BGTaskScheduler` — background work; the
  `id` must be declared in `Info.plist` `BGTaskSchedulerPermittedIdentifiers` and `UIBackgroundModes`.
- **`.onOpenURL { url in … }`** (iOS 14.0+) / **`.onContinueUserActivity(_:perform:)`** — deep-link /
  Handoff entry points.
- **`@UIApplicationDelegateAdaptor`** (iOS 14.0+) — only for what `scenePhase`/`.backgroundTask` can't
  cover (push registration, third-party SDK init).

---

## The mistakes (❌ WRONG → ✅ CORRECT)

### 1. A scene with mutable state and no `scenePhase` save on `.background`

iOS suspends — and can terminate — the app at any time. An edit a user just made is lost unless a
`scenePhase` change to `.background` triggers a save.

❌ **WRONG** — mutable in-flight state, nothing wired to suspension:
```swift
@main struct DraftApp: App {
    @State private var draft = Draft()
    var body: some Scene { WindowGroup { EditorView(draft: draft) } }  // ❌ edits lost on suspend
}
```
✅ **CORRECT** — save when the scene goes to `.background`:
```swift
@main struct DraftApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft = Draft()
    var body: some Scene {
        WindowGroup { EditorView(draft: draft) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { draft.save() }   // ✅ persist before suspension
            }
    }
}
```
> The save *trigger* is this domain; the save *itself* (a SwiftData `modelContext.save()`, an
> `@ModelActor` write) is `swiftdata.md`.

### 2. `BGTaskScheduler.submit` with no matching `register(...)` (and no plist declaration)

A background task must be **registered at launch before** it can be submitted, and its identifier must be
declared in the plist — otherwise it silently never runs.

❌ **WRONG** — submit with no register, no plist entry:
```swift
BGTaskScheduler.shared.submit(BGAppRefreshTaskRequest(identifier: "com.x.refresh"))  // ❌ never fires
```
✅ **CORRECT** — register at launch, submit later, declare in `Info.plist`:
```swift
// register once at launch:
BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.x.refresh", using: nil) { task in
    handleRefresh(task as! BGAppRefreshTask)
}
// or, SwiftUI-native, the scene modifier (iOS 16.0+):
WindowGroup { RootView() }
    .backgroundTask(.appRefresh("com.x.refresh")) { await refresh() }
// Info.plist: BGTaskSchedulerPermittedIdentifiers = ["com.x.refresh"]; UIBackgroundModes ⊇ ["fetch"]
```

### 3. `@SceneStorage` holding large or non-UI model data

`@SceneStorage` is small per-scene UI restoration — a selected tab, a search string, a codable
`NavigationPath`. Stuffing the data model into it bloats restoration and is the wrong tool.

❌ **WRONG** — model array in scene storage:
```swift
@SceneStorage("items") private var itemsJSON: String = ""   // ❌ the data model belongs in SwiftData
```
✅ **CORRECT** — UI restoration state only:
```swift
@SceneStorage("selectedTab") private var selectedTab: AppTab = .home   // ✅ small UI state
@SceneStorage("searchText") private var searchText: String = ""
```

### 4. An `@UIApplicationDelegateAdaptor` doing work `scenePhase`/`.backgroundTask` already covers

Reaching for an AppDelegate to detect background/foreground or run refresh is the UIKit-era habit;
`scenePhase` and `.backgroundTask` are the SwiftUI answers. Keep the delegate for what only it can do
(push-notification registration, certain SDK init).

❌ **WRONG** — AppDelegate `applicationDidEnterBackground` to save:
```swift
func applicationDidEnterBackground(_ application: UIApplication) { Store.shared.save() }  // ❌ use scenePhase
```
✅ **CORRECT** — `scenePhase` for lifecycle; delegate only for push:
```swift
@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(PushDelegate.self) var pushDelegate   // ✅ only push registration
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene { WindowGroup { RootView() }.onChange(of: scenePhase) { /* save */ } }
}
```

### 5. A deep link / Handoff with no scene entry point

A URL the app should open (or a Handoff `NSUserActivity`) needs `.onOpenURL` / `.onContinueUserActivity`
on the scene — not a custom URL parser bolted onto a view.

✅ **CORRECT**:
```swift
WindowGroup { RootView() }
    .onOpenURL { url in router.handle(url) }                       // deep link
    .onContinueUserActivity("com.x.detail") { activity in router.restore(activity) }   // Handoff
```
> The *data load* a URL/activity kicks off is `async-data` (`.task`); the *intent* behind a deep link
> (an `OpenIntent` / Shortcuts-exposed `AppIntent`) is the App-Intents concern — cross-ref, don't
> reimplement here.

### 6. Faking a "menu" with an in-window button list — iOS has `contextMenu` / `Menu` / App Intents

There is **no macOS-style menu bar** on iOS. The iOS vocabulary is: `Menu { … }` (a pull-down button),
`.contextMenu { … }` (long-press / right-click on a row), `.swipeActions` on a `List` row, and
**App Intents** to expose an action to Shortcuts / Spotlight / the Action button. Don't port
`.commands {}` / `CommandMenu` — they don't exist on iOS.

❌ **WRONG (macOS port)** — a `.commands {}` / `MenuBarExtra` on an iOS scene → won't compile.
✅ **CORRECT** — the iOS surfaces:
```swift
Menu("Add", systemImage: "plus") { Button("Photo") {}; Button("Note") {} }   // pull-down (iOS 14+)
RowView(item: item)
    .contextMenu { Button("Delete", role: .destructive) { delete(item) } }    // long-press (iOS 13+)
    .swipeActions { Button("Archive") { archive(item) } }                     // list swipe
// expose to Shortcuts/Spotlight/Action button:
struct AddNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Note"
    func perform() async throws -> some IntentResult { /* … */ .result() }
}
```

---

## Detection tells

- A scene with mutable `@State`/`@Bindable` model and **no** `onChange(of: scenePhase)` save on
  `.background` (mistake 1).
- `BGTaskScheduler.shared.submit(` with no `register(forTaskWithIdentifier:` and/or no
  `BGTaskSchedulerPermittedIdentifiers` plist entry (mistake 2).
- `@SceneStorage` holding JSON / an array / model data instead of small UI state (mistake 3).
- `applicationDidEnterBackground` / `applicationWillResignActive` doing lifecycle work `scenePhase`
  covers (mistake 4).
- A view-level URL parser with no `.onOpenURL` / `.onContinueUserActivity` on the scene (mistake 5).
- `.commands {`, `MenuBarExtra`, `Settings {`, `CommandMenu`, `CommandGroup` in an iOS target →
  macOS-only, won't compile; the iOS answer is `Menu` / `.contextMenu` / `.swipeActions` / App Intents
  (mistake 6).

---

## Canonical pattern

```swift
@main
struct NotesApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .onOpenURL { store.open($0) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { store.save() }                 // persist before suspension
        }
        .backgroundTask(.appRefresh("com.x.sync")) { await store.sync() }   // declared in Info.plist
    }
}
```

**Rules:** (1) Save on `onChange(of: scenePhase)` to `.background` — iOS suspends/terminates. (2) Register
a background task before submitting it and declare its id in `Info.plist`; prefer `.backgroundTask`. (3)
`@SceneStorage` = small per-scene UI restoration only, never the model. (4) Use the AppDelegate adaptor
only for what `scenePhase`/`.backgroundTask` can't do. (5) Wire deep links / Handoff with
`.onOpenURL` / `.onContinueUserActivity` on the scene. (6) iOS has no menu bar — use `Menu`,
`.contextMenu`, `.swipeActions`, and App Intents.

---

## Availability table

| API | Min iOS | Note |
|---|---|---|
| `WindowGroup` | iOS 14.0+ | the standard app scene |
| `scenePhase` (env) / `ScenePhase` | iOS 14.0+ | `.active` / `.inactive` / `.background` |
| `SceneStorage` | iOS 14.0+ | small per-scene UI restoration |
| `backgroundTask(_:action:)` | iOS 16.0+ | scene modifier; pairs with `BGTaskScheduler` register + plist |
| `onOpenURL(perform:)` | iOS 14.0+ | deep-link entry point |
| `onContinueUserActivity(_:perform:)` | iOS 14.0+ | Handoff / `NSUserActivity` |
| `UIApplicationDelegateAdaptor` | iOS 14.0+ | bridge to an `UIApplicationDelegate` |
| `Menu` | iOS 14.0+ | pull-down menu button |
| `contextMenu(menuItems:)` | iOS 13.0+ | long-press context menu |

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/scenephase | `ScenePhase` `.active`/`.inactive`/`.background`; the lifecycle environment value — iOS 14.0+ | high |
| https://developer.apple.com/documentation/swiftui/scenestorage | *"reads and writes to persisted, per-scene storage"* — iOS 14.0+ | high |
| https://developer.apple.com/documentation/swiftui/scene/backgroundtask(_:action:) | scene background-task modifier — iOS 16.0+ | high |
| https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler | register before submit; `BGTaskSchedulerPermittedIdentifiers` plist requirement | high |
| https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:) | deep-link scene entry — iOS 14.0+ | high |
| https://developer.apple.com/documentation/swiftui/uiapplicationdelegateadaptor | bridge to `UIApplicationDelegate` — iOS 14.0+ | high |
| https://developer.apple.com/documentation/appintents/appintent | App Intents expose actions to Shortcuts / Spotlight / the Action button | high |
