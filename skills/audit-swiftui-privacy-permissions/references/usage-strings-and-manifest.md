# Reference — Usage Strings, the Privacy Manifest & Required-Reason APIs (pp-01 · pp-02 · pp-03 · pp-04)

The four defects that turn a clean-compiling iOS app into a **runtime crash** or an **App Store
rejection**: a privacy-protected API with **no `Info.plist` usage string** (pp-01/02), a required-reason
API with **no `NSPrivacyAccessedAPITypes` entry** in `PrivacyInfo.xcprivacy` (pp-03), and tracking with
**no `NSUserTrackingUsageDescription` / unfilled `NSPrivacyTracking*`** (pp-04). The reason AI ships these:
training data shows the *API call* but never the **config-file half** that makes it legal. The Swift side
is only half the evidence — **the other half is two config files this skill reads by hand.**

> **The exact keys below are `verify against Xcode 26 SDK` — never asserted from memory.** The
> camera/mic/tracking/contacts/location APIs are AVFoundation/AppTrackingTransparency/Contacts/CoreLocation,
> **not SwiftUI** — they are **not in the swiftui-ctx catalog** (`lookup --platform ios` returns **exit 3**,
> which here means "verify the floor against the SDK," not "hallucination"). Only the SwiftUI surfaces
> (`onOpenURL` iOS 14.0, `PhotosPicker` iOS 16.0, `privacySensitive` iOS 15.0) ground via swiftui-ctx.

**As of:** 2026-06-16 · iOS 17 deployment floor · Xcode 26 SDK.

---

## pp-01 — privacy-protected API with no `Info.plist` usage string (hard-fail, flag-only)

A camera / microphone / contacts / location API needs a purpose string in `Info.plist`. With the string
**absent**, iOS **hard-crashes the process** the instant the system would show the consent prompt — not a
silent failure, an immediate `SIGABRT` with a console message naming the missing key.

```swift
// ❌ WRONG — compiles clean; HARD CRASH on device the moment the camera prompt would appear.
import AVFoundation
let granted = await AVCaptureDevice.requestAccess(for: .video)
// Info.plist carries NO NSCameraUsageDescription → crash on first call (pp-01).
```
```swift
// ✅ CORRECT — the .swift call is HALF the contract; the Info.plist usage string is the other half.
import AVFoundation
let granted = await AVCaptureDevice.requestAccess(for: .video)
// Info.plist MUST carry (key read from the Xcode 26 SDK list, string text is a product decision):
//   <key>NSCameraUsageDescription</key>
//   <string>Used to scan documents.</string>
```

**The per-API usage-string map (verify every key against the Xcode 26 SDK — never invent):**

| API in `.swift` | Required `Info.plist` key | Note |
|---|---|---|
| `AVCaptureDevice.requestAccess(for: .video)` / `UIImagePickerController(.camera)` | `NSCameraUsageDescription` | camera |
| `AVAudioSession…requestRecordPermission` / `AVCaptureDevice(for: .audio)` | `NSMicrophoneUsageDescription` | microphone |
| `PHPhotoLibrary`/`PhotosPicker`/`PHPickerViewController` (read) | `NSPhotoLibraryUsageDescription` | photos read (pp-02) |
| `PHPhotoLibrary` add-only | `NSPhotoLibraryAddUsageDescription` | add-only variant (pp-02) |
| `CNContactStore.requestAccess(for: .contacts)` | `NSContactsUsageDescription` | contacts |
| `CLLocationManager.requestWhenInUseAuthorization()` | `NSLocationWhenInUseUsageDescription` | location (in-use) |
| `CLLocationManager.requestAlwaysAuthorization()` | `NSLocationAlwaysAndWhenInUseUsageDescription` | location (always) |
| `ATTrackingManager.requestTrackingAuthorization` | `NSUserTrackingUsageDescription` | tracking (pp-04) |

> **Judge before flagging.** A finding is 100% **only after `Info.plist` has been READ and the key is
> demonstrably absent** — never infer absence from the `.swift` side alone. A guarded simulator-only stub
> that never reaches the prompt, or a use already backed by the string, is *not* a defect.

