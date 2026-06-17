# iOS UX smell catalog (shared design truth)

**Verified: 2026-06-16.** The qualitative UX layer that pure code analysis misses — the things a reviewer judges by *looking* at a rendered screen (plus a code corroboration where available). Each entry: **SMELL — why it's bad — how to detect (pixels and/or code) — source.** Measurable rules (contrast ratios, 44 pt, type scale) live in [[hig-design-rubric]]; Liquid Glass smells in [[liquid-glass-design]]. The reviewer ([[design-finding-schema]]) cites these for `tier: vision` findings; never assert a blacklisted myth ([[design-claims-blacklist]]).

---

## Native vs not

- **Floating Action Button (FAB)** — the Android/Material primary-action pattern; iOS puts primary actions in the nav/tool bar. *Detect:* screenshot — a floating circle with one glyph (often `+`) and a drop shadow pinned bottom-trailing; code — a `ZStack`/overlay-pinned `Circle()`/`Button` with `.shadow(...)` bottom-trailing. https://developer.apple.com/design/human-interface-guidelines/buttons
- **Hamburger menu as primary navigation** — hides top-level sections; iOS uses a persistent bottom tab bar. *Detect:* a ☰ icon with no bottom tab bar; a drawer/side-menu instead of `TabView`. https://developer.apple.com/design/human-interface-guidelines/tab-bars
- **Top tab bar for primary sections** — top-level switching belongs in a *bottom* bar. *Detect:* a section switcher pinned under the nav bar; a custom top segmented switcher replacing `TabView`. https://developer.apple.com/design/human-interface-guidelines/tab-bars
- **Material icons / Roboto font** — Google's icon + type language signals a cross-platform port. *Detect:* glyph silhouettes differ from SF Symbols; `Image("ic_...")` rasters or `.font(.custom("Roboto"…))` instead of `Image(systemName:)` / system text styles. https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- **Missing large title** — iOS root/list screens open with a large bold title collapsing on scroll. *Detect:* only a small centered title, no large left-aligned heading; `.inline` everywhere with no `.navigationBarTitleDisplayMode(.large)`. https://developer.apple.com/design/human-interface-guidelines/typography
- **Material elevation (heavy drop-shadow cards)** — iOS leans flat/translucent. *Detect:* pronounced elevation shadows on cards/buttons; repeated `.shadow(radius:)`. https://developer.apple.com/design/human-interface-guidelines/materials
- **iPad layout shrunk onto iPhone** — reusing a wide/multi-column layout yields cramped controls. *Detect:* multi-column/sidebar squeezed into iPhone width; no `horizontalSizeClass` checks, `NavigationSplitView` with no compact collapse. https://developer.apple.com/design/human-interface-guidelines/layout
- **Web-wrapper tells** — page-wide momentum bounce, web text-selection callouts over chrome, blue underlined links, tap-highlight flashes. *Detect:* web selection handles/callouts, web link styling, full-page scroll bounce. https://developer.apple.com/design/human-interface-guidelines/designing-for-ios

## Hierarchy

- **No single primary action / competing CTAs** — equally-prominent buttons dilute the path. *Detect:* >1 high-emphasis (filled/tinted, similar size) button per view; multiple `.buttonStyle(.borderedProminent)` in one tree. https://developer.apple.com/design/human-interface-guidelines/buttons
- **Buried primary action** — the key action is small/gray/off the top-leading path or below the fold. *Detect:* the semantically strongest action is visually weaker or positioned away from top-leading; primary action `.plain`/untinted. https://developer.apple.com/design/human-interface-guidelines/layout
- **Flat / undifferentiated hierarchy** — uniform size/weight/color, no focal point. *Detect:* low variance in type size/weight/color; all `Text` at one style with no `.headline`/`.secondary` contrast. https://developer.apple.com/design/human-interface-guidelines/layout
- **Weak grouping** — related items not clustered. *Detect:* uniform spacing everywhere, no dividers/cards/sections; one flat `VStack` instead of `Section`/`GroupBox`; misaligned leading edges. https://developer.apple.com/design/human-interface-guidelines/layout
- **Clutter / no progressive disclosure** — everything on one screen. *Detect:* high density, little whitespace, repeated labels; huge subview count with no drill-down/sheet deferral. https://developer.apple.com/design/human-interface-guidelines/layout

## Affordances

