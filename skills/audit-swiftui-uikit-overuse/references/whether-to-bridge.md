# Reference — The WHETHER-to-Bridge Decision Tree

This skill audits **whether a UIKit bridge should exist**, not how it is wired (that is
`audit-swiftui-uikit-interop`). Every `UIViewRepresentable` / `UIViewControllerRepresentable` /
`UIHostingController` / system-UIKit call costs a `make`/`update`/Coordinator handshake, a
responder-chain edge, and a Swift-6 isolation boundary. The default posture is **stay in SwiftUI**; a
bridge must earn its keep.

**As of:** 2026-06-16 · iOS 26 · Xcode 26 SDK · iOS 17 deployment floor.

---

## The decision tree (apply to every bridge)

```
For each UIKit bridge / system call:
 1. Is there a NATIVE SwiftUI control/API for this exact thing?
      NO  → it may be a JUSTIFIED hatch — go to 3.
      YES → go to 2.
 2. Does that native API exist AT THE PROJECT'S DEPLOYMENT FLOOR (iOS 17; read it in ORIENT)?
      YES → OVERUSE. Flag (over-01…over-06). Show the SwiftUI ✅.
      NO  → JUSTIFIED-FOR-NOW (e.g. rich-text TextEditor(text:selection:) needs iOS 26).
            Record status: justified; note "remove the bridge when the floor reaches iOS 26" (over-07).
 3. Does the UIKit view add CAPABILITY SwiftUI structurally lacks?
      (UICollectionView-grade cell-reuse grid · precise first-responder / inputAccessoryView control ·
       UIScrollView paging/zoom past scrollTargetBehavior · advanced UITextView text-layout)
      YES → JUSTIFIED escape hatch. status: justified. DO NOT FLAG. (justified-escape-hatches.md)
      NO  → OVERUSE with no native equal named? Re-check step 1 against swiftui-ctx; if still no
            native API and no special capability, flag as an unjustified bridge and say what is missing.
```

**Two sides, one audit.** A clean run reports *both* the overuse defects (flag) **and** the confirmed
escape hatches (`status: justified`). Confirming the warranted bridges is as much the job as flagging
the unnecessary ones — it stops a later refactor from churning a correct `UICollectionView` into a
broken `LazyVGrid`.

## Why each UIKit boundary is a liability (the cost you are weighing)

- Every representable owes BOTH `makeUIView` and `updateUIView` or it silently goes stale; a `@Binding`
  owes a `makeCoordinator()` + delegate or the UIKit→SwiftUI direction is dead — the whole class of
  bugs `audit-swiftui-uikit-interop` exists to catch. A native SwiftUI control has none of that.
- The Coordinator boundary is exactly where Swift 6 strict-concurrency bites (`@Sendable` closure
  touching main-actor state). Fewer bridges = fewer isolation edges.
- UIKit controls don't auto-adopt Liquid Glass, Dynamic Type, or the system tint the way SwiftUI
  controls do — a bridged `UIButton` looks subtly non-native next to a `Button`, and a `UIScreen.main`
  read ignores the multi-scene / Split View / Stage Manager geometry SwiftUI hands you for free.

## VERIFY the replacement before flagging

Never flag a bridge until you have **confirmed the SwiftUI replacement exists at the floor**. In step
VERIFY run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <SwiftUI-api> --platform ios --json`
for the `consensus` shape + `recommended` permalink + `introduced_ios`, and confirm the floor via Sosumi
(`references/source-directory.md`). For a multi-API replacement use the recipe, e.g.
`swiftui-ctx recipe draggable-reorder` (Transferable), `swiftui-ctx recipe uiview-bridge` (the bridge
itself, to judge what it actually wraps). CLI contract:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. Floor values:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

## The bridge-ledger artifact (optional go-beyond)

`swiftui-audits/uikit-overuse/_bridge-ledger.md` — one row per UIKit bridge in the project:
`site · what it wraps · native candidate · floor · verdict (overuse | justified | justified-for-now)`.
A reviewer sees the entire UIKit surface and its justification at a glance, and a future refactor knows
which bridges are load-bearing.

## Seam ownership (don't double-own)

Per `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`: **overuse owns WHETHER**, interop owns
HOW (every shared site cross_refs both). For `UIDocumentPickerViewController`/`UIImagePickerController`,
overuse decides *whether*, `document-picker-permissions` owns consent/bookmark correctness. For
`UIVisualEffectView`, overuse flags the bridge, `liquid-glass` owns the SwiftUI glass placement and
`appearance-color` owns the material/vibrancy choice. For raw `UIImpactFeedbackGenerator`, overuse flags
the bridge, `haptics` owns the feedback idiom. For a `UITableView`/`UICollectionView` perf justification,
`view-performance` owns the cost argument. Emit a `cross_ref` on every shared site.

---

## Sources

| URL | Type | Confidence | Key fact |
|---|---|---|---|
| https://developer.apple.com/documentation/swiftui/uiviewrepresentable | primary-doc | high | Required `makeUIView`/`updateUIView`; bridge is the sanctioned escape, not the default. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass | primary-doc | high | SwiftUI controls auto-adopt the new design; bridged UIKit controls do not. Accessed 2026-06-16. |
| https://developer.apple.com/documentation/uikit/uiscreen/main | primary-doc | high | `UIScreen.main` is deprecated (iOS 16); use the view's window scene / SwiftUI geometry instead. Accessed 2026-06-16. |
