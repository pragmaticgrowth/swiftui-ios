# Reference — Container Creation, Previews & Multi-Process (sd-06, sd-07, sd-12)

The `ModelContainer` lifecycle defects: a preview that crashes for lack of an in-memory container, a
`fatalError` that turns every recoverable container error into a hard crash, and the
multi-process container race. Floor *values* live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. Get the canonical container ✅ from
`swiftui-ctx` (see the bottom of this file).

**As of:** 2026-06-07 · iOS 17+ · Xcode 26 SDK.

---

## sd-06 — `#Preview` with no in-memory container → the canvas crashes

Constructing a `@Model` value (or touching `\.modelContext`) with no `ModelContainer` in scope crashes
the preview (*"failed to find a currently active container"*). Previews gate the whole edit loop, so
this is high-friction. Inject an **in-memory** container built from
`ModelConfiguration(isStoredInMemoryOnly: true)` and insert sample data so `@Query` finds something.
`try!` is acceptable **in a preview only**.

❌ model created with no container:
```swift
#Preview { EditingView(trip: Trip(name: "Test")) }   // ❌ no container → preview crash
```
✅ in-memory container + sample data:
```swift
#Preview {                                              // iOS 17+
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Trip.self, configurations: config) // try! OK in preview
    container.mainContext.insert(Trip(name: "Sample"))   // ✅ insert so @Query has data
    return EditingView(trip: Trip(name: "Sample")).modelContainer(container)
}
```
> **Init availability:** the variadic `ModelContainer(for:configurations:)` is iOS 17+. Use
> `ModelContainer(for:migrationPlan:configurations:)` with `migrationPlan: nil` for maximum
> back-compatibility. `@Model`, `ModelContext`, `ModelConfiguration`, `isStoredInMemoryOnly` are
> all iOS 17+. Confirm every floor against `floors-master.md`.

**Detection:** grep `sd-06` locates `#Preview`; the agent READS to confirm it constructs a `@Model`
with no `ModelConfiguration(isStoredInMemoryOnly:` / `.modelContainer(` in scope. Severity **warning**,
`fix_mode: flag-only`. **Seam:** the preview-rig *mechanics* (sample factory, environment injection) are
owned by `audit-swiftui-previews` — emit `cross_ref: previews`; this skill owns the *model-design*
reason it crashes.

## sd-07 — `fatalError` (or `try!`) on `ModelContainer` creation → recoverable errors crash blind

`ModelContainer.init` throws for **recoverable, real-world reasons**: a schema/migration mismatch
(`Code=134504`, *"Cannot use staged migration with an unknown model version"*), no free disk space
(which produces *no* logs), or two processes migrating concurrently (`Code=134110` / `134100`). Apple's
getting-started code wraps this in `fatalError(error.localizedDescription)` — turning each into a hard
crash with no usable diagnostic (the `SwiftDataError` `_explanation` is typically `nil`). On iOS the
multi-process case is **common** (app + widget extension + share extension on one group container), so this is not a
corner case. Catch, classify, recover — or surface a real message.

❌ Apple's `fatalError`:
```swift
do { container = try ModelContainer(for: Trip.self) }
catch { fatalError(error.localizedDescription) }   // ❌ schema/disk/concurrent-migrate → blind crash
```
✅ classify and recover (never blind-`fatalError`):
```swift
do {
    container = try ModelContainer(for: Trip.self, configurations: ModelConfiguration())
} catch {
    // 134504 schema mismatch · no-free-space · 134110/134100 concurrent migration (common in app+widget targets):
    // serialize multi-process opens with a lock file; check disk; clear+recreate on an unrecoverable
    // schema mismatch — or surface a real message. Do NOT fatalError(error).
}
```
**Detection:** grep `sd-07` (`fatalError\(` / `try!`); the agent READS to confirm it is on a non-preview
`ModelContainer` creation (`try!` inside a `#Preview` is fine — see sd-06). Severity **warning**,
`fix_mode: flag-only`.

## sd-12 — multi-process container with no lock-file serialization

A sandboxed store lands in the app/group container (`…/Library/Application Support/default.store`).
Sharing it with a widget extension or app extension needs a **group-container** entitlement, and those multi-process
opens are exactly what triggers the concurrent-migration crash class in sd-07. Serialize container
creation across processes with a lock file.

**Detection:** grep `sd-12` locates container sites; the agent READS the project for a second
container-opening target (a widget extension, a share extension, or an app clip) with no serialization. Severity
**advisory**, `fix_mode: flag-only`. **Seam:** the store-location / group-container **entitlement** is
owned by `audit-swiftui-document-picker-permissions` — emit `cross_ref: document-picker-permissions`.

---

## The canonical container ✅ — from swiftui-ctx (verified during this build)

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup ModelContainer --json` returns the dominant
real-world shape: **`(for, configurations)` at 76% consensus** (the variadic init). Its
`recommended` example (`introduced_ios: 17.0`, `doc: https://sosumi.ai/documentation/swiftui/modelcontainer`):

```swift
ModelContainer(for: schema, configurations: [modelConfiguration])
// fayazara/bucketdrop · BucketDropApp.swift#L29 · author_authority 9558 · 218★
// https://github.com/fayazara/bucketdrop/blob/92816bedcd2267022ede0c797d12e593f0997e4b/BucketDrop/BucketDropApp.swift#L29
```
`ModelContainer` `co_occurs_with` `Schema`, `ModelConfiguration`, `ModelContext`, `Query` — the real
container-layer cluster. Fetch the full enclosing body for `## Correct` with
`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart`; put its permalink + the
Sosumi `doc:` in `## Source`.

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://scottdriggers.com/blog/swiftdata-modelcontainer-creation-crash/ | practitioner blog | high | "creating a `ModelContainer` can throw … they recommend crashing your app with `fatalError`"; the three causes (schema mismatch / no free disk space / concurrent migrators); `Code=134504`; `SwiftDataError(… _explanation: nil)`. Accessed 2026-06-06. |
| https://www.hackingwithswift.com/quick-start/swiftdata/how-to-use-swiftdata-in-swiftui-previews | practitioner tutorial (Paul Hudson, upd. Xcode 16.4) | high | "create a custom `ModelConfiguration` that stores data in memory only …" and "If you attempt to create a model object without first having created a container … your preview will crash." Accessed 2026-06-06. |
| https://www.reddit.com/r/swift/comments/145e4p7/swiftdata_crashes_in_preview/ | forum | medium | corroborates the preview-crash-without-container symptom. Accessed 2026-06-06. |
| https://developer.apple.com/documentation/swiftdata/modelcontainer | primary-doc | high | `init(for:configurations:)` (variadic) and `init(for:migrationPlan:configurations:)` are both iOS 17.0+. Confirmed 2026-06-07. |
| https://github.com/fayazara/bucketdrop/blob/92816bedcd2267022ede0c797d12e593f0997e4b/BucketDrop/BucketDropApp.swift#L29 | corpus example (swiftui-ctx `recommended`) | high | the canonical `ModelContainer(for: schema, configurations: [modelConfiguration])` shape (64% consensus). Fetched 2026-06-07. |
