# Version Drift, Deprecations & Hallucinated APIs (iOS)

> Read AI-generated SwiftUI. Spot the API the model learned from a 2020–2022 corpus, the modifier it invented, and the iOS-26-only call it forgot to gate. Fix all three.
>
> iOS-only. Every ✅ compiles against the iOS SDK; macOS appears solely as ❌ contrast. Verified against the Apple docs snapshot of 2026-06-06 (iOS 26, Xcode 26, Swift 6.3.2).

**Why AI gets this wrong.** Three mechanisms compound. (a) **Training recency** — SwiftUI renames hard every year, but the bulk of any model's corpus is the 2019–2022 surface, so it reflexively emits `NavigationView`, `.foregroundColor`, 1-param `onChange`. (b) **Confident confabulation** — for an unknown surface (especially Liquid Glass) the most *probable* next token is a plausible invention, not an admission of absence. (c) **No availability awareness** — models do not track which iOS version introduced an API, so they emit iOS-26-only calls with no `#available`, which fails to compile against a lower deployment target. The unifying tell: the code *looks* idiomatic and usually compiles, so it survives casual review.

---

## The 9 mistakes (❌ WRONG → ✅ CORRECT)

### 1. `NavigationView` → `NavigationStack` / `NavigationSplitView`

```swift
// ❌ WRONG — deprecated iOS 13–26.5
NavigationView { List(items) { row($0) } }

// ✅ CORRECT — the iOS-primary push/stack shell (iPhone, and the default everywhere)
NavigationStack { List(items) { row($0) } }

// ✅ CORRECT — iPad/regular-width sidebar, GATED so it doesn't collapse oddly on iPhone
NavigationSplitView { Sidebar() } detail: { Detail() }   // gate to regular width / iPad idiom
```

`NavigationView` is deprecated on every platform through OS 26.5. On iOS the primary replacement is `NavigationStack` (push/pop); `NavigationSplitView` is the *adaptive* choice for iPad / regular width and must be **gated** (never unconditional — it collapses oddly on compact-width iPhone). Apple: "Use `NavigationStack` and `NavigationSplitView` instead." Both replacements are iOS 16.0+. → `adaptive-navigation.md`.

### 2. `.foregroundColor(_:)` → `.foregroundStyle(_:)`

```swift
// ❌ WRONG — deprecated iOS 13–26.5
Text("Hi").foregroundColor(.red)

// ✅ CORRECT — same length, accepts ShapeStyle (gradients, hierarchical .primary/.secondary)
Text("Hi").foregroundStyle(.red)
Text("Hi").foregroundStyle(.secondary)
```

`foregroundColor(_:)` is deprecated with explicit "Use `foregroundStyle(_:)` instead." `foregroundStyle` is iOS 15.0+ and adapts to glass vibrancy automatically.

### 3. Single-param `onChange(of:perform:)` → two-param (or zero-param)

```swift
// ❌ WRONG — deprecated 1-param closure (since iOS 17)
.onChange(of: value) { newValue in handle(newValue) }

// ✅ CORRECT — two-parameter (oldValue, newValue), optional `initial:`
.onChange(of: value, initial: false) { oldValue, newValue in handle(newValue) }

// ✅ CORRECT — zero-parameter form
.onChange(of: value) { recompute() }
```

Apple's deprecation text: "`onChange(of:perform:)` was deprecated in iOS 17.0: Use onChange with a two or zero parameter action closure instead." Current signature `onChange<V>(of:initial:_:)` with `(V, V) -> Void` is iOS 17.0+.

### 4. Hallucinated / nonexistent modifiers → verify, then use the real call

```swift
// ❌ WRONG — invented APIs that DO NOT EXIST
.glassBackground()        // not a SwiftUI API
.liquidGlass()            // not a SwiftUI API
.material(.glass)         // not a SwiftUI API
SomeView().cardStyle()    // invented convenience modifier

// ✅ CORRECT — real Liquid Glass names, gated (see §5/§gating)
if #available(iOS 26.0, *) {
    Image(systemName: "star").padding().glassEffect()
}
```

