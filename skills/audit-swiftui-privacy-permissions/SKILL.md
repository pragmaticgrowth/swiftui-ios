---
name: audit-swiftui-privacy-permissions
description: Audits a finished iOS SwiftUI codebase for privacy, permission, and required-reason defects, writing per-finding Markdown to swiftui-audits/. Use when an app crashes the instant it touches the camera, microphone, photos, contacts, or location; when App Store Connect rejects an upload for a missing purpose string or privacy manifest; when AI called AVCaptureDevice, ATTrackingManager.requestTrackingAuthorization, UNUserNotificationCenter.requestAuthorization, or CLLocationManager with no matching Info.plist usage string; when a required-reason API (UserDefaults, file timestamp, boot time, disk space) lacks an NSPrivacyAccessedAPITypes entry in PrivacyInfo.xcprivacy; when onOpenURL/universal links lack apple-app-site-association; or when StoreKit 2 purchases skip a transaction listener. Reads Info.plist and the privacy manifest by hand. AUDIT-ONLY, iOS-only, SwiftUI-only. Not document-picker scope (document-picker-permissions), AppIntents (app-intents), or scenePhase lifecycle (app-lifecycle-background).
---

# Audit SwiftUI Privacy & Permissions

**AUDIT-ONLY · iOS-only · SwiftUI-only.** Run this on a *finished or in-progress* iOS SwiftUI
project to detect — and where certain, fix — every way a privacy-protected resource or a required-reason
API is touched **without the declaration iOS demands**: a camera/microphone/photos/contacts/location API
called with no matching `Info.plist` usage string (a runtime crash the instant the prompt would appear), a
required-reason API (`UserDefaults`, file timestamp, system boot time, disk space) used with no
`NSPrivacyAccessedAPITypes` entry in `PrivacyInfo.xcprivacy` (an App Store upload rejection),
`ATTrackingManager.requestTrackingAuthorization` with no `NSUserTrackingUsageDescription`, a background
capability used with no `UIBackgroundModes`, and `onOpenURL`/universal-link entry with no
`apple-app-site-association`. Findings are written to disk in the toolkit's unified schema; certain
mechanical defects are fixed under the fix-safety protocol. This is never a from-scratch permission-flow
generator.

The governing rule that makes this domain a crash-and-reject minefield — and the reason AI gets it wrong
(training data shows the *API call* but never the project-config side that makes it legal): **a
privacy-protected API is a two-part contract — the call in `.swift` AND the declaration in
`Info.plist` / `PrivacyInfo.xcprivacy`.** The Swift side compiles fine alone. At runtime, iOS hard-crashes
the process the moment a protected API would surface its consent prompt with **no usage string** present;
at submission, App Store Connect rejects a binary that touches a required-reason API with **no manifest
entry**. The `.swift` call is only half the evidence — **the other half is two config files this skill
reads by hand.**

> iOS is **not** macOS here. There is no `NSOpenPanel` consent, no Hardened-Runtime entitlement plist, no
> TCC-prompt-only model — on iOS the consent surface is the **`Info.plist` usage string** (the purpose
> string shown in the system prompt) plus, since 2024, the **`PrivacyInfo.xcprivacy` privacy manifest**
> (required-reason APIs + tracking + collected data types). Both are config files, not Swift — so the grep
> tier locates the `.swift`-side API use, and the SKILL workflow READ step inspects `Info.plist` and
> `PrivacyInfo.xcprivacy` **by hand** (the shared lint runner greps `*.swift` only — say so, and do it).

## Boundary / seam note (stay in lane)

