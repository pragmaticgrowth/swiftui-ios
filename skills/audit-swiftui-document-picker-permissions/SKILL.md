---
name: audit-swiftui-document-picker-permissions
description: Audits a finished iOS SwiftUI codebase for document-picker, security-scoped-URL, and file-consent defects, writing per-finding Markdown to swiftui-audits/. Use when a file read fails though the URL looks valid, a picked file is unreachable next launch, or Photos/Files access returns nothing; when AI read a fileImporter/UIDocumentPickerViewController URL with no startAccessingSecurityScopedResource(); when a picked URL is persisted by .path or a plain bookmarkData() lacking .withSecurityScope; when startAccessingSecurityScopedResource has no balancing stop/defer; when a raw UIDocumentPicker/PHPicker is bridged where fileImporter/PhotosPicker fits; when drag-drop uses NSItemProvider/onDrop instead of Transferable; or when a Photos/Files API lacks an Info.plist usage string. AUDIT-ONLY, iOS-only, SwiftUI-only. Not the loadTransferable Sendable-race owner (concurrency-safety), bridge-or-not (uikit-overuse), the FileDocument/DocumentGroup shape (app-file-handling), or usage strings (privacy-permissions).
---

# Audit SwiftUI Document Picker & File Permissions

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way file access goes wrong through the **document
picker and the security-scoped URL it hands back**: reading a picked URL with no
`startAccessingSecurityScopedResource()`, a picked URL persisted without a security-scoped bookmark, a
`start` access with no balancing `stop`, a raw `UIDocumentPickerViewController`/`PHPickerViewController`
bridge where SwiftUI's `fileImporter`/`PhotosPicker` fits, legacy `NSItemProvider`/`.onDrop` instead of
`Transferable`, and Photos/Files use with no Info.plist usage string. Findings are written to disk in the
toolkit's unified schema; certain mechanical defects are fixed under the fix-safety protocol. This is
never a from-scratch file-pipeline generator.

The governing rule that makes this domain counter-intuitive — and the reason AI gets it wrong (training
data treats a `URL` like a freely-readable path): **a URL the document picker hands you is
security-scoped — holding it is NOT the same as being allowed to open it.** An iOS app reaches its own
container freely, but a file *outside* it (chosen through `fileImporter`/`UIDocumentPickerViewController`,
or a folder/file from the Files provider) is wrapped in a **security scope** you must explicitly enter
with `startAccessingSecurityScopedResource()` and balance with `stopAccessingSecurityScopedResource()` —
and that grant does **not** survive relaunch without a `.withSecurityScope` bookmark.

> iOS is **not** macOS here. There is no App Sandbox *entitlement* plist to declare
> (`com.apple.security.*`), no Hardened Runtime, and no `NSOpenPanel`/`NSSavePanel`/`NSPasteboard` — every
> iOS app is sandboxed unconditionally and the consent surface is the **picker** plus the
> **security-scoped URL**. Photos/Files *consent* on iOS is an **Info.plist usage string**
> (`NSPhotoLibraryUsageDescription` etc.), owned by `audit-swiftui-privacy-permissions` (cross_ref).

## Boundary / seam note (stay in lane)

- **The `loadTransferable` Swift-6 Sendable data race** ("Sending main actor-isolated value …") is owned
  by **`audit-swiftui-concurrency-safety`** (the isolation fix: move the picker item + transfer work into
  an `@Observable` model). This skill owns only the *file-consent* angle of the same site; emit a
  `cross_ref: audit-swiftui-concurrency-safety` when the isolation hazard is present (dp-06).
- **Whether a `UIDocumentPickerViewController`/`PHPickerViewController` bridge should exist at all** is
  owned by **`audit-swiftui-uikit-overuse`** (prefer SwiftUI `fileImporter`/`PhotosPicker`); the *how* of
  a kept bridge is **`audit-swiftui-uikit-interop`**. This skill owns **security-scope/consent
  correctness** once a picker or importer is in use; `cross_ref` overuse/interop (dp-04).
- **The `FileDocument`/`DocumentGroup`/`ReferenceFileDocument` document shape** is owned by
  **`audit-swiftui-app-file-handling`**; this skill owns the *consent/bookmark* angle of the same file IO
  and `cross_ref`s it.
- **The Info.plist usage string / privacy manifest** (`NSPhotoLibraryUsageDescription`,
  `PrivacyInfo.xcprivacy`) is owned by **`audit-swiftui-privacy-permissions`**; this skill flags a
  Photos/Files API in use and `cross_ref`s privacy for the string itself (dp-07).
- **The blanket "is every OS-floored API gated" sweep** belongs to `audit-swiftui-availability-gating`;
  this skill owns the floors of the picker/Transferable APIs in depth and defers the rest.

