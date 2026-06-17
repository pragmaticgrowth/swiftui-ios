# Reference — Safe-Area & Keyboard Patterns (sak-01 … sak-05)

The defects that ship content under a system inset (status bar / Dynamic Island / home indicator) or trap a
field behind the keyboard: a **blanket `.ignoresSafeArea()`**, the **deprecated `.edgesIgnoringSafeArea`**, a
**scrolling input form with no keyboard-dismiss**, a **fixed bottom bar with no `safeAreaInset`**, and a
**hand-rolled keyboard observer** where SwiftUI's automatic avoidance is the answer. All are *flag-only* (the
fix is a judgment call: is this a background or foreground content? which edge does a bleed need? which dismiss
mode does the form want?). Floors live in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` — read,
never restate. The ✅ here is the swiftui-ctx **consensus shape** (`lookup --platform ios`) backed by a real
iOS example permalink, not opinion.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK. iPad is modeled within `ios`.

---

## sak-01 — blanket `.ignoresSafeArea()` on foreground content (warning, flag-only)

`.ignoresSafeArea()` with **no `edges:`/`regions:` argument** ignores **every** edge. On a notch/Dynamic-Island
iPhone the top of the content runs under the status bar and Dynamic Island; the bottom runs under the home
indicator. It is correct **only** for a full-bleed *background* layer (a `Color`/`Image`/gradient *behind*
content). `swiftui-ctx lookup ignoresSafeArea --platform ios` → consensus `()` 74% (the blanket form is by far
the most common — and most misused) with `(_, edges)` and `(edges)` overloads for scoping.

```swift
// ❌ WRONG — foreground content ignores all safe-area edges; title runs under the Dynamic Island,
//            the footer under the home indicator
VStack {
    Text("Account").font(.largeTitle)
    ProfileForm()
}
.ignoresSafeArea()                       // sak-01: blanket; no edges/regions argument
```
```swift
// ✅ CORRECT — keep foreground content inside the safe area; let only a background bleed, scoped to its edge
ZStack {
    BackgroundGradient()
        .ignoresSafeArea()               // a background MAY bleed all edges
    VStack {
        Text("Account").font(.largeTitle)
        ProfileForm()
    }                                    // foreground content stays inside the safe area
}
```

> **Judge before flagging.** `.ignoresSafeArea()` on a `Color`/`Image`/gradient *background* layer is correct.
> sak-01 LOCATES every argument-less `.ignoresSafeArea()`; you decide whether it wraps a background (fine) or
> foreground content (defect). Its recommended iOS use (a full-screen HUD background) is in
> `relatedcode/ProgressHUD`:
> `https://github.com/relatedcode/ProgressHUD/blob/e6f7339d70d793a12dbccb008d374e153f2b98b5/SwiftUI/Sources/ProgressHUD.swift#L104`.

## sak-02 — scrolling input form with no `.scrollDismissesKeyboard` (warning, flag-only)

A `Form`/`List`/`ScrollView` containing text fields needs `.scrollDismissesKeyboard(_:)` (iOS 16.0;
`swiftui-ctx lookup scrollDismissesKeyboard --platform ios` → consensus `(_)` 100%). Without it the keyboard
stays up over the lower fields and there is no drag-to-dismiss — the user can scroll content *under* the
keyboard but never get it out of the way. `.interactive` lets the keyboard track the drag; `.immediately`
dismisses on any scroll.

```swift
// ❌ WRONG — long form, keyboard covers the lower fields, no way to dismiss by dragging
Form {
    TextField("Name", text: $name)
    TextField("Email", text: $email)
    SecureField("Password", text: $password)
    // …many more fields…
}                                        // sak-02: no .scrollDismissesKeyboard
```
```swift
// ✅ CORRECT — the scroll gesture dismisses the keyboard interactively (iOS 16.0)
Form {
    TextField("Name", text: $name)
    TextField("Email", text: $email)
    SecureField("Password", text: $password)
}
.scrollDismissesKeyboard(.interactive)   // drag the form down to push the keyboard away
```

**Grounded in the corpus.** `swiftui-ctx lookup scrollDismissesKeyboard --platform ios` recommends a real iOS
use in `mainframecomputer/fullmoon-ios`:
`https://github.com/mainframecomputer/fullmoon-ios/blob/cbc3c8206921afaa7fc4fe3dcdf790a18843226f/fullmoon/Views/Chat/ConversationView.swift#L232`.
When the form is inside a `.sheet`, the **detent interaction** is `audit-swiftui-presentation-sheets-modals`
(`cross_ref`); when the smell is the *dismiss-style* idiom on a `Form`, `cross_ref: controls-forms`.

## sak-03 — fixed bottom bar with no `safeAreaInset(edge: .bottom)` (warning, flag-only)

