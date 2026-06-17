# Reference — Chrome Auto-Adoption & Scroll-Edge Effects

How iOS 26 hands chrome glass for free, the leftover overrides that block it, scroll-edge effects,
and the constrained-`TextEditor` opaque-navigation-bar trap. Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; real symbols in `glass-api-surface.md`.

**As of:** 2026-06-16 · iOS 26.

---

## Free chrome — what auto-adopts glass on an SDK rebuild

Recompiling on the iOS 26 SDK **auto-glasses** standard chrome: the navigation bar, the tab bar
(`TabView`), toolbars (`.toolbar`), the iPad sidebar (`NavigationSplitView`), and sheets. Hand-applying
`.glassEffect()` to chrome that already adopts glass fights the system and risks glass-on-glass.

**glass-10 — re-glassed free chrome (warning, flag-only).** `.glassEffect()` on a navigation bar, a
`TabView` bar, a `NavigationSplitView` sidebar, a `.toolbar`, or a sheet container.
✅ rely on auto-adoption; hand-apply glass only to genuinely custom floating controls. Use
`backgroundExtensionEffect()` to extend content under a sidebar/inspector rather than glassing the
sidebar itself.

> **Auto-adoption opportunity finder (go-beyond):** detect hand-applied `.glassEffect()` on chrome that
> would adopt glass for free and recommend **deleting** the manual call — the inverse of the usual "add
> glass" advice.

---

## Leftover overrides that BLOCK glass

**glass-11 — leftover toolbar/navigation-bar overrides that block glass (warning; fix_mode: auto).**
`.toolbarBackground(.visible, …)` (iOS 16.0+ — see floors-master) and `.toolbarColorScheme(_:)`
**block glass rendering** on the navigation bar / toolbar. Under auto-glass they have no purpose; removal
restores intended rendering. Safe to auto-fix (deletion only). (`toolbarBackgroundVisibility(_:for:)`
is iOS 26.0+ — see floors-master — and is the symbol used to *hide* a shared toolbar background where
that is the goal.)

iOS navigation-bar/toolbar polish that frequently accompanies glass adoption (flag, show the pattern):
`.toolbarBackgroundVisibility(.hidden, for: .navigationBar)`,
`ToolbarItemGroup` + `.sharedBackgroundVisibility(.hidden)` to split the shared glass background.

---

## Scroll-edge effects

`scrollEdgeEffectStyle(_:for:)` styles the automatic/soft/hard fade where content meets chrome;
`scrollEdgeEffectHidden(_:for:)` removes it. Both are iOS 26.0+ (floors-master). The `.soft` and
`.hard` styles are both valid iOS values.

> **VERIFY AGAINST XCODE 26 SDK — do not assert as fact:** the iOS scroll-edge **default** style
> (`.soft` claimed; macOS `.hard`) is observed behavior, not a scraped fact. Carry it as advisory with
> the unverified flag; confirm on a device/simulator before stating it.

**glass-12 — `TextEditor` in a `NavigationSplitView` detail (iPad) forces an opaque navigation bar
(warning, flag-only — community-sourced).** A constrained scroll region in the detail column drags the
navigation bar to opaque-with-border, losing glass across the detail pane.
```swift
// ✅ soften the top scroll edge on the constrained editor
TextEditor(text: $text)
    .scrollEdgeEffectStyle(.soft, for: .top)
```
> **VERIFY AGAINST XCODE 26 SDK:** this pitfall is community-sourced and may not reproduce on every
> layout. Flag it, show the `.soft` suggestion, never silent-fix; confirm on a device/simulator.

---

## Double transparency

**glass-13 — `.glassEffect()` + `.background(.ultraThinMaterial)` on one view (advisory, flag-only).**
Two transparency systems stacked on one view. ✅ use one system per view (branch, don't stack).
> **VERIFY AGAINST XCODE 26 SDK:** an early-beta crash from this combination is community-reported and
> **unverified** against the shipping SDK. Flag as advisory; never assert the crash as fact; confirm on
> a device/simulator.

---

## Sources

- Apple — "Adopting Liquid Glass" (auto-adoption of system bars, `backgroundExtensionEffect`
  rationale): `https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass`
  (via Sosumi, accessed 2026-06-16).
- Apple — `scrollEdgeEffectStyle(_:for:)` / `scrollEdgeEffectHidden(_:for:)` / `backgroundExtensionEffect()`,
  iOS 26.0+: `/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)` etc. (via Sosumi, 2026-06-16).
- Community report of the constrained-`TextEditor` opaque-navigation-bar pitfall and the
  double-transparency crash — unverified; carried as flags, not facts.
