---
name: audit-swiftui-uikit-overuse
description: Audits a finished or in-progress iOS SwiftUI codebase for UNNECESSARY UIKit bridging — where code drops to UIViewRepresentable/UIViewControllerRepresentable/UIHostingController when a native SwiftUI API already fits — and writes per-finding Markdown to swiftui-audits/. Use when the user says an app bridges too much UIKit, wraps UILabel/UIButton/UISwitch/UISlider/UIDatePicker/UIStepper/UISegmentedControl in a representable, reads UIScreen.main.bounds for layout, reaches UIApplication.shared.windows for the active scene, hand-packs UIPasteboard instead of PasteButton/Transferable, branches layout on UIDevice.current, or bridges a UIVisualEffectView instead of SwiftUI glass; when they ask whether a bridge is justified or could be pure SwiftUI; or to confirm a rich-text UITextView, UICollectionView grid, or first-responder bridge is warranted. AUDIT-ONLY, iOS-only, SwiftUI-only. Not for HOW a bridge is implemented (that is audit-swiftui-uikit-interop).
---

# Audit SwiftUI UIKit Overuse

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to answer one question at every UIKit boundary: **should this bridge exist at all?** It is the
**stay-in-SwiftUI enforcer** — it flags every place the code reaches for UIKit
(`UIViewRepresentable`, `UIViewControllerRepresentable`, `UIHostingController`, `UIScreen.main`,
`UIApplication.shared.windows`, `UIPasteboard`, `UIVisualEffectView`) when a native SwiftUI API already
covers the case, **and** it *confirms* the genuinely warranted escape hatches so they are not churned
away. Findings are written to disk in the toolkit's unified schema; this skill is **flag-only by
default** — it never auto-rewrites a bridge (deleting a representable is too blast-heavy for the
fix-safety floor).

This is the **WHETHER**-to-bridge half of a pair: `audit-swiftui-uikit-interop` owns **HOW** a justified
bridge is implemented correctly (`updateUIView`, Coordinator, first-responder, `@Sendable` boundary).
Every overuse finding cross_refs interop, and vice versa.

## Boundary / seam note (stay in lane)

- **HOW a bridge is wired** — missing `updateUIView`, dead Coordinator, responder-chain, Swift-6
  `@Sendable` race — is **`audit-swiftui-uikit-interop`**. This skill decides *whether the bridge should
  exist*; once it confirms one is warranted (`status: justified`), interop owns its correctness. Emit a
  `cross_ref` on every shared site.
- **UIKit `UIVisualEffectView`** as a blur/glass surface: this skill flags the *bridge* (use SwiftUI
  `.glassEffect`/material); the SwiftUI glass placement/grouping rules are
  **`audit-swiftui-liquid-glass`** and the material/vibrancy choice is **`audit-swiftui-appearance-color`**.
  cross_ref them.
- **`UIDocumentPickerViewController` / `UIImagePickerController`**: this skill owns *whether* to bridge
  (use `fileImporter`/`PhotosPicker`/`DocumentGroup`); **`audit-swiftui-document-picker-permissions`**
  owns security-scoped-bookmark and consent correctness once the SwiftUI API is in place. cross_ref it.
- **raw `UIImpactFeedbackGenerator`** where `.sensoryFeedback` fits: this skill flags the bridge as
  overuse; the feedback *idiom* (which pattern, when) belongs to **`audit-swiftui-haptics`**. cross_ref it.
- **`UITableView`/`UICollectionView` render ceiling**: when a large-data grid is the *justification* for
  a bridge, **`audit-swiftui-view-performance`** owns the cost argument. cross_ref it.

## The one design rule

**Default: stay in SwiftUI. Bridge only the one subsystem that genuinely has no native answer.** Every
`UIViewRepresentable` is a maintenance liability (a `make`/`update`/Coordinator handshake, a
responder-chain edge, a Swift-6 isolation boundary). It earns its keep **only** when SwiftUI has no
equivalent control, no equivalent capability, or not at the project's deployment floor.

**The WHETHER test** (apply to every bridge — full decision tree in
`references/whether-to-bridge.md`): (1) Is there a **native SwiftUI control/API** for this exact thing?
→ if yes, the bridge is *overuse* (flag). (2) Does that native API exist **at the project's deployment
floor** (iOS 17)? → if no (e.g. rich-text `TextEditor(text:selection:)` needs iOS 26), the bridge is
*justified for now*. (3) Does the UIKit view add **capability SwiftUI structurally lacks**
(cell-reuse grid perf at `UICollectionView` scale, precise first-responder / input-accessory control,
advanced `UITextView` text-layout)? → if yes, `status: justified`. Otherwise: **flag as overuse.**