Seam verdicts are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md`
— apply them in the tells and emit `cross_ref` on a shared-seam finding; do not double-own.

- **The document-picker security-scoped URL** (`startAccessingSecurityScopedResource()`, security-scoped
  bookmarks) is owned by **`audit-swiftui-document-picker-permissions`**. This skill owns the **Photos/Files
  *usage string* / privacy-manifest** half of the same file/photos consent; when a Photos/Files API needs a
  purpose string, the picker skill flags the use and `cross_ref`s here for the string (the reciprocal seam,
  pp-02).
- **The `AppIntent` definition itself** (the `perform()` shape, `@Parameter`, `AppShortcutsProvider`) is
  owned by **`audit-swiftui-app-intents`**. When an intent touches a protected resource (camera, location),
  this skill owns the **manifest/usage-string** correctness and `cross_ref`s app-intents — do not audit the
  intent's structure here.
- **Where an interactive widget / Live Activity is placed** is owned by
  **`audit-swiftui-widgets-live-activities`**; when a widget's data source needs a privacy manifest, that
  skill flags placement and `cross_ref`s here for the **manifest correctness** (pp-01).
- **The `scenePhase` / `onOpenURL` / `onContinueUserActivity` lifecycle wiring** is owned by
  **`audit-swiftui-app-lifecycle-background`**; this skill owns only the **deep-link consent surface** of
  `onOpenURL`/universal links (the `apple-app-site-association` declaration, pp-05) and `cross_ref`s
  app-lifecycle-background for the scene-event handling.
- **The `ATTrackingManager`/`UNUserNotificationCenter` request *flow*** (where in the lifecycle the prompt
  fires) is a seam with **`audit-swiftui-async-data`**; this skill owns the **declaration** the request
  needs (the usage string / manifest tracking entry) and `cross_ref`s async-data for the request-flow angle.
- **The blanket "is every OS-floored API gated" sweep** belongs to `audit-swiftui-availability-gating`;
  this skill owns the floors of the privacy/permission APIs it names in depth and defers the rest.

## The three non-negotiable iOS rules

1. **A privacy-protected API needs a matching `Info.plist` usage string — or the app hard-crashes.** Every
   camera (`AVCaptureDevice`/`UIImagePickerController(.camera)`), microphone, photos
   (`PHPhotoLibrary`/`PhotosPicker`), contacts (`CNContactStore`), and location
   (`CLLocationManager.request*Authorization`) API requires a purpose string
   (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`,
   `NSContactsUsageDescription`, `NSLocationWhenInUseUsageDescription`, …). The string is **not** optional
   polish — its **absence is a guaranteed crash** the instant the system would show the prompt (pp-01).
2. **A required-reason API needs a `PrivacyInfo.xcprivacy` manifest entry — or the upload is rejected.**
   `UserDefaults`, file-timestamp (`URLResourceKey.contentModificationDateKey`/`.creationDateKey`),
   system-boot-time (`systemUptime`), and disk-space (`volumeAvailableCapacity*`) APIs are **required-reason
   APIs**: each needs an `NSPrivacyAccessedAPITypes` entry with an approved reason code in
   `PrivacyInfo.xcprivacy`. Tracking (`ATTrackingManager`) additionally needs `NSUserTrackingUsageDescription`
   **and** the manifest's `NSPrivacyTracking`/`NSPrivacyTrackingDomains` filled (pp-03, pp-04).
3. **A deep-link / background entry surface needs its own declaration.** `onOpenURL`/universal links need an
   `apple-app-site-association` file + the `Associated Domains` entitlement (pp-05); a background capability
   (`BGTaskScheduler`, background location) needs the matching `UIBackgroundModes` array
   (cross_ref `app-lifecycle-background`).

**The consent test:** for every privacy-protected or required-reason API use found in `.swift`, open
`Info.plist` **and** `PrivacyInfo.xcprivacy` by hand and confirm the matching declaration is present →
**legal**; a use with **no** usage string → **crash-on-use**; a required-reason API with **no** manifest
entry → **App-Store reject.** Full reasoning + the per-API key map: `references/usage-strings-and-manifest.md`.

## Correct (grounded — the API is verify-SDK; the config is read by hand)

The privacy/permission APIs in this domain (`AVCaptureDevice`, `ATTrackingManager`,
`UNUserNotificationCenter`, `CLLocationManager`, `CNContactStore`, StoreKit 2 `Product`/`Transaction`) are
**UIKit/Foundation/AVFoundation/StoreKit, not SwiftUI** — they are **not in the swiftui-ctx catalog** (a
`lookup --platform ios` returns **exit 3**). Their floors are the well-known framework introductions, carried
`source: verify against Xcode 26 SDK` — **never fabricated**. The SwiftUI surfaces that *are* in the catalog
(`onOpenURL` iOS 14.0, `onContinueUserActivity` iOS 14.0, `privacySensitive` iOS 15.0) ground via swiftui-ctx as usual.

```swift
// ✅ The .swift call is HALF the contract — the Info.plist usage string is the other half.
// requestAccess(for: .video) shows the system camera prompt; with NO NSCameraUsageDescription in
// Info.plist iOS HARD-CRASHES the process the instant the prompt would appear.
let granted = await AVCaptureDevice.requestAccess(for: .video)   // AVFoundation — verify against Xcode 26 SDK
// Info.plist MUST carry:  <key>NSCameraUsageDescription</key><string>Scan a document.</string>
```

