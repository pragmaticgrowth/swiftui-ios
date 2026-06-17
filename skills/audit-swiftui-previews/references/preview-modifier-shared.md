# Shared PreviewModifier instead of per-preview inline containers (prev-09)

The inline `.modelContainer(for:inMemory:true)` (the prev-06 fix) builds a **fresh** container — and
re-seeds sample data — for *every* `#Preview`, which is wasteful when many previews share one fixture. On
**iOS 18.0+**, `PreviewModifier` is the modern fix: build the `ModelContainer` **once** in
`makeSharedContext()` (Preview caches it by the modifier type and reuses it across previews), then attach
it as a trait with `.modifier(_:)`. It wraps any reusable preview environment, not just SwiftData.
`advisory`, `fix_mode: flag-only`.

```swift
// ❌ (iOS 18+) — every preview rebuilds + re-seeds its own container
#Preview { ItemListView().modelContainer(for: Item.self, inMemory: true) /* seed… */ }
#Preview("Filtered") { FilteredView().modelContainer(for: Item.self, inMemory: true) /* seed again… */ }
```
```swift
// ✅ define the fixture once, share it via .modifier (iOS 18.0+)
struct SampleData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        container.mainContext.insert(Item(name: "Sample"))   // seeded ONCE, cached & reused
        return container
    }
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

#Preview(traits: .modifier(SampleData())) { ItemListView() }
#Preview("Filtered", traits: .modifier(SampleData())) { FilteredView() }
```

## Floor gates (VERIFY at audit time)

- `PreviewModifier` / `.modifier(_:)` trait — **iOS 18.0+** (carried `verify-SDK` in
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`). Confirm via `swiftui-ctx lookup
  PreviewModifier --platform ios --json` + Sosumi before asserting.
- `@Previewable @Query` inside a `#Preview` body also needs **iOS 18**. Keep the prev-06 inline
  in-memory container as the **iOS-17 fallback** when the deployment target can't require iOS 18
  (read in ORIENT).
- `ModelContainer.init(for:configurations:)` (variadic) is iOS 18.0+; `ModelConfiguration` /
  `isStoredInMemoryOnly` are the right knobs — gate on the iOS arm per
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` if the floor is below 18.

Because prev-09 is purely a refactor of a *working* preview (not a crash), only raise it when the project
floor is iOS 18+ and the repeated-container pattern actually recurs across multiple `#Preview`s — a
single inline container is fine.

## VERIFY / FIX

`swiftui-ctx lookup PreviewModifier --platform ios --json` for the consensus shape (note: a thin/`low_corpus` result
means lean on Sosumi for the floor); the ✅ in `## Correct` is the consensus shape backed by `swiftui-ctx
file <recommended.id> --smart`; permalink + Sosumi `doc:` go in `## Source`. Fix is `flag-only`.

## Sources

- **Apple — `PreviewModifier` protocol + `.modifier(_:)` trait.** `iOS 18.0+`. Build a shared environment once in `makeSharedContext()` (Preview caches it by modifier type) and apply via `body(content:context:)`; attach with `#Preview(traits: .modifier(SampleData()))`. https://developer.apple.com/documentation/SwiftUI/PreviewModifier — accessed 2026-06-07.
- **Apple — `ModelContainer` / `ModelConfiguration`.** `ModelConfiguration(isStoredInMemoryOnly:)`; the `(for:configurations:)` variadic init is iOS 18.0+. https://developer.apple.com/documentation/swiftdata/modelcontainer — accessed 2026-06-07. https://developer.apple.com/documentation/swiftdata/modelconfiguration — accessed 2026-06-07.
- **WWDC24 — "What's new in SwiftUI" (session 10144).** `PreviewModifier` for shared, cached preview fixtures. https://developer.apple.com/videos/play/wwdc2024/10144 — accessed 2026-06-07.
