# Touch affordances & the inverse pointer trap (tg-05 … tg-11)

iOS is touch-first: a finger taps, long-presses, drags, swipes, and pinches. There is **no cursor** and
(on iPhone) **no hover**. `.onHover` / `onContinuousHover` / `pointerStyle` are **iPad-pointer-only**
affordances — they fire from a trackpad / Magic Keyboard / Apple Pencil hover, never from a finger, and
`pointerStyle` has **no iOS arm at all**. Cross-platform-trained corpora ship views whose *only*
interaction is one of these — they compile and look plausible but are **dead under a finger**. This
reference covers the **touch-affordance** half (tg-05 … tg-11); gesture currency, live state, and
composition are in `gestures-and-state.md`; the `pointerStyle`/wrong-arm gating is in
`gesture-availability.md`.

Floor values are NOT restated here — read them from
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`. The deprecated/invented case names are in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md`. The canonical ✅ shape is the
swiftui-ctx **consensus** + a permalinked example, not the snippet below — `lookup … --platform ios`
before you cite.

---

## The touch test (how to judge tg-05/06/07)

Can a **finger** — no pointer, no keyboard — trigger this interaction, and can **VoiceOver**? If the view
is **interactive** (it should react to a tap/drag/long-press) the answer must be yes. Two failure modes:

- the only trigger is `.onHover` / `onContinuousHover` / `pointerStyle` → dead on iPhone (tg-05);
- a custom gesture has no `.accessibilityAction` and no underlying `Button`/control → invisible to
  VoiceOver (tg-06).

A **static** label/decoration is not a defect for lacking touch — that is the load-bearing distinction
the agent must make at READ. tg-05/06/07 are warnings, not hard-fails, precisely because only the agent
(not grep) can tell interactive from static, and pointer-augmenting from pointer-only.

---

## tg-05 — a pointer-only affordance is the *only* interaction (warning) — THE INVERSION

On macOS, hover is a primary affordance and its *absence* is the defect. **On iOS the inversion holds:**
`.onHover` (iOS 13.4+), `onContinuousHover` (iOS 16.0+), and `pointerStyle` (no iOS arm) are
**iPad-pointer-only**. A finger never triggers them, so a control whose **only** interaction is hover is
dead on iPhone and on any iPad without a pointer attached. Hover may **augment** an existing tap/gesture
on iPad; it may never be the sole path.

```swift
// ❌ WRONG on iOS — the row only responds to a pointer that an iPhone never has
RowView(item)
    .onHover { isHighlighted = $0 }      // dead under a finger — no tap, no gesture
```
```swift
// ✅ CORRECT — touch is the primary path; hover (iPad pointer) merely augments
RowView(item)
    .onTapGesture { open(item) }                 // the finger path
    .accessibilityAction { open(item) }          // VoiceOver path
    .onHover { isHighlighted = $0 }              // optional iPad-pointer polish, not the sole trigger
```
`cross_ref: ios-idiomaticness` (this is an iPad-app-in-an-iPhone-window idiom smell the meta-scorer routes
here). If the affordance is `pointerStyle`, it is *platform-wrong*, not merely pointer-only → tg-08
(`gesture-availability.md`).

## tg-06 — a custom gesture unreachable by VoiceOver (warning)

A `Button` / `NavigationLink` / `Toggle` is accessible for free. A **bare** `onTapGesture` /
`DragGesture` / `LongPressGesture` attached to a plain view is **not** — VoiceOver cannot trigger it, so
for an assistive-technology user the interaction does not exist. Add `.accessibilityAction(_:_:)` (iOS
13.0+) mirroring the gesture, or (better, when it is really a button) replace the gesture with a real
`Button`. swiftui-ctx shows `onTapGesture` `co_occurs_with` `accessibilityAction` in accessible code.

```swift
// ❌ WRONG — tap-to-open invisible to VoiceOver
card.onTapGesture { open(item) }
```
```swift
// ✅ CORRECT — the gesture is mirrored as an accessibility action (or use a Button)
card
    .onTapGesture { open(item) }
    .accessibilityAction { open(item) }
```
`cross_ref: accessibility` — this skill *flags* the missing reachability; the deeper a11y craft (labels,
traits, custom rotor actions) is `audit-swiftui-accessibility`'s.

## tg-07 — row/item with actions but no touch-and-hold `.contextMenu` (warning)

`.contextMenu(menuItems:)` (iOS 13.0+) is triggered by **touch-and-hold** on iOS — the native idiom for a
row's *secondary* actions (rename, share, delete). A row that surfaces secondary actions only as
always-visible buttons, or hides them with no menu at all, misses the iOS idiom. Mark destructive items
`role: .destructive`.