- **Apple doc (Sosumi):** `doc:` <https://sosumi.ai/documentation/avfoundation/avcapturedevice/requestaccess(for:)> — the camera prompt; needs `NSCameraUsageDescription`.
- **Apple doc (Sosumi):** `doc:` <https://sosumi.ai/documentation/bundleresources/privacy-manifest-files> — required-reason APIs + tracking in `PrivacyInfo.xcprivacy`.

Contrast the ❌: the same `AVCaptureDevice.requestAccess(for: .video)` with **no** `NSCameraUsageDescription`
in `Info.plist` — compiles clean, crashes on device (pp-01). The fix is the usage string (read/added by
hand) — never asserted from memory, always verified against the Xcode 26 SDK key list.

## Defect index (pp-01 … pp-06)

`id · tell · severity · fix · open reference`. Severities: **hard-fail** (guaranteed runtime crash /
App-Store reject / never-correct on iOS), **warning** (compiles but fails at runtime or submission),
**advisory** (judgment / craft). `auto` = mechanical single-answer fix; `flag` = show the ✅, dev applies.

| id | One-line tell | Sev | Fix | Reference |
|---|---|---|---|---|
| pp-01 | a camera/mic/photos/contacts/location API (`AVCaptureDevice`/`UIImagePickerController(.camera)`/`PHPhotoLibrary`/`CNContactStore`/`CLLocationManager.request*Authorization`) in use with **no** matching `Info.plist` usage string → hard crash on first use | hard-fail | flag | `usage-strings-and-manifest.md` |
| pp-02 | a Photos/Files API (`PHPickerViewController`/`PhotosPicker`/`PHPhotoLibrary`) in use — confirm the `NSPhotoLibraryUsageDescription` string (seam with document-picker-permissions) | warning | flag | `usage-strings-and-manifest.md` |
| pp-03 | a required-reason API (`UserDefaults`, `contentModificationDateKey`/`creationDateKey`, `systemUptime`, `volumeAvailableCapacity*`) in use with **no** `NSPrivacyAccessedAPITypes` entry in `PrivacyInfo.xcprivacy` → App-Store reject | warning | flag | `usage-strings-and-manifest.md` |
| pp-04 | `ATTrackingManager.requestTrackingAuthorization` in use with **no** `NSUserTrackingUsageDescription` (and `NSPrivacyTracking`/`NSPrivacyTrackingDomains` unfilled) → crash + reject | hard-fail | flag | `usage-strings-and-manifest.md` |
| pp-05 | `onOpenURL`/`onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` (universal link) with no `apple-app-site-association` / `Associated Domains` declaration | advisory | flag | `request-flows-and-deep-links.md` |
| pp-06 | `UNUserNotificationCenter.requestAuthorization`, or a StoreKit 2 `Product.purchase()` with no `Transaction.updates` listener / unfinished transaction | advisory | flag | `request-flows-and-deep-links.md` |

**pp-01 and pp-04 are the hard-fails** — a missing usage string is a guaranteed runtime crash, a missing
tracking string is a crash *and* a reject. They are still `flag-only` (the *exact* string text is a product
decision; the *key* is read/added by hand from the Xcode 26 SDK list, never invented). **The
`Info.plist`/`PrivacyInfo.xcprivacy` side is read by hand in ORIENT/READ — the grep tier only LOCATES the
`.swift`-side API uses that REQUIRE a declaration.**

## The real API, at a glance

**Real (exist on iOS — floors are verify-SDK framework introductions unless noted; never fabricate):**
`AVCaptureDevice.requestAccess(for:)` (AVFoundation), `ATTrackingManager.requestTrackingAuthorization`
(AppTrackingTransparency, iOS 14.0 — verify against Xcode 26 SDK),
`UNUserNotificationCenter.requestAuthorization` (UserNotifications),
`CLLocationManager.requestWhenInUseAuthorization`/`requestAlwaysAuthorization` (CoreLocation),
`CNContactStore.requestAccess(for:)` (Contacts), `PHPhotoLibrary.requestAuthorization`/`PhotosPicker`
(PhotoKit — `PhotosPicker` iOS 16.0, verify against Xcode 26 SDK), `Product`/`Transaction`/`.purchase()`
(StoreKit 2, iOS 15.0 — verify against Xcode 26 SDK). SwiftUI surfaces **in the catalog** (ground via
swiftui-ctx): `onOpenURL` (iOS 14.0), `onContinueUserActivity` (iOS 14.0), `privacySensitive` (iOS 15.0).

