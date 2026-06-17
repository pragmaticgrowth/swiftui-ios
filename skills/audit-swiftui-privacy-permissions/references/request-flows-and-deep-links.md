# Reference — Deep-Link Consent, Notifications & StoreKit 2 (pp-05 · pp-06)

The two advisory surfaces where a *runtime entry point* needs a declaration or a paired listener the
`.swift` call alone doesn't reveal: a universal-link / `onOpenURL` entry with no
`apple-app-site-association` (pp-05), and a notification-authorization request or a StoreKit 2
`Product.purchase()` with no follow-through (pp-06). The reason AI gets these wrong: the modifier or call
compiles and *looks* complete, but the deep link silently never resolves, the notification permission has
no delegate to receive the tap, or the purchased entitlement is lost because the transaction is never
finished.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## pp-05 — `onOpenURL` / universal link with no `apple-app-site-association` (advisory, flag-only)

`onOpenURL` (iOS 14.0, **in the catalog** — `swiftui-ctx lookup onOpenURL --platform ios` → `introduced_ios:
14.0`, consensus `{ }` 74%) and `onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` (iOS 14.0) are the
SwiftUI **entry points** for deep links. A *universal* link (an https URL that opens your app instead of
Safari) additionally requires, off the `.swift` side:

- an **`apple-app-site-association`** (AASA) file served at `https://<domain>/.well-known/apple-app-site-association`,
- the **Associated Domains** entitlement (`applinks:<domain>`) in the app's `.entitlements`.

Without both, the link falls through to the browser — the handler never fires. (A custom URL scheme
`myapp://` needs `CFBundleURLTypes` in `Info.plist` instead — also read by hand.)

```swift
// ❌ WRONG — onOpenURL handler with no AASA / Associated Domains backing the universal link (pp-05).
WindowGroup {
    ContentView().onOpenURL { url in route(url) }   // link falls through to Safari; handler never runs
}
```
```swift
// ✅ CORRECT — the handler, backed by the two off-Swift declarations.
WindowGroup {
    ContentView().onOpenURL { url in route(url) }   // onOpenURL — iOS 14.0 (catalog)
}
// .entitlements:  com.apple.developer.associated-domains = [ "applinks:example.com" ]
// served:         https://example.com/.well-known/apple-app-site-association  (AASA JSON)
```

> **Seam.** The `scenePhase` / scene-event *lifecycle* handling around `onOpenURL`/`onContinueUserActivity`
> is owned by `audit-swiftui-app-lifecycle-background` — `cross_ref` it. This skill owns only the
> **deep-link consent/declaration surface** (the AASA + Associated Domains entitlement).

## pp-06 — notification authorization / StoreKit 2 purchase with no follow-through (advisory, flag-only)

**Notifications.** `UNUserNotificationCenter.requestAuthorization(options:)` (UserNotifications — **not in
the catalog**, verify against Xcode 26 SDK) shows the system prompt, but a granted permission is useless
without a `UNUserNotificationCenterDelegate` registered to receive foreground/tap callbacks, and (for
remote pushes) `UIApplication.shared.registerForRemoteNotifications()`.

```swift
// ❌ WRONG — permission requested but no delegate wired to receive the notification (pp-06).
_ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
```
```swift
// ✅ CORRECT — request + a registered delegate (and registerForRemoteNotifications for push).
let center = UNUserNotificationCenter.current()
center.delegate = notificationDelegate                    // receives willPresent / didReceive
_ = try? await center.requestAuthorization(options: [.alert, .sound])
```

**StoreKit 2.** `Product.purchase()` (StoreKit 2 — iOS 15.0, **not in the catalog**, verify against Xcode
26 SDK) returns a result, but the app must **(a)** verify the transaction, **(b)** `finish()` it, and
**(c)** run a `Transaction.updates` listener at launch to catch transactions completed outside the app
(Ask-to-Buy, interrupted purchases). A purchase flow with no `Transaction.updates` listener loses
entitlements.

```swift
// ❌ WRONG — purchase with no Transaction.updates listener; transaction never finished (pp-06).
let result = try await product.purchase()
```
```swift
// ✅ CORRECT — verify, finish, and listen for out-of-app transactions.
let result = try await product.purchase()              // StoreKit 2 — iOS 15.0 (verify against Xcode 26 SDK)
if case let .success(.verified(transaction)) = result {
    await transaction.finish()                         // grant entitlement, then finish
}
// at launch, run once:
for await update in Transaction.updates {              // catches Ask-to-Buy / interrupted purchases
    if case let .verified(t) = update { await t.finish() }
}
```

> **Seam.** *Where in the lifecycle* the notification/purchase request fires (await `scenePhase`, the
> `.task` timing) is the request-flow angle owned by `audit-swiftui-async-data` — `cross_ref` it when the
> finding is about timing rather than the missing listener/delegate.

---

## Sources

- Apple — `onOpenURL(perform:)` (SwiftUI deep-link entry; iOS 14.0):
  `https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)` (via Sosumi, accessed
  2026-06-16); floor confirmed `swiftui-ctx lookup onOpenURL --platform ios` → `introduced_ios: 14.0`.
- Apple — *Supporting universal links in your app* (AASA + Associated Domains entitlement):
  `https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app` (via Sosumi,
  accessed 2026-06-16).
- Apple — `UNUserNotificationCenter.requestAuthorization(options:)` (UserNotifications):
  `https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:)`
  (via Sosumi, accessed 2026-06-16) — **not in the swiftui-ctx catalog; verify against Xcode 26 SDK.**
- Apple — `Product.purchase(options:)` / `Transaction.updates` (StoreKit 2; iOS 15.0):
  `https://developer.apple.com/documentation/storekit/product/purchase(options:)` ·
  `https://developer.apple.com/documentation/storekit/transaction/updates` (via Sosumi, accessed
  2026-06-16) — **not in the swiftui-ctx catalog; verify against Xcode 26 SDK.**
- Practice corpus: only the SwiftUI surfaces resolve — `swiftui-ctx lookup onOpenURL --platform ios`
  (iOS 14.0), `onContinueUserActivity` (iOS 14.0); StoreKit/UserNotifications return no catalog usage
  (expected — verify-SDK, not hallucination).
