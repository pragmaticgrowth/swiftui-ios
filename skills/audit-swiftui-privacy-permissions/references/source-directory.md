# Reference — Apple/Practitioner Source Map (the VERIFY map)

The navigable official-source map the auditor uses in step VERIFY to confirm any ≤~70%-confidence
privacy / permission / required-reason claim. **Always fetch Apple docs via Sosumi** — the shared fetch
protocol with the curl/CLI commands and the JSON-404 caveat is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`; this file is the privacy-specific *map* of
which pages to fetch. Floor values for the catalog SwiftUI surfaces live in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the practice corpus (consensus + permalink)
is reached with `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json` per
`${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## How to verify (summary; full protocol in the shared sosumi reference)

1. **Does the symbol exist + what's its iOS floor?** Fetch
   `https://sosumi.ai/documentation/<framework>/<symbol-path>` and read the `**Available on:** … iOS N+ …`
   line. **For this domain most APIs are AVFoundation/AppTrackingTransparency/UserNotifications/StoreKit/
   PhotoKit — NOT SwiftUI** — so `swiftui-ctx lookup --platform ios` returns **no catalog usage**; that is
   **expected and means verify-SDK, NOT a hallucination.** Only `onOpenURL`/`onContinueUserActivity`/
   `privacySensitive` return a real iOS floor from the corpus.
2. **The exact `Info.plist` / `PrivacyInfo.xcprivacy` key.** Every `NS…UsageDescription` key, every
   `NSPrivacyAccessedAPICategory…` value, and every approved reason code is **read from the Xcode 26 SDK
   list and the privacy-manifest doc — never asserted from memory.** Carry the finding
   `source: verify against Xcode 26 SDK`.
3. **Read the config by hand.** The shared lint runner is `*.swift`-only — `Info.plist` and
   `PrivacyInfo.xcprivacy` are opened by hand in ORIENT/READ; a use is a finding only when its declaration
   is demonstrably absent there.

---

## A. The privacy/permission API → declaration symbol map

Human doc path = `developer.apple.com/documentation/<framework>/<path>` (fetch via `sosumi.ai/...`).

| Symbol | Framework path | iOS floor | Required declaration |
|---|---|---|---|
| `AVCaptureDevice.requestAccess(for:)` | `avfoundation/avcapturedevice/requestaccess(for:)` | verify-SDK | `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` |
| `ATTrackingManager.requestTrackingAuthorization` | `apptrackingtransparency/attrackingmanager/requesttrackingauthorization()` | iOS 14.0 (verify-SDK) | `NSUserTrackingUsageDescription` + `NSPrivacyTracking*` |
| `UNUserNotificationCenter.requestAuthorization(options:)` | `usernotifications/unusernotificationcenter/requestauthorization(options:)` | verify-SDK | delegate registration (not a usage string) |
| `CLLocationManager.requestWhenInUseAuthorization()` | `corelocation/cllocationmanager/requestwheninuseauthorization()` | verify-SDK | `NSLocationWhenInUseUsageDescription` |
| `CNContactStore.requestAccess(for:)` | `contacts/cncontactstore/requestaccess(for:)` | verify-SDK | `NSContactsUsageDescription` |
| `PhotosPicker` / `PHPhotoLibrary` | `photokit/photospicker` · `photokit/phphotolibrary` | iOS 16.0 (verify-SDK) | `NSPhotoLibraryUsageDescription` |
| `Product.purchase()` / `Transaction.updates` | `storekit/product/purchase(options:)` · `storekit/transaction/updates` | iOS 15.0 (verify-SDK) | `Transaction.updates` listener (finish transactions) |
| `onOpenURL(perform:)` | `swiftui/view/onopenurl(perform:)` | **iOS 14.0 (catalog)** | AASA + Associated Domains entitlement |
| `onContinueUserActivity(_:perform:)` | `swiftui/view/oncontinueuseractivity(_:perform:)` | **iOS 14.0 (catalog)** | AASA (browsing-web) |
| `privacySensitive(_:)` | `swiftui/view/privacysensitive(_:)` | **iOS 15.0 (catalog)** | redaction (no plist) |

## B. The required-reason API → manifest-category map (read the manifest doc; verify every code)

| Required-reason API | `NSPrivacyAccessedAPITypes` category | Doc |
|---|---|---|
| `UserDefaults` / `@AppStorage` | `NSPrivacyAccessedAPICategoryUserDefaults` | `bundleresources/privacy-manifest-files` |
| file timestamp (`contentModificationDateKey`) | `NSPrivacyAccessedAPICategoryFileTimestamp` | same |
| system boot time (`systemUptime`) | `NSPrivacyAccessedAPICategorySystemBootTime` | same |
| disk space (`volumeAvailableCapacity*`) | `NSPrivacyAccessedAPICategoryDiskSpace` | same |

## C. Apple conceptual / config pages

| Page | Path | Anchors |
|---|---|---|
| Privacy manifest files | `documentation/bundleresources/privacy-manifest-files` | required-reason APIs, tracking, collected data types (pp-03/04) |
| Information Property List (usage strings) | `documentation/bundleresources/information-property-list` | every `NS…UsageDescription` key (pp-01/02/04) |
| Requesting access to protected resources | `documentation/uikit/requesting-access-to-protected-resources` | the usage-string-or-crash contract (pp-01) |
| Supporting universal links | `documentation/xcode/supporting-universal-links-in-your-app` | AASA + Associated Domains (pp-05) |
| Configuring background execution modes | `documentation/uikit/configuring-background-execution-modes` | `UIBackgroundModes` (cross_ref app-lifecycle-background) |

## D. Practitioners (corroboration only — never primary; label `confidence:` low / verified-by-research)

| Source | URL | Reliable for | Trust |
|---|---|---|---|
| Hacking with Swift | `hackingwithswift.com/example-code/system/how-to-request-a-users-location-only-once` | usage-string-or-crash for location (pp-01) | high |
| Apple sample (StoreKit) | `github.com/apple/sample-food-truck` | StoreKit 2 `Transaction.updates` + `finish()` pattern (pp-06) | high |
| Apple sample (push) | `developer.apple.com/documentation/usernotifications/registering-your-app-with-apns` | notification delegate + `registerForRemoteNotifications` (pp-06) | high |

---

## Sources

- Sosumi fetch protocol + JSON-404 caveat: `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md`.
- The practice corpus contract: `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`.
- All Apple paths above fetched via `https://sosumi.ai/...` (access 2026-06-16); catalog SwiftUI floors
  cross-checked against `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; every
  UIKit/AVFoundation/ATT/StoreKit/PhotoKit floor and every `Info.plist`/`.xcprivacy` key carried
  `verify against Xcode 26 SDK` (not in the swiftui-ctx catalog).
- Practitioner / Apple-sample URLs as listed (trust labelled; corroboration only).
