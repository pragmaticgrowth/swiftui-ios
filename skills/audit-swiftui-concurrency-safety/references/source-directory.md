# Reference — swift.org / Swift-Evolution / Apple Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
concurrency claim. **Two source classes — route each fact correctly:**

- **Toolchain / isolation-semantics facts** (`@concurrent`, `nonisolated(nonsending)`, the
  `NonisolatedNonsendingByDefault` flag, `-default-isolation MainActor`, the language-mode default):
  the spec is **swift.org / Swift Evolution**, NOT swiftui-ctx and NOT Apple SDK docs. Fetch the SE
  proposal or the swift.org blog directly.
- **API floor / signature facts** (`.task`, `MainActor.run`, `Transferable`): fetch the Apple page
  **via Sosumi** — protocol + JSON-404 caveat in
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; never `WebFetch developer.apple.com`.

Floor values: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. **As of:** 2026-06-07 ·
iOS 26 (Tahoe) · Xcode 26 SDK · Swift 6.2.

---

## A. Swift toolchain / evolution (the authoritative spec for isolation semantics)

| Fact to verify | Source | Anchor |
|---|---|---|
| Swift 6 default = strict data-race checking; opt-in per target | https://www.swift.org/migration/documentation/migrationguide/ | "complete checking"; `SWIFT_VERSION = 6` / `swiftLanguageMode(.v6)` |
| Swift 6.2 "main actor by default" is OPT-IN (`-default-isolation MainActor`) | https://swift.org/blog/swift-6.2-released/ | "*the new option to isolate code to the main actor by default*" |
| `nonisolated(nonsending)` (caller's context) + `@concurrent` (global executor) | https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md | SE-0461 |
| plain `nonisolated async` hops to the global executor (what the flag replaces) | https://github.com/swiftlang/swift-evolution/blob/main/proposals/0338-clarify-execution-non-actor-async.md | SE-0338 |
| `sending` transfers ownership across a boundary | https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md | SE-0430 |

## B. Apple SwiftUI / Swift API docs (floor + signature; fetch via Sosumi)

Human doc path = `developer.apple.com/documentation/<path>` (fetch as `sosumi.ai/<path>`).

| Symbol | Path | Floor |
|---|---|---|
| `.task(name:priority:file:line:_:)` / `.task(id:name:priority:file:line:_:)` | `swiftui/view/task(name:priority:file:line:_:)` | iOS 15.0+ |
| `MainActor.run(resultType:body:)` | `swift/mainactor/run(resulttype:body:)` | iOS 13.0+ |
| `@MainActor` / `Sendable` / `Task` / `Task.detached` | `swift/mainactor` · `swift/sendable` · `swift/task` | iOS 13.0+ |
| `Transferable` / `transferRepresentation` | `coretransferable/transferable` | iOS 16.0+ |

**Era-gated to Swift 6.2+ (no iOS floor — a toolchain gate; verify against Xcode 26 SDK):**
`@concurrent`, `nonisolated(nonsending)`, the `NonisolatedNonsendingByDefault` flag,
`-default-isolation MainActor`, `Task(name:)`.

## C. Practitioners (corroboration only — never primary; label findings low/verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Hacking with Swift | `hackingwithswift.com/swift/6.0/concurrency` | strict checking as the 6.0 default; the non-Sendable error class | high |
| Donny Wals | `donnywals.com/solving-main-actor-isolated-property-can-not-be-referenced-from-a-sendable-closure-in-swift/` | the `@Sendable`-closure error + ownership-dependent fix | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- swift.org / Swift-Evolution proposals fetched directly (toolchain facts are not in the SwiftUI corpus or Sosumi). Access 2026-06-07.
- Apple paths fetched via `https://sosumi.ai/...` (access 2026-06-07). Practitioner URLs as listed (corroboration only).
