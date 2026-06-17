# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map · iOS)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
app-lifecycle-background claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the
curl/CLI commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`;
this file is the lifecycle-specific *map* of which iOS pages to fetch. The **practice** side (consensus shape
+ permalinked example) comes from `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor
values live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK. iPad modeled within `ios`.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …` line.
   Cross-check `introduced_ios` from `swiftui-ctx lookup <api> --platform ios --json` (it surfaces at
   `result.introduced_ios`, **not** under `result.availability`) against it and against `floors-master.md`.
   The reconciled floor in `floors-master.md` wins.
2. **UIKit BackgroundTasks is not in the SwiftUI catalog.** `BGTaskScheduler`, `BGAppRefreshTaskRequest`,
   `BGProcessingTaskRequest`, `BGTask` return **exit 3** from `swiftui-ctx lookup` — that is **expected**,
   not a hallucination signal. Fetch the BackgroundTasks doc via Sosumi, cite the well-known iOS 13.0
   introduction, and mark findings `availability: verify against Xcode 26 SDK`. Never fabricate a catalog floor.
3. **Lifecycle is SwiftUI-native first.** `@Environment(\.scenePhase)`, `.backgroundTask(_:action:)`,
   `onOpenURL`, `onContinueUserActivity`, `@SceneStorage` are the SwiftUI entry points; an AppDelegate is the
   fallback only for what SwiftUI genuinely lacks.
4. **Seam deferral.** The save shape → `swiftdata`; the load a scene event triggers → `async-data`; a deep
   link that should be an `AppIntent` → `app-intents`; manifest/usage-string hygiene → `privacy-permissions`;
   "where does this state live" → `state-observation`; `NavigationPath` restoration → `adaptive-navigation`.

---

## A. SwiftUI lifecycle symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are
the reconciled truth in `floors-master.md` — never restate them here.

| Symbol | Path |
|---|---|
| `scenePhase` (`ScenePhase`, iOS 14.0) | `environmentvalues/scenephase` · `scenephase` |
| `onChange(of:_:)` (iOS 14.0; 1-param form deprecated iOS 17) | `view/onchange(of:initial:_:)` |
| `@SceneStorage` (`SceneStorage`, iOS 14.0) | `scenestorage` |
| `@AppStorage` (`AppStorage`, iOS 14.0) | `appstorage` |
| `.backgroundTask(_:action:)` (`BackgroundTask`, iOS 16.0) | `scene/backgroundtask(_:action:)` · `backgroundtask` |
| `onOpenURL(perform:)` (iOS 14.0) | `view/onopenurl(perform:)` |
| `onContinueUserActivity(_:perform:)` (iOS 14.0) | `view/oncontinueuseractivity(_:perform:)` |
| `@UIApplicationDelegateAdaptor` (iOS 14.0) | `uiapplicationdelegateadaptor` |

## B. UIKit BackgroundTasks symbol map (verify-SDK — not in the SwiftUI catalog)

Human doc path = `developer.apple.com/documentation/backgroundtasks/<path>` (fetch via `sosumi.ai/...`).
Floor is the well-known **iOS 13.0**; mark findings `verify against Xcode 26 SDK`.

| Symbol | Path |
|---|---|
| `BGTaskScheduler` (`.shared`, `register`, `submit`) | `bgtaskscheduler` · `bgtaskscheduler/register(fortaskwithidentifier:using:launchhandler:)` · `bgtaskscheduler/submit(_:)` |
| `BGAppRefreshTaskRequest` | `bgapprefreshtaskrequest` |
| `BGProcessingTaskRequest` | `bgprocessingtaskrequest` |
| `BGTask` / `BGAppRefreshTask` | `bgtask` · `bgapprefreshtask` |
| `Info.plist` keys | `documentation/bundleresources/information_property_list/bgtaskschedulerpermittedidentifiers` · `.../uibackgroundmodes` |

## C. Apple conceptual / HIG pages

| Page | Path | Anchors |
|---|---|---|
| Managing your app's life cycle | `documentation/uikit/app_and_environment/managing_your_app_s_life_cycle` | scene phases, suspension, state preservation (alb-01) |
| Using background tasks | `documentation/backgroundtasks` · `documentation/backgroundtasks/choosing_background_strategies_for_your_app` | register-and-submit, plist identifiers (alb-02/03/05) |
| Restoring your app's state | `documentation/swiftui/restoring_your_apps_state_with_swiftui` | `@SceneStorage` / `@AppStorage` restoration (alb-04) |
| HIG — Going to the background | `design/human-interface-guidelines/going-to-the-background` | persist before suspension (alb-01) |

## D. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| id | Title | Covers |
|---|---|---|
| wwdc2019/707 | Advances in App Background Execution | `BGTaskScheduler` register-and-submit, plist (alb-02/03) |
| wwdc2020/10037 | Background execution demystified | refresh vs processing tasks, scheduling (alb-02/05) |
| wwdc2022/10054 | What's new in SwiftUI | `.backgroundTask` scene modifier (alb-05) |

## E. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Hacking with Swift | `hackingwithswift.com/quick-start/swiftui/how-to-detect-when-your-app-moves-to-the-background-or-foreground` | scenePhase save-on-background (alb-01) | medium |
| Donny Wals | `donnywals.com/scheduling-background-tasks-using-the-task-scheduler-on-ios` | `BGTaskScheduler` register/submit + plist (alb-02/03) | high |
| Sarunw | `sarunw.com/posts/scenestorage-in-swiftui/` | `@SceneStorage` restoration scope (alb-04) | medium |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16).
- `BGTaskScheduler` family floor: well-known iOS 13.0, marked `verify against Xcode 26 SDK` (UIKit
  BackgroundTasks, outside the SwiftUI catalog).
- Practitioner URLs as listed (trust labelled; corroboration only).
