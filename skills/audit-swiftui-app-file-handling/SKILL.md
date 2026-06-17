---
name: audit-swiftui-app-file-handling
description: Audits a finished or in-progress iOS SwiftUI codebase for document and file-handling defects and writes per-finding Markdown to swiftui-audits/. Use when the user has a DocumentGroup, FileDocument, ReferenceFileDocument, fileImporter, fileExporter, or fileMover app and says saving is broken, edits do not persist, the document never gets dirty, the file type is not recognized, or the import sheet shows nothing; when AI may have written FocusedDocument, a class conforming to FileDocument, a ReferenceFileDocument with no snapshot, a fileImporter with no allowedContentTypes, a raw UIDocumentPickerViewController bridge, UIDocument inside SwiftUI, an ungated DocumentGroupLaunchScene (iOS 18), or serialization on the main actor; or when readableContentTypes, writableContentTypes, or a custom UTType is misdeclared. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for SwiftData stores, not for security-scoped consent or bookmarks, not for scene-lifecycle plumbing, not for writing a new document app.
---

# Audit SwiftUI App File Handling

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way the **document / file-handling architecture** goes
wrong: the wrong document protocol (value `FileDocument` vs reference `ReferenceFileDocument`), a missing
`snapshot(contentType:)`, mis-declared content types / UTTypes, a `fileImporter` with **no
`allowedContentTypes`** (nothing is selectable), mishandled `FileWrapper` (data loss), mutation that bypasses
the document binding (no dirty-state / no autosave), serialization pinned to the main actor, a phantom
`@FocusedDocument`, `UIDocument` / a raw `UIDocumentPickerViewController` smuggled into a SwiftUI app, and a
`DocumentGroupLaunchScene` used **without a gate** above the project floor. Findings are written to disk in
the toolkit's unified schema; this domain has **no mechanical auto-fix** (every correction is judgment-
gated), so findings are emitted `flag-only` with the ✅ shown. Never a from-scratch document-app generator.

The document API surface (`DocumentGroup`/`FileDocument`/`ReferenceFileDocument`/`FileDocumentConfiguration`)
is **iOS 14.0+** but thinly used, so AI frequently confuses the value vs reference split and invents
`@FocusedDocument`. The sheet-presented importers (`fileImporter`/`fileExporter`/`fileMover`, all iOS 14.0+)
are the iPhone/iPad-native way to reach files — AI often reaches for a raw `UIDocumentPickerViewController`
bridge instead, or forgets `allowedContentTypes`. Be suspicious wherever AI wrote document-app or file-import
scaffolding.

## Boundary / seam note (stay in lane)

- **SwiftData (`@Model`/`ModelContainer`/`@Query`) persistence is out of scope** → `audit-swiftui-swiftdata`.
  This skill owns the *document* file format (`FileDocument`/`ReferenceFileDocument`), not the database.
- **Security-scoped *consent* — `startAccessingSecurityScopedResource`, the bookmark round-trip, Photos/Files
  permission** belongs to `audit-swiftui-document-picker-permissions`. This skill owns the document *type*,
  the importer's `allowedContentTypes`/shape, and the read/write; the consent correctness of a
  `fileImporter`/`fileExporter` result (doc-11) is flagged here and `cross_ref`'d there.
- **Scene-lifecycle plumbing — `scenePhase`, save-on-background, `@SceneStorage` restoration** belongs to
  `audit-swiftui-app-lifecycle-background`. The `DocumentGroupLaunchScene` floor-gate trap (doc-05) is flagged
  here and `cross_ref`'d there.
- **Serialization Sendable / actor-isolation correctness** is owned by `audit-swiftui-concurrency-safety`;
  this skill flags the *MainActor-pinned document* smell (doc-08) and `cross_ref`s it there.
- **HOW a justified UIKit bridge is wired** (`UIViewControllerRepresentable`/`Coordinator`) is
  `audit-swiftui-uikit-interop`; `UIDocument` / a raw `UIDocumentPickerViewController` in a SwiftUI app
  (doc-04) is flagged here and `cross_ref`'d there.

## The document / file-handling design rules (non-negotiable)

1. **Value vs reference is a type decision, not a style.** A small, snapshot-serializable model →
   `struct: FileDocument` (SwiftUI copies a value to write). A large/graph/incrementally-mutated model →
   `final class: ReferenceFileDocument` (reference semantics + `snapshot(contentType:)`). A **class
   conforming to `FileDocument`** (doc-02) defeats the value contract; a `ReferenceFileDocument` without
   `snapshot(contentType:)` (doc-03) does not compile / loses the write.
2. **All edits flow through the document binding.** Mutate via the `$document` binding from
   `FileDocumentConfiguration` (or the `@ObservableObject`/`@Observable` reference document) so SwiftUI
   marks the scene dirty and autosaves. Mutating a copy / `configuration.document` directly (doc-10) means
   no dirty-state and silent data loss.
