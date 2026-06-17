# Labels, decorative hiding, traits, large-content viewer, floor-gating (a11y-01/02/08/12)

How the *perceivable identity* and *operable trait* of a control are announced — plus the iOS large-content
viewer and the iOS-17-floor gating reality. Floors are in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`.

## a11y-01 — icon-only control with no label (warning, flag-only)

An icon-only `Button` (or any tappable whose only content is `Image(systemName:)` / a `Label` with no
visible text) announces the raw SF Symbol name ("plus.circle.fill") or nothing. VoiceOver users cannot tell
what it does.

```
// ❌ icon-only, unlabeled
Button { add() } label: { Image(systemName: "plus") }
// ✅ labeled (consensus shape: trailing string, pct 99 — swiftui-ctx lookup accessibilityLabel --platform ios)
Button { add() } label: { Image(systemName: "plus") }
    .accessibilityLabel("Add item")
```

**Reuse the `.help` text.** If `audit-swiftui-controls-forms` already authored a `.help("Add item")` tooltip
for this control (iPad pointer hover), reuse that exact string as the label (emit `cross_ref controls-forms`).
A `Label("Add", systemImage: "plus")` with *visible* text is already accessible — not a finding. For the
canonical real iOS example run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup accessibilityLabel
--platform ios --json` and read its `recommended` permalink (`introduced_ios` 14.0).

## a11y-02 — decorative image not hidden (advisory, flag-only)

A purely-decorative `Image` (a background flourish, a separator glyph, a redundant icon next to its own text
label) should be removed from the VoiceOver tree so it doesn't add noise:

```
Image("sparkle-divider").accessibilityHidden(true)
// or, for a non-asset decorative SF Symbol next to text it duplicates:
Label { Text("Favorites") } icon: { Image(systemName: "star") }   // icon already covered by the text — fine
```

Judgment call: only flag images that carry **no** information. `Image(decorative:)` initializer already hides
it. READ the surrounding view before flagging.

## a11y-08 — custom gesture with no actionable trait OR no `.accessibilityAction` (warning, flag-only) · cross_ref touch-gestures

This is an **iOS-sharpened** rule. `.onTapGesture` / `.onLongPressGesture` / a custom `DragGesture` / a
`.swipeActions`-style hand-rolled swipe on a `Text`/`HStack`/`Image` makes it interactive *to a sighted touch*
but leaves VoiceOver with **no actionable trait and no way to perform the gesture** — VoiceOver cannot swipe
or drag a custom element, so the action is simply unreachable. Prefer a real `Button`; if a gesture is
unavoidable, add **both** the trait **and** a mirrored `.accessibilityAction`:

```
// ❌ invisible AND unreachable to VoiceOver
HStack { … }.onTapGesture { select() }
// ✅
HStack { … }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { select() }        // VoiceOver double-tap now performs it
```

For a custom toggle, use `.isToggle` (available unconditionally at the iOS 17 floor — see a11y-12) +
`.accessibilityValue("On"/"Off")`. For a custom swipe (delete/archive), mirror each direction with a named
`.accessibilityAction(named:)` so the destructive/secondary actions are reachable. The gesture *mechanics*
are `audit-swiftui-touch-gestures`' domain — this skill owns *"VoiceOver can't trigger it."* Cross-link.

## a11y-12 — missing large-content viewer / above-floor a11y API ungated (advisory, flag-only)

**The iOS inversion — re-derived, NOT copied from macOS.** The macOS edition of this rule flagged `.isToggle`
and closure-form label/value used under a lower floor. **On the iOS-17 toolkit floor every one of those forms
is at or below the floor**, so that gating finding is dead here:

| Form | iOS floor | At iOS-17 floor? |
|---|---|---|
| `AccessibilityTraits.isToggle` | **iOS 17.0** | available — **no gate** (exactly the floor) |
| `accessibilityLabel(content:)` closure | iOS 15.0 | available — no gate |
| `accessibilityValue(_:isEnabled:)` closure | iOS 15.0 | available — no gate |
| `accessibilityChartDescriptor` / `accessibilityRepresentation` | iOS 15.0 | available — no gate |
| `accessibilityShowsLargeContentViewer` | iOS 15.0 | available — no gate |

So a11y-12 has **two iOS arms**, neither of which is the old macOS isToggle gate:

**(1) Missing large-content viewer (the primary iOS arm).** An icon-only **tab item** or **toolbar item** that
has an `.accessibilityLabel` but **no `.accessibilityShowsLargeContentViewer`** is unreadable under the iOS
long-press large-content viewer at the largest accessibility text sizes — the icon doesn't scale and the user
gets no readable name. Add it:

```
TabView {
    HomeView().tabItem { Label("Home", systemImage: "house") }
    // ❌ icon-only profile tab — no large-content label
    ProfileView().tabItem { Image(systemName: "person.crop.circle") }
        .accessibilityLabel("Profile")
        // ✅ readable in the large-content viewer (iOS 15+)
        .accessibilityShowsLargeContentViewer { Label("Profile", systemImage: "person.crop.circle") }
}
```

`accessibilityShowsLargeContentViewer` consensus is **88% trailing-closure `{ }`** (`swiftui-ctx lookup
accessibilityShowsLargeContentViewer --platform ios`, introduced_ios 15.0). A `Label` with *visible* text in a
tab already scales — not a finding.

**(2) Above-floor a11y API ungated (rare).** A genuinely iOS-18+ accessibility API used under a floor below it
— `accessibilityDimFlashingLights` (iOS 18), `accessibilityScrollStatus` (iOS 18),
`accessibilityReduceHighlightingEffects` (iOS 18), `accessibilityDefaultFocus` (iOS 18) — needs a gate. Gate on
the **iOS** arm (never `macOS`) per `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`:

```
if #available(iOS 18, *) { view.accessibilityDimFlashingLights() }
```

The blanket "is every floored API gated" sweep is `audit-swiftui-availability-gating`'s; this skill owns only
the accessibility-specific forms above.

## Go-beyond — the coverage map

Optional `swiftui-audits/accessibility/_coverage-map.md`: one row per interactive view with columns
*label · value · trait · grouped? · large-content? · axis* and a per-axis (`perceivable`/`operable`/`grouped`/
`represented`) coverage score. Lets a reviewer see at a glance which controls are silent to VoiceOver.

## Sources

- Apple — `accessibilityLabel(_:)` / `accessibilityAddTraits(_:)` / `accessibilityHidden(_:)`:
  `https://sosumi.ai/documentation/swiftui/view/accessibilitylabel(_:)`,
  `https://sosumi.ai/documentation/swiftui/view/accessibilityaddtraits(_:)` (via Sosumi; access 2026-06-16).
- Apple — `accessibilityShowsLargeContentViewer(_:)` (iOS 15):
  `https://sosumi.ai/documentation/swiftui/view/accessibilityshowslargecontentviewer(_:)` (access 2026-06-16).
- `AccessibilityTraits.isToggle` floor (iOS 17) and the iOS-17-floor gating policy: `_shared/floors-master.md`
  + `_shared/ios-gating.md` (re-confirmed 2026-06-16).
- Real label example: `swiftui-ctx lookup accessibilityLabel --platform ios` `recommended` permalink.
- Apple HIG — Accessibility: `https://sosumi.ai/design/human-interface-guidelines/accessibility` (access 2026-06-16).
