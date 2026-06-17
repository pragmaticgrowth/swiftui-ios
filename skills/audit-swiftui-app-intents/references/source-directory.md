# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
App Intents claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the App-Intents-specific *map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the practice layer (consensus + permalinks)
is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi + swiftui-ctx references)

1. **Does it exist / its iOS floor?** Fetch `https://sosumi.ai/documentation/appintents/<symbol-path>`
   and read the `**Available on:** … iOS N+ …` line. The AppIntents core is **iOS 16**; Action-button /
   Apple-Intelligence schemas are **iOS 18**.
2. **What's the canonical shape?** `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx recipe app-intent` for
   the `AppIntent` + `AppShortcutsProvider` template; `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx
   lookup <api> --platform ios --json` → `consensus` + `recommended` permalink.
3. **A `lookup` exit 3 on a capitalised intent type is NOT a hallucination.** `OpenIntent`, `EntityQuery`,
   `AppEntity`, `AppEnum` are real Apple symbols absent from the *usage* corpus — confirm the floor in
   `floors-master.md` (all iOS 16) and the shape via the recipe / Sosumi, not by discarding them.
4. Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess.

---

## A. AppIntents framework symbol map

Human doc path = `developer.apple.com/documentation/appintents/<path>` (fetch via `sosumi.ai/...`). Floors
per floors-master (re-confirmed 2026-06-16; AppIntents core = iOS 16.0+, below the iOS-17 floor → no gate).

| Symbol | Path | iOS floor |
|---|---|---|
| `AppIntent` (protocol; `perform()`, `static var title`) | `appintent` | 16.0+ |
| `AppShortcutsProvider` (`static var appShortcuts`) | `appshortcutsprovider` | 16.0+ |
| `AppShortcut(intent:phrases:shortTitle:systemImageName:)` | `appshortcut` | 16.0+ |
| `@Parameter(title:)` | `parameter` | 16.0+ |
| `OpenIntent` | `openintent` | 16.0+ |
| `EntityQuery` / `EntityStringQuery` | `entityquery` · `entitystringquery` | 16.0+ |
| `AppEntity` / `AppEnum` | `appentity` · `appenum` | 16.0+ |
| `IntentResult` / `.result(...)` / `ProvidesDialog` / `ShowsSnippetView` | `intentresult` · `providesdialog` | 16.0+ |
| `LocalizedStringResource` (the title's type) | `documentation/foundation/localizedstringresource` | 16.0+ |
| `AppIntentConfiguration` (WidgetKit) | `documentation/widgetkit/appintentconfiguration` | 17.0+ |
| `AssistantIntent` / `AssistantSchemas` (Apple Intelligence) | `assistantintent` · `assistantschemas` | 18.0+ (gate / verify) |

**Legacy / pre-AppIntents (ain-05, migrate):** `INIntent` (Intents/SiriKit, iOS 10),
`IntentConfiguration` (WidgetKit + SiriKit), `INInteraction` donation, `CustomIntentMigratedAppIntent`
(the migration shim). Real-but-legacy — not hallucinations.

## B. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| App Intents (framework overview) | `documentation/appintents` | the intent / entity / shortcut model; `perform()`; phrases |
| Creating your first app intent | `documentation/appintents/creating-your-first-app-intent` (verify exact path) | the `static title` + `@Parameter` + `perform()` skeleton |
| App Shortcuts | `documentation/appintents/app-shortcuts` (verify exact path) | `AppShortcutsProvider`, `phrases`, the Action button |
| HIG — Siri | `design/human-interface-guidelines/siri` (verify exact path) | phrase wording; `\(.applicationName)` token |

## C. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| Session | Covers |
|---|---|
| WWDC22 — "Dive into App Intents" | the AppIntents model, `AppIntent`/`@Parameter`/`AppShortcutsProvider` |
| WWDC22 — "Implement App Shortcuts with App Intents" | `phrases`, Siri/Spotlight discovery |
| WWDC — "Bring your app to Siri" (Apple Intelligence years) | `AssistantIntent`/`AssistantSchemas` (iOS 18) |

> WWDC ids drift year to year — resolve the exact id via the session index before citing; treat the video
> as corroboration, the doc page (via Sosumi) as the spec.

## D. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | Reliable for | Trust |
|---|---|---|
| Hacking with Swift — App Intents tutorials | the `AppIntent`/`AppShortcut` skeleton on iOS | medium |
| swiftui-ctx corpus (`recipe app-intent` / `lookup --platform ios` / `file --smart`) | real consensus shapes + permalinked iOS examples (the PRACTICE half) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- swiftui-ctx CLI contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16); floors cross-checked
  against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (AppIntents core = iOS 16).
- Practitioner sources as listed (trust labelled; corroboration only).