3. **Declare every content type you read, write, or import.** `readableContentTypes` / `writableContentTypes`
   and a `fileImporter`'s `allowedContentTypes` must be real `UTType`s, and any custom UTI must be
   exported/imported in `Info.plist` (doc-06); an editable document that omits `writableContentTypes` is
   read-only by accident (doc-07); a `fileImporter` with **no `allowedContentTypes`** shows an empty/locked
   picker (doc-13).
4. **Reach files the SwiftUI way.** On iOS the sheet-presented `fileImporter` / `fileExporter` / `fileMover`
   are the native importers — prefer them over a hand-bridged `UIDocumentPickerViewController` (doc-04). The
   security-scoped URL they return must be consumed correctly; that consent is owned by
   `document-picker-permissions` (doc-11).
5. **Don't serialize on the main actor.** Apple: *"Don't perform serialization on MainActor."* A document
   type annotated `@MainActor` (doc-08) drags `init(configuration:)` / `fileWrapper(...)` onto the main
   thread and blocks the UI on every save.
6. **Gate `DocumentGroupLaunchScene` to its floor.** It is a **real iOS API (iOS 18.0+)** — the native
   document-launch experience — but it sits **above this toolkit's iOS-17 project floor**, so an ungated use
   (doc-05) won't compile/run on iOS 17. Gate it with `@available(iOS 18, *)` / `if #available`, don't remove
   it.

Full reasoning + the value/reference decision table: `references/file-document-model.md`.

## Defect index (doc-01 … doc-13)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (build break / never-correct),
**warning** (compiles but unsound), **advisory** (judgment / perf). All findings are **`flag` (flag-only)**
— document architecture has no mechanical single-answer fix; show the ✅, the dev applies it.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| doc-01 | `@FocusedDocument` — phantom property wrapper (does not exist) | hard-fail | flag | `document-api-surface.md` |
| doc-02 | a **class** conforming to value-type `FileDocument` (use `ReferenceFileDocument`) | warning | flag | `file-document-model.md` |
| doc-03 | `: ReferenceFileDocument` with **no** `func snapshot(contentType:)` | hard-fail | flag | `file-document-model.md` |
| doc-04 | `UIDocument` / raw `UIDocumentPickerViewController` inside a SwiftUI app | warning | flag | `document-scene.md` |
| doc-05 | `DocumentGroupLaunchScene` (iOS 18.0) used **without an availability gate** | warning | flag | `document-scene.md` |
| doc-06 | `UTType(exportedAs:` / `importedAs:` not declared in `Info.plist` | warning | flag | `content-types-utis.md` |
| doc-07 | `readableContentTypes` set, `writableContentTypes` omitted on an editable doc | warning | flag | `content-types-utis.md` |
| doc-08 | `@MainActor` on the document type → serialization on the main actor | warning | flag | `file-document-model.md` |
| doc-09 | `FileWrapper.regularFileContents` force-unwrapped / un-guarded → data loss | warning | flag | `file-document-model.md` |
| doc-10 | `configuration.document` mutated directly (not via the `$document` binding) | warning | flag | `file-document-model.md` |
| doc-11 | `FileManager` / `Data(contentsOf:)` manual IO, or an unconsumed importer URL | advisory | flag | `document-scene.md` |
| doc-12 | `ReferenceFileDocument` app with no `@Environment(\.undoManager)` undo wiring | advisory | flag | `file-document-model.md` |
| doc-13 | `.fileImporter(...)` with **no `allowedContentTypes:`** → empty/locked picker | warning | flag | `content-types-utis.md` |

doc-10 has **no clean lint tell** (mutation-through-binding is semantic) — `configuration.document` is a
*locator* hint only; the real call is READ-by-hand at step 3. doc-03/doc-12 share the `ReferenceFileDocument`
grep locator and split in DETECT.

## The real API, at a glance

**Real (exist on iOS):** `DocumentGroup(newDocument:)` / `(viewing:)` / `(editing:migrationPlan:)` (iOS 14.0+),
`FileDocument` (a **struct** protocol, iOS 14.0+), `ReferenceFileDocument` (a **class** + `Sendable` protocol,
requires `snapshot(contentType:)` + `fileWrapper(snapshot:configuration:)`, iOS 14.0+),
`FileDocumentConfiguration` (gives the `$document` **binding** + `fileURL` + `isEditable`),
`ReferenceFileDocumentConfiguration`, `static readableContentTypes` / `writableContentTypes: [UTType]`,
`init(configuration:)`, `fileWrapper(configuration:)` / `fileWrapper(snapshot:configuration:)`, `FileWrapper`,
`UTType(exportedAs:)` / `(importedAs:)`, `@Environment(\.undoManager)`, the sheet importers
`.fileImporter(isPresented:allowedContentTypes:…)` / `.fileExporter(…)` / `.fileMover(…)` (all iOS 14.0+),
and **`DocumentGroupLaunchScene` (iOS 18.0+)** — a real iOS launch experience that needs a gate above the
iOS-17 floor.