For a brand-new surface the model fabricates a confident name. The **real** Liquid Glass API is `glassEffect(_:in:)`, `GlassEffectContainer`, `GlassButtonStyle` / `.buttonStyle(.glass)` — all `iOS 26.0+`. Treat any unfamiliar modifier as hallucinated until you find it in the docs.

### 5. Missing `#available` / `@available` gating (the sharpest mistake)

```swift
// ❌ WRONG if deployment target < iOS 26 — won't compile
struct Toolbar: View {
    var body: some View { content.glassEffect() }   // glassEffect is iOS 26.0+ only
}

// ✅ CORRECT — runtime branch with a fallback for older iOS
struct Toolbar: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            content.glassEffect()
        } else {
            content.background(.regularMaterial)     // iOS 18 and earlier
        }
    }
}
```

`glassEffect` (iOS 26), `@Observable` / `@Bindable` / two-param `onChange` (all iOS 17) carry hard minimum-OS floors. Using one below the project's deployment target is a compile error — see the gating section below, the #1 thing even good artifacts get wrong.

### 6. `.cornerRadius(_:)` → `.clipShape(RoundedRectangle(cornerRadius:))`

```swift
// ❌ WRONG — deprecated
view.cornerRadius(12)

// ✅ CORRECT — Apple-canonical: clip to a rounded-rect shape (uneven corners supported)
view.clipShape(RoundedRectangle(cornerRadius: 12))
view.clipShape(.rect(topLeadingRadius: 12, bottomTrailingRadius: 12))
```

`cornerRadius(_:)` is deprecated; Apple's text says "Use `clipShape(_:style:)` with `RoundedRectangle` instead." The replacement is **universally safe**: `clipShape(_:style:)` and `RoundedRectangle` are both `iOS 13+`, so it works on every iOS target with no gating. (The `.rect(cornerRadius:)` shorthand compiles via type inference too, and `.rect` also feeds the `in:` parameter of `.glassEffect`.) Only caveat: `.foregroundStyle` — not this clip — is `iOS 15.0+`, which matters solely if you target iOS 14.

### 7. `tabItem` / inline-destination `NavigationLink` → `Tab` / `.navigationDestination(for:)`

```swift
// ❌ WRONG — legacy tab item + inline list destination (eagerly builds every destination)
TabView { Home().tabItem { Label("Home", systemImage: "house") } }
List { NavigationLink("Detail", destination: DetailView()) }

// ✅ CORRECT — type-safe Tab + value-based navigation
TabView { Tab("Home", systemImage: "house") { Home() } }
List(items) { item in NavigationLink(item.name, value: item) }
    .navigationDestination(for: Item.self) { DetailView(item: $0) }
```

Inline destinations in a `List`/`ForEach` build every destination up front and break value-based navigation. `.navigationDestination(for:)` is iOS 16.0+. The `Tab(...)` struct is `iOS 18.0+` (Apple-confirmed) — gate it per the gating section for any target below iOS 18. On iPad you can also reach for `.tabViewStyle(.sidebarAdaptable)` (iOS 18+) so the tabs adapt to a sidebar at regular width.

### 8. `DispatchQueue.main.async` cargo-cult → `@MainActor` / structured concurrency

```swift
// ❌ WRONG (smell) — pre-async/await main-thread hop, overused under modern concurrency
DispatchQueue.main.async { self.items = newItems }

// ✅ CORRECT — stay on the main actor via isolation, not GCD
@MainActor func update(_ newItems: [Item]) { items = newItems }
// or, hopping in from a Sendable context:
await MainActor.run { items = newItems }
```

When a model hits a concurrency problem it reaches for the old GCD hop an unreasonable number of times. Note: "main actor by default" is the **opt-in** Swift 6.2 build mode (`-default-isolation MainActor`), *not* an unconditional language default — so don't assume `@MainActor` is free everywhere either.

### 9. `Text + Text` concatenation → string interpolation

```swift
// ❌ WRONG — the Text `+` operator is deprecated (iOS 13–26.0)
Text("Hello ") + Text(name).bold()

// ✅ CORRECT — interpolate; style the whole run, or compose with AttributedString
Text("Hello \(name)").bold()
Text(AttributedString(makeStyledGreeting(name)))   // per-run styling
```

