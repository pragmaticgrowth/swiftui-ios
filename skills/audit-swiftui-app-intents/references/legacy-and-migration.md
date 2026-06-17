# Reference — Legacy SiriKit → AppIntents Migration (ain-05)

The migration rule for code still on the **pre-AppIntents** SiriKit surface. The AppIntents framework
(iOS 16) replaced the older `Intents`/SiriKit model — a codebase that still ships `INIntent` subclasses,
`IntentConfiguration(kind:intent:)` widget configs, or `INInteraction` donations is on legacy API and
should migrate. Floors per `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the legacy names
are **real-but-legacy** (not invented — do not treat them as hallucinations), per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## What ain-05 flags

| Legacy symbol | Framework | Migrate to (AppIntents, iOS 16) |
|---|---|---|
| `INIntent` (generated subclass) | Intents / SiriKit (iOS 10) | a struct conforming to `AppIntent` |
| `IntentConfiguration(kind:intent:provider:)` (WidgetKit) | WidgetKit + SiriKit Intents | `AppIntentConfiguration(kind:intent:provider:)` |
| `INInteraction` donation | Intents (iOS 10) | `AppShortcutsProvider` + `AppShortcut` phrases |
| `CustomIntentMigratedAppIntent` | AppIntents migration shim | the shim is the *bridge*; finish the migration to a native `AppIntent` |

`CustomIntentMigratedAppIntent` is Apple's own migration protocol — its presence means a
SiriKit-generated intent is being adapted, *not* that the migration is complete. Flag it as
"migration in progress; finish it" rather than a defect in itself.

---

## ❌ → ✅

```swift
// ❌ legacy SiriKit: a generated INIntent + an IntentConfiguration-backed widget
struct LegacyWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "OpenNote", intent: OpenNoteIntent.self, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
    }
}

// ✅ AppIntents (iOS 16): an AppIntent struct + AppIntentConfiguration
struct OpenNoteIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Open Note"
    @Parameter(title: "Note") var note: NoteEntity?
    func perform() async throws -> some IntentResult { .result() }
}

struct ModernWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "OpenNote", intent: OpenNoteIntent.self, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
    }
}
```

The `IntentConfiguration` → `AppIntentConfiguration` placement on a widget is the seam with
`audit-swiftui-widgets-live-activities`; flag the legacy intent shape here and `cross_ref` widgets when the
config lives on a `Widget`. The deprecation flag itself seams with `audit-swiftui-api-currency`.

---

## Sources

- `https://sosumi.ai/documentation/appintents` (the AppIntents framework, iOS 16.0+) and
  `https://sosumi.ai/documentation/widgetkit/appintentconfiguration` — fetched via Sosumi
  (`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`), access 2026-06-16.
- Floors cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; legacy-name
  status per `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`.