## pp-02 — Photos/Files API with no usage string (warning, flag-only · seam)

The Photos surfaces (`PhotosPicker`, `PHPhotoLibrary`, `PHPickerViewController`) need
`NSPhotoLibraryUsageDescription` (read) or `NSPhotoLibraryAddUsageDescription` (add-only). **Note the
exception:** a plain document picker (`fileImporter`/`UIDocumentPickerViewController`) needs **no** usage
string — *the picker itself is the consent*. `PhotosPicker` is PhotoKit/SwiftUI iOS 16.0 — **not in the
swiftui-ctx catalog** (a `lookup` returns no usage); carry the floor `verify against Xcode 26 SDK`.

```swift
// ❌ WRONG — PhotosPicker shown with no NSPhotoLibraryUsageDescription (pp-02).
.photosPicker(isPresented: $show, selection: $item)
```
```swift
// ✅ CORRECT — picker + Info.plist string.
.photosPicker(isPresented: $show, selection: $item)   // PhotosPicker — iOS 16.0 (verify against Xcode 26 SDK)
// Info.plist: <key>NSPhotoLibraryUsageDescription</key><string>Choose a profile photo.</string>
```

> **keep-both / reciprocal seam (do NOT collapse).** A Photos API is detected by BOTH this skill (the
> *usage string*) and `audit-swiftui-document-picker-permissions` (the *security-scope/consent* angle). Per
> `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` the **usage string is owned here**; the
> picker skill flags the use and `cross_ref`s here. File the string finding here with
> `cross_ref: audit-swiftui-document-picker-permissions`.

## pp-03 — required-reason API with no `PrivacyInfo.xcprivacy` manifest entry (warning, flag-only)

Since 2024 Apple requires a **privacy manifest** declaring **required-reason APIs**: each use needs an
`NSPrivacyAccessedAPITypes` entry with an approved `NSPrivacyAccessedAPITypeReasons` code. A binary that
uses one with **no** entry is **rejected at upload** (and warned in the App Store Connect privacy report).

```swift
// ❌ WRONG — UserDefaults + a disk-space query, no NSPrivacyAccessedAPITypes entry → upload rejected (pp-03).
UserDefaults.standard.set(true, forKey: "launched")               // required-reason: UserDefaults
let free = try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey])   // required-reason: disk space
```
```swift
// ✅ CORRECT — the same calls, with PrivacyInfo.xcprivacy declaring each required-reason API + reason code.
UserDefaults.standard.set(true, forKey: "launched")
// PrivacyInfo.xcprivacy NSPrivacyAccessedAPITypes (keys/reason codes verify against Xcode 26 SDK):
//   NSPrivacyAccessedAPICategoryUserDefaults        → reason CA92.1 (app-internal use)
//   NSPrivacyAccessedAPICategoryDiskSpace           → reason E174.1 (display to user)
```

**The required-reason-API → manifest-category map (verify every category + reason code against the Xcode 26 SDK):**

| API in `.swift` | `NSPrivacyAccessedAPITypes` category | Note |
|---|---|---|
| `UserDefaults` / `@AppStorage` | `NSPrivacyAccessedAPICategoryUserDefaults` | the most common miss |
| `URLResourceKey.contentModificationDateKey`/`.creationDateKey` | `NSPrivacyAccessedAPICategoryFileTimestamp` | file timestamp |
| `ProcessInfo.processInfo.systemUptime` / `mach_absolute_time` | `NSPrivacyAccessedAPICategorySystemBootTime` | boot time |
| `volumeAvailableCapacity*` resource values / `statfs` | `NSPrivacyAccessedAPICategoryDiskSpace` | disk space |

## pp-04 — tracking with no `NSUserTrackingUsageDescription` / unfilled `NSPrivacyTracking*` (hard-fail, flag-only)

`ATTrackingManager.requestTrackingAuthorization` needs **both** `NSUserTrackingUsageDescription` in
`Info.plist` (a missing string crashes the prompt) **and** `NSPrivacyTracking` = true plus
`NSPrivacyTrackingDomains` filled in `PrivacyInfo.xcprivacy` (an unfilled manifest is rejected). The
AppTrackingTransparency framework introduced this in iOS 14 — **not in the swiftui-ctx catalog; carry the
floor `verify against Xcode 26 SDK`.**