**The config side (read by hand — never Swift):** `Info.plist` usage strings
(`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`,
`NSPhotoLibraryAddUsageDescription`, `NSContactsUsageDescription`, `NSLocationWhenInUseUsageDescription`,
`NSLocationAlwaysAndWhenInUseUsageDescription`, `NSUserTrackingUsageDescription`),
`UIBackgroundModes`; `PrivacyInfo.xcprivacy` keys (`NSPrivacyAccessedAPITypes` +
`NSPrivacyAccessedAPITypeReasons`, `NSPrivacyTracking`, `NSPrivacyTrackingDomains`,
`NSPrivacyCollectedDataTypes`). **Verify every exact key against the Xcode 26 SDK — never assert from
memory.**

Floor *values* for the catalog SwiftUI symbols are the reconciled truth in
`${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md`; the canonical invented-name guard is
`${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` — read, never restate.

## The 8-step audit workflow (execute verbatim)

1. **ORIENT.** `tree` / `find` the SwiftUI sources **and the two config files this domain lives in**:
   `Info.plist` (usage strings + `UIBackgroundModes`) and `PrivacyInfo.xcprivacy` (the privacy manifest).
   **Open both now and inventory every declared key** — they are the other half of every finding and the
   shared lint runner does NOT read them. Read the **deployment target** (`project.pbxproj`
   `IPHONEOS_DEPLOYMENT_TARGET`, or `Package.swift` `platforms:`) — load-bearing for the `onOpenURL` iOS-14
   / `PhotosPicker` iOS-16 / `privacySensitive` iOS-15 floors and the App-Store privacy-manifest requirement
   (in force for all current submissions). Record the target.
2. **LOCATE.** Run the shared hybrid lint runner:
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-privacy-permissions --dir <sources> --json /tmp/pp.json --sarif /tmp/pp.sarif`.
   It runs this skill's tier-1 grep tells (`lint/grep-tells.tsv`, pp-01…pp-06), plus a per-file **parse
   probe**, and emits unified JSON + SARIF. **Read its `parse_warnings`** — a flagged file did not fully
   parse, so a miss can't masquerade as clean; READ those by hand. The runner only LOCATES — never treat a
   hit as a finding. Engine + rule-file format + degradation:
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`. **The lint scans `*.swift` only — the
   `Info.plist` usage-string check (pp-01/02/04) and the `PrivacyInfo.xcprivacy` manifest check (pp-03/04)
   are READ BY HAND from the config files inventoried in ORIENT.** A finding exists only when the `.swift`
   use is present AND the matching declaration is absent.
3. **READ.** Open every located `.swift` file **in full**, then **cross-check each against the two config
   files**. Whether a camera API genuinely fires a prompt (vs a guarded simulator stub), whether the
   matching usage string is present in `Info.plist`, whether a `UserDefaults` use already has its
   `NSPrivacyAccessedAPITypes` entry, and whether `onOpenURL` has an `apple-app-site-association` are all
   invisible to grep. Build a per-API inventory: each privacy/required-reason API + its required declaration
   key + present/absent in the config.
4. **DETECT.** Apply the index. Assign each candidate a **confidence**; report a finding **only at 100%
   certainty** — a camera API with the usage string **demonstrably absent** from `Info.plist`, a
   `UserDefaults` use with **no** `NSPrivacyAccessedAPITypes` entry. A use whose declaration **is** present
   is *not* a defect — judge it. For pp-02 set `cross_ref: audit-swiftui-document-picker-permissions`; for a
   privacy-API surfaced in a widget set `cross_ref: audit-swiftui-widgets-live-activities`; for an
   intent touching a protected resource set `cross_ref: audit-swiftui-app-intents`; for the request-flow
   timing set `cross_ref: audit-swiftui-async-data`; for `UIBackgroundModes`/scene events set
   `cross_ref: audit-swiftui-app-lifecycle-background`.
