# Reference — Apple/WWDC/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence UIKit-bridge
claim. **Always fetch Apple docs via Sosumi** — the shared fetch protocol with the curl/CLI commands and the
JSON-404 caveat is `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the
interop-specific *map* of which pages to fetch. **The practice half is `swiftui-ctx`** — run
`recipe uiview-bridge` / `bridges` / `lookup <api> --platform ios` per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Spec — does the symbol exist + what's its iOS floor?** Fetch the SwiftUI page for the representable
   protocol or the UIKit page for the wrapped host, and read the `**Available on:** … iOS N+ …` line. The
   representable protocols are SwiftUI; `UIHostingController`/`UIResponder.becomeFirstResponder` are UIKit
   (iOS 13.0-era for the bridge surface — below the iOS-17 project floor, so no gate is needed).
2. **Practice — how do shipping iOS apps write the bridge?**
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx recipe uiview-bridge --json` → the canonical
   `makeUIView → updateUIView → makeCoordinator → Coordinator` template + permalinked examples;
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx bridges --json` → the 1,007-bridge corpus + `by_kind`.
   A `lookup` **exit 3** on an invented bridge name corroborates a hallucination; **exit 3** on
   `Coordinator`/`makeCoordinator` is *expected* (protocol-requirement names, not catalog symbols).
3. `introduced_ios` surfaces at `result.introduced_ios` (NOT under `result.availability`); use `--platform ios`.

---

## A. SwiftUI representable / Context symbol map

Human doc path = `developer.apple.com/documentation/swiftui/<path>` (fetch via `sosumi.ai/...`). Floors are
reconciled in `floors-master.md`; the representable protocols are conformance patterns (see
`swiftui-ctx recipe uiview-bridge`).

| Symbol | Path | iOS |
|---|---|---|
| `UIViewRepresentable` | `uiviewrepresentable` | 13.0+ (conformance pattern) |
| `UIViewRepresentable.makeUIView(context:)` | `uiviewrepresentable/makeuiview(context:)` | 13.0+ |
| `UIViewRepresentable.updateUIView(_:context:)` | `uiviewrepresentable/updateuiview(_:context:)` | 13.0+ |
| `UIViewControllerRepresentable` | `uiviewcontrollerrepresentable` | 13.0+ |
| `UIViewControllerRepresentable.makeUIViewController(context:)` | `uiviewcontrollerrepresentable/makeuiviewcontroller(context:)` | 13.0+ |
| `UIViewControllerRepresentable.updateUIViewController(_:context:)` | `uiviewcontrollerrepresentable/updateuiviewcontroller(_:context:)` | 13.0+ |
| `makeCoordinator()` | `uiviewrepresentable/makecoordinator()` | 13.0+ (protocol requirement) |
| `UIViewRepresentableContext` | `uiviewrepresentablecontext` | 13.0+ (`.coordinator`/`.environment`/`.transaction`) |

## B. UIKit host / responder symbol map

Human doc path = `developer.apple.com/documentation/uikit/<path>` (fetch via `sosumi.ai/...`).

| Symbol | Path | iOS |
|---|---|---|
| `UIHostingController` | `swiftui/uihostingcontroller` | 13.0+ (`init(rootView:)`) |
| `UIViewController.addChild(_:)` | `uikit/uiviewcontroller/addchild(_:)` | 5.0+ |
| `UIViewController.didMove(toParent:)` | `uikit/uiviewcontroller/didmove(toparent:)` | 5.0+ |
| `UIResponder.becomeFirstResponder()` | `uikit/uiresponder/becomefirstresponder()` | 2.0+ |
| `UIResponder.resignFirstResponder()` | `uikit/uiresponder/resignfirstresponder()` | 2.0+ |

## C. WWDC / practitioner provenance

- **WWDC19 “Integrating SwiftUI”** — the original `UIViewRepresentable`/`UIViewControllerRepresentable`
  make/update/Coordinator model.
- **WWDC20 “Build document-based apps in SwiftUI”** + the SwiftUI tutorials’ “Interfacing with UIKit” chapter —
  the canonical `Coordinator` + delegate write-back pattern.
- The `swiftui-ctx recipe uiview-bridge` first example (`1amageek/Toolbar`,
  `EditorBacking+iOS.swift`) is the corpus-ranked real exemplar.
