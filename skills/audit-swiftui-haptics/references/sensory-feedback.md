# Reference — Sensory Feedback & Generator Lifecycle (hap-01 … hap-04)

The domain reference for SwiftUI haptics: the iOS-17 `.sensoryFeedback(_:trigger:)` idiom, the raw
`UIFeedbackGenerator` lifecycle (`.prepare()` + hoisting), and the overuse rule. Every ❌→✅ here is
grounded in the **swiftui-ctx** corpus (`lookup`/`examples` + a real GitHub permalink). Floor *values* are
the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## The floors (confirmed live, not from memory)

| Symbol | iOS floor | Source |
|---|---|---|
| `.sensoryFeedback(_:trigger:)` / `SensoryFeedback` | **iOS 17.0+** | `swiftui-ctx lookup sensoryFeedback --platform ios` → `introduced_ios: 17.0`, `deprecated: false`; in `floors-master.md` iOS 17.0 block |
| `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` / `UISelectionFeedbackGenerator` | **iOS 10.0+** (well-known) | UIKit — `swiftui-ctx lookup` returns `introduced_ios: null` (outside the SwiftUI corpus); `source: verify against Xcode 26 SDK` |
| `CHHapticEngine` (Core Haptics, advanced) | **iOS 13.0+** (well-known) | Core Haptics — outside the SwiftUI corpus; `source: verify against Xcode 26 SDK` |

> A UIKit generator / `CHHapticEngine` floor **cannot** be confirmed from swiftui-ctx — it has no SwiftUI
> corpus row. Cite the well-known introduction and mark `verify against Xcode 26 SDK`. Never fabricate a
> corpus floor for it.

`.sensoryFeedback` value list (the `_` first arg): `.impact` · `.success` · `.warning` · `.error` ·
`.selection` · `.increase` · `.decrease` · `.start` · `.stop` · `.alignment` · `.levelChange`. Consensus
shape from the corpus is `(_, trigger)` (92%), then `(trigger)` (7%), then `(_, trigger, condition)` (1%).

---

## hap-01 — raw generator where `.sensoryFeedback` fits (the keystone)

On an iOS 17 target, the declarative modifier ties the buzz to a state change and warms the engine for you —
the raw generator is the pre-17 reflex. **This skill is primary** on the seam; `cross_ref: uikit-overuse`
for the "should this be SwiftUI at all" angle.

```swift
// ❌ pre-17 reflex on an iOS 17 target — imperative, easy to leak / forget .prepare()
struct DownloadButton: View {
    let installed: Bool
    var body: some View {
        Button("Install") { startInstall() }
            .onChange(of: installed) { _, done in
                if done {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)   // hap-01 + hap-03
                }
            }
    }
}
```

```swift
// ✅ iOS-17 native — verified consensus shape `(_, trigger)` (92% of 74 corpus uses)
struct DownloadButton: View {
    let installed: Bool
    var body: some View {
        Button("Install") { startInstall() }
            .sensoryFeedback(.success, trigger: installed)   // ties the buzz to the state change; engine warm-up handled
    }
}
// Source: https://github.com/mainframecomputer/fullmoon-ios/blob/cbc3c8206921afaa7fc4fe3dcdf790a18843226f/fullmoon/Views/Onboarding/OnboardingDownloadingModelProgressView.swift#L76
//         (mainframecomputer/fullmoon-ios, 2258★, min_ios 17 — swiftui-ctx lookup sensoryFeedback recommended)
// Spec:   https://sosumi.ai/documentation/swiftui/view/sensoryfeedback(_:trigger:)  (sensoryFeedback — iOS 17.0+)
```

More real `.sensoryFeedback` shapes from the corpus (`swiftui-ctx examples sensoryFeedback`):

- `.sensoryFeedback(.selection, trigger: snappedOpacity)` — rileytestut/Delta (5988★)
  `https://github.com/rileytestut/Delta/blob/35a582c0f579f3ee7168fe58a7f78fc6504911fd/Delta/Settings/Controller Skins/SkinSettingsView.swift#L48`