A favourite AI cargo-cult: `static func +(Text, Text) -> Text` lets you glue styled runs, and models lean on it constantly. Apple now deprecates it — "Text concatenation using the + operator is deprecated… Use Text interpolation instead." Reach for `Text("… \(value) …")` for a uniformly-styled string, or an `AttributedString` when individual runs need different styling. **Note the window closes early:** this operator is gone at `iOS 26.0`, ahead of the `26.5` cutoff most of the other deprecations carry — so it warns sooner.

---

## Gating discipline — the `#available(iOS …)` arm (read this twice)

This is the single thing even strong artifacts get wrong. With an **iOS-17 deployment floor**, anything above it — `glassEffect` (iOS 26), `Tab(...)` (iOS 18) — *must* be gated, or the build breaks against the lower target. The exact code that runs on an iOS-26 device fails to compile for an iOS-17-targeting app unless every above-floor call is behind a runtime branch or an `@available` annotation.

- **Branch gate** — `#available` picks a code path at runtime; always supply an `else` fallback:
  ```swift
  if #available(iOS 26.0, *) { view.glassEffect() }
  else { view.background(.regularMaterial) }
  ```
- **Whole-symbol gate** — `@available` annotates a type/function that uses a floored API end to end:
  ```swift
  @available(iOS 17.0, *)
  struct ModernModel { /* uses @Observable */ }
  ```
- **Gate on the iOS arm — `#available(iOS 26.0, *)`.** A snippet copied from macOS docs that gates on `#available(macOS 26, *)` silently does **nothing** in an iOS build: the wildcard `*` covers iOS, so the branch always runs and the iOS floor is never enforced. The arm you name must be `iOS`.
- **Match the floor to the real API:** `glassEffect` / Liquid Glass = iOS 26.0+; `Tab(...)` = iOS 18.0+; `@Observable` / `@Bindable` / two-param `onChange` = iOS 17.0+ (= the floor, so usually no gate needed). Gate to the floor of the *highest* API in the branch.
- **Tell:** any iOS-26 / iOS-18 call with **no** nearby `#available` / `@available` and a deployment target below its floor — that is a build break waiting to happen.

---

## Detection tells (grep / scan)

- `NavigationView {` — deprecated; replace with `NavigationStack` (primary) or a gated `NavigationSplitView` (iPad/regular width).
- `.foregroundColor(` — deprecated; replace with `.foregroundStyle(`.
- `.cornerRadius(` — deprecated; replace with `.clipShape(.rect(cornerRadius:`.
- `.onChange(of:` immediately followed by a single-identifier closure `{ newValue in` / `{ value in` — deprecated 1-param form.
- `.tabItem {` — replace with the `Tab(...) { }` API.
- `NavigationLink(` carrying a `destination:` argument **inside a `List` / `ForEach`** — inline destination; move to `.navigationDestination(for:)`.
- `DispatchQueue.main.async` in a file that otherwise uses `async` / `await` — concurrency cargo-cult.
- `Text(` … `) + Text(` — deprecated `Text` `+` concatenation; replace with `Text("… \(value) …")` interpolation or an `AttributedString`.
- `.glassBackground(`, `.liquidGlass(`, `.material(.glass`, `LiquidGlassView`, or any glass-ish modifier — likely hallucinated; the real call is `.glassEffect()` and must be `#available(iOS 26.0, *)`-gated.
- `.glassEffect()` (or any glass call) gated on `#available(macOS 26, *)` in iOS code — wrong arm; the `*` wildcard already covers iOS so the floor is never enforced. Gate on `#available(iOS 26, *)`. `Glass.interactive(_:)` IS iOS 26.0+.
- An iOS-26 / iOS-18 API with **no** nearby `#available` / `@available` and a below-floor target — missing gating (see above).
- `#available(macOS …` guarding an iOS build — wrong arm; the gate never fires on iOS.
- Any unfamiliar modifier that "reads right" but isn't in the docs — treat as hallucinated until verified.

---

## Canonical substitutions (quick reference)

