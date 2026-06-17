# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
widgets / Live-Activities / Controls claim. **Always fetch Apple docs via Sosumi** — the shared fetch
protocol with the curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the widgets-specific *map* of
which pages to fetch. The **practice** side (consensus shape + permalinked example) comes from
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Run
   `B=/Users/serkan/swiftui-ios/swiftui-scan/.build/release/swiftui-ctx; export SWIFTUI_CTX_CATALOG=/Users/serkan/swiftui-ios/catalog; "$B" lookup <api> --platform ios --json`
   and read `result.introduced_ios`. Cross-check against the Sosumi `**Available on:** … iOS N+ …` line and
   against `floors-master.md` (the reconciled floor wins).
2. **The `lookup` exit-3 fork (important here).** WidgetKit/ActivityKit framework types
   (`TimelineProvider`, `AppIntentTimelineProvider`, `ActivityAttributes`) return **exit 3** because the
   catalog floors SwiftUI + WidgetKit-*configuration* symbols, **not the whole framework**. Exit 3 on one of
   these is **expected** — carry the well-known floor (`TimelineProvider` iOS 14.0, `ActivityAttributes`
   iOS 16.1) as `verify against Xcode 26 SDK`, never fabricate a number. Exit 3 on an *unknown* name
   corroborates a hallucination — disambiguate via Sosumi + the hallucination blacklist.
3. **Floor cases.** `AppIntentConfiguration` iOS 17.0 · `ActivityConfiguration`/`DynamicIsland` iOS 16.1 ·
   `ControlWidgetButton`/`ControlWidgetToggle` iOS 18.0 · `IntentConfiguration`/`StaticConfiguration`/`Timeline`
   iOS 14.0 (all confirmed via `swiftui-ctx lookup --platform ios`). iOS-18 controls are **under-gated**,
   not platform-wrong — gate, don't replace.
4. **Seam deferral.** The `AppIntent` definition behind an interactive control → `app-intents`; a widget
   data source's privacy manifest / usage string → `privacy-permissions`; the blanket gate net →
   `availability-gating`; a widget's tint / `AccessoryWidgetBackground` → `appearance-color`.

---

## A. WidgetKit / ActivityKit / Controls symbol map

Human doc path = `developer.apple.com/documentation/<framework>/<path>` (fetch via `sosumi.ai/...`). Floors
are the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `Widget` (protocol) / `WidgetBundle` | `widgetkit/widget` · `widgetkit/widgetbundle` |
| `StaticConfiguration` | `widgetkit/staticconfiguration` |
| `IntentConfiguration` (legacy, SiriKit-intent) | `widgetkit/intentconfiguration` |
| `AppIntentConfiguration` (**iOS 17.0**) | `swiftui/appintentconfiguration` |
| `TimelineProvider` / `AppIntentTimelineProvider` (WidgetKit; not in catalog) | `widgetkit/timelineprovider` · `widgetkit/appintenttimelineprovider` |
| `Timeline` / `TimelineReloadPolicy` (`.atEnd`/`.after`/`.never`) | `widgetkit/timeline` · `widgetkit/timelinereloadpolicy` |
| `WidgetFamily` / `supportedFamilies(_:)` | `widgetkit/widgetfamily` |
| `ActivityConfiguration` (**iOS 16.1**) | `activitykit/activityconfiguration` |
| `DynamicIsland` / `DynamicIslandExpandedRegion` (**iOS 16.1**) | `widgetkit/dynamicisland` |
| `ActivityAttributes` / `Activity` (ActivityKit; not in catalog) | `activitykit/activityattributes` · `activitykit/activity` |
| `Button(intent:)` / `Toggle(isOn:_,intent:)` (**iOS 17.0**) | `swiftui/button` · `swiftui/toggle` |
| `ControlWidget` / `ControlWidgetButton` / `ControlWidgetToggle` (**iOS 18.0**) | `widgetkit/controlwidget` · `widgetkit/controlwidgetbutton` · `widgetkit/controlwidgettoggle` |

**Not in `sdk_catalog` → carry `verify against Xcode 26 SDK`:** `TimelineProvider`,
`AppIntentTimelineProvider`, `ActivityAttributes`, `Button(intent:)`/`Toggle(isOn:intent:)` initializers.
**Under-gated (real on iOS, above the iOS-17 floor → gate, never replace):** `ControlWidget*` (iOS 18).

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| HIG — Widgets | `design/human-interface-guidelines/widgets` | family sizes, glanceability, reload cadence (wla-01/05) |
| HIG — Live Activities | `design/human-interface-guidelines/live-activities` | Lock Screen + Dynamic Island presentations (wla-02) |
| HIG — Controls | `design/human-interface-guidelines/controls` | Control Center / Lock Screen controls (wla-06) |
| Keeping a widget up to date | `documentation/widgetkit/keeping-a-widget-up-to-date` | reload policies, `reloadTimelines` (wla-01) |
| Displaying live data with Live Activities | `documentation/activitykit/displaying-live-data-with-live-activities` | the `ActivityConfiguration` + `DynamicIsland` shape (wla-02) |
| Adding interactivity to widgets and Live Activities | `documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities` | `Button(intent:)`/`Toggle(isOn:intent:)` (wla-04) |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2023/10027 | Bring widgets to life | interactive `Button(intent:)`/`Toggle(isOn:intent:)`, `AppIntentConfiguration` (wla-03/04) |
| wwdc2023/10184 | Meet ActivityKit | `ActivityConfiguration`, Dynamic Island presentations (wla-02) |
| wwdc2024/10157 | Extend your app's controls across the system | `ControlWidget`/`ControlWidgetButton`/`ControlWidgetToggle` (wla-06) |
| wwdc2020/10034 | Widgets Code-along | `TimelineProvider`, reload policies, families (wla-01/05) |

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Swift with Majid | `swiftwithmajid.com/2023/06/06/interactive-widgets-in-swiftui/` | `Button(intent:)`/`Toggle(isOn:intent:)` placement (wla-04) | medium |
| Donny Wals | `donnywals.com/getting-started-with-live-activities/` | `ActivityConfiguration` + `DynamicIsland` (wla-02) | medium |
| Pol Piella | `polpiella.dev/widget-reload-policies/` | timeline reload policies `.atEnd`/`.after`/`.never` (wla-01) | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- Practitioner URLs as listed (trust labelled; corroboration only).
