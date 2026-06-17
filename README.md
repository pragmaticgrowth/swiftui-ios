# swiftui-ios

**real-world swiftui for claude — grounded in shipping iOS & iPadOS apps.**

[![version](https://img.shields.io/badge/version-0.4.0-blue)](https://github.com/yigitkonur/swiftui-ios-plugin/releases) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE) [![platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS-lightgrey)](https://developer.apple.com/ios/)

---

claude writes bad swiftui. not wrong-syntax bad — confidently-stale bad. deprecated modifiers, api shapes that never existed, idioms from wwdc three years ago. the docs tell claude *what* an api does; they don't tell it *how 2026 shipping iOS apps actually use it.*

this plugin fills that gap. it gives claude a queryable corpus of real open-source iOS & iPadOS apps — parsed with swiftsyntax (apple's own compiler parser, not regex), ranked by code quality, and wrapped in a cli that answers one question: **how do actual shipping iOS apps write this?**

every result carries a github permalink pinned to a commit sha and links to the matching [sosumi.ai](https://sosumi.ai) doc so the spec and the practice are always one hop apart.

on top of the lookup layer sits a complete **iOS swiftui audit suite** — skill-driven domain auditors covering navigation, adaptive layout, presentation/sheets, UIKit interop, widgets/Live Activities, accessibility, concurrency, and more — each backed by a static lint engine that locates candidates and lets claude judge.

---

## the numbers

| | |
|---|---|
| repos analyzed | **319** open-source iOS & iPadOS SwiftUI apps (2,474 candidates → 614 gated → 319 with real SwiftUI content) |
| parser | **swiftsyntax** — exact attributes, modifiers, property wrappers, call shapes; not regex |
| sdk surface | iOS 17 target · iPhoneOS 26.5 SDK `swift symbolgraph-extract` (incl. WidgetKit · ActivityKit · AppIntents) |
| api coverage | 375 modifiers · 325 types · 25 property wrappers · 66 env keys · 13 whole-pattern recipes |
| platform mix | 229 iOS · 85 cross-platform · 5 macOS (cross-listed) |
| audit suite | **34 domain auditors** + an orchestrator (`audit-ios-swiftui-full`) + a **pixel-first visual design reviewer** (`audit-swiftui-design-review`) |
| commands | 4 — `/swiftui`, `/swiftui-review`, `/swiftui-audit`, `/swiftui-settings` |
| quality ranking | composite score: author authority (aggregate stars) + repo stars + api modernity + recency |

---

## install

```
/plugin marketplace add yigitkonur/claude-swiftui-plugin
/plugin install swiftui
```

the cli (`swiftui-ctx`) auto-installs on first use — downloads a prebuilt universal binary, or builds from source if xcode is available. no manual paths or env setup needed.

**audit deps** — `jq` is required to run the audit/lint tier; `ast-grep` + `ripgrep` are optional (they unlock the structural lint tier):

```sh
brew install jq            # required for the audit suite
brew install ast-grep ripgrep   # optional — structural + faster grep tiers
```

without `ast-grep`/`ripgrep` the audit suite degrades gracefully to the grep-only tier — it still runs 283 grep tells, just not the 42 ast-grep structural rules. without `jq` the audit scripts exit early with a clear message.

### cli-only install (no plugin)

```sh
git clone https://github.com/yigitkonur/claude-swiftui-plugin
cd claude-swiftui-plugin
make install       # downloads/builds swiftui-ctx and symlinks it onto PATH
swiftui-ctx doctor # verify the install
```

---

## the four commands

### `/swiftui <api or intent>`

look up any swiftui api by name, modifier, property wrapper, or plain english intent. returns the consensus argument shape (ranked by how production apps actually call it), the best real-world example with a github permalink, co-occurring apis, and a link to the sosumi doc.

```
/swiftui NavigationSplitView
/swiftui @Observable
/swiftui .searchable
/swiftui "drag and drop between lists"
/swiftui frame(width:height:)
```

### `/swiftui-review [file]`

review a swift file or the current diff for deprecated apis, non-idiomatic patterns, and consensus deviations. produces a prioritized finding list with migration paths and real counterexamples pulled from the corpus.

```
/swiftui-review ContentView.swift
/swiftui-review                    # reviews the current diff
```

### `/swiftui-audit [directory]`

full codebase audit. the orchestrator routes your source tree through the relevant domain auditors in dependency-ordered waves, runs the static lint engine, and rolls everything into `_SUMMARY.md` with per-finding severity ratings and fix guidance.

```
/swiftui-audit Sources/
/swiftui-audit .
```

### `/swiftui-settings`

create or update `.claude/swiftui.local.md` — per-project plugin configuration. the file is gitignored automatically.

---

## skills

skills fire automatically when you describe a task to claude. the commands above are the explicit entry points when you want to invoke them directly.

### write / look up (4 skills)

| skill | fires when you… |
|---|---|
| `swiftui-examples` | write or look up a swiftui api — returns consensus arg shape + ranked real examples with permalinks |
| `swiftui-modernize` | upgrade existing code — finds deprecated apis, produces concrete migration patches with before/after |
| `ios-app-patterns` | scaffold a whole feature — tab-bar app, NavigationStack master-detail, sheet + detents flow, uiview bridge, widget, onboarding… |
| `build-ios-swiftui` | write / review / refactor broadly — @Observable state, native iOS/iPadOS idioms, hig conformance |

`build-ios-swiftui` and `ios-app-patterns` are **design-aware**: they generate with built-in text styles, semantic colors, 44 pt targets, correct Liquid Glass placement, and HIG navigation by default (grounded in the same cited `references/_shared/` design knowledge base the reviewer uses), and can render-and-self-check what they wrote via `swiftui-capture.sh` + `audit-swiftui-design-review`.

### audit suite (34 skills)

`audit-ios-swiftui-full` is the orchestrator — it routes your codebase through the right subset of auditors automatically, runs them in dependency order, and produces `_SUMMARY.md`.

each domain auditor pairs the lint engine (which *locates* candidates) with `swiftui-ctx` evidence (which lets claude *judge*). the engine never reports a finding as fact — it surfaces lines for review.

### design & ux review (pixel-first)

`audit-swiftui-design-review` is the visual complement to the code audits — it judges *rendered design quality*, not code. It builds the app, screenshots every screen across **light/dark + Dynamic Type** in the Simulator (`scripts/swiftui-capture.sh` — auto-explores via the accessibility tree, or a `screens.manifest.json`), runs **deterministic** objective checks (static `dr-*` tells + Apple's `performAccessibilityAudit`), then **critiques the pixels** against a cited **Apple HIG + iOS 26 Liquid Glass** knowledge base (`references/_shared/hig-design-rubric.md`, `liquid-glass-design.md`, `ux-smell-catalog.md`) — ending in a **0–100 Design Score**. Every finding cites a real HIG/WWDC rule (`expected → gap → fix`); debunked myths are blacklisted; it degrades to code-only when no simulator is available. It runs as **Wave 9** of `audit-ios-swiftui-full`, or invoke it directly for a design-only pass.

| domain | skill | what it catches |
|---|---|---|
| **orchestrator** | `audit-ios-swiftui-full` | routes all domains in dependency-ordered waves, rolls up to `_SUMMARY.md` |
| accessibility | `audit-swiftui-accessibility` | icon-only controls with no label, ungrouped composite rows, custom controls with no value/trait |
| adaptive layout | `audit-swiftui-adaptive-layout` | iPhone-only designs on a Universal (iPhone + iPad) target, frozen widths, missing size-class adaptation |
| adaptive navigation | `audit-swiftui-adaptive-navigation` | `NavigationStack`/`NavigationSplitView` shell, toolbar placement, iPhone↔iPad nav adaptation |
| animation & motion | `audit-swiftui-animation-motion` | deprecated `.animation(_:)`, missing `withAnimation`, spring misconfiguration, reduce-motion |
| api currency | `audit-swiftui-api-currency` | deprecated/renamed/hallucinated apis, floor mismatches, migration paths to successors |
| app file handling | `audit-swiftui-app-file-handling` | `DocumentGroup` wiring, value-type `FileDocument`, import/export, autosave |
| app intents | `audit-swiftui-app-intents` | features invisible to Siri/Spotlight/Shortcuts, `AppShortcutsProvider`, `@Parameter` wiring |
| app lifecycle & background | `audit-swiftui-app-lifecycle-background` | scenePhase state loss on suspension, background tasks that never run |
| appearance & color | `audit-swiftui-appearance-color` | hardcoded colors, missing dark-mode adaptation, missing semantic color usage |
| async & data loading | `audit-swiftui-async-data` | missing `.task`, retain cycles, `.onAppear` anti-patterns, missing cancellation |
| availability gating | `audit-swiftui-availability-gating` | above-floor apis shipped ungated, gated on the wrong arm, deployment-target drift |
| charts | `audit-swiftui-charts` | swift charts patterns, accessibility marks, missing axis labels, wrong mark types |
| concurrency safety | `audit-swiftui-concurrency-safety` | Swift 6 data-race safety, actor-isolation gaps, @State mutation off main thread |
| controls & forms | `audit-swiftui-controls-forms` | text-input ergonomics, focus management, picker/keyboard styles, control wiring |
| document picker & permissions | `audit-swiftui-document-picker-permissions` | security-scoped urls, file-consent gaps, importer/exporter patterns |
| drawing & canvas | `audit-swiftui-drawing-canvas` | `Canvas` misuse, `GeometryReader` overuse, `MeshGradient` availability |
| dynamic type | `audit-swiftui-dynamic-type` | body text that ignores Larger Text, fixed font sizes, clipped scaled layouts |
| haptics | `audit-swiftui-haptics` | missing/overused haptic feedback, wrong feedback style, `.sensoryFeedback` patterns |
| iOS idiomaticness | `audit-swiftui-ios-idiomaticness` | desktop habits shoehorned onto a phone — scores 0-100 with a routed punch-list |
| layout & tables | `audit-swiftui-layout-and-tables` | iPad/Mac-shaped grids that break on iPhone, device-frozen layouts, `Table` misuse |
| liquid glass | `audit-swiftui-liquid-glass` | iOS 26 liquid glass adoption, `.glassEffect` placement, material misuse |
| localization | `audit-swiftui-localization` | raw string literals, missing `LocalizedStringKey`, RTL layout gaps |
| presentation & sheets | `audit-swiftui-presentation-sheets-modals` | stale/non-idiomatic sheet, cover, popover, and detent presentation |
| previews | `audit-swiftui-previews` | `#Preview` macro migration, `PreviewProvider` removal, preview traits |
| privacy & permissions | `audit-swiftui-privacy-permissions` | missing usage-description keys, required-reason api gaps, launch-time crashes |
| safe area & keyboard | `audit-swiftui-safe-area-keyboard` | notch/Dynamic Island/home-indicator overlap, fields trapped behind the keyboard |
| state & observation | `audit-swiftui-state-observation` | `@Observable` vs `ObservableObject`, wrong ownership wrappers, mixed observation worlds |
| swiftdata | `audit-swiftui-swiftdata` | `@Model` schema, `ModelContext` threading, migration plans, relationship cascade |
| touch & gestures | `audit-swiftui-touch-gestures` | ignored taps, gesture conflicts, drag/drop wiring, hit-testing gaps |
| typography & text | `audit-swiftui-typography-text` | font scaling, `AttributedString` usage, markdown rendering, dynamic type |
| uikit interop | `audit-swiftui-uikit-interop` | `UIViewRepresentable`/`UIViewControllerRepresentable`/`UIHostingController` bridge correctness |
| uikit overuse | `audit-swiftui-uikit-overuse` | uikit bridging where a native swiftui equivalent exists and should be preferred |
| view performance | `audit-swiftui-view-performance` | needless body re-evaluation, view recreation, lazy-stack misuse, heavy initializers |
| widgets & live activities | `audit-swiftui-widgets-live-activities` | WidgetKit/ActivityKit timeline staleness, Live Activity, interactivity defects |

---

## cli reference

`swiftui-ctx` is the engine behind every skill and command. it speaks `--json` everywhere (stable envelope: `{ok, schema_version, result, next_actions, error}`) with semantic exit codes:

| code | meaning |
|---|---|
| 0 | success |
| 2 | usage error |
| 3 | not found |
| 4 | network error |
| 5 | no catalog / env error |

every result ends with a `next_actions` block — literal commands to drill in further. agents use this to chain calls without guessing.

```sh
# look up how a production app writes a specific api
swiftui-ctx lookup NavigationSplitView
swiftui-ctx lookup @Observable --json
swiftui-ctx lookup frame(width:height:)       # name formats are flexible

# search by intent
swiftui-ctx search "bottom sheet with detents"
swiftui-ctx search "pull to refresh a list"

# pull the real enclosing view from github (syntax-accurate span)
swiftui-ctx file ex_4bdd3cf4d9
swiftui-ctx file ex_4bdd3cf4d9 --smart        # expand to the full enclosing view

# whole patterns
swiftui-ctx recipe tab-bar-app                # tab-bar iOS app scaffold
swiftui-ctx recipe navigationstack-master-detail
swiftui-ctx recipe uiview-bridge
swiftui-ctx recipes                           # list all 13 recipes

# deprecation guard
swiftui-ctx deprecated foregroundColor        # → .foregroundStyle
swiftui-ctx deprecated listStyle             # lists all deprecated forms

# sdk and conformance info
swiftui-ctx conformances View                 # what protocols View conforms to
swiftui-ctx bridges                           # all uiview/uiviewcontroller bridge patterns

# corpus quality and coverage
swiftui-ctx rankings                          # top-quality repos in the corpus
swiftui-ctx stats                             # corpus summary (repos, coverage, sdk)
swiftui-ctx insights                          # usage patterns and outliers

# environment
swiftui-ctx doctor                            # verify install, catalog, sdk surface
swiftui-ctx settings                          # show active config paths
```

---

## per-project settings

run `/swiftui-settings` once in any project to create `.claude/swiftui.local.md`:

```markdown
---
enabled: true       # false → silences the deprecation hook entirely
strict_audit: true  # false → /swiftui-audit is advisory (no non-zero exit on hard findings)
---
```

the file is gitignored automatically (`.claude/*.local.md` pattern). restart claude code after editing for hook changes to take effect. you can also set `SWIFTUI_GUARD=off` as an env variable to disable the deprecation hook without a settings file.

**what the deprecation hook does:** every time you edit a `.swift` file, a fast static grep checks whether any deprecated swiftui api names appear in the edit. if they do, it adds a non-blocking nudge — never denies the write, just surfaces the issue so claude can address it.

---

## how the data was built

the pipeline is reproducible. `scripts/00..08_*.py` do the full thing (run manually, step-by-step, per [`RUN.md`](RUN.md) — this is a dev-only offline build, not an install step):

```
00  harvest seed repos from awesome-ios + open-source-ios-apps
 ↓
01  gate: filter to recent commits + actually-swiftui repos
 ↓
02  build sdk symbol catalog from the iOS sdk + symbolgraph-extract
 ↓
03  swiftui-scan (swiftsyntax) — parse every .swift file for exact api usage
 ↓
04  clone → scan → delete loop across every gated repo
 ↓
05  aggregate shards into catalog/ json files
 ↓
06  discovery pass: iOS-focused github code search for more repos
 ↓
07  author-authority enrichment: contributors' aggregate stars
 ↓
08  recipe extraction: whole-pattern scaffolds from the best examples
```

the cli reads from `catalog/` (plain json, committed to the repo). the 92mb raw declaration dump is excluded — regenerate it with the pipeline if you need it.

---

## caveats

- **iOS-first**: the corpus is shipping iOS & iPadOS apps (229 iOS · 85 cross-platform · 5 macOS cross-listed). for cross-platform or macOS examples, pass `--platform any`.
- **evidence tiers**: `low_corpus: true` means fewer than 10 repos matched — thin evidence. cross-check the sosumi doc before trusting the consensus.
- **the ranking is a heuristic**: `recommended` ≈ "how a current, high-quality iOS app writes it." trust it over claude's memory; verify the spec on sosumi.
- **audit findings are candidates**: the lint engine locates, the auditor judges. a grep match is never a confirmed bug — claude reads the surrounding code and decides.
- **sdk surface**: matched against the iPhoneOS 26.5 SDK with an iOS 17 deployment floor. floor annotations in `references/_shared/floors-master.md` are verified against apple's published release notes; anything marked `verify-SDK` should be confirmed in xcode.

---

## credits

- [sosumi.ai](https://sosumi.ai) — apple docs as markdown for llms. every result links to the matching doc.
- [awesome-ios](https://github.com/vsouza/awesome-ios) and [open-source-ios-apps](https://github.com/dkhamsing/open-source-ios-apps) by dkhamsing — the seed corpus.
- apple swiftsyntax + swift-argument-parser — the parser and the cli scaffolding.
- the authors who shipped real iOS & iPadOS apps in the open. every example permalink points back to your repo.

---

## license

mit. see [`LICENSE`](LICENSE).