5. **VERIFY.** For anything ≤ ~70% confidence (a symbol you're unsure exists, a floor you can't place, an
   exact `Info.plist`/manifest key) run **both** evidence sources. (a) **Practice** —
   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-ctx lookup <api> --platform ios --json`: read `consensus`,
   `deprecated`+`replacement`, `recommended` permalink, `introduced_ios`, `co_occurs_with`. **Expect
   `exit 3` for `ATTrackingManager`/`UNUserNotificationCenter`/`AVCaptureDevice`/StoreKit** — they are NOT
   SwiftUI and NOT in the catalog; that exit 3 is **not** a hallucination signal here, it just means
   "verify the floor against the SDK." Only `onOpenURL`/`onContinueUserActivity`/`privacySensitive` return a
   real iOS floor; `PhotosPicker` (PhotoKit) also returns no usage — carry it verify-SDK. (b) **Spec** —
   confirm via **Sosumi**: `curl -sSL https://sosumi.ai/<apple-path>` using
   `references/source-directory.md` for the path and
   `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` for the protocol (never `WebFetch`
   `developer.apple.com`). Cross-check the catalog floors against `floors-master.md` and the Sosumi `doc:`
   floor. The CLI contract is `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md`. **Carry
   every framework-floor and every exact `Info.plist`/`.xcprivacy` key as `advisory` with
   `source: verify against Xcode 26 SDK` — never as fact, never fabricate a floor.** Promote with the
   citation or discard.
6. **REPORT.** Write each confirmed finding (output contract below). One finding per file, zero-padded,
   ordered. Write the run's `_index.md`.
7. **FIX.** Apply corrections under the fix-safety protocol
   (`${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md`): clean-tree gate, findings-first,
   one conventional commit per finding citing its `rule_id`, never weaken a check. The ✅ "Correct" pairs
   the `.swift` use with the **exact config declaration** added by hand — the usage-string *key* and the
   manifest *reason code* are read from the Xcode 26 SDK list, **never invented**; the string *text* is a
   product decision left to the dev. Every fix here is `fix_mode: flag-only` (the declaration text is a
   judgment call and the config files are edited by hand) — leave findings `open` with the ✅ in
   `## Correct` and the exact key in `## Source`.
8. **DOUBLE-CHECK.** Re-grep each fixed `.swift` file AND re-read the two config files to confirm the
   matching declaration is now present; record the evidence in `## Fix applied?`. Re-confirm every citation
   still resolves and still says the recorded floor/key. If a fix introduced a new tell (e.g. a usage string
   you added for the camera now reveals a microphone API in the same file with no `NSMicrophoneUsageDescription`),
   loop that file back to DETECT.

## Confidence gating (load-bearing)

Report a finding **only at 100% certainty**. Anything ≤ ~70% goes to VERIFY (step 5) before it can become
a finding — never emit a speculative finding. A "missing usage string" finding is 100% **only after the
`Info.plist` has been READ and the key is demonstrably absent** — never infer absence from the `.swift`
side alone. Every fix is `fix_mode: flag-only`: the declaration text is a product decision and the config
files are edited by hand; never assert an exact `NS…UsageDescription` key or a manifest reason code from
memory — carry it `verify against Xcode 26 SDK`.

## Output contract

Inherits the toolkit's unified contract (full schema + body sections + frontmatter keys:
`${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` — do not restate it). Specialized for this
domain:

- Findings: `swiftui-audits/privacy-permissions/<context>/NN-slug.md` (one finding per file, zero-padded,
  ordered). Per-run index: `swiftui-audits/privacy-permissions/_index.md`.
- `domain: privacy-permissions`. Frontmatter is the canonical schema; `fix_mode` is `flag-only` for every
  defect. `availability` reads from `floors-master.md` for the catalog SwiftUI symbols
  (`onOpenURL` 14.0, `onContinueUserActivity` 14.0, `privacySensitive` 15.0); for the UIKit/Foundation/StoreKit/PhotoKit
  framework symbols it carries the well-known introduction with `source: verify against Xcode 26 SDK`
  (never a fabricated floor). Emit `cross_ref` per the boundary note (document-picker-permissions for pp-02,
  widgets-live-activities / app-intents / async-data / app-lifecycle-background as the site demands).

**Starter `<context>` folders (file here when…):**

| `<context>` | File a finding here when… |
|---|---|
| `usage-strings/` | a camera/mic/photos/contacts/location API is used with no matching `Info.plist` usage string (pp-01, pp-02) |
| `privacy-manifest/` | a required-reason API has no `NSPrivacyAccessedAPITypes` entry, or tracking is undeclared in `PrivacyInfo.xcprivacy` (pp-03, pp-04) |
| `tracking-att/` | `ATTrackingManager.requestTrackingAuthorization` runs with no `NSUserTrackingUsageDescription` / unfilled `NSPrivacyTracking*` (pp-04) |
| `deep-links/` | `onOpenURL`/universal links have no `apple-app-site-association` / `Associated Domains` (pp-05) — `cross_ref` app-lifecycle-background |
| `notifications-storekit/` | `UNUserNotificationCenter.requestAuthorization`, or a StoreKit 2 purchase with no `Transaction.updates` listener (pp-06) |