- `.sensoryFeedback(.impact, trigger: didCrossActionThreshold, condition: { _, _ in !isFinishingSwipeWithAnimation })`
  — ProtonMail/ios-mail (1598★)
  `https://github.com/ProtonMail/ios-mail/blob/701463fe4542945c49ac5d326b0c27e91441e02f/Modules/App/Sources/UI/Screens/Mailbox/SwipeActions/SwipeableView.swift#L102`

---

## hap-02 — fired with no `.prepare()` (latent first buzz)

`.prepare()` warms the Taptic Engine so the first fire is not latent (~tens of ms). A generator fired with
no `.prepare()` anywhere in scope produces a delayed first buzz.

```swift
// ❌ no .prepare() — the first .impactOccurred() is noticeably late
func didLike() {
    let gen = UIImpactFeedbackGenerator(style: .medium)
    gen.impactOccurred()                 // hap-02 (and hap-03: inline instance)
}
```

```swift
// ✅ if a raw generator is genuinely needed (pre-17, or a Core-Haptics-adjacent path): hoist + prepare
final class LikeHaptics {
    private let gen = UIImpactFeedbackGenerator(style: .medium)
    func arm()  { gen.prepare() }        // warm the engine just before the likely fire
    func fire() { gen.impactOccurred() }
}
// On an iOS 17 target, prefer .sensoryFeedback(.impact, trigger: likeCount) and delete the class entirely.
// Source/Spec: verify against Xcode 26 SDK — UIImpactFeedbackGenerator is iOS 10.0+ (UIKit, outside the SwiftUI corpus).
```

---

## hap-03 — generator re-instantiated inline per call

`UI…FeedbackGenerator().…Occurred()` creates a fresh generator at every call site, so `.prepare()` can never
warm it (the warmed instance is discarded). It is the worst of both worlds: imperative *and* latent. Fix =
hoist to a stored, `.prepare()`d property, or (iOS 17) move to `.sensoryFeedback`. See the hap-01/hap-02 ✅.

---

## hap-04 — haptics on a high-frequency event (overuse)

Feedback is punctuation, not texture. A buzz on every scroll tick, per frame, or a continuously firing
`DragGesture().onChanged` desensitizes the user, fights the system, and drains the Taptic Engine.

```swift
// ❌ fires every drag delta — dozens of buzzes per second
.gesture(DragGesture().onChanged { _ in
    UISelectionFeedbackGenerator().selectionChanged()      // hap-04 (+ hap-03)
})
```

```swift
// ✅ one buzz per discrete crossing — drive .sensoryFeedback off a value that flips, not a continuous one
.sensoryFeedback(.selection, trigger: snappedIndex)        // snappedIndex changes once per notch, not per pixel
// Source: https://github.com/rileytestut/Delta/blob/35a582c0f579f3ee7168fe58a7f78fc6504911fd/Delta/Settings/Controller Skins/SkinSettingsView.swift#L48
// Spec:   https://sosumi.ai/documentation/swiftui/view/sensoryfeedback(_:trigger:)  (iOS 17.0+)
```

> hap-04 is **advisory** and judgment-bound: a one-shot `.onChange` (a value that flips once on user action)
> is *not* overuse. The defect is a *continuously* changing trigger. Carry as `advisory`; if you cannot
> prove the event is high-frequency, do not emit.

---

## Sources

- swiftui-ctx CLI contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`
  (`lookup sensoryFeedback --platform ios` → `introduced_ios: 17.0`; `examples sensoryFeedback` for the
  permalinks above, access 2026-06-16).
- Floors: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (`sensoryFeedback`/`SensoryFeedback`
  iOS 17.0). UIKit generator (iOS 10.0+) and `CHHapticEngine` (iOS 13.0+) are outside the SwiftUI corpus —
  `verify against Xcode 26 SDK`.
- Apple spec fetched via Sosumi: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`;
  path map in `source-directory.md`.
