// DesignA11yAuditTemplate.swift — drop this into your app's **UI test target** to get Apple's
// first-party, deterministic accessibility audit (Xcode 15+). It is the objective backbone of the
// design layer's deterministic tier: contrast, Dynamic Type, hit-region (sub-44pt), clipped text,
// and element-description checks — each reported by XCTest with the offending element's screenshot.
//
// Wiring (once):
//   1. Add this file to your UI test target (e.g. <App>UITests).
//   2. Ensure the target's scheme is testable on a simulator destination.
//   3. Run:  bash scripts/a11y-audit/run.sh <project-dir>
//
// It launches the app and audits the first screen. Extend `auditedScreens` / add navigation taps to
// cover more screens (mirror your swiftui-design/screens.manifest.json).

import XCTest

final class DesignA11yAuditTests: XCTestCase {

    func testFirstScreenAccessibilityAudit() throws {
        let app = XCUIApplication()
        // Match the capture harness environment if your app honors a UITEST flag:
        // app.launchEnvironment["UITEST_MODE"] = "1"
        app.launch()

        // Apple's audit types most relevant to a *visual design* review. `performAccessibilityAudit`
        // throws/records an issue per violation, each with an element screenshot attachment.
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit(for: [
                .contrast,                      // text/background contrast below threshold
                .dynamicType,                   // text that won't scale with Dynamic Type
                .hitRegion,                     // tappable area smaller than 44x44 pt
                .textClipped,                   // truncated/clipped text
                .sufficientElementDescription,  // controls/images missing a usable label
            ])
        } else {
            try app.performAccessibilityAudit()
        }
    }
}
