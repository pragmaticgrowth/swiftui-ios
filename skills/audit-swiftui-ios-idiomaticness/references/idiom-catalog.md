# Reference — iOS idiom catalog + the 0–100 idiom-score rubric (idi-01 … idi-09)

The per-smell depth for `audit-swiftui-ios-idiomaticness` — the "iPad-app-in-a-phone" / "Mac-habit on
iOS" tell, **why an iOS-trained model still emits it**, the absence-or-misuse detection method, the
**category** each smell scores into, and the **owner skill** the fix is routed to. This skill is the
META-SCORER: it owns **no** ❌→✅ fix — the owner skill holds the floor, the consensus shape, and the
auto-fix. Every finding here carries a `cross_ref` to that owner and stays `status: open`,
`fix_mode: flag-only`.

**As of:** 2026-06-16 · iOS 17 deployment floor · iPad modeled within `ios` · Xcode 26 SDK.
Floor values are the reconciled truth in `${CLAUDE_PLUGIN_ROOT}/references/_shared/floors-master.md` —
read, never restated here.

---

## The one rule

**A smell is the *absence* of an iOS-idiomatic affordance or the *presence* of a Mac/iPad-pointer /
deprecated-UIKit habit — never decided by grep alone.** Most tells locate a candidate SITE; the
*absence judgment* ("this `.sheet` has **no** `presentationDetents`", "this `Table` has **no**
size-class fallback", "this `.onHover` is the **only** interaction") is the auditor's after READ. Never
score a smell you have not confirmed by reading the view in full and grounding the floor in
`swiftui-ctx` (`lookup <api> --platform ios --json` → `result.introduced_ios`).

---

## The five idiom categories (the score breakdown)

The 0–100 idiom score is the weighted complement of confirmed smells per category. Each `idi-NN` scores
into exactly one category; the dashboard `_index.md` (`kind: nativeness-dashboard`) shows the total +
the per-category sub-score + the routed punch-list.

| Category | What it measures | Smells | Weight |
|---|---|---|---|
| **navigation-idiom** | `NavigationStack`/`NavigationSplitView`/`TabView` fit; no deprecated `NavigationView` shell | idi-01, idi-05, idi-08 | 25 |
| **modality** | `.sheet` + `presentationDetents` vs over-reaching `.fullScreenCover`; modal fit | idi-04 | 20 |
| **touch-vs-pointer** | touch-first interaction; `.onHover`/`pointerStyle` not the sole affordance on an iPhone surface | idi-02 | 20 |
| **adaptive-coverage** | size-class / `ViewThatFits` / `containerRelativeFrame` over hard-coded device frames | idi-03, idi-07 | 25 |
| **platform-surface** | SwiftUI geometry/scene sources over deprecated UIKit global reach | idi-06, idi-09 | 10 |

The exact weights, the per-smell point deductions, and the dashboard layout are applied at SCORE+REPORT
(step 6). A category with zero confirmed smells contributes its full weight; the total is the sum of
category sub-scores, so the dashboard total always equals the sum of its parts (DOUBLE-CHECK, step 8).

---

## Smell catalog (each routes — never fix here)

### idi-01 — `NavigationView` as the navigation root (navigation-idiom · warn)
**Tell.** A `NavigationView { … }` shell. **Why AI emits it.** The training corpus is pre-iOS-16, where
`NavigationView` was the only push container. **Detect.** Confirm it is the shell, not a stray reference.
**Route.** `cross_ref: adaptive-navigation` (the structural migration to `NavigationStack` /
`NavigationSplitView`) + note `api-currency` owns the deprecation flag.

### idi-02 — pointer affordance as the sole interaction (touch-vs-pointer · advisory)
**Tell.** `.onHover` / `pointerStyle` / `onContinuousHover` with **no** touch path. **Why AI emits it.**
Mac/iPad-pointer code leaks into an iPhone target that has no hover hardware. **Detect.** READ the view:
is there a `Button`/`TapGesture`/`onTapGesture` too, or is hover load-bearing? A hover *enhancement* atop
a real touch path is fine (iPad pointer polish); hover-only is the smell. **Route.**
`cross_ref: touch-gestures`.

### idi-03 — hard-coded full-screen device frame (adaptive-coverage · warn)
**Tell.** `.frame(width: 3xx …)` / `.frame(width:height:)` with a literal device size. **Why AI emits
it.** It memorised an iPhone point size instead of an adaptive container. **Detect.** Is the view meant
to fill the screen / adapt across iPhone↔iPad↔split? **Route.** `cross_ref: adaptive-layout`
(`GeometryReader` / `containerRelativeFrame` / size-class).

### idi-04 — modal-modality misfit (modality · advisory)
**Tell.** `.fullScreenCover` where a resizable `.sheet` fits, **or** a `.sheet` with **no**
`presentationDetents`. **Why AI emits it.** Pre-iOS-16 sheets were full-height only. **Detect.** Is the
cover immersive/onboarding (justified) or just a detail (should be a sheet with detents)? **Route.**
`cross_ref: presentation-sheets-modals`.

### idi-05 — `TabView` idiom fit (navigation-idiom · advisory)
**Tell.** A `TabView` whose tabs are **not** top-level peers, or **>5** tabs (collapse to More on
iPhone). **Detect.** Are these genuine top-level sections, or a push hierarchy faked as tabs? **Route.**
`cross_ref: adaptive-navigation`.

### idi-06 — `UIScreen.main` device metrics (platform-surface · advisory)
**Tell.** `UIScreen.main` / `UIScreen.main.bounds`. **Why AI emits it.** A UIKit habit for sizing.
**Detect.** `UIScreen.main` is **deprecated (iOS 16+, multi-window unsafe)** — a SwiftUI geometry source
(`GeometryReader`, size-class, `containerRelativeFrame`) is the idiom. **Route.**
`cross_ref: uikit-overuse` (the WHETHER) + `adaptive-layout` (the SwiftUI sizing source).

### idi-07 — `Table` with no compact fallback (adaptive-coverage · advisory)
**Tell.** A `Table` (multi-column grid). **Why it's a smell on iOS.** `Table` collapses to a single
column on iPhone (compact width) — a multi-column data grid with no `horizontalSizeClass` branch to a
`List` reads as iPad-only. **Detect.** Is there a `List` fallback for compact width? **Route.**
`cross_ref: layout-and-tables` (Table-vs-List) + `adaptive-layout` (size-class branch).

### idi-08 — `navigationBarTitle` deprecated (navigation-idiom · advisory)
**Tell.** `.navigationBarTitle(…)`. **Why AI emits it.** Pre-iOS-14 title API. **Detect.** The idiom is
`.navigationTitle(_:)` + `.navigationBarTitleDisplayMode(_:)`. **Route.** `cross_ref:
adaptive-navigation` + note `api-currency` owns the flag.

### idi-09 — global window reach (platform-surface · advisory)
**Tell.** `UIApplication.shared.windows` / `keyWindow`. **Why AI emits it.** A UIKit habit to find the
key window. **Detect.** Both are **deprecated (iOS 15+, multi-scene unsafe)** — a SwiftUI scene /
environment source is the idiom. **Route.** `cross_ref: uikit-overuse`.

---

## Worked ✅ — the navigation-root idiom (idi-01), grounded in the corpus

This skill never writes the fix; the `## Correct` of an idi-01 finding shows the **owner's route + the
`swiftui-ctx` consensus shape**, never a hand-written snippet. Verified live (iOS catalog):

```
swiftui-ctx lookup NavigationStack --platform ios --json
  → result.introduced_ios = 16.0
  → result.consensus = [{ pct: 91, shape: "{ }" }, { pct: 9, shape: "(path)" }]
swiftui-ctx deprecated NavigationView --json
  → { deprecated: true, migrate_to: "NavigationStack", replacement: "NavigationStack",
      note: "use NavigationStack for single-column, NavigationSplitView for sidebar+detail" }
```

```swift
// ❌ idi-01 — the deprecated push shell an iOS-trained model emits:
NavigationView {
    List(items) { item in NavigationLink(item.name) { Detail(item) } }
}

// ✅ The iOS-idiomatic root — NavigationStack (91%-consensus { } shape, iOS 16.0+).
// The FIX is owned by adaptive-navigation; this skill only flags + routes.
NavigationStack {
    List(items) { item in NavigationLink(item.name, value: item) }
        .navigationDestination(for: Item.self) { Detail($0) }
}
```

- **Real iOS site (re-fetch the live recommended permalink in VERIFY, never trust a static link):**
  `swiftui-ctx lookup NavigationStack --platform ios --json` → `result.recommended.permalink`
  (example class: github.com/…/*.swift — an iOS-16 app whose root is a `NavigationStack`). One verified
  real permalink at the time of writing:
  https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/CaseStudies/SwiftUICaseStudies/01-GettingStarted-Navigation.swift
- **Spec (Sosumi):** doc: https://sosumi.ai/documentation/swiftui/navigationstack — `NavigationStack`,
  iOS 16.0+. (`navigationView` page documents the deprecation.)
- **Route:** the *fix* (migrating the shell) belongs to `audit-swiftui-adaptive-navigation`; this skill
  flags the absence of the idiom and hands off. Re-derive the shape live per API in VERIFY — never trust
  this snippet as a static signature.