## Defect index (over-01 … over-07)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (never-correct on iOS),
**warning** (compiles but a native API fits), **advisory** (judgment / context-dependent). All findings
are **`fix_mode: flag-only`** — show the SwiftUI ✅, the dev rewrites. (Removing a representable is never
mechanical.)

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| over-01 | a `UIViewRepresentable` wrapping a 1:1-native control — `UILabel`/`UIButton`/`UISwitch`/`UISlider`/`UIStepper`/`UIDatePicker`/`UIProgressView`/`UISegmentedControl`/`UIPickerView`/`UIImageView`/`UITextField` (plain) | warning | flag | `native-control-equivalents.md` |
| over-02 | `UIScreen.main` / `UIScreen.main.bounds` read for layout — **deprecated iOS 16+**; use `GeometryReader`/`containerRelativeFrame`/size class | warning | flag | `scene-and-system-bridges.md` |
| over-03 | `UIApplication.shared.windows` / `.keyWindow` to reach the active scene/window | warning | flag | `scene-and-system-bridges.md` |
| over-04 | `UIPasteboard.general` for copy/paste of a model type | advisory | flag | `scene-and-system-bridges.md` |
| over-05 | UIKit `UIVisualEffectView` bridged for blur/glass | warning | flag | `native-control-equivalents.md` |
| over-06 | a whole screen / large subtree wrapped — `UIHostingController` reverse-bridge in a SwiftUI-first app, or a representable returning a composed `UIStackView`/container | advisory | flag | `scene-and-system-bridges.md` |
| over-07 | a `UITextView` bridge for plain or lightly-styled text on an **iOS-26** floor | advisory | flag | `justified-escape-hatches.md` |

