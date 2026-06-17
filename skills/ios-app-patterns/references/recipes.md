# Recipe index (iOS)

Each recipe = a canonical template + the real APIs it composes + ranked real examples (with permalinks).
Run `swiftui-ctx recipe <name>` for the template + examples; `swiftui-ctx file <id> --smart` to read real code.

| Recipe | Composes (APIs) | What you get |
|---|---|---|
| `tab-bar-app` | `TabView`, `tabItem` | a tab-bar app shell — a tab per root screen |
| `navigationstack-master-detail` | `NavigationStack`, `navigationDestination` | a list → detail push flow (type-safe `.navigationDestination(for:)`) |
| `sheet-detents` | `sheet`, `presentationDetents` | a bottom sheet with height detents (`.medium`, `.large`, or a custom fraction/height) |
| `uiview-bridge` | `UIViewRepresentable`, `UIViewControllerRepresentable` | wrap a UIKit view/controller (Coordinator + `makeUIView` / `updateUIView`) |
| `widget-scaffold` | `Widget`, `WidgetBundle` | a WidgetKit home-screen widget (a `Widget` with a `TimelineProvider` and an entry view) |
| `fullscreen-cover-flow` | `fullScreenCover` | a full-screen modal flow (onboarding / immersive; no drag-to-dismiss) |

Tips:
- For **uiview-bridge**, read the example with `--full` — bridges (Coordinator + `makeUIView` + `updateUIView`) are
  best understood whole, not as a fragment. The corpus has 931 real bridges across 182 repos.
- **widget-scaffold** has no in-corpus app examples (widgets live in a separate WidgetKit extension target rather than
  the app target the corpus indexes). Use the recipe template and confirm each API with
  `swiftui-ctx lookup Widget --platform ios` / `lookup TimelineProvider --platform ios`.
- Recipe examples are filtered to ones that actually use the recipe's APIs (a `sheet-detents` example uses
  `.presentationDetents`).
- After scaffolding, confirm any individual API's current argument shape with `swiftui-ctx lookup <api> --platform ios`.
  Floors: `NavigationStack` / `navigationDestination` / `presentationDetents` are iOS 16; `TabView` is iOS 13;
  `fullScreenCover` is iOS 14 — all under the iOS-17 baseline. iPad is covered within iOS.