## The three non-negotiable iOS rules

1. **A picked file is security-scoped — enter the scope before you read.** A URL from
   `fileImporter`/`UIDocumentPickerViewController` (or a Files-provider folder) sits **outside** the app
   container. Wrap every read/write in `startAccessingSecurityScopedResource()` … (guard the `Bool`) …
   `stopAccessingSecurityScopedResource()` balanced by `defer`. Your own container
   (`FileManager.default.url(for: .documentDirectory …)`, `Bundle.main`) needs no scope — the trap is
   reading a *picked, out-of-container* URL with no scope.
2. **Persistence needs a security-scoped bookmark.** To re-open a user file next launch, persist
   `url.bookmarkData(options: .withSecurityScope)` (the `Data`, not `.path`); resolve with
   `URL(resolvingBookmarkData:options: .withSecurityScope …)` and wrap re-access in ref-counted
   `startAccessingSecurityScopedResource()` … `stopAccessingSecurityScopedResource()` balanced by `defer`.
   A plain `bookmarkData()` round-trips the *path*, not the *permission*.
3. **Get the file from the picker; declare Photos/Files consent in Info.plist.** Source a user file
   through SwiftUI `fileImporter`/`fileExporter` or `PhotosPicker` (not a raw UIKit picker bridge unless
   justified). Photos/Files access also needs an Info.plist usage string (e.g.
   `NSPhotoLibraryUsageDescription`) — owned by `privacy-permissions`, flagged here.

**The consent test:** trace each out-of-container file URL back to its origin — a picker
(`fileImporter`/`UIDocumentPickerViewController`) or a resolved security-scoped bookmark → **granted**,
but only if the read sits **inside** a `start`/`stop` scope; a read of a picked URL with **no**
`startAccessingSecurityScopedResource()`, a `.path` persisted to `UserDefaults`, or a plain
`bookmarkData()` → **ungranted, will fail at runtime.** Full reasoning + the round-trip artifact:
`references/consent-and-bookmarks.md`.

## Correct (grounded — real shipping code, not a placeholder)

The ✅ for the consent finding (dp-01) is the swiftui-ctx **consensus shape** for `fileImporter`
(`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup fileImporter --platform ios --json`): the top
shape `(isPresented, allowedContentTypes, allowsMultipleSelection)` (40%), `(…, onCompletion)` (28%),
`(isPresented, allowedContentTypes)` (23%) — shown here as the canonical picker + the security-scope wrap
that makes the picked URL actually readable on iOS:

```swift
// ✅ The URL comes from the user through the document picker — but on iOS it is SECURITY-SCOPED:
// enter the scope, guard the Bool grant, balance start with stop via defer.
.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
    guard case let .success(url) = result else { return }
    guard url.startAccessingSecurityScopedResource() else { return }   // ← the iOS-load-bearing line
    defer { url.stopAccessingSecurityScopedResource() }
    let text = try? String(contentsOf: url, encoding: .utf8)           // reachable only inside the scope
    // to re-open next launch, persist url.bookmarkData(options: .withSecurityScope) (dp-02)
}
```

- **Apple doc (Sosumi):** `doc:` <https://sosumi.ai/documentation/swiftui/view/fileimporter> — `fileImporter` introduced iOS 14.0.
- **Apple doc (Sosumi):** `doc:` <https://sosumi.ai/documentation/foundation/url/startaccessingsecurityscopedresource()> — ref-counted; each `start` needs one `stop`.

Contrast the ❌: a `String(contentsOf: pickedURL)` with **no** `startAccessingSecurityScopedResource()` —
the app holds a security-scoped URL it never entered, so the read throws at runtime (dp-01). The fix is
the scope wrap above and, to re-open it next launch, a `.withSecurityScope` bookmark (dp-02).

