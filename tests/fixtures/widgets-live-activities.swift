// widgets-live-activities.swift — deliberate iOS WidgetKit / ActivityKit / Controls violations.
// Each flat grep tell in lint/grep-tells.tsv (wla-01..wla-06) catches at least one line below.
// AUDIT FIXTURE ONLY — not buildable as-is; intents/attributes are stubs.

import WidgetKit
import ActivityKit
import AppIntents
import SwiftUI

// ───────────────────────── wla-01 — timeline reload policy .never on time-driven content ──────────
struct CountdownEntry: TimelineEntry {
    let date: Date
    let remaining: TimeInterval
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, remaining: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(CountdownEntry(date: .now, remaining: 60))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let entry = CountdownEntry(date: .now, remaining: 60)
        // wla-01: a countdown that freezes forever — should be .atEnd or .after(date)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// ───────────────────────── wla-03 — legacy IntentConfiguration where AppIntentConfiguration fits ──
// wla-05 — supportedFamilies lists an accessory family the body can't render
struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "CountdownWidget",
                            intent: SelectTimerIntent.self,
                            provider: CountdownIntentProvider()) { entry in
            CountdownTileView(entry: entry)   // a system tile, no accessory layout
        }
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

// ───────────────────────── wla-04 — interactive Button(intent:) / Toggle(isOn:intent:) ────────────
struct CountdownTileView: View {
    let entry: CountdownEntry
    var body: some View {
        VStack {
            Text(entry.remaining, format: .number)
            // wla-04: ToggleFavoriteIntent.perform() is empty → tap is a no-op
            Button(intent: ToggleFavoriteIntent()) {
                Image(systemName: "star")
            }
            // wla-04 (second form): Toggle(isOn:_,intent:)
            Toggle("Pin", isOn: entry.remaining > 0, intent: PinTimerIntent())
        }
    }
}

// ───────────────────────── wla-02 — ActivityConfiguration with NO DynamicIsland ───────────────────
struct DownloadActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
    }
    var fileName: String
}

struct DownloadLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // wla-02: Lock Screen view only — no DynamicIsland → blank in the Dynamic Island
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            DownloadLockScreenView(context: context)
        }
    }
}

struct DownloadLockScreenView: View {
    let context: ActivityViewContext<DownloadActivityAttributes>
    var body: some View {
        Text(context.state.progress, format: .percent)
    }
}

// ───────────────────────── wla-06 — ControlWidgetToggle (iOS 18) with no availability gate ─────────
struct LightControl: ControlWidget {            // missing @available(iOS 18.0, *)
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LightControl") {
            ControlWidgetToggle("Light", isOn: false, action: ToggleLightIntent()) { isOn in
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
            }
        }
    }
}

// ───────────────────────── stubs (keep the fixture self-contained) ────────────────────────────────
struct SelectTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Timer"
    func perform() async throws -> some IntentResult { .result() }
}
struct CountdownIntentProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry { CountdownEntry(date: .now, remaining: 0) }
    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(CountdownEntry(date: .now, remaining: 0))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        completion(Timeline(entries: [], policy: .atEnd))
    }
}
struct ToggleFavoriteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    func perform() async throws -> some IntentResult { .result() }   // empty: the wla-04 defect
}
struct PinTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pin Timer"
    func perform() async throws -> some IntentResult { .result() }
}
struct ToggleLightIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Light"
    func perform() async throws -> some IntentResult { .result() }
}
