# Reference — Keyboard Config, Field Style, Submit & Focus (cf-01 · cf-02 · cf-03 · cf-04 · cf-06)

The text-input defects that make an iOS form awkward to type into: a `TextField` bound to **typed data with
the wrong keyboard**, an **email/code field that auto-capitalizes and auto-corrects**, a **free-standing
field with no visible border**, a **multi-field form with no Return-key label**, and a **custom view / form
with no keyboard-focus wiring** so fields can't be advanced or the keyboard dismissed. These are absent from
the corpus because on iOS a `Form` already looks grouped and a `TextField` already *works* with the default
keyboard — it is just the wrong one. These are *flag-only* defects (the correct fix is a judgment call: what
data is bound, is the field free-standing, is the form multi-field). Floors live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read, never restate. The ✅ here is the
swiftui-ctx **consensus shape** backed by a real iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 26 · Swift 6.2 · project floor iOS 17.

> **What is NOT a defect on iOS (inverted from macOS).** An iOS `Form` is **grouped by default** — a missing
> `.formStyle(.grouped)` is *not* a finding. `.pickerStyle(.wheel)` / `WheelPickerStyle` is a **native iOS
> control** (`introduced_ios 13.0`), never platform-wrong. `.help(_:)` exists (iOS 14.0+) but its tooltip
> surfaces only under the iPad pointer — it is not a required affordance and never a finding here.

---

## cf-01 — numeric/email/URL/phone `TextField` with no `.keyboardType(_:)` (warning, flag-only)

A `TextField` bound to a number, amount, email, URL, or phone number pops the **full QWERTY keyboard** by
default (`.keyboardType(.default)`). The user has to hunt for digits or the `@` key. Match the keyboard to the
bound data.

```swift
// ❌ WRONG — an amount field shows the full QWERTY keyboard
TextField("Amount", value: $amount, format: .number)
```
```swift
// ✅ CORRECT — the decimal keypad for a numeric amount
TextField("Amount", value: $amount, format: .number)
    .keyboardType(.decimalPad)              // .numberPad for ints, .decimalPad for decimals (iOS 13.0+)
```

**Grounded in the corpus.** `swiftui-ctx lookup keyboardType --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 13.0`, `deprecated: false`, consensus `(_)` **100%** — every real use passes a type. The
practical cases: `.numberPad` (integer), `.decimalPad` (amount), `.emailAddress` (email), `.URL`, `.phonePad`,
`.numbersAndPunctuation`. A `TextField` bound to **free-text prose** (a name, a note) correctly keeps
`.default` — judge the bound data before flagging.

## cf-02 — email/username/code/URL field with no autocaps/autocorrection suppression (warning, flag-only)

iOS capitalizes the first letter of a `TextField` (`.sentences` by default) and auto-corrects what it types.
For an **email, username, login code, or URL** that mangles valid input ("john@…" → "John@…"; a coupon code
"swift10" → "Swift10"). Suppress both.

```swift
// ❌ WRONG — email gets a capital first letter and is "auto-corrected"
TextField("Email", text: $email)
    .keyboardType(.emailAddress)
```
```swift
// ✅ CORRECT — no capitalization, no autocorrect for an identifier
TextField("Email", text: $email)
    .keyboardType(.emailAddress)
    .textInputAutocapitalization(.never)    // iOS 15.0+ (replaces the deprecated .autocapitalization)
    .autocorrectionDisabled()               // iOS 13.0+
```

**Grounded in the corpus.** `swiftui-ctx lookup textInputAutocapitalization --platform ios --json` (run
2026-06-16) returns `introduced_ios: 15.0`, `deprecated: false`, consensus `(_)` **100%**;
`swiftui-ctx lookup autocorrectionDisabled --platform ios` returns `introduced_ios: 13.0`, consensus `()`
**86%** · `(_)` 14% (the no-arg form is the idiom). `.textInputAutocapitalization(.words)` is right for a name,
`.never` for emails/codes — judge the field. Both are at/below the iOS-17 floor, so **no gate** is needed.

## cf-03 — free-standing `TextField` with no `.textFieldStyle(.roundedBorder)` (advisory, flag-only)