A bar pinned to the literal bottom — a `Spacer()`-pushed `VStack`, a bottom `.overlay`, a `ZStack`
bottom-aligned child — overlaps the home indicator and is hidden when the keyboard appears.
`safeAreaInset(edge: .bottom)` (iOS 15.0; `swiftui-ctx lookup safeAreaInset --platform ios` → consensus
`(edge)` 76%) reserves real space **above** the home indicator and inset-shifts the content so the bar always
sits in the safe area and rides the keyboard.

```swift
// ❌ WRONG — bar pinned to the literal bottom; overlaps the home indicator, hidden by the keyboard
ZStack(alignment: .bottom) {
    ScrollView { MessageList() }
    HStack {
        TextField("Message", text: $draft)
        Button("Send") { send() }
    }
    .padding()
    .background(.bar)                     // sak-03: a fixed bottom bar with no safeAreaInset
}
```
```swift
// ✅ CORRECT — reserve space for the bar above the home indicator; it rides the keyboard automatically
ScrollView { MessageList() }
    .safeAreaInset(edge: .bottom) {
        HStack {
            TextField("Message", text: $draft)
            Button("Send") { send() }
        }
        .padding()
        .background(.bar)
    }
```

**Grounded in the corpus.** `swiftui-ctx lookup safeAreaInset --platform ios` recommends a real iOS use in
`1amageek/Toolbar`:
`https://github.com/1amageek/Toolbar/blob/651c24079698401734dbca70c00632ef1498b295/Sources/Toolbar/ToolbarContainer.swift#L283`.
The bar's **internal arrangement** (stack/grid/spacing inside the inset) is `audit-swiftui-layout-and-tables`
(`cross_ref`) — file the *inset* finding here.

## sak-04 — deprecated `.edgesIgnoringSafeArea` (hard-fail, flag-only)

`.edgesIgnoringSafeArea(_:)` is **deprecated on iOS 14.0+**, replaced by `.ignoresSafeArea(_:edges:)`. It is a
deprecation, not a low floor — never wrap it in `#available(iOS …)`; replace it and scope the replacement to
the edge the original argument meant.

```swift
// ❌ WRONG — deprecated iOS 14.0+
Image("hero")
    .resizable()
    .edgesIgnoringSafeArea(.all)         // sak-04
```
```swift
// ✅ CORRECT — the current API; scope to the edge actually needed
Image("hero")
    .resizable()
    .ignoresSafeArea(edges: .all)        // or .top / .bottom — replace, never gate
```

**Replace, never gate.** Route any genuine above-floor gate via
`${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md`; but `.edgesIgnoringSafeArea` needs none — its
replacement `.ignoresSafeArea` is iOS 14.0, below the iOS-17 project floor.

## sak-05 — hand-rolled keyboard observer instead of SwiftUI auto-avoidance (advisory, flag-only)

SwiftUI moves content out of the keyboard's way **automatically** (the keyboard is part of the safe area). A
`keyboardWillShow` / `keyboardFrameEndUserInfoKey` `NotificationCenter` observer that adds manual
`.padding(.bottom, keyboardHeight)` fights the built-in avoidance and double-shifts the layout. To *opt out*
of the keyboard inset for a specific view (e.g. a background that should stay put), use the `regions` overload:
`.ignoresSafeArea(.keyboard)`.

```swift
// ❌ WRONG — manual keyboard tracking double-shifts against SwiftUI's automatic avoidance
@State private var keyboardHeight: CGFloat = 0
var body: some View {
    Form { /* fields */ }
        .padding(.bottom, keyboardHeight)
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification)) { note in
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            keyboardHeight = frame?.height ?? 0     // sak-05
        }
}
```
```swift
// ✅ CORRECT — let SwiftUI avoid the keyboard; opt a specific layer OUT with the regions overload
var body: some View {
    Form { /* fields */ }                // automatic keyboard avoidance — no observer needed
    // for a background that must NOT shift with the keyboard:
    // BackgroundView().ignoresSafeArea(.keyboard)
}
```

`.ignoresSafeArea(.keyboard, edges: .bottom)` is the SwiftUI control for the keyboard safe area; the UIKit
equivalent `UIView.keyboardLayoutGuide` (iOS 15.0) only appears when a `UIViewRepresentable` bridge is in play
— `cross_ref: uikit-interop`. `keyboardLayoutGuide` is **not in the catalog** (`swiftui-ctx lookup` not-found);
carry its floor as **verify against Xcode 26 SDK**.

---

## Sources

- Floors / availability: `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` (iOS truth —
  `ignoresSafeArea` 14.0, `safeAreaInset` 15.0, `scrollDismissesKeyboard` 16.0, `safeAreaPadding` 17.0).
- Practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. All consensus
  shapes + permalinks above from `swiftui-ctx lookup <api> --platform ios --json` (run 2026-06-16).
- Apple paths fetched via `https://sosumi.ai/...` — see `references/source-directory.md` for the map and
  `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol.
