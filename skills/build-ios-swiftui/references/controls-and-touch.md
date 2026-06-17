# Controls, Forms & Touch Interaction (iOS)

> **iOS-only.** iOS is **touch-first**: controls have large hit targets, `Form` is grouped by default,
> `Picker` defaults to the native `.wheel`/`.menu`, text fields configure the **keyboard** (`keyboardType`,
> `submitLabel`, `textContentType`), and interaction is gestures (`tap`, `longPress`, `swipeActions`,
> `contextMenu`, `refreshable`). `.onHover` / pointer interaction exist only on **iPad with a trackpad** —
> they are an *enhancement*, never the only path to an action. macOS appears only as a ❌ contrast.

**As of 2026-06-07 · iOS 26 · Swift 6.2 toolchain.** Cross-checked against `references/api-currency.md`.

## Why AI gets this wrong

A model that learned controls from desktop or web habits adds hover-only affordances, forgets to
configure the keyboard, hand-rolls a settings screen instead of a `Form`, and never reaches for the touch
gestures (`swipeActions`, `contextMenu`, `refreshable`) that make a list feel native.

---

## The six mistakes (❌ WRONG → ✅ CORRECT)

### 1. A settings/detail screen hand-built instead of a `Form`

On iOS a settings or data-entry screen is a `Form` — it gives grouped sections, inset rows, correct
spacing, and Dynamic Type for free. A hand-rolled `VStack` of rows reads as non-native.

```swift
// ❌ WRONG — VStack of rows fakes a settings screen
VStack { Toggle("Wi-Fi", isOn: $wifi); Toggle("Bluetooth", isOn: $bt) }.padding()
```
```swift
// ✅ CORRECT — Form (grouped by default on iOS) + Section
Form {
    Section("Connectivity") {
        Toggle("Wi-Fi", isOn: $wifi)
        Toggle("Bluetooth", isOn: $bt)
    }
}
```
> On iOS, `Form` is already grouped — you do **not** need `.formStyle(.grouped)` (that is the macOS knob).
> Bind settings to `@AppStorage` for persistence.

### 2. Not configuring the keyboard on a `TextField`

A text field that takes an email, number, or URL should set `keyboardType`, the return-key label
(`submitLabel`), autocapitalization, and `textContentType` for autofill. Omitting them gives a generic
keyboard and no autofill — a clear "not native" tell.

```swift
// ❌ WRONG — bare field; wrong keyboard, no autofill, generic return key
TextField("Email", text: $email)
```
```swift
// ✅ CORRECT — configure the keyboard for the content
TextField("Email", text: $email)
    .keyboardType(.emailAddress)
    .textContentType(.emailAddress)            // enables autofill
    .textInputAutocapitalization(.never)
    .autocorrectionDisabled()
    .submitLabel(.next)                         // return-key label
    .onSubmit { focusNextField() }
```

### 3. Reaching for a custom picker UI instead of the native `Picker`

The native `Picker` adapts to context — `.wheel` (the classic iOS spinner, **a correct native choice**),
`.menu` (a pull-down), `.segmented`, `.navigationLink`. Hand-rolling a scroll-of-buttons loses the
platform feel and accessibility.

```swift
// ✅ CORRECT — native picker; .wheel is a legitimate iOS style, not a smell
Picker("Speed", selection: $speed) {
    ForEach(Speed.allCases, id: \.self) { Text($0.label).tag($0) }
}
.pickerStyle(.wheel)        // native iOS spinner — fine to use
// or .menu / .segmented / .navigationLink as the context calls for
```

### 4. No swipe actions / context menu / pull-to-refresh on a list

Native iOS lists carry **touch** affordances: leading/trailing `.swipeActions`, a long-press
`.contextMenu`, and pull-to-refresh via `.refreshable`. A bare `List` with none of these feels inert.

```swift
// ✅ CORRECT — the iOS touch affordances on a list
List(items) { item in
    ItemRow(item: item)
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) { delete(item) }
        }
        .swipeActions(edge: .leading) { Button("Pin") { pin(item) } }
        .contextMenu { Button("Share") { share(item) } }     // long-press
}
.refreshable { await reload() }                              // pull-to-refresh
```

### 5. Hover-only affordances (treating iPad/iPhone like a pointer device)

`.onHover` and pointer hover effects only fire on **iPad with a trackpad/mouse** — on iPhone there is no
hover at all. Any action reachable *only* on hover is unreachable for most users. Use hover as an
*enhancement* layered on a tap/long-press path that always works.

```swift
// ❌ WRONG — the only way to reveal an action is hover → unreachable on iPhone
RowView().onHover { showActions = $0 }     // iPad-trackpad only; iPhone never hovers
```
```swift
// ✅ CORRECT — tap/long-press is the real path; hover (iPad) is an optional enhancement
RowView()
    .contextMenu { Button("Edit") { edit() } }         // works everywhere (touch)
    .onHover { isHovering = $0 }                        // iPad-trackpad nicety only
    .hoverEffect(.highlight)                            // iPad pointer effect
```