```swift
// ✅ CORRECT — touch-and-hold menu, the iOS idiom for secondary actions
Text(item.title).contextMenu {
    Button("Rename") { rename(item) }
    Button("Delete", role: .destructive) { delete(item) }
}
```
If a menu action belongs in Shortcuts/Siri, `cross_ref: app-intents`. A `.contextMenu` *on a control*
crosses into `controls-forms` — note and `cross_ref`.

## tg-10 — `.swipeActions` as the only secondary-action path (advisory)

`.swipeActions(edge:allowsFullSwipe:)` (iOS 15.0+) is a great iOS idiom, but a **hidden** one — a user who
does not discover the swipe has no other path to those actions. Keep the swipe and **also** expose the
same actions in a touch-and-hold `.contextMenu` (tg-07) so they are discoverable. Don't remove the swipe.

```swift
// ✅ CORRECT — swipe AND a touch-and-hold menu expose the same actions
row
    .swipeActions(edge: .trailing) { Button("Delete", role: .destructive) { delete(item) } }
    .contextMenu { Button("Delete", role: .destructive) { delete(item) } }
```

## tg-11 — scrollable data list with no `.refreshable` (advisory, UNVERIFIED judgment)

`.refreshable { … }` (iOS 15.0+) wires the **pull-to-refresh** gesture onto a `List` / `ScrollView`. A
list backed by *refetchable* remote/async data that has no `.refreshable` is missing the idiom iOS users
reach for first. This is a **judgment** call — a static or purely-local list should *not* refresh. Carry
as `advisory` / `source: verify against Xcode 26 SDK`. The consensus shape is `.refreshable { … }` (93% of
real uses, `swiftui-ctx lookup refreshable --platform ios`).

```swift
// ✅ CORRECT — pull-to-refresh on a list backed by async data (iOS 15+)
List(items) { row($0) }
    .refreshable { await store.reload() }
```

---

## Detection tells (what LOCATE surfaces; you READ and judge)

- `.onHover` / `onContinuousHover` / `.pointerStyle(` present on an interactive view with **no** tap /
  gesture / `Button` fallback → tg-05 (READ to confirm it is the *only* trigger).
- A bare `onTapGesture` / `DragGesture` / `LongPressGesture` on a plain view with **no**
  `.accessibilityAction` and no enclosing `Button`/`NavigationLink` → tg-06.
- A `List`/`ForEach`/`Table` row with action `Button`s but no `.contextMenu` → tg-07.
- `.swipeActions` as the only action path → tg-10.
- A `List`/`ScrollView` over async/remote data with no `.refreshable` → tg-11.

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/view/ontapgesture(count:perform:) | `onTapGesture` — iOS 13.0+; finger tap | high |
| https://developer.apple.com/documentation/swiftui/view/accessibilityaction(_:_:) | `.accessibilityAction` — iOS 13.0+; makes a custom gesture reachable by VoiceOver | high |
| https://developer.apple.com/documentation/swiftui/view/onhover(perform:) | `onHover(perform:)` — iOS 13.4+, **iPad-pointer-only** (trackpad/Pencil hover; never a finger) | high |
| https://developer.apple.com/documentation/swiftui/view/oncontinuoushover(coordinatespace:perform:) | `onContinuousHover` — iOS 16.0+, iPad-pointer-only | high |
| https://developer.apple.com/documentation/swiftui/view/pointerstyle(_:) | `pointerStyle(_:)` — **no iOS arm** (macOS/visionOS only); platform-wrong on iOS | high |
| https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:) | `contextMenu(menuItems:)` — iOS 13.0+; touch-and-hold for secondary actions | high |
| https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:) | `.swipeActions` — iOS 15.0+; trailing/leading row actions | high |
| https://developer.apple.com/documentation/swiftui/view/refreshable(action:) | `.refreshable` — iOS 15.0+; pull-to-refresh | high |
| swiftui-ctx `lookup onTapGesture --platform ios` (1,533 uses) | consensus `{ }` 94%; recommended `relatedcode/ProgressHUD` `ProgressHUD+Banner.swift#L63` permalink | high |
| swiftui-ctx `lookup refreshable --platform ios` | consensus `{ }` 93%; recommended `Dimillian/IceCubesApp` `ExploreView.swift#L114` permalink | high |
| swiftui-ctx `lookup swipeActions --platform ios` | consensus `(edge, allowsFullSwipe)` 45% / `(edge)` 33%; recommended `3lvis/SwiftSync` `ProjectView.swift#L195` permalink | high |
| swiftui-ctx `lookup pointerStyle --platform ios` | **exit 3** — no iOS arm (platform-wrong) | high |

Apple availability strings cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`
and fetched via Sosumi (access 2026-06-16). tg-11 (does a list truly need pull-to-refresh) is a judgment
call — carry as `verify against Xcode 26 SDK`. The ✅ shapes above are confirmed by the swiftui-ctx
consensus rows; cite the permalink in each finding's `## Source`, not the static snippet.
