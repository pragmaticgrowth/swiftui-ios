# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
view-performance claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol (curl/CLI
commands + the JSON-404 caveat) is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this
file is the perf-specific *map* of which pages to fetch. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. The **practice** half (the canonical shape +
a permalinked real example) comes from `swiftui-ctx` per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of 2026-06-07 · iOS 26 · Xcode 26 SDK.**

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the fix-target symbol exist + its iOS floor?** Fetch
   `https://sosumi.ai/documentation/swiftui/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. In this domain the symbols are all **real** (the defects are misuse) — the floor that matters is
   `Text(_:format:)` (**iOS 15.0+** for `FormatOutput == String`; **iOS 15.0+** for `FormatOutput == AttributedString`), to confirm the formatter fix is available at the project's deployment target (iOS 17 floor = no gate needed).
2. **What's the canonical *shape*?** Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`
   → read `consensus` (the % shape), `recommended` (the permalink for the ✅), `introduced_ios`,
   `co_occurs_with`. Then `file <recommended.id> --smart` for the real enclosing body.
3. **Deprecated-in-practice?** `swiftui-ctx deprecated <api>` — for this domain it answers *no* for every
   symbol (`AnyView`, `GeometryReader`, `.id`, `@Environment` are current), which is itself the proof that
   findings are `warning`/`advisory`, not "fake API" hard-fails.

## A. SwiftUI symbol map (the fix targets — all real on iOS)

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`).

| Symbol | Path | Floor / note |
|---|---|---|
| `Text(_:format:)` | `text/init(_:format:)` | iOS **15.0+** (`FormatOutput == String` · `FormatOutput == AttributedString`) — the formatter fix; no gate needed at iOS 17 floor |
| `ViewBuilder` | `viewbuilder` | the `AnyView` fix (returns `some View`) |
| `EquatableView` / `View.equatable()` | `equatableview` · `view/equatable()` | iOS 13.0+ — the closure-prop fix |
| `LazyVStack` / `LazyVGrid` | `lazyvstack` · `lazyvgrid` | iOS 14.0+ — the eager-`ForEach` fix |
| `Layout` | `layout` | iOS 16.0+ — custom layout to replace a greedy `GeometryReader` |
| `containerRelativeFrame` | `view/containerrelativeframe(_:alignment:)` | iOS 17.0+ — no gate needed at iOS 17 floor |
| `GeometryReader` | `geometryreader` | real; misused when it wraps a whole subtree (vperf-05) |
| `AnyView` | `anyview` | real; erases the diffing type (vperf-03) |
| `View.id(_:)` | `view/id(_:)` | real; `.id(UUID())` churns identity (vperf-02) |
| `Environment` | `environment` | real; fast-changing value = fan-out (vperf-08) |
| `List` | `list` | iOS 13.0+; large-dataset ceiling (vperf-10) |

`Self._printChanges()` and the SwiftUI Instrument are **profiling tools**, not adoptable API floors —
they back the render test, not a fix target (see `rendering-model-and-profiling.md`).

## B. WWDC sessions (`developer.apple.com/videos/play/wwdc<year>/<id>`)

| Year/id | Title | Covers |
|---|---|---|
| 2021 / 10022 | Demystify SwiftUI | identity, lifetime, dependencies — the diffing model behind every defect |
| 2023 / 10160 | Demystify SwiftUI performance | update cost, expensive `body` work, `List`/`ForEach` cost |
| 2025 / 306 | Discover the new SwiftUI instrument. | the SwiftUI Instrument + Cause & Effect graph; the `@Environment` high-frequency fan-out warning |

## C. Practitioners (corroboration only — never primary; label findings `confidence:` low / verified-by-research)

| Source | Reliable for | Trust |
|---|---|---|
| r/SwiftUI + iOS SwiftUI performance write-ups | the iOS 26 plain-`List` headroom (~10k smooth, ~50k usable); `List`/`LazyVStack` ceiling on iPhone vs iPad | medium — **profile your build** |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (accessed 2026-06-07).
- WWDC sessions 10022 / 10160 / 306: `https://developer.apple.com/videos/play/` (accessed 2026-06-07).
- Practitioner reports as listed (trust labelled; corroboration only).