- **Tappable things don't look tappable** — weak signifiers force guessing. *Detect:* action text with no border/fill/color/chevron next to static labels; `Text(...).onTapGesture` with no styling. https://developer.apple.com/design/human-interface-guidelines/buttons
- **Links indistinguishable from text (or vice versa)** — breaks the click contract. *Detect:* link-colored non-interactive text, or interactive text rendered like body; `.underline()` on plain `Text`, `Link`/`Button` styled `.primary`. https://developer.apple.com/design/human-interface-guidelines/buttons
- **Ghost / low-contrast buttons** — thin outlines read as decoration. *Detect:* text in a 1px outline with transparent fill; Button styled only with `.overlay(stroke())`. https://developer.apple.com/design/human-interface-guidelines/buttons
- **Icon-only buttons without labels (mystery-meat)** — most icons aren't self-explanatory. *Detect:* bare glyph toolbar/tab/row controls, especially non-standard symbols; `.labelStyle(.iconOnly)`/image-only buttons with no `.accessibilityLabel`. https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- **Swipe-only / long-press-only actions** — low discoverability. *Detect:* a list with no chevron/trailing control relying on `.swipeActions`; `.contextMenu`/`.onLongPressGesture` carrying actions with no visible parallel. https://developer.apple.com/design/human-interface-guidelines/gestures

## Consistency

- **Mismatched type scale (hardcoded sizes)** — defeats Dynamic Type, differs across screens. *Detect:* same role at different sizes/weights; `.font(.system(size:))` where a semantic style exists. https://developer.apple.com/design/human-interface-guidelines/typography
- **Inconsistent iconography** — mixed families/weights/perspective. *Detect:* thin-stroke beside filled glyphs, custom icons at a different optical weight from SF Symbols; `Image("...")` rasters interleaved with `Image(systemName:)`. https://developer.apple.com/design/human-interface-guidelines/icons
- **Non-standard icons for standard actions** — raises learning cost. *Detect:* custom glyph for delete/search/share instead of `trash`/`magnifyingglass`/`square.and.arrow.up`. https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- **Inconsistent component styles / casing / nav patterns** — same action styled or capitalized differently; same drill-in is a push here, a sheet there. *Detect:* differing `ButtonStyle`s for one action; "Save Changes" vs "Save changes"; mixed `NavigationLink`/`.sheet` for analogous flows. https://developer.apple.com/design/human-interface-guidelines/navigation-bars
- **Multiple competing color accents** — dilutes hierarchy. *Detect:* two+ saturated accent colors, or one action's tint differing across screens; multiple hardcoded `.tint` instead of one accent set. https://developer.apple.com/design/human-interface-guidelines/color

## States

- **Blank empty state** — users can't tell empty vs. loading vs. error. *Detect:* a list/grid fully blank with no message/CTA; collection-driven `List`/`ForEach` with no `if items.isEmpty` branch and no `ContentUnavailableView`. https://developer.apple.com/design/human-interface-guidelines/loading
- **Empty state with no CTA/learnability; blank search no-results** — wastes a teachable moment. *Detect:* empty view of only `Text`; no `ContentUnavailableView.search(text:)`. https://developer.apple.com/design/human-interface-guidelines/loading
- **Blank/static loading; content pop-in & layout shift** — looks frozen. *Detect:* empty/static screen during a fetch; structure renders then content jumps; no `ProgressView`/`.redacted(reason:.placeholder)` skeleton. https://developer.apple.com/design/human-interface-guidelines/loading
- **Spinner where progress is quantifiable; stalled/fake indicator** — feels broken. *Detect:* indeterminate spinner on a measurable download; a bar stuck at one value; `ProgressView()` instead of `ProgressView(value:total:)`. https://developer.apple.com/design/human-interface-guidelines/progress-indicators
- **Raw/jargon error string; error with no recovery** — cryptic and dead-ends. *Detect:* alert/label with a stack trace/HTTP code; an error view with only "OK"/dismiss and no Retry; `Text(error.localizedDescription)` surfaced directly. https://developer.apple.com/design/human-interface-guidelines/alerts
- **Launch screen ≠ first screen; splash/onboarding gating content; setup wall before value; no state restoration.** *Detect:* launch image differs from the first real screen; a forced multi-screen tutorial with no Skip; first launch lands on required sign-up; relaunch always resets to home. https://developer.apple.com/design/human-interface-guidelines/launching

## Modality & flow