Outside a grouped `Form` or an inset `List` (which give a field its own bounded row), a bare `TextField` has
**no border** — it is invisible until tapped. `.textFieldStyle(.roundedBorder)` is the standard iOS bordered
field.

```swift
// ❌ WRONG — a free-standing field with no visible bounds
VStack {
    TextField("Search", text: $query)
}
```
```swift
// ✅ CORRECT — the standard rounded iOS field
VStack {
    TextField("Search", text: $query)
        .textFieldStyle(.roundedBorder)     // RoundedBorderTextFieldStyle (iOS 13.0+)
}
```

**Grounded in the corpus.** `swiftui-ctx lookup textFieldStyle --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 13.0`, `deprecated: false`, consensus `(_)` **100%**; `RoundedBorderTextFieldStyle` is
`introduced_ios: 13.0`. **Judge the container:** a `TextField` already inside a `Form` `Section` or an inset
`List` row gets its bounds from the row — `.roundedBorder` there is redundant; this is a **free-standing**
field defect only.

## cf-04 — multi-field form with no `.submitLabel(_:)` (advisory, flag-only)

In a form of several fields, the keyboard's Return key reads a generic "return" — it should say **Next** to
advance and **Done**/**Go** on the last field. `.submitLabel` sets it (and pairs with `.onSubmit` + `@FocusState`
to actually advance — cf-06).

```swift
// ❌ WRONG — Return key has no Next/Done affordance across fields
TextField("Email", text: $email)
SecureField("Password", text: $password)
```
```swift
// ✅ CORRECT — Next then Go labels guide the user through the form
TextField("Email", text: $email)
    .submitLabel(.next)                     // iOS 15.0+
SecureField("Password", text: $password)
    .submitLabel(.go)
```

**Grounded in the corpus.** `swiftui-ctx lookup submitLabel --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 15.0`, `deprecated: false`, consensus `(_)` **100%**. Cases: `.done`/`.next`/`.go`/`.search`/
`.send`/`.return`. A single-field form doesn't need this — judge the field count.

## cf-06 — custom view / form with no `@FocusState` keyboard-focus wiring (warning, flag-only)

`@FocusState` + `.focused($field, equals:)` + `.onSubmit` is how iOS **drives the keyboard**: focus the first
field on appear, advance on Return, and dismiss the keyboard programmatically. A custom focus-taking view, or a
multi-field form, with **none** of this can't advance fields or dismiss the keyboard. (Keyboard focus is fully
valid on iOS — `@FocusState` is `introduced_ios 15.0`, `.focusable()` 17.0.)

```swift
// ❌ WRONG — no way to advance fields or dismiss the keyboard
struct LoginForm: View {
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
        }
    }
}
```
```swift
// ✅ CORRECT — @FocusState drives the keyboard (all at/below the iOS-17 floor)
struct LoginForm: View {
    enum Field { case email, password }
    @FocusState private var focused: Field?   // @FocusState: iOS 15.0+
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .focused($focused, equals: .email)   // .focused(_:equals:): iOS 15.0+
                .submitLabel(.next)
            SecureField("Password", text: $password)
                .focused($focused, equals: .password)
                .submitLabel(.go)
        }
        .onSubmit { focused = (focused == .email) ? .password : nil }   // advance / dismiss
        .onAppear { focused = .email }
    }
}
```

**Grounded in the corpus.** `swiftui-ctx lookup focused --platform ios --json` (run 2026-06-16) returns
`introduced_ios: 15.0`, `deprecated: false`; `@FocusState` is `introduced_ios: 15.0`, `focusable` is
`introduced_ios: 17.0` (corpus consensus `()` 68% · `(_)` 32%). All at/below the iOS-17 floor — **no gate**.

> **keep-apart seam.** `@FocusState` (keyboard / which field the keyboard targets) is **this skill**;
> `AccessibilityFocusState` / `.accessibilityFocused` (VoiceOver focus) is `audit-swiftui-accessibility` —
> per `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` they are different wrappers; `cross_ref`
> accessibility, don't claim its half.

---

## Canonical pattern (the native iOS entry-form exemplar — controls half only)

```swift
// Native iOS sign-in form: grouped Form (grouped by default on iOS — NO .formStyle needed),
// keyboard configured per field, submit labels, @FocusState advance + dismiss.
// (Tap/swipe affordances are audit-swiftui-touch-gestures' half — omitted here on purpose.)
struct SignInForm: View {
    enum Field { case email, password }
    @FocusState private var focused: Field?
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {                                          // iOS Form is grouped by default — no .formStyle
            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)        // cf-01 (iOS 13.0+)
                    .textInputAutocapitalization(.never)// cf-02 (iOS 15.0+)
                    .autocorrectionDisabled()           // cf-02 (iOS 13.0+)
                    .focused($focused, equals: .email)  // cf-06 (iOS 15.0+)
                    .submitLabel(.next)                 // cf-04 (iOS 15.0+)
                SecureField("Password", text: $password)
                    .focused($focused, equals: .password)
                    .submitLabel(.go)
            }
        }
        .onSubmit { focused = (focused == .email) ? .password : nil }
        .onAppear { focused = .email }
    }
}
```

**Rules recap:** (1) `.keyboardType` matched to the bound data — `.default` is wrong for typed data (cf-01).
(2) `.textInputAutocapitalization(.never)` + `.autocorrectionDisabled()` for emails/codes (cf-02). (3)
`.textFieldStyle(.roundedBorder)` for a **free-standing** field (cf-03). (4) `.submitLabel` on each field of a
multi-field form (cf-04). (5) `@FocusState` + `.focused($_, equals:)` + `.onSubmit` to advance/dismiss the
keyboard (cf-06). The picker-style and `controlSize` density choices are in `control-styles-density.md`
(cf-05/07); the tap/swipe affordances are `audit-swiftui-touch-gestures`' half.

---

## Sources

- Apple — `keyboardType(_:)`: *"Sets the keyboard type for this view."* (`.numberPad`/`.decimalPad`/
  `.emailAddress`/`.URL`/`.phonePad`; iOS 13.0+):
  `https://developer.apple.com/documentation/swiftui/view/keyboardtype(_:)` (via Sosumi, accessed 2026-06-16).
- Apple — `textInputAutocapitalization(_:)`: iOS 15.0+ (replaces the deprecated `.autocapitalization`):
  `https://developer.apple.com/documentation/swiftui/view/textinputautocapitalization(_:)` (via Sosumi,
  accessed 2026-06-16).
- Apple — `autocorrectionDisabled(_:)`: iOS 13.0+:
  `https://developer.apple.com/documentation/swiftui/view/autocorrectiondisabled(_:)` (via Sosumi, accessed
  2026-06-16).
- Apple — `textFieldStyle(_:)` (`.roundedBorder`/`.plain`/`.automatic`; iOS 13.0+):
  `https://developer.apple.com/documentation/swiftui/view/textfieldstyle(_:)` (via Sosumi, accessed
  2026-06-16).
- Apple — `submitLabel(_:)`: iOS 15.0+:
  `https://developer.apple.com/documentation/swiftui/view/submitlabel(_:)` (via Sosumi, accessed 2026-06-16).
- Apple — `focused(_:equals:)` (binds focus to a `@FocusState`; iOS 15.0+):
  `https://developer.apple.com/documentation/swiftui/view/focused(_:equals:)`; `@FocusState` (iOS 15.0+):
  `https://developer.apple.com/documentation/swiftui/focusstate` (via Sosumi, accessed 2026-06-16).
- Practice corpus (consensus shapes + the ✅ permalinks): `swiftui-ctx lookup keyboardType` /
  `textInputAutocapitalization` / `autocorrectionDisabled` / `textFieldStyle` / `submitLabel` / `focused`
  `--platform ios` (1,857-repo iOS catalog, SwiftSyntax, iOS 26 SDK; accessed 2026-06-16);
  `swiftui-ctx recipe settings-form` →
  `https://github.com/groue/GRDB.swift/blob/9ed8c8457e00ff9c7aedb3bf213f20a2cfdf509e/Documentation/DemoApps/GRDBDemo/GRDBDemo/Views/PlayerCreationSheet.swift#L11`
  (the canonical grouped-`Form` iOS exemplar).