```swift
// ❌ WRONG — ATT prompt with no NSUserTrackingUsageDescription (crash) and no NSPrivacyTracking* (reject) (pp-04).
import AppTrackingTransparency
let status = await ATTrackingManager.requestTrackingAuthorization()
```
```swift
// ✅ CORRECT — the request, with both declarations present.
import AppTrackingTransparency
let status = await ATTrackingManager.requestTrackingAuthorization()
// Info.plist:                 <key>NSUserTrackingUsageDescription</key><string>…</string>
// PrivacyInfo.xcprivacy:      NSPrivacyTracking = true ; NSPrivacyTrackingDomains = [ "…" ]
```

> **Seam.** *Where in the lifecycle* the request fires (e.g. wait for `scenePhase == .active`) is the
> request-flow angle owned by `audit-swiftui-async-data` — `cross_ref` it. The **declaration** the request
> needs is owned here.

---

## The consent test (the canonical procedure)

For every privacy-protected or required-reason API use found in `.swift`:

1. Identify the **required declaration** from the maps above (usage-string key and/or manifest category).
2. **Open `Info.plist` and `PrivacyInfo.xcprivacy` by hand** (the shared lint runner does NOT scan them).
3. Present → **legal, no finding.** Usage string absent → **crash-on-use (pp-01/02/04).** Manifest entry
   absent → **App-Store reject (pp-03/04).**

**Go-beyond artifact** — `swiftui-audits/privacy-permissions/_consent-map.md`:

| API (file:line) | Required declaration | In `Info.plist`? | In `.xcprivacy`? | Verdict |
|---|---|---|---|---|
| `AVCaptureDevice` (CaptureView.swift:31) | `NSCameraUsageDescription` | ✗ | n/a | crash (pp-01) |
| `UserDefaults` (State.swift:8) | `NSPrivacyAccessedAPICategoryUserDefaults` | n/a | ✗ | reject (pp-03) |

---

## Sources

- Apple — *Describing use of required reason API* / privacy manifest files (`NSPrivacyAccessedAPITypes`,
  approved reason codes): `https://developer.apple.com/documentation/bundleresources/privacy-manifest-files`
  (via Sosumi, accessed 2026-06-16) — keys/reason codes **verify against Xcode 26 SDK**.
- Apple — `AVCaptureDevice.requestAccess(for:)` (camera/microphone prompt; needs the usage string):
  `https://developer.apple.com/documentation/avfoundation/avcapturedevice/requestaccess(for:)`
  (via Sosumi, accessed 2026-06-16).
- Apple — `ATTrackingManager.requestTrackingAuthorization` (needs `NSUserTrackingUsageDescription`):
  `https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/requesttrackingauthorization()`
  (via Sosumi, accessed 2026-06-16) — AppTrackingTransparency iOS 14.0, **verify against Xcode 26 SDK**
  (not in the swiftui-ctx catalog; `lookup` exit 3 expected).
- Apple — *Requesting access to protected resources* / `Information Property List` usage-string keys:
  `https://developer.apple.com/documentation/bundleresources/information-property-list` (via Sosumi,
  accessed 2026-06-16) — every `NS…UsageDescription` key **verify against Xcode 26 SDK**.
- Practice corpus (the catalog SwiftUI surfaces only): `swiftui-ctx lookup onOpenURL --platform ios`
  (iOS 14.0, run 2026-06-16), `swiftui-ctx lookup onContinueUserActivity --platform ios` (iOS 14.0),
  `swiftui-ctx lookup privacySensitive --platform ios` (iOS 15.0); `PhotosPicker` and the
  UIKit/AVFoundation/ATT/StoreKit symbols return **no catalog usage** (PhotoKit/non-SwiftUI) — that is
  expected here and means verify-SDK, not hallucination.
- Real shipping reference — App Tracking Transparency request + Info.plist string (corroboration only):
  `https://github.com/firebase/quickstart-ios` (Analytics ATT sample; AASA/ATT patterns mirrored from
  Apple's own samples). Carry as `confidence:` low / verified-by-research.
