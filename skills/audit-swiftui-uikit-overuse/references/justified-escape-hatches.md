# Reference — Justified Escape Hatches (CONFIRM, never flag) + over-07

The other half of the audit. When a bridge matches one of these, SwiftUI has **no native equal** (or not
at the project's floor) — the bridge is **correct**. Record `status: justified` (the uikit-overuse
additive `status` value in `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md`) with the
one-line reason; **do not flag it as a defect**. Confirming these stops a later refactor from churning a
correct bridge into a broken pseudo-SwiftUI control.

**As of:** 2026-06-16 · iOS 26 · iOS 17 deployment floor.

---

## The warranted set

| Escape hatch | Why SwiftUI has no equal | Owner of its HOW |
|---|---|---|
| Rich-text `UITextView` **below iOS 26** | SwiftUI `TextEditor` is plain-text until iOS 26's `TextEditor(text:selection:)` over `AttributedString`. Below 26, rich text REQUIRES the bridge. | `uikit-interop` |
| `UICollectionView`-grade data grids | SwiftUI `List`/`LazyVGrid` lack cell-level reuse, compositional layout, drag-reorder at scale, and the row-count ceiling of `UICollectionView`; a heavy grid/feed stays UIKit. | `view-performance` (the cost argument) |
| Precise **first-responder / inputAccessoryView / inputView** | `@FocusState` covers SwiftUI-native controls only; a custom keyboard toolbar (`inputAccessoryView`), a custom `inputView`, insertion-point color, and `becomeFirstResponder()` timing have no public SwiftUI surface. | `uikit-interop` |
| `UIScrollView` with **paging / zoom / contentOffset** control | SwiftUI's `ScrollView` + `scrollTargetBehavior`/`scrollPosition` (iOS 17) covers most cases, but pinch-to-zoom (`viewForZooming`), precise programmatic `contentOffset`, and `UIScrollViewDelegate` callbacks may still need the bridge. | `uikit-interop` · perf → `view-performance` |
| Camera / advanced media — `PHPickerViewController`, `AVCaptureSession` preview, `UIImagePickerController` camera | `PhotosPicker` covers library picking, but live camera capture and some media flows have no full SwiftUI control. | `uikit-interop` · consent → `document-picker-permissions` |

When you confirm one of these, emit `status: justified` and a `cross_ref` to the HOW owner so the
interop audit verifies the bridge is *implemented* correctly. The two skills together: overuse says "this
bridge is warranted," interop says "and it is wired right."

## over-07 — the iOS-26 inflection on rich text

This is the one case that flips with the floor:

- **Floor < iOS 26** → a rich-text `UITextView` bridge is **justified** (status: justified). The native
  `TextEditor(text:selection:)` rich-text editor over `AttributedString` does not exist yet (it is iOS
  26; below the floor, `TextEditor` is plain-text only — `(text)` is the 96% consensus shape, `(text,
  selection)` only 4%).
- **Floor ≥ iOS 26** AND the bridge handles only plain or lightly-styled text → **over-07** (flag): the
  native `TextEditor(text:selection:)` may remove the bridge. Show it as the ✅. **But** confirm scope
  first: a `UITextView` used for advanced layout (custom `NSTextLayoutManager`, multiple text containers,
  text-attachment interaction, `inputAccessoryView`) is still beyond the native editor — keep it
  justified.

Because the iOS-26 native rich-text editor is new (post-most-training-data), **VERIFY it before
recommending it**: `swiftui-ctx lookup TextEditor --platform ios --json` (read `consensus` for the
`(text, selection)` shape + `recommended` permalink + `introduced_ios`) and confirm the floor via Sosumi
(`references/source-directory.md`). If you cannot confirm the rich-text initializer at iOS 26, carry
over-07 as `advisory` with `source: verify against Xcode 26 SDK` — never assert it as fact. Floor truth:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

---

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://developer.apple.com/documentation/swiftui/texteditor | primary-doc | high | `TextEditor`; the `AttributedString` `selection:` rich-text form is the iOS-26 addition — verify the exact floor against the Xcode 26 SDK. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/uikit/uitextview | primary-doc | high | Full rich-text engine (text layout manager, containers, attachments) — no full SwiftUI equal below iOS 26. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/uikit/uicollectionview | primary-doc | high | Cell-reuse / compositional-layout grid — beyond `List`/`LazyVGrid` at scale. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/photokit/photospicker | primary-doc | high | `PhotosPicker` covers library picking; live camera capture still needs a UIKit bridge. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/swiftui/focusstate | primary-doc | high | `@FocusState` — SwiftUI-native controls only; no public arbitrary-first-responder / inputAccessoryView API. iOS 15.0+. Accessed 2026-06-16. |