- **Overused modality** — most navigation opens sheets/alerts. *Detect:* many `.sheet`/`.fullScreenCover` where a push fits. https://developer.apple.com/design/human-interface-guidelines/modality
- **A sheet that should be a push** — hierarchical drill-in loses the back affordance. *Detect:* a detail screen as a bottom sheet with "Done"/"X" instead of a back chevron; `.sheet` wrapping a logical child of a `NavigationStack`. https://developer.apple.com/design/human-interface-guidelines/modality
- **Modal-within-modal; modal over a popover** — people get lost. *Detect:* a sheet peeking behind another (stacked rounded edges/double dimming); `.sheet`/`.alert` triggered from inside `.sheet`/`.popover` content. https://developer.apple.com/design/human-interface-guidelines/modality
- **Alert for non-actionable info or routine undoable actions** — overuse erodes impact. *Detect:* a centered alert with one "OK"; "Are you sure?" on frequent reversible actions (prefer undo / `confirmationDialog`). https://developer.apple.com/design/human-interface-guidelines/alerts
- **Dead-end modal; hidden tab bar on push; tab/nav changing without user action.** *Detect:* a sheet/cover with no Cancel/Done; `.toolbar(.hidden, for: .tabBar)` on pushed screens; `TabView` selection mutated from timers/network. https://developer.apple.com/design/human-interface-guidelines/tab-bars

## Density & touchability

- **Tap target < 44×44 pt; adjacent targets with no spacing** — wrong-element taps. *Detect:* measure interactive boxes, flag any axis < 44 pt; Buttons in `HStack(spacing: 0)` with no padding; icon-only buttons with no `.frame(minWidth:44,minHeight:44)`/`.contentShape`. https://developer.apple.com/design/human-interface-guidelines/layout
- **Content under notch / Dynamic Island / status bar / home indicator** — clipped or un-tappable. *Detect:* glyphs/controls in the top sensor band or bottom ~34 pt; `.ignoresSafeArea()` on a container holding controls. https://developer.apple.com/design/human-interface-guidelines/layout
- **Focused field / submit button hidden behind the keyboard.** *Detect:* render with the keyboard up; flag a focused `TextField`/CTA inside the keyboard frame; `TextField` in a fixed `VStack`/`ZStack` (not `ScrollView`/`Form`). https://developer.apple.com/design/human-interface-guidelines/entering-data
- **Text truncated/ellipsized in normal conditions; edge-to-edge text with no margins; overlapping elements; sub-11 pt text.** *Detect:* trailing "…" or clipped glyphs; near-zero side gap; intersecting bounding boxes; `.lineLimit(1)` on substantive labels with no `.minimumScaleFactor`. https://developer.apple.com/design/human-interface-guidelines/typography

## Forms & input

- **Wrong keyboard type; missing AutoFill** — slow entry. *Detect:* an email field without `.keyboardType(.emailAddress)`, numeric without `.numberPad`; credential/contact fields lacking `.textContentType` (email/username/password/newPassword/oneTimeCode). https://developer.apple.com/design/human-interface-guidelines/entering-data
- **Submit-only validation; vague error messages** — users discover mistakes late. *Detect:* validation only in the submit action, no per-field `.onChange` error; generic "invalid input". https://developer.apple.com/design/human-interface-guidelines/entering-data
- **Placeholder used as the only label** — vanishes on typing, hurts VoiceOver. *Detect:* a grey hint with no separate label; `TextField("Email", …)` with no adjacent label/`.accessibilityLabel`. https://developer.apple.com/design/human-interface-guidelines/text-fields
- **No submit affordance / focus advancement; typing required where a picker fits.** *Detect:* `TextField`s with no `.submitLabel`/`@FocusState` advancement; a free `TextField` for constrained values (country/category/date) instead of `Picker`/`DatePicker`. https://developer.apple.com/design/human-interface-guidelines/entering-data

## Accessibility UX

- **Breaks at largest Dynamic Type (AX5)** — truncation/overlap/off-screen. *Detect:* re-render at AX5; flag clipped/overlapping/off-screen content; hardcoded `.font(.system(size:))`, fixed `.frame(height:)` on text rows, `.lineLimit(1)` on substantive labels. https://developer.apple.com/design/human-interface-guidelines/typography
- **Hardcoded colors break Dark Mode** — fixed light backgrounds/black text don't adapt. *Detect:* render dark, check legibility; literal `Color(red:green:blue:)`/`.white`/`.black` without a dark variant; prefer `.primary`/`.secondary`/semantic colors. https://developer.apple.com/design/human-interface-guidelines/dark-mode
- **Meaning by color alone; icon-only control with no a11y label; decorative image announced.** *Detect:* status by color only with no icon/label; `Button { } label: { Image(systemName:) }` with no `.accessibilityLabel`; decorative `Image` without `.accessibilityHidden(true)`. https://developer.apple.com/design/human-interface-guidelines/accessibility
- **Reduce Motion / Reduce Transparency not respected.** *Detect:* animations/transitions with no `@Environment(\.accessibilityReduceMotion)` gate; `.ultraThinMaterial`/blur behind text with no `@Environment(\.accessibilityReduceTransparency)` solid fallback. https://developer.apple.com/design/human-interface-guidelines/accessibility
