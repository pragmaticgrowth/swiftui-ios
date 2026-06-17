# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
async-data claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI
commands and the JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the async-data-specific *map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. **Practice** (the consensus shape + a real
iOS-26 example) comes from `swiftui-ctx` per `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of:** 2026-06-07 · iOS 26 · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. Every API in this domain floors at iOS 14–15, so gating rarely fires — but confirm, never assume.
2. **Need the consensus shape / a real example?** `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup
   <api> --json` → `consensus` + `recommended` permalink; `… recipe cached-async-image` for the image loader.
3. Never `WebFetch` `developer.apple.com`; never paper a 404 with a memory guess — fall back to Sosumi.

## A. SwiftUI async-data symbol map (human path = `developer.apple.com/documentation/...`, fetch via `sosumi.ai/...`)

| Symbol | Doc path | Floor (confirm in floors-master) | Defect |
|---|---|---|---|
| `task(priority:_:)` / `task(id:priority:_:)` | `/documentation/swiftui/view/task(priority:_:)` | iOS 15 | async-01, async-09 |
| `refreshable(action:)` | `/documentation/swiftui/view/refreshable(action:)` | iOS 15 | async-08 |
| `searchable(text:…)` | `/documentation/swiftui/view/searchable(text:placement:prompt:)` | iOS 15 | async-06 |
| `AsyncImage` / `AsyncImagePhase` | `/documentation/swiftui/asyncimage` | iOS 15 | async-07 |
| `redacted(reason:)` / `RedactionReasons` | `/documentation/swiftui/view/redacted(reason:)` | iOS 14 | async-02, async-10 |
| `ContentUnavailableView` | `/documentation/swiftui/contentunavailableview` | iOS 17 | async-03, async-04 |
| `URLSession.data(from:)` | `/documentation/foundation/urlsession/data(from:delegate:)` | iOS 15 | async-05 |
| `Task.isCancelled` / `Task.cancel()` | `/documentation/swift/task/iscancelled` | iOS 13 | async-01, async-09 |

## B. WWDC / practitioner background

- WWDC21 — "Discover concurrency in SwiftUI" (`/videos/play/wwdc2021/10019`): `.task`, lifecycle binding,
  cancellation — via Sosumi.
- WWDC23 — "What's new in SwiftUI" (`/videos/play/wwdc2023/10148`): `ContentUnavailableView` empty states.

---

## Sources

- Apple — SwiftUI async-data symbol pages (table above), fetched via Sosumi. Accessed 2026-06-07.
- WWDC21 "Discover concurrency in SwiftUI" `https://developer.apple.com/videos/play/wwdc2021/10019`,
  WWDC23 "What's new in SwiftUI" `https://developer.apple.com/videos/play/wwdc2023/10148`, via Sosumi.
  Accessed 2026-06-07.