**Justified escape hatches — CONFIRM, never flag** (record `status: justified`, a positive note;
detail + the iOS-26 inflection in `references/justified-escape-hatches.md`): rich-text `UITextView`
**below iOS 26**, `UICollectionView`-grade data grids (cell-level reuse / compositional layout past
`List`/`LazyVGrid`'s ceiling — cross_ref view-performance), precise **first-responder / input-accessory
view / inputView** control, a `UIScrollView` with paging/zoom behavior SwiftUI's `ScrollView`+
`scrollTargetBehavior` can't express, and `PHPickerViewController`/camera surfaces a SwiftUI control
doesn't yet cover. An audited bridge that matches one of these is correct: emit `status: justified`,
not a defect.

## The native SwiftUI surface, at a glance

`UILabel` → `Text` · `UITextField` (plain) → `TextField`/`SecureField` · `UITextView` (iOS 26 rich) →
`TextEditor(text:selection:)` · `UIButton` → `Button` · `UISwitch` → `Toggle` · `UISlider` → `Slider` ·
`UIStepper` → `Stepper` · `UIColorWell`/color → `ColorPicker` · `UIDatePicker` → `DatePicker` ·
`UIProgressView` → `ProgressView` · `UISegmentedControl` → `Picker(...).pickerStyle(.segmented)` ·
`UIPickerView` → `Picker(...).pickerStyle(.wheel)` · `UIImageView` → `Image`/`AsyncImage` ·
`UIScreen.main(.bounds)` → `GeometryReader` / `containerRelativeFrame(_:)` / `horizontalSizeClass` ·
`UIApplication.shared.windows` → `@Environment(\.scenePhase)` + `UIWindowScene` via the scene delegate ·
`UIPasteboard` → `PasteButton` / `.copyable(_:)` + `Transferable` ·
`UIDevice.current.userInterfaceIdiom` (for layout) → `horizontalSizeClass` ·
`UIVisualEffectView` → `.glassEffect(_:in:)` (iOS 26) / `Material` (`.ultraThinMaterial`, iOS 15).

These are existence/floor claims — **confirm the replacement actually exists** in VERIFY via
`swiftui-ctx lookup` + Sosumi; floor *values* are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (read, never restate). `containerRelativeFrame`
is iOS 17+; `TextEditor(text:selection:)` rich text is iOS 26; `PasteButton` is iOS 16+.

### Grounded ✅ example — `UIViewRepresentable<UISwitch>` → `Toggle` (over-01)

This is the canonical correct shape a FIX cites for the most common overuse. It is **not hand-written**:
the `(_, isOn)` form is the swiftui-ctx **consensus shape** (67% of real call sites,
`swiftui-ctx lookup Toggle --platform ios`), and the snippet mirrors the real `recommended` example
(`ex_7d2f6205be`, `Toggle("Save to desktop", isOn:$…)`). Replace a bridged `UISwitch` representable with:

```swift
// ✅ Toggle is native SwiftUI (iOS 13+) — no UISwitch / UIViewRepresentable bridge needed.
Toggle("Sync over cellular", isOn: $syncOverCellular)
    .toggleStyle(.switch)
```

- **Real permalink (## Source):** https://github.com/AvdLee/Diagnostics/blob/574b3f4e07ca5451b9d4e0f2188152aad32085f6/Example/Diagnostics-Example/ContentView%2BmacOS.swift#L26 (repo `AvdLee/Diagnostics`, 1177★, `min_ios: 14`, shape `(_, isOn)`) — re-fetch a same-platform iOS example in FIX.
- **Sosumi `doc:` (## Source):** https://sosumi.ai/documentation/swiftui/toggle — confirms `Toggle` iOS 13.0+.

Re-fetch both in FIX (step 7) for the actual bridge under audit; never paste this verbatim without
re-running `swiftui-ctx` for the specific over-NN API in scope.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources. Read the **deployment target**
   (`project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`). It is load-bearing:
   over-07 (rich-text bridge) is *justified* below iOS 26 and *flaggable* at/above it; the
   `containerRelativeFrame`/`PasteButton` floors (iOS 17/16) gate the over-02/04 replacements. Record it.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-uikit-overuse --dir <sources> --json /tmp/over.json --sarif /tmp/over.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`) + the tier-2 structural ast-grep rule
   (`lint/ast-grep/*.yml` — a representable whose `makeUIView` *constructs* a trivial control, which
   grep can't prove), plus a per-file **parse probe**, emitting unified JSON + SARIF. **Read its
   `parse_warnings`** — a flagged file did not fully parse; READ those by hand. The runner only
   LOCATES — never treat a hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
3. **READ.** Open every located file **in full** — never pattern-match-and-patch blind. A class name
   appearing is not a verdict: a `UITextField` bridge may be a justified input-accessory hatch, not a
   plain-field overuse. Build a per-bridge inventory: each representable/system call + what it wraps +
   the native candidate + whether that candidate exists at the floor.
4. **DETECT.** Apply the WHETHER test + the index. Assign each candidate a **confidence**; report a
   finding **only at 100% certainty** (a 1:1 control wrapper with a floor-met native equal = over-01; a
   warranted escape hatch = `status: justified`). When in doubt whether the native API exists/covers the
   case → VERIFY.
5. **VERIFY.** For any ≤ ~70%-confidence call (does the SwiftUI replacement exist? at this floor? does it
   really cover the UIKit control's behavior?), run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` (and
   `swiftui-ctx deprecated <api>` for a currency rule): read its `consensus` (the canonical shape),
   `recommended` permalink, `introduced_ios`, and `co_occurs_with`; a `lookup` **exit 3** (not-found /
   no-iOS-arm) means no shipping iOS app uses that SwiftUI name — re-check it isn't a hallucination. For
   a multi-API pattern use `swiftui-ctx recipe <name>` (e.g. `recipe uiview-bridge`,
   `recipe draggable-reorder`, `recipe settings-form`). (b) **Spec** — confirm the floor via **Sosumi**:
   `curl -sSL https://sosumi.ai/<apple-path>` using `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check `introduced_ios` against `floors-master.md`. The CLI contract is
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Promote with the citation or discard.
   **Deeper corpus evidence (WHETHER-to-bridge):** when a bridge looks like overuse, prove real apps don't
   need it — `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx bridges <kind-or-name> --json` (stable
   envelope + `next_actions`) shows what the corpus actually wraps (1,007 bridges: 504 `UIViewRepresentable`
   + 427 `UIViewControllerRepresentable`) vs does natively, then `lookup` the native replacement to prove
   it exists and `recipe uiview-bridge` for the justified pattern.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per bridge site,
   zero-padded, ordered. Record `status: justified` notes for warranted hatches. Write the run's
   `_index.md`.
7. **FIX.** **Flag-only** under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`) — never auto-delete a
   representable. Leave each finding `open` with the SwiftUI ✅ in `## Correct`. The ✅ is **not a
   hand-written snippet** — it is the swiftui-ctx **consensus shape** for the native replacement, backed
   by a real iOS example fetched with
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx file <recommended.id> --smart` whose GitHub permalink
   (plus the Sosumi `doc:`) goes in `## Source` as the canonical example.
8. **DOUBLE-CHECK.** Re-confirm every citation still resolves and the replacement's floor still matches
   the project's target (a `containerRelativeFrame` ✅ is useless if the floor is below iOS 17). Re-verify
   each `status: justified` note still holds (e.g. the floor really is < iOS 26 for an over-07 hatch). If a
   recommendation would itself need a new gate, note it in `## Correct`.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty** — a bridge is overuse only when the native SwiftUI API
**provably exists at the project's floor and covers the control's behavior**. Anything ≤ ~70% goes to
VERIFY (step 5) first. Never flag a bridge whose native equal you have not confirmed. All findings are
`fix_mode: flag-only`; there is no auto-fix in this domain.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/uikit-overuse/<context>/NN-slug.md` (one finding per bridge site,
  zero-padded, ordered). Per-run index: `swiftui-audits/uikit-overuse/_index.md`.
- `domain: uikit-overuse`. `fix_mode` is `flag-only` for every finding. `status` is `open` for a
  defect, **`justified`** for a confirmed warranted escape hatch (the schema's uikit-overuse additive
  value). `cross_ref` carries the interop/glass/picker/perf seam. `source` is an Apple URL +
  access date (via Sosumi) or `verify against Xcode 26 SDK`.

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `native-control-wrappers/` | a representable wraps a 1:1 SwiftUI control (over-01) |
| `screen-and-window-reads/` | a `UIScreen.main`/`UIApplication.shared.windows` read has a native equal (over-02, over-03) |
| `system-affordances/` | a pasteboard bridge has a native equal (over-04) |
| `uikit-glass/` | a `UIVisualEffectView` is bridged where SwiftUI glass/material fits (over-05) |
| `over-wrapped-scene/` | a whole screen or large subtree is bridged when SwiftUI scenes/layout fit (over-06) |
| `floor-gated-bridge/` | a bridge is only needed below a floor — e.g. rich-text `UITextView` pre-26 (over-07) |
| `justified-hatch/` | a bridge is CONFIRMED warranted (`status: justified`) — grid/first-responder/scrollview/pre-26 rich text |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/uikit-overuse/` with a lowercase-hyphen slug naming the sub-category, and note it in
the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is
a hard requirement.* Two runs over the same code produce structurally identical trees.

> **Go-beyond artifact (optional):** `swiftui-audits/uikit-overuse/_bridge-ledger.md` — every UIKit
> bridge in the project classified `overuse` / `justified` with the WHETHER-test verdict and the native
> candidate, so a reviewer sees the whole UIKit surface at a glance. See `references/whether-to-bridge.md`.

## Reference routing

| File | Open when |
|---|---|
| `references/whether-to-bridge.md` | the core WHETHER decision tree, the two-sided framing, the bridge-ledger artifact |
| `references/native-control-equivalents.md` | the UIKit-control → SwiftUI-control map + `UIVisualEffectView`→glass/material (over-01, over-05) |
| `references/scene-and-system-bridges.md` | screen/window reads, pasteboard, and whole-screen bridges (over-02/03/04/06) |
| `references/justified-escape-hatches.md` | the confirm-don't-flag set + the iOS-26 rich-text inflection (over-07, `status: justified`) |
| `references/source-directory.md` | step VERIFY — the Apple/WWDC/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` + `lint/ast-grep/*.yml` | step LOCATE — this skill's declarative lint rule set fed to the shared runner (tier-1 grep tells + the tier-2 structural rule); edit here to tune detection |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | every floor/availability value (the reconciled truth) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name list (confirm a SwiftUI replacement is real) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (replacements that need a new gate) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + the `status: justified` additive value |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the fix-safety protocol (step 7) — this domain is flag-only |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`recipe`/`file --smart` for the consensus shape + permalinked example (steps 5 VERIFY · 7 FIX) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (interop ↔ overuse handshake) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-uikit-overuse --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this
skill's declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, over-01…over-07 by flat symbol
presence) + the **tier-2 ast-grep** structural rule (`lint/ast-grep/over-01-wraps-native-control.yml` —
a `makeUIView` that *constructs* a trivial native control, which grep cannot prove). It runs a per-file
**parse probe** (surfaces "did not fully parse"), emits unified **JSON + SARIF**, and **degrades to
grep-only with a notice** if ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster:
`brew install ast-grep`). It only LOCATES — always READ each hit in full and apply the WHETHER test
before reporting (step 3), since a bridge may be a justified hatch. The thin `scripts/over-lint.sh` is a
pointer to this runner. Engine + rule-file format + JSON/SARIF shape + safety rails:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
