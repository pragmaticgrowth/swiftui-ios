import AppIntents
import SwiftUI

// Deliberate iOS App Intents violations for audit-swiftui-app-intents (lint self-test fixture).
// Floors: AppIntent / AppShortcutsProvider / @Parameter / AppShortcut — AppIntents framework, iOS 16.0+
// (below the iOS-17 deployment floor → no #available gate needed).

// ain-01: an AppIntent with NO `static var title: LocalizedStringResource` — the protocol requirement is
//          absent, so the intent has no Siri/Shortcuts display name (and does not compile as-is).
// ain-03: its @Parameter has NO `title:` — it renders as a blank field in the Shortcuts editor.
// ain-04: perform() touches view-model/UI state with no @MainActor on the intent nor a main-actor hop.
struct OpenNoteIntent: AppIntent {
    // MISSING: static var title: LocalizedStringResource = "Open Note"

    @Parameter var noteID: String                                      // ain-03 — no title:

    func perform() async throws -> some IntentResult {                 // ain-04 — off-actor UI work
        AppState.shared.selectedNote = noteID                          // mutates UI state off the main actor
        return .result()
    }
}

// ain-02: an AppShortcutsProvider whose AppShortcut carries an EMPTY `phrases` array — Siri and Spotlight
//          have nothing to match, so the action is undiscoverable by voice even though it builds.
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenNoteIntent(),
            phrases: [],                                               // ain-02 — empty phrases
            shortTitle: "Open Note",
            systemImageName: "note.text"
        )
    }
}

// ain-05: a legacy SiriKit IntentConfiguration / INIntent left unmigrated to the AppIntents framework.
struct LegacyWidgetConfig {
    // Pre-AppIntents: IntentConfiguration(kind:intent:) backed by a generated INIntent subclass.
    let configuration = "IntentConfiguration"                          // ain-05 — legacy token in source
    typealias Migrated = CustomIntentMigratedAppIntent                 // ain-05 — migration shim
}

@MainActor
final class AppState {
    static let shared = AppState()
    var selectedNote: String = ""
}