**Hallucinated / wrong:** `@FocusedDocument` (**not a real symbol** → custom `FocusedValues` `@Entry` key +
`@FocusedValue(\.focusedDocument)`); a **`class … : FileDocument`** (value protocol on a reference type);
`UIDocument` / a raw `UIDocumentPickerViewController` in a SwiftUI lifecycle (use `DocumentGroup` /
`fileImporter`).

Allow-list, signatures, and the `@FocusedDocument` → custom-key rewrite: `references/document-api-surface.md`.
Floor *values* are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the
canonical invented-name list (incl. `@FocusedDocument`) is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read, never restate them.

## Grounded ✅ — the canonical document-app shape (real code, not a placeholder)

The `## Correct` block on every finding is the **swiftui-ctx consensus shape** backed by a real iOS
example — never a hand-invented snippet. From `swiftui-ctx lookup DocumentGroup --platform ios --json`
(introduced iOS 14.0; corpus `repo_count: 3`): consensus `(newDocument)` **100%**. The `recommended`
permalinked example (`ex_296b66f771`, `nathanfallet/ocaml`, min iOS 16) fetched via
`swiftui-ctx file ex_296b66f771 --smart`:

```swift
// ✅ canonical DocumentGroup — value document, edits flow through the configuration binding (doc-10)
@main struct AcmeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { NoteDocument() }) { file in
            EditorView(document: file.$document)        // mutate via $document → dirty-state + autosave
        }
    }
}
```

```swift
// ✅ canonical fileImporter — allowedContentTypes is REQUIRED (doc-13); consume the security-scoped URL (doc-11)
.fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.plainText]) { result in
    // consent/bookmark handling owned by document-picker-permissions
}
```

- **Source (canonical example):** `https://github.com/nathanfallet/ocaml/blob/871ea233cc2f5a07d6c59ac1c225d2c3f27315f3/Shared/OCamlApp.swift#L48`
- **Spec (`doc:`):** `https://sosumi.ai/documentation/swiftui/documentgroup`

