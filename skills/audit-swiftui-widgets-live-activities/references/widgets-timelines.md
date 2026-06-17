# Reference — Timelines, Configuration Currency & Families (wla-01 · wla-03 · wla-05)

The three WidgetKit defects that make a widget silently stop working: a **timeline with no deliberate reload
policy** (it goes stale and never refreshes), a **legacy `IntentConfiguration`** where the iOS-17
`AppIntentConfiguration` is now the idiom, and a **`supportedFamilies` listing a family the body cannot
render**. All three are *flag-only* (the fix is a judgment call: is this widget actually static? does
migrating the config preserve the intent? which families does the body really draw?). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** backed by a real iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK · Swift 6.2.

---

## wla-01 — `getTimeline` returns a `Timeline` with `.never` (or no policy) on time-driven content (warning, flag-only)

A widget refreshes only when its `TimelineProvider.getTimeline(...)` returns a `Timeline(entries:policy:)`
whose **reload policy** tells WidgetKit when to ask again. `.never` means "never ask again" — correct for a
genuinely static widget, a silent staleness bug for anything clock-, countdown-, or data-driven. AI reaches
for `.never` (or copies a sample that uses it) because the bug is invisible until the widget freezes hours
later.

```swift
// ❌ WRONG — a countdown widget that never refreshes after its first entry
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = Entry(date: .now, remaining: deadline.timeIntervalSinceNow)
    let timeline = Timeline(entries: [entry], policy: .never)   // freezes forever
    completion(timeline)
}
```
```swift
// ✅ CORRECT — schedule the next reload deliberately (.atEnd or .after(date))
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [Entry] = []
    let now = Date.now
    for minute in 0..<60 {
        let date = Calendar.current.date(byAdding: .minute, value: minute, to: now)!
        entries.append(Entry(date: date, remaining: deadline.timeIntervalSince(date)))
    }
    let timeline = Timeline(entries: entries, policy: .atEnd)   // ask again when the last entry passes
    completion(timeline)
}
```

**Grounded in the corpus.** `swiftui-ctx lookup Timeline --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 14.0` — `Timeline` is the WidgetKit timeline type; `TimelineProvider` /
`AppIntentTimelineProvider` are **not in `sdk_catalog`** (`lookup` **exit 3** — they ship in WidgetKit,
which the catalog does not floor), so carry them as `verify against Xcode 26 SDK` and cite the well-known
iOS 14.0 floor. `TimelineReloadPolicy` cases: `.atEnd`, `.after(Date)`, `.never`.

> **Judge before flagging.** `.never` is *correct* for a truly static widget (a fixed branding tile, a
> launcher with no time/data component). wla-01 LOCATES `policy: .never`; **you decide** whether the
> entries are time-driven (a clock, a countdown, a "next event", a value that ages) — only then is `.never`
> a defect. A `getTimeline` that returns no `Timeline(... policy:)` at all is the structural-absence twin,
> caught at READ (step 3).

## wla-03 — `IntentConfiguration` where `AppIntentConfiguration` (iOS 17) fits (advisory, flag-only)

`IntentConfiguration(kind:intent:provider:)` is backed by a **SiriKit `INIntent`** defined in an `.intentdefinition`
file — the iOS 14 era. iOS 17 introduced `AppIntentConfiguration(kind:intent:provider:)`, backed by a
Swift-native `WidgetConfigurationIntent` (an `AppIntent`), with `AppIntentTimelineProvider`. A widget freshly
written for an iOS-17 target should use the App-Intents surface; carrying `IntentConfiguration` forward keeps
a legacy intent definition alive.

```swift
// ❌ legacy — SiriKit INIntent-backed configuration
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "MyWidget", intent: SelectStationIntent.self,
                            provider: Provider()) { entry in MyWidgetView(entry: entry) }
    }
}
```
```swift
// ✅ iOS 17 — AppIntent-backed configuration (a WidgetConfigurationIntent)
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "MyWidget", intent: SelectStationIntent.self,
                               provider: Provider()) { entry in MyWidgetView(entry: entry) }
    }
}
```

**Grounded in the corpus.** `swiftui-ctx lookup AppIntentConfiguration --platform ios --json` returns
`introduced_ios: 17.0`, `deprecated: false`, consensus `(kind, intent, provider)` **86%** /
`(kind, provider)` 14%. Its `diverse` example is `home-assistant/iOS`:
`https://github.com/home-assistant/iOS/blob/c7cc3a56222607c10393014cf9bbc5ddab458110/Sources/Extensions/Widgets/Script/WidgetScripts.swift#L10`.
`IntentConfiguration` returns `introduced_ios: 14.0`, `deprecated: false` — it is **not** API-deprecated, so
this is a **currency advisory**, not a hard flag: the migration is only correct when the `SelectStationIntent`
is (or becomes) an `AppIntent`. `co_occurs_with` for `AppIntentConfiguration`: `IntentDescription`,
`AccessoryWidgetBackground`, `DisplayRepresentation`.

> The `SelectStationIntent` migration (`INIntent` → `AppIntent` conforming to `WidgetConfigurationIntent`) is
> owned by `audit-swiftui-app-intents` — flag the configuration type here, `cross_ref: app-intents` for the
> intent rewrite.

## wla-05 — `supportedFamilies` lists a family the body can't render (advisory, flag-only)

`.supportedFamilies([...])` declares which `WidgetFamily` cases the widget offers. The accessory families
(`.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline` — Lock Screen / watch) need an accessory
view treatment; a `systemSmall`/`systemMedium`/`systemLarge` body dropped into an accessory family renders
blank or clipped. List only the families the body genuinely draws.

```swift
// ❌ WRONG — body draws a system tile; accessory families render blank
StaticConfiguration(kind: kind, provider: Provider()) { MyTileView(entry: $0) }
    .supportedFamilies([.systemSmall, .accessoryRectangular])   // body has no accessory layout
```
```swift
// ✅ CORRECT — branch the body per family, or list only what it draws
StaticConfiguration(kind: kind, provider: Provider()) { entry in
    switch entry.family {        // or @Environment(\.widgetFamily)
    case .accessoryRectangular: AccessoryRectView(entry: entry)
    default:                    MyTileView(entry: entry)
    }
}
.supportedFamilies([.systemSmall, .accessoryRectangular])
```

`StaticConfiguration` is `introduced_ios: 14.0` (swiftui-ctx). The accessory `WidgetFamily` cases are
**iOS 16.0** (Lock Screen widgets) — `verify against Xcode 26 SDK` against the `WidgetFamily` page. This is
a READ-the-body judgment: the tell LOCATES `supportedFamilies(...)`; you confirm the body covers each listed
family.

---

## Sources

- Practice corpus: `swiftui-ctx lookup Timeline|AppIntentConfiguration|IntentConfiguration|StaticConfiguration --platform ios --json` (access 2026-06-16) — floors `Timeline` 14.0, `AppIntentConfiguration` 17.0, `IntentConfiguration` 14.0, `StaticConfiguration` 14.0.
- Real example: `home-assistant/iOS` WidgetScripts.swift permalink above (fetched via `swiftui-ctx`).
- Apple docs via Sosumi (`references/source-directory.md` for paths): `documentation/widgetkit/timeline`, `documentation/swiftui/appintentconfiguration`, `documentation/widgetkit/widgetfamily`.
- Floors are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; WidgetKit framework types not in `sdk_catalog` carry `verify against Xcode 26 SDK`.