**New-folder rule:** *if a finding does not fit any existing context folder, create a new one under
`swiftui-audits/privacy-permissions/` with a lowercase-hyphen slug naming the sub-category, and note it in
the run's `_index.md`. Prefer an existing folder when the fit is reasonable; consistency across runs is a
hard requirement.* Two runs over the same code produce structurally identical trees.

> **Go-beyond artifact (optional):** `swiftui-audits/privacy-permissions/_consent-map.md` — a table tracing
> every privacy/required-reason API use to its required declaration key and present/absent status across
> `Info.plist` + `PrivacyInfo.xcprivacy`, with a declaration-coverage score (see
> `references/usage-strings-and-manifest.md`).

## Reference routing

| File | Open when |
|---|---|
| `references/usage-strings-and-manifest.md` | the `Info.plist` usage-string ↔ API map, the required-reason-API → `NSPrivacyAccessedAPITypes` manifest map, the ATT tracking declaration, and the consent test / consent map (pp-01/02/03/04) |
| `references/request-flows-and-deep-links.md` | `onOpenURL`/universal-link `apple-app-site-association`, `UNUserNotificationCenter.requestAuthorization`, and StoreKit 2 `Product.purchase()` + `Transaction.updates` (pp-05/06) |
| `references/source-directory.md` | step VERIFY — the Apple/practitioner source map fetched via Sosumi |
| `lint/grep-tells.tsv` | step LOCATE — this skill's declarative tier-1 grep tell set fed to the shared runner (pp-01…pp-06, `*.swift`-side locators); edit here to tune detection. The config-file side is read by hand. |

**Shared toolkit references (point in, never restate):**

| Shared file | For |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` | the floor/availability values for the catalog SwiftUI surfaces (`onOpenURL` 14.0, `onContinueUserActivity` 14.0, `privacySensitive` 15.0); the UIKit/StoreKit/PhotoKit/ATT symbols are verify-SDK |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/hallucination-blacklist.md` | the canonical invented-name guard (cross-check a made-up usage-string key or manifest field) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/ios-gating.md` | the iOS-arm gating rule (`#available(iOS NN, *)` for the floored `onOpenURL`/`PhotosPicker`/`privacySensitive` surfaces) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/finding-schema.md` | the unified finding schema + frontmatter keys |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/fix-safety-protocol.md` | the 8-point fix-safety protocol (step 7) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/sosumi-reference.md` | the Apple-doc spec fetch protocol (step 5 VERIFY) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/swiftui-ctx-reference.md` | the practice-corpus CLI contract — `lookup`/`deprecated`/`file --smart` for the consensus shape (steps 5 VERIFY · 7 FIX; expect exit 3 for non-SwiftUI privacy symbols) |
| `${CLAUDE_PLUGIN_ROOT}/references/_shared/cross-ref-graph.md` | seam ownership + `cross_ref` targets (document-picker-permissions · app-intents · widgets-live-activities · async-data · app-lifecycle-background) |

## Detection accelerator

`bash ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-lint.sh --skill audit-swiftui-privacy-permissions --dir <files-or-dir>
[--json out.json] [--sarif out.sarif]` — the toolkit's **one shared hybrid lint engine**, fed this skill's
declarative rules: **tier-1 grep tells** (`lint/grep-tells.tsv`, pp-01…pp-06 flat presence of the
`.swift`-side privacy/required-reason API uses). It runs a per-file **parse probe** (surfaces "did not fully
parse" so a miss can't look clean), emits unified **JSON + SARIF**, and **degrades to grep-only with a
notice** if ast-grep is unreachable (`npx --package @ast-grep/cli ast-grep`; faster: `brew install
ast-grep`). **This domain's other half lives in `Info.plist` + `PrivacyInfo.xcprivacy`, which the runner
does NOT scan** — always READ those two config files by hand (ORIENT/READ) before any hit becomes a finding;
a `.swift` use is only a defect when its declaration is demonstrably absent. The thin
`scripts/privacy-permissions-lint.sh` is a pointer to this runner. Engine + rule-file format + JSON/SARIF
shape + safety rails: `${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md`.
