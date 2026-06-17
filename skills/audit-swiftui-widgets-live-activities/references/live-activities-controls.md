# Reference — Live Activities, Interactivity & Control Widgets (wla-02 · wla-04 · wla-06)

The three ActivityKit / interactivity / Controls defects: an **`ActivityConfiguration` with no
`DynamicIsland`** (blank in the island), an **interactive `Button(intent:)` / `Toggle(isOn:intent:)` whose
`AppIntent` is missing** (tap does nothing), and an **iOS-18 `ControlWidget*` used with no availability gate**
(won't build below 18). All three are *flag-only* (the fix is a judgment/structural call). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** backed by a real iOS example permalink.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK · Swift 6.2.

---

## wla-02 — `ActivityConfiguration` with no `DynamicIsland` (warning, flag-only)

A Live Activity widget's `body` is an `ActivityConfiguration(for: Attributes.self)` that takes **two**
presentations: the Lock Screen / banner view (the trailing content closure) **and** a `DynamicIsland { ... }`
describing the compact, minimal, and expanded island regions. Omit the `DynamicIsland` and the activity is
blank in the Dynamic Island on every device that has one — the content closure alone is not enough.

```swift
// ❌ WRONG — Lock Screen view only; nothing renders in the Dynamic Island
struct DownloadLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            DownloadLockScreenView(context: context)
        }                                   // no DynamicIsland → island is blank
    }
}
```
```swift
// ✅ CORRECT — Lock Screen view + a DynamicIsland presentation
struct DownloadLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            DownloadLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Label("Downloading", systemImage: "arrow.down") }
                DynamicIslandExpandedRegion(.trailing) { Text(context.state.progress, format: .percent) }
            } compactLeading: {
                Image(systemName: "arrow.down")
            } compactTrailing: {
                Text(context.state.progress, format: .percent)
            } minimal: {
                Image(systemName: "arrow.down")
            }
        }
    }
}
```

**Grounded in the corpus.** `swiftui-ctx lookup ActivityConfiguration --platform ios --json` (run
2026-06-16) returns `introduced_ios: 16.1`, `deprecated: false`; `DynamicIsland` returns
`introduced_ios: 16.1`. Both have a real example in `mozilla-mobile/firefox-ios`'s `DownloadLiveActivity.swift`:
`ActivityConfiguration(for: DownloadLiveActivityAttributes.self)` at
`https://github.com/mozilla-mobile/firefox-ios/blob/abda1cb752bf139c391190e200142df643914d26/firefox-ios/WidgetKit/DownloadManager/DownloadLiveActivity.swift#L315`
and its `DynamicIsland` at
`https://github.com/mozilla-mobile/firefox-ios/blob/abda1cb752bf139c391190e200142df643914d26/firefox-ios/WidgetKit/DownloadManager/DownloadLiveActivity.swift#L318`
— the canonical shape: an `ActivityConfiguration` *with* a `DynamicIsland`. `ActivityAttributes` (the
`for:` type) is **not in `sdk_catalog`** (`lookup` **exit 3** — ActivityKit, not floored by the SwiftUI
catalog); carry it as `verify against Xcode 26 SDK` with its well-known iOS 16.1 floor.

> **Judge before flagging.** wla-02 LOCATES every `ActivityConfiguration(`; you READ the closure to confirm
> there is **no** `dynamicIsland:` / `DynamicIsland {` in it. A configuration that already attaches one is
> correct, not a defect.

## wla-04 — interactive `Button(intent:)` / `Toggle(isOn:intent:)` with a missing `AppIntent` (warning, flag-only)

iOS 17 made widgets interactive: a `Button(intent:)` or `Toggle(isOn:_, intent:)` inside a widget body runs
an `AppIntent` on tap — the *only* in-widget interaction mechanism (no `NavigationLink`, no `onTapGesture`).
The control is inert unless the named `AppIntent` exists and its `perform()` is wired.

```swift
// ❌ WRONG — button references an intent that doesn't exist / has an empty perform()
Button(intent: ToggleFavoriteIntent()) {       // ToggleFavoriteIntent.perform() is empty → tap is a no-op
    Image(systemName: entry.isFavorite ? "star.fill" : "star")
}
```
```swift
// ✅ CORRECT — a real AppIntent whose perform() does the work (intent body owned by app-intents)
Button(intent: ToggleFavoriteIntent(id: entry.id)) {
    Image(systemName: entry.isFavorite ? "star.fill" : "star")
}
// elsewhere — the AppIntent itself is audit-swiftui-app-intents' territory:
struct ToggleFavoriteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    @Parameter(title: "Item") var id: String
    func perform() async throws -> some IntentResult { /* mutate store */ .result() }
}
```

`Button(intent:)` / `Toggle(isOn:_,intent:)` are **iOS 17.0** (`verify against Xcode 26 SDK` against the
`Button`/`Toggle` interactive initializers; SwiftUI). **This is a keep-in-lane seam:** the *placement* of the
interactive control in the widget is this skill (wla-04); the `AppIntent` definition — `title`, `@Parameter`,
`perform()` — is `audit-swiftui-app-intents`. File the placement finding here with
`cross_ref: app-intents`.

## wla-06 — `ControlWidgetButton` / `ControlWidgetToggle` (iOS 18) with no availability gate (warning, flag-only)

iOS 18 added **Control Center / Lock Screen controls** via `ControlWidget`, with `ControlWidgetButton` and
`ControlWidgetToggle` as the interactive primitives. They are **iOS 18.0** — above the iOS-17 project floor,
so a target deploying to iOS 17 needs `@available(iOS 18.0, *)` on the `ControlWidget` (or an
`#available(iOS 18, *)` use-site gate) or the build fails below 18.

```swift
// ❌ WRONG — ControlWidget on an iOS-17 target with no gate → won't build below 18
struct LightControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LightControl") {
            ControlWidgetToggle("Light", isOn: false, action: ToggleLightIntent()) { isOn in
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
            }
        }
    }
}
```
```swift
// ✅ CORRECT — gate the iOS-18 control surface
@available(iOS 18.0, *)
struct LightControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LightControl") {
            ControlWidgetToggle("Light", isOn: false, action: ToggleLightIntent()) { isOn in
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
            }
        }
    }
}
```

**Grounded in the corpus.** `swiftui-ctx lookup ControlWidgetButton --platform ios --json` and
`ControlWidgetToggle --platform ios --json` (run 2026-06-16) both return `introduced_ios: 18.0`,
`deprecated: false`. `ControlWidgetButton`'s `diverse` example is `home-assistant/iOS`:
`https://github.com/home-assistant/iOS/blob/c7cc3a56222607c10393014cf9bbc5ddab458110/Sources/Extensions/Widgets/Assist/Control/ControlAssist.swift#L14`.
This is **under-gating, not platform-wrong** — the symbols exist on iOS, just above the floor; gate per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`. `cross_ref: availability-gating` only when the gate
is the entire finding.

---

## Sources

- Practice corpus: `swiftui-ctx lookup ActivityConfiguration|DynamicIsland|ControlWidgetButton|ControlWidgetToggle --platform ios --json` (access 2026-06-16) — floors `ActivityConfiguration` 16.1, `DynamicIsland` 16.1, `ControlWidgetButton` 18.0, `ControlWidgetToggle` 18.0.
- Real examples: `mozilla-mobile/firefox-ios` DownloadLiveActivity.swift (L315 ActivityConfiguration, L318 DynamicIsland) and `home-assistant/iOS` ControlAssist.swift (L14 ControlWidgetButton) — permalinks above, fetched via `swiftui-ctx`.
- Apple docs via Sosumi (`references/source-directory.md` for paths): `documentation/activitykit/activityconfiguration`, `documentation/widgetkit/dynamicisland`, `documentation/widgetkit/controlwidgetbutton`, `documentation/widgetkit/controlwidgettoggle`.
- `Button(intent:)` / `Toggle(isOn:intent:)` (iOS 17) and `ActivityAttributes` (iOS 16.1) are framework types not in `sdk_catalog` — carry as `verify against Xcode 26 SDK`.
