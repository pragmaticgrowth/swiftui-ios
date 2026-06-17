# Playbook — worked transcripts per scenario

Each block is the exact command sequence an agent should run. `$BIN` = `swiftui-ctx`. Always finish a
write task with `file --smart` on the `recommended` example before emitting code.

## Writing a known call (e.g. a search field)
```
$BIN lookup searchable --platform ios   # consensus shapes + recommended example + co_occurs_with
$BIN file <recommended.id> --smart       # the real enclosing view, compilable
```
Read `consensus` to pick the shape (`(text)` 28% vs `(text, prompt)` 24% vs `(text, placement, prompt)` 24%), then write it the dominant way.

## Choosing an overload / argument shape
```
$BIN lookup frame --platform ios        # consensus: (width, height) 31% · (height) 19% · (maxWidth) 13% · (maxWidth, alignment) 12% …
$BIN examples frame --shape "(maxWidth, alignment)"   # real call sites of that exact shape
```
Note: `examples` shows a curated ≤25/API sample; the consensus % is over *all* uses (the tool says so in its output).

## Is an API current or deprecated?
```
$BIN deprecated foregroundColor         # ⚠️ DEPRECATED → use .foregroundStyle  (+ next_action)
$BIN lookup foregroundStyle             # real usage of the modern replacement
```
`$BIN deprecated` (no arg) lists every deprecated API still in production use, with its replacement — the audit entry point.

**Floor gaps:** replacements can have a higher iOS floor than the deprecated API — always check `min_ios`/`introduced_ios` in the `lookup` result before swapping. Example: `tabItem(_:)` is iOS 13.0+ Deprecated, but its replacement `Tab` is iOS 18.0+. Using `Tab` on an iOS 17 deployment target is a compile error; use `#available(iOS 18, *)` or keep `tabItem` if you must support iOS 17.

## Building a known pattern (recipes)
```
$BIN recipes                            # list patterns
$BIN recipe tab-bar-app                 # template skeleton + real examples (each with a file/permalink next_action)
$BIN file <example> --smart
```
Recipes: `tab-bar-app · navigationstack-master-detail · sheet-detents · fullscreen-cover-flow · widget-scaffold ·
app-intent · searchable-list · settings-form · observable-model · charts-bar · draggable-reorder ·
cached-async-image · uiview-bridge`.

## Planning a feature from intent (you don't know the API names)
```
$BIN search "bottom sheet"              # intent → APIs (sheet/presentationDetents) + recipe
$BIN lookup presentationDetents --platform ios   # drill into each candidate
```
`search` understands design vocabulary ("tab bar", "master detail", "bottom sheet", "reorder", "async image", "settings", "widget").

## Reviewing / auditing existing SwiftUI
```
$BIN deprecated                         # what's deprecated in the wild → flag any the code uses
$BIN lookup <api-in-the-code>           # compare the code's call to `consensus`; cite the permalink
$BIN repo <owner/name>                  # if the code is from a corpus repo: its fingerprint + modernity
```

## Debugging a SwiftUI symptom
```
# "@State isn't updating the view"
$BIN lookup State                       # confirm the wrapper + see co_occurs_with
$BIN recipe observable-model            # the correct ownership pattern (@Observable + @State var model)
$BIN file <example> --smart             # a working reference to diff your code against
```

## UIView/UIViewController bridging (where LLMs fail most)
```
$BIN recipe uiview-bridge               # template + real bridges (use the file <permalink> next_action)
$BIN file <permalink> --full            # bridges are best read whole: Coordinator + makeUIView + updateUIView
```

## Reading the `file` modes
- `--smart` (default): tightest useful, anchor-guaranteed span (enclosing `var body`/func if it fits, else the statement, else an anchored window). Start here.
- `--full`: the whole file — for App/Scene-level patterns (App struct) and UIView/UIViewController bridges.
- `--chain`: just the modifier chain — for a dense `.a().b().c()` call.
- `--decl`: the full enclosing declaration even if large.