Step 7 (FIX) regenerates this same trio (consensus shape + `--smart` permalink + Sosumi `doc:`) for the
specific finding's API; the snippets above are the worked instances for `DocumentGroup` / `fileImporter`.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Confirm this is a **document or file-handling app** (a
   `DocumentGroup` scene in the `App` body, or a `.fileImporter`/`.fileExporter` call) and read the
   deployment target (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET` / `Package.swift` `platforms:`). Note
   whether the model is value- or reference-shaped — it drives the doc-02/doc-03 split.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-app-file-handling --dir <sources> --json /tmp/doc.json --sarif /tmp/doc.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + tier-2 structural ast-grep rules
   (`lint/ast-grep/*.yml` — the missing-`snapshot` and MainActor-pinned-document rules grep can't express),
   plus a per-file **parse probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a
   flagged file did not fully parse, so a structural miss can't masquerade as clean; READ those by hand.
   The runner only LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. The
   value/reference choice, the binding flow, container conformance, the importer's `allowedContentTypes`, and
   `Info.plist` UTI declarations are invisible to grep. Build a per-file inventory: each document type + its
   kind (value/reference) + its content types + how edits reach it (binding vs copy) + its serialization
   actor + every importer call and its `allowedContentTypes`.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** (e.g. a `@FocusedDocument`, a `class … : FileDocument`, a `ReferenceFileDocument` with no
   `snapshot`, a `.fileImporter` with no `allowedContentTypes`, a `DocumentGroupLaunchScene` with no
   `iOS 18` gate above the project floor).
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, a
   serialization-actor claim), run **both** evidence sources. (a) **Practice** — `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and `swiftui-ctx deprecated
   <api>` for a currency rule): read its `consensus` (the canonical shape), `deprecated`+`replacement`,
   `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a `lookup` returning **not_found**
   (`ok:false`, `error.class: not_found` + a did-you-mean `suggestion`) corroborates a hallucination finding —
   no shipping iOS app uses the symbol (this is how `@FocusedDocument` resolves). (b) **Spec** — confirm via
   **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path
   and `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md` and the Sosumi `doc:`
   floor. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote
   with the citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Emit a `cross_ref` on shared-seam findings (doc-04 → uikit-interop, doc-05 → app-lifecycle-background,
   doc-08 → concurrency-safety, doc-11/doc-13 → document-picker-permissions). Write the run's `_index.md`.
7. **FIX.** This domain is **`fix_mode: flag-only` end-to-end** — no auto-fix (document type / binding /
   UTI / importer changes are never a mechanical single answer). Under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`) leave every finding `open` with the
   ✅ in `## Correct`. The ✅ is **not a hand-written snippet** — it is the swiftui-ctx **consensus shape**
   put in `## Correct`, backed by a real iOS example fetched with `bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink (plus the
   Sosumi `doc:`) goes in `## Source` as the canonical example. The canonical `DocumentGroup` shape is
   `(newDocument:editor:)` (per `swiftui-ctx lookup DocumentGroup --platform ios`, `recommended` =
   `ex_296b66f771` → `nathanfallet/ocaml` `OCamlApp.swift#L48`).
8. **DOUBLE-CHECK.** Re-grep each touched file to confirm the tell no longer matches; record the evidence
   in `## Fix applied?`. Re-confirm every citation still resolves and still says the floor it claimed. If a
   change introduced a new tell (e.g. switching to `ReferenceFileDocument` now needs a `snapshot`), loop
   that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding. There is **no auto-fix** in this domain; everything is
`fix_mode: flag-only`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/app-file-handling/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/app-file-handling/_index.md`.
- `domain: app-file-handling`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every
  finding. `availability` reads from `floors-master.md`. `source` is an Apple URL + access date (fetched
  via Sosumi) or `verify against Xcode 26 SDK`.
- **Additive field** (catalogued, this domain only): `doc_kind` = `FileDocument` | `ReferenceFileDocument`
  | `DocumentGroup` | `fileImporter` | `n/a` — the document/importer shape the finding concerns. Add it
  alongside the canonical frontmatter; nothing else.

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `phantom-api/` | a name doesn't exist — `@FocusedDocument` (doc-01) |
| `value-vs-reference/` | the wrong document protocol — class-on-`FileDocument`, missing `snapshot` (doc-02, doc-03) |
| `scene-architecture/` | `UIDocument` in SwiftUI, or `DocumentGroupLaunchScene` with no gate (doc-04, doc-05) |
| `content-types/` | a `UTType` undeclared in `Info.plist`, missing `writableContentTypes`, or a `fileImporter` with no `allowedContentTypes` (doc-06, doc-07, doc-13) |
| `serialization-safety/` | serialization on the main actor, or a force-unwrapped `FileWrapper` (doc-08, doc-09) |
| `dirty-state-autosave/` | edits bypass the `$document` binding (doc-10) |
| `manual-io/` | hand-rolled file IO, or an unconsumed importer URL, inside a document app (doc-11) |
| `undo/` | a reference document with no `UndoManager` wiring (doc-12) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/app-file-handling/` with a lowercase-hyphen slug naming the sub-category, and note it in the
run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a hard
requirement.* Two runs over the same code produce structurally identical trees.

## Reference routing

| File | Open when |
|---|---|
| `references/document-api-surface.md` | a name/existence question — the real allow-list + the `@FocusedDocument` → custom-`FocusedValues`-key rewrite (doc-01) |
| `references/file-document-model.md` | the value/reference decision, `snapshot`, `FileWrapper`, binding-mutation, MainActor serialization, undo (doc-02/03/08/09/10/12) |
| `references/content-types-utis.md` | `readableContentTypes`/`writableContentTypes`, custom `UTType`, the `Info.plist` declaration, a `fileImporter`'s `allowedContentTypes` (doc-06/07/13) |
| `references/document-scene.md` | `DocumentGroup` vs `UIDocument`, the `DocumentGroupLaunchScene` floor gate, the `fileImporter` vs raw-picker decision, manual IO (doc-04/05/11) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + tier-2 structural ast-grep); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (incl. `@FocusedDocument`) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS availability-gating rule + the iOS-17 project floor (doc-05) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys (incl. additive `doc_kind`) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the fix-safety protocol (step 7 — all flag-only here) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (doc-04/05/08/11/13) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-app-file-handling --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, doc-01/02/04/05/06/07/09/10/11/12/13) +
**tier-2 ast-grep** structural rules (`lint/ast-grep/*.yml` — doc-03 `ReferenceFileDocument`-missing-`snapshot`,
doc-08 `@MainActor`-pinned document type) that grep cannot express. It runs a per-file **parse probe**
(surfaces "did not fully parse" so a structural miss can't look clean), emits unified **JSON + SARIF**, exits
**2** on any hard-fail (doc-01/03/04/05) for a CI gate, and **degrades to grep-only with a notice** if
ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster: `brew install ast-grep`). It only
LOCATES — always READ each hit in full before reporting (step 3). The thin `scripts/doc-lint.sh` is a
pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