## Defect index (dp-01 … dp-07)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (silent runtime failure /
won't compile / never-correct on iOS), **warning** (compiles but breaks at runtime), **advisory**
(judgment / craft). `auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| dp-01 | a picked URL (from `fileImporter`/`UIDocumentPickerViewController`) read by `String(contentsOf:`/`Data(contentsOf:`/`FileManager` with **no** preceding `startAccessingSecurityScopedResource()` | warning | flag | `consent-and-bookmarks.md` |
| dp-02 | a picked `URL` persisted by `.path`/`.absoluteString` **or** plain `bookmarkData()` with no `options: .withSecurityScope` | warning | flag | `consent-and-bookmarks.md` |
| dp-03 | `startAccessingSecurityScopedResource()` with no balancing `stopAccessing…`/`defer` (ref-count leak) | warning | flag | `consent-and-bookmarks.md` |
| dp-04 | raw `UIDocumentPickerViewController`/`UIImagePickerController`/`PHPickerViewController` bridge where SwiftUI `fileImporter`/`PhotosPicker` fits | advisory | flag | `pickers-and-transferable.md` |
| dp-05 | `NSItemProvider` `loadObject`/`loadDataRepresentation` or `.onDrop(of:)` callbacks instead of `Transferable` + `.dropDestination` | warning | flag | `pickers-and-transferable.md` |
| dp-06 | `loadTransferable` / `.task` touching a `@MainActor`-created `PhotosPickerItem` (file-consent angle; isolation = concurrency-safety) | warning | flag | `pickers-and-transferable.md` |
| dp-07 | a Photos/Files API (`PHPicker*`/`UIImagePickerController`/`PHPhotoLibrary`) in use with no matching Info.plist usage string | advisory | flag | `pickers-and-transferable.md` |

**One claim is carried as `advisory` and never asserted as fact** (flagged in its reference + written
`source: verify against Xcode 26 SDK`): the exact Info.plist usage-string **key required per API**
(dp-07) — the string itself is owned by `audit-swiftui-privacy-permissions` and read from the
`Info.plist` by hand, never asserted from memory.

## The real API, at a glance

**Real (exist on iOS):** `fileImporter(...)` / `fileExporter(...)` (iOS 14.0+), `UIDocumentPickerViewController`
(UIKit — bridge with care), `PhotosPicker` + `PhotosPickerItem` (iOS 16.0+),
`PHPickerViewController` (UIKit), `URL.bookmarkData(options: .withSecurityScope)` /
`URL(resolvingBookmarkData:options:relativeTo:bookmarkDataIsStale:)`,
`startAccessingSecurityScopedResource()` (ref-counted) / `stopAccessingSecurityScopedResource()`,
`Transferable` (iOS 16.0+) + `.draggable(_:)` (iOS 16.0+) / `.dropDestination(for:isEnabled:action:)`,
`CodableRepresentation`.

**Wrong on iOS / stale:** a raw `UIDocumentPickerViewController`/`UIImagePickerController`/`PHPickerViewController`
bridge where SwiftUI's `fileImporter`/`PhotosPicker` is the native answer (a *whether-to-bridge* smell —
cross_ref `uikit-overuse`); persisting a picked URL by `.path` or a plain `bookmarkData()` (round-trips
the path, **not** the security scope); reading a picked URL with **no** security-scope wrap.

Floor *values* are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`;
the canonical platform-wrong/invented-name list is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read, never restate them.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources **and** the `Info.plist` (Photos/Files usage strings
   feed dp-07). Read the **deployment target** (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or
   `Package.swift` `platforms:`) — load-bearing for the `Transferable`/`PhotosPicker` iOS-16 floor and the
   `fileImporter` iOS-14 floor. Record the target.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-document-picker-permissions --dir <sources> --json /tmp/dp.json --sarif /tmp/dp.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + tier-2 structural ast-grep rules
   (`lint/ast-grep/*.yml` — the start-without-stop and item-provider-in-onDrop rules grep can't express),
   plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a
   flagged file did not fully parse, so a structural miss can't masquerade as clean; READ those by hand.
   The runner only LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`. The lint scans `*.swift`; the
   **`Info.plist` usage-string check (dp-07) is read by hand** in this step.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. The URL's
   *origin* (picker vs container vs bookmark), the `start`/`stop` balance across a function body, and the
   match between a Photos/Files API and its Info.plist string are invisible to grep. Build a per-file
   inventory: each out-of-container file URL + its origin (consent test) + its persistence (bookmark or
   `.path`) + its `start`/`stop` balance.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `String(contentsOf:)` on a picked URL with no scope, a `.path` persistence, a
   `bookmarkData()` with no `.withSecurityScope`). For dp-06, if the `loadTransferable` site also carries
   an isolation hazard, set `cross_ref: audit-swiftui-concurrency-safety`. For dp-04, set
   `cross_ref: audit-swiftui-uikit-overuse`. For dp-07, set `cross_ref: audit-swiftui-privacy-permissions`.
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, a
   deprecation), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx deprecated <api>` where relevant): read its `consensus`
   (the canonical shape), `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`, and
   `co_occurs_with`; a `lookup` **exit 3** (not-found / no iOS arm) corroborates a platform-wrong finding.
   (b) **Spec** — confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote
   with the citation or discard. Carry the dp-07 usage-string-key assumption as `advisory` with
   `source: verify against Xcode 26 SDK` — never as fact.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅ "Correct" is
   **not a hand-written snippet** — it is the swiftui-ctx **consensus shape** put in `## Correct`, backed
   by a real iOS example fetched with `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart`
   whose GitHub permalink (plus the Sosumi `doc:`) goes in `## Source`. Every consent/bookmark fix is
   `fix_mode: flag-only` (it depends on the picker wiring and the persistence intent) — leave them `open`
   with the ✅ in `## Correct`.
8. **DOUBLE-CHECK.** Re-grep each fixed file to confirm the tell no longer matches; record the evidence
   in `## Fix applied?`. Re-confirm every citation still resolves and still says the recorded floor. If a
   fix introduced a new tell (e.g. a `start` you added now needs a balancing `stop`), loop that file back
   to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can
become a finding — never emit a speculative finding. Every consent/bookmark/picker fix is
`fix_mode: flag-only` because it depends on the picker wiring and the app's persistence intent (never
blindly wrap a read in a scope without confirming the URL is picked and out-of-container).

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/document-picker-permissions/<context>/NN-slug.md` (one finding per file,
  zero-padded, ordered). Per-run index: `swiftui-audits/document-picker-permissions/_index.md`.
- `domain: document-picker-permissions`. Frontmatter is the canonical schema; `fix_mode` is `flag-only`.
  `availability` reads from `floors-master.md`. `source` is an Apple URL + access date (fetched via
  Sosumi) or `verify against Xcode 26 SDK`. Emit `cross_ref` per the boundary note (concurrency-safety
  for dp-06, uikit-overuse/uikit-interop for dp-04, privacy-permissions for dp-07, app-file-handling for
  the document-shape angle).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `security-scoped-read/` | a picked, out-of-container URL is read with no `startAccessingSecurityScopedResource()` (dp-01) |
| `security-scoped-bookmarks/` | a picked URL is persisted by `.path`/plain bookmark, or `start` has no balancing `stop` (dp-02, dp-03) |
| `picker-bridge/` | a raw `UIDocumentPickerViewController`/`PHPickerViewController`/`UIImagePickerController` bridge where SwiftUI fits (dp-04) |
| `transferable-drag-drop/` | legacy `NSItemProvider`/`onDrop`, or the `loadTransferable` consent angle (dp-05, dp-06) |
| `photos-files-consent/` | a Photos/Files API in use with no Info.plist usage string (dp-07) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/document-picker-permissions/` with a lowercase-hyphen slug naming the sub-category, and
note it in the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency
across runs is a hard requirement.* Two runs over the same code produce structurally identical trees.

> **Go-beyond artifact (optional):** `swiftui-audits/document-picker-permissions/_consent-map.md` tracing
> every out-of-container file URL to its origin (picker / bookmark / container) with a consent-coverage
> score — see `references/consent-and-bookmarks.md`.

## Reference routing

| File | Open when |
|---|---|
| `references/consent-and-bookmarks.md` | a consent/persistence question — the no-scope read, the security-scoped-bookmark round-trip, the `start`/`stop` ref-count balance, the stale-bookmark re-create, the consent map (dp-01/02/03) |
| `references/pickers-and-transferable.md` | the SwiftUI-vs-UIKit picker decision (`fileImporter`/`PhotosPicker` vs `UIDocumentPickerViewController`/`PHPickerViewController`), drag-drop modernization (`NSItemProvider`/`onDrop` → `Transferable` + `.dropDestination`), the `loadTransferable` consent seam, and the Photos/Files usage-string flag (dp-04/05/06/07) |
| `references/source-directory.md` | step VERIFY — the Apple/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + tier-2 structural ast-grep); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth — `fileImporter` iOS 14.0, `Transferable`/`PhotosPicker` iOS 16.0) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical platform-wrong/invented-name list |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (`#available(iOS NN, *)` discipline for the floored picker/Transferable APIs) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (concurrency-safety · uikit-overuse · app-file-handling · privacy-permissions) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-document-picker-permissions --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this
skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`,
dp-01/02/04/05/06/07 flat presence) + **tier-2 ast-grep** structural rules (`lint/ast-grep/*.yml` —
dp-03 `start` with no balancing `stop` in the same function, dp-05 `NSItemProvider.load*` inside an
`.onDrop` closure) that grep cannot express. It runs a per-file **parse probe** (surfaces "did not fully
parse" so a structural miss can't look clean), emits unified **JSON + SARIF**, and **degrades to
grep-only with a notice** if ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster:
`brew install ast-grep`). It only LOCATES — always READ each hit in full before reporting (step 3), and
read the `Info.plist` by hand (the lint is `*.swift`-only). The thin `scripts/document-picker-lint.sh` is
a pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