### 6. Wrong control density / button role on touch

iOS touch targets should stay large (≈44pt) — don't shrink with `.controlSize(.small)` the way a dense Mac
pane would. Use button **roles** (`.destructive`, `.cancel`) and the right `buttonStyle`
(`.borderedProminent` for the one primary action, `.bordered`/`.plain` otherwise; on iOS 26
`.glassProminent` for the primary — see `liquid-glass.md`).

```swift
// ✅ CORRECT — roles + one prominent primary; full-size touch targets
Button("Delete", role: .destructive) { delete() }
Button("Save")  { save() }.buttonStyle(.borderedProminent)   // exactly one primary per screen
```

---

## iOS notes

- **Haptics belong to touch.** A confirmation/selection often wants `.sensoryFeedback(_:trigger:)`
  (iOS 17+) — the haptics domain owns the details (`audit-swiftui-haptics`); reach for it on meaningful
  touch outcomes.
- **Dynamic Type & hit targets.** Controls must grow with Dynamic Type and keep ≈44pt touch targets;
  never hard-code a tiny frame on a tappable control. (Dynamic Type is its own audit domain.)
- **`@FocusState` for field navigation.** Move the keyboard focus between fields with `@FocusState` +
  `.focused($field, equals:)` and `.onSubmit` — the iOS field-advance idiom.
- **Boundary:** bridging a UIKit control (a `UITextView`, a custom keyboard accessory) is
  `uikit-interop.md`; the visual HIG/typography judgement is out of scope.

---

## Detection tells

- A settings/data-entry screen built as a `VStack` of `Toggle`/`TextField` rows instead of a `Form` +
  `Section` (mistake 1).
- A `TextField` for email/number/URL/password with **no** `keyboardType` / `textContentType` /
  `submitLabel` (mistake 2).
- A hand-rolled picker (scroll of buttons / custom wheel) where a native `Picker` would do; or a comment
  treating `.wheel` as wrong — it is a fine iOS style (mistake 3).
- A `List` with no `.swipeActions` / `.contextMenu` / `.refreshable` where the data supports them
  (mistake 4).
- `.onHover` / `.hoverEffect` as the **only** way to reach an action → unreachable on iPhone (mistake 5).
- `.controlSize(.small)`/`.mini` on a primary touch control, or two `.borderedProminent` buttons on one
  screen (mistake 6).
- `.formStyle(.grouped)` in an iOS target → unnecessary (iOS `Form` is grouped by default; that knob is
  macOS).

---

## Canonical pattern

```swift
struct SettingsScreen: View {
    @AppStorage("displayName") private var name = ""
    @AppStorage("notifications") private var notify = true
    @FocusState private var nameFocused: Bool

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .focused($nameFocused)
            }
            Section("Preferences") {
                Toggle("Notifications", isOn: $notify)
            }
        }
        .navigationTitle("Settings")
    }
}
```

**Rules:** (1) `Form` + `Section` for settings/entry (grouped by default on iOS — no `.formStyle`). (2)
Configure the keyboard (`keyboardType`/`textContentType`/`submitLabel`) on every typed field. (3) Native
`Picker` (incl. `.wheel`) over a custom one. (4) `.swipeActions` / `.contextMenu` / `.refreshable` make a
list feel native. (5) Hover is an iPad enhancement — never the only path to an action. (6) Keep full-size
touch targets; one `.borderedProminent`/`.glassProminent` primary per screen.

---

## Sources

| URL | Claim | Confidence |
|---|---|---|
| https://developer.apple.com/documentation/swiftui/form | `Form` groups content; grouped by default on iOS | high |
| https://developer.apple.com/documentation/swiftui/view/keyboardtype(_:) | configures the on-screen keyboard for a text field | high |
| https://developer.apple.com/documentation/swiftui/view/submitlabel(_:) | the return-key label (`.next`/`.done`/`.search`/…) | high |
| https://developer.apple.com/documentation/swiftui/picker | `Picker` styles `.wheel`/`.menu`/`.segmented`/`.navigationLink` | high |
| https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:) | leading/trailing list swipe actions — iOS 15.0+ | high |
| https://developer.apple.com/documentation/swiftui/view/refreshable(action:) | pull-to-refresh — iOS 15.0+ | high |
| https://developer.apple.com/documentation/swiftui/view/onhover(perform:) | hover — fires on iPad with a pointer, not iPhone | high |
| https://developer.apple.com/documentation/swiftui/focusstate | `@FocusState` for keyboard focus between fields — iOS 15.0+ | high |
