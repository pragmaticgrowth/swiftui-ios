# Reference — App Intents & App Shortcuts (the discovery contract)

The full ❌→✅ rewrites for ain-01…ain-04: the required `static title`, the `AppShortcutsProvider`
`phrases`, the `@Parameter title`, and `perform()` actor-correctness. Floors are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (AppIntents core = **iOS 16.0+**, below the
iOS-17 deployment floor → **no `#available` gate needed**). The practice layer (consensus + permalinks)
is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`; fetch the canonical struct shape
with `swiftui-ctx recipe app-intent`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## The shape, from the corpus (not a placeholder)

`swiftui-ctx recipe app-intent` returns the canonical Siri-exposed intent — an `AppIntent` struct with a
`static var title`, `@Parameter` inputs, and an `AppShortcutsProvider` whose `AppShortcut` carries
spoken `phrases`:

```swift
struct OpenItemIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Item"   // ← required; the Siri/Shortcuts name
  @Parameter(title: "Item") var item: ItemEntity            // ← titled; the editor field label
  func perform() async throws -> some IntentResult {
    // navigate to item
    return .result()
  }
}

struct MyShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: OpenItemIntent(),
                phrases: ["Open \(\.$item) in MyApp"])      // ← non-empty; the ONLY Siri match surface
  }
}
```

The `swiftui-ctx lookup AppShortcut --platform ios` **recommended** real-world example (a non-empty
`phrases` array, the ain-02 ✅) is fullmoon-ios:

```swift
AppShortcut(
  intent: RequestLLMIntent(),
  phrases: [
    "Start a new chat",
    "Start a \(.applicationName) chat",
    "Chat with \(.applicationName)",
    "Ask \(.applicationName) a question"
  ],
  shortTitle: "new chat",
  systemImageName: "bubble"
)
// Source: https://github.com/mainframecomputer/fullmoon-ios/blob/cbc3c8206921afaa7fc4fe3dcdf790a18843226f/fullmoon/Models/RequestLLMIntent.swift#L91
```

Every finding's `## Source` carries the live `recommended` permalink for *its* API, fetched fresh via
`swiftui-ctx lookup <api> --platform ios` + `file <recommended.id> --smart` (SKILL.md step 7) — the block
above is the worked template, not the only citation.

---

## ain-01 — AppIntent with no `static var title`

`title` is a non-optional `AppIntent` protocol requirement *and* the action's display name everywhere the
system surfaces it (Siri, Spotlight, the Shortcuts app, the Action button). Its absence is a compile
error; a stub like `"Untitled"` hides a real label.

```swift
// ❌ no static title — the protocol requirement is missing; the intent is unnamed / non-compiling
struct OpenNoteIntent: AppIntent {
    @Parameter(title: "Note") var noteID: String
    func perform() async throws -> some IntentResult { .result() }
}

// ✅ declare the LocalizedStringResource title (iOS 16; no gate)
struct OpenNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Note"
    @Parameter(title: "Note") var noteID: String
    func perform() async throws -> some IntentResult { .result() }
}
```

`LocalizedStringResource` (Foundation, iOS 16) makes the title localizable — prefer it over a bare
`String`. Spec: `https://sosumi.ai/documentation/appintents/appintent` (`title` — iOS 16.0+).

---

## ain-02 — AppShortcutsProvider with empty / no `phrases`

`appShortcuts` is the bridge from an intent to **Siri / Spotlight**. An `AppShortcut`'s `phrases` array
is the *only* thing voice and Spotlight match a request against — an empty array compiles but leaves the
action undiscoverable by voice.

```swift
// ❌ empty phrases — builds, but Siri/Spotlight have nothing to match → the action is invisible
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenNoteIntent(), phrases: [])
    }
}

// ✅ non-empty phrases including the \(.applicationName) token (the corpus consensus shape)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenNoteIntent(),
            phrases: ["Open my note in \(.applicationName)", "Show note in \(.applicationName)"],
            shortTitle: "Open Note",
            systemImageName: "note.text"
        )
    }
}
```

Spec: `https://sosumi.ai/documentation/appintents/appshortcutsprovider` (iOS 16.0+) and
`https://sosumi.ai/documentation/appintents/appshortcut` (iOS 16.0+).

---

## ain-03 — `@Parameter` with no `title:`

The `@Parameter` `title` is the field label the user sees in the Shortcuts editor. With no `title:`, the
parameter renders unlabeled.

```swift
// ❌ untitled — blank field in the Shortcuts editor
@Parameter var noteID: String

// ✅ titled (a LocalizedStringResource label)
@Parameter(title: "Note") var noteID: String
```

Spec: `https://sosumi.ai/documentation/appintents/parameter` (iOS 16.0+).

---

## ain-04 — `perform()` doing UI work off the main actor (advisory)

`perform()` runs on the AppIntents framework's background executor. Touching UI / `@Observable` view-model
state from there is a runtime hazard — annotate the intent `@MainActor` (or hop explicitly).

```swift
// ❌ mutates UI state on the intent's background executor
func perform() async throws -> some IntentResult {
    AppState.shared.selectedNote = noteID
    return .result()
}

// ✅ make the intent main-actor-isolated so perform() and its UI writes run on the main actor
@MainActor
struct OpenNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Note"
    @Parameter(title: "Note") var noteID: String
    func perform() async throws -> some IntentResult {
        AppState.shared.selectedNote = noteID
        return .result()
    }
}
```

Carry as **advisory** — whether `perform()` truly touches main-actor state is a READ judgment; mark
`source: verify against Xcode 26 SDK` when the isolation requirement is not certain. This seams with
`audit-swiftui-concurrency-safety` for deeper isolation analysis.

---

## Sources

- `swiftui-ctx recipe app-intent` (the canonical struct shape) and
  `swiftui-ctx lookup AppShortcut --platform ios --json` (the fullmoon-ios permalink above), access
  2026-06-16; CLI contract `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- Apple docs fetched via `https://sosumi.ai/...` (paths in `references/source-directory.md`); floors
  cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (AppIntents = iOS 16).
- Sosumi fetch protocol: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