```
Deprecated → current (iOS):
  NavigationView                        → NavigationStack (primary) / gated NavigationSplitView (iPad)
  .foregroundColor(_:)                  → .foregroundStyle(_:)
  .cornerRadius(_:)                     → .clipShape(RoundedRectangle(cornerRadius:))
  .onChange(of:) { newValue in }        → .onChange(of:, initial:) { old, new in }  (or 0-param)
  .tabItem { … }                        → Tab("…", systemImage:) { … }
  NavigationLink(destination:) in List  → .navigationDestination(for:)
  DispatchQueue.main.async              → @MainActor / await MainActor.run
  Text("a") + Text("b")                 → Text("a b")  (interpolation / AttributedString)

DOES NOT EXIST (hallucinations) — never trust without checking docs:
  .glassBackground()   .liquidGlass()   .material(.glass)   LiquidGlassView   .cardStyle()
  REAL Liquid Glass: .glassEffect()  GlassEffectContainer  .buttonStyle(.glass)  — iOS 26.0+ ONLY

ALWAYS gate above your deployment target — on the iOS arm:
  if #available(iOS 26.0, *) { … } else { /* fallback */ }
  @available(iOS 17.0, *) on whole types using @Observable / @Bindable.
```

**Confirmed floors** (Apple docs): `Tab(...)` struct = `iOS 18.0+`; `clipShape(_:style:)` + `RoundedRectangle` = `iOS 13+` (universally safe); `GlassProminentButtonStyle` / `.buttonStyle(.glassProminent)` = `iOS 26.0+` (confirmed — struct exists, not deprecated).

---

## Sources

- Paul Hudson, "What to fix in AI-generated Swift code," 2025-12-09 — https://www.hackingwithswift.com/articles/281/what-to-fix-in-ai-generated-swift-code (accessed 2026-06-06). Source for the deprecation/discouraged set (`NavigationView`, `.foregroundColor`, 1-param `onChange`, `.cornerRadius`, `tabItem`, inline `NavigationLink`, `DispatchQueue.main.async`) and hallucination prevalence.
- Apple — `NavigationView` (deprecated `iOS 13–26.5`; "Use NavigationStack and NavigationSplitView instead"): https://developer.apple.com/documentation/swiftui/navigationview (scraped 2026-06-06).
- Apple — `foregroundColor(_:)` (deprecated `iOS 13–26.5`; "Use foregroundStyle(_:) instead"): https://developer.apple.com/documentation/SwiftUI/View/foregroundColor(_:) (scraped 2026-06-06).
- Apple — `onChange(of:initial:_:)` (current 2-param, `iOS 17.0+`): https://developer.apple.com/documentation/SwiftUI/View/onChange(of:initial:_:)-4psgg (scraped 2026-06-06). Compiler deprecation text via Use Your Loaf — https://useyourloaf.com/blog/swiftui-onchange-deprecation/ (accessed 2026-06-06).
- Apple — `glassEffect(_:in:)` and `GlassEffectContainer` (real Liquid Glass names, `iOS 26.0+`): https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) and https://developer.apple.com/documentation/swiftui/glasseffectcontainer (scraped 2026-06-06).
- Apple — `clipShape(_:style:)` (`iOS 13+`) and `RoundedRectangle` (`iOS 13+`), the safe `.cornerRadius(_:)` replacement: https://developer.apple.com/documentation/swiftui/view/clipshape(_:style:) and https://developer.apple.com/documentation/swiftui/roundedrectangle (confirmed 2026-06-07).
- Apple — `Tab` struct (`iOS 18.0+`): https://developer.apple.com/documentation/swiftui/tab (confirmed 2026-06-07).
- Apple — `Text` `+` operator `static func +(Text, Text) -> Text` (deprecated `iOS 13–26.0`; "Text concatenation using the + operator is deprecated… Use Text interpolation instead"): https://developer.apple.com/documentation/swiftui/text/+(_:_:) (confirmed 2026-06-07).
- Apple — `Observable()` macro (`iOS 17.0+`, gating floor): https://developer.apple.com/documentation/observation/observable() (scraped 2026-06-06).
- Swift 6.2 release (main-actor-by-default is an opt-in `-default-isolation MainActor` build mode, not a language default), Holly Borla, 2025-09-15 — https://swift.org/blog/swift-6.2-released/ (scraped 2026-06-06).
- HN, "Adding a feature because ChatGPT incorrectly thinks it exists" — https://news.ycombinator.com/item?id=44491071 (accessed 2026-06-06; illustrative of API hallucination).
