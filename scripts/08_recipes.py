#!/usr/bin/env python3
"""Stage 8 — Build catalog/recipes.json: multi-API production patterns an agent can request whole.

Two sources:
  1. Curated recipes (canonical templates) whose presence we verify against the corpus and to which
     we attach real top examples (by the score already baked into the shards).
  2. Mined "bridge" + "settings" template recipes from catalog/{bridges,settings}.json.

Each recipe: {name, kind, apis:[...], description, template (code skeleton), repos (count), examples:[ex ids]}.
"""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..")
CAT = os.path.join(ROOT, "catalog")

def load(name):
    try: return json.load(open(os.path.join(CAT, name)))
    except Exception: return {}

# Curated recipes: api list + a canonical skeleton. We resolve real examples from the shards.
CURATED = [
 # ── iOS-specific patterns ────────────────────────────────────────────────────
 {"name":"tab-bar-app","apis":["TabView","tabItem"],"dim":"types","anchor":"TabView",
  "description":"A tab-bar iOS app: TabView with .tabItem labels for each root screen.",
  "template":'@main struct MyApp: App {\n  var body: some Scene {\n    WindowGroup { MainTabs() }\n  }\n}\n\nstruct MainTabs: View {\n  var body: some View {\n    TabView {\n      HomeView().tabItem { Label("Home", systemImage: "house") }\n      SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }\n      ProfileView().tabItem { Label("Profile", systemImage: "person") }\n    }\n  }\n}'},
 {"name":"navigationstack-master-detail","apis":["NavigationStack","navigationDestination"],"dim":"types","anchor":"NavigationStack",
  "description":"iOS master-detail: NavigationStack with .navigationDestination for type-safe push navigation.",
  "template":'NavigationStack(path: $path) {\n  List(items) { item in\n    NavigationLink(item.name, value: item)\n  }\n  .navigationDestination(for: Item.self) { item in\n    DetailView(item: item)\n  }\n  .navigationTitle("Items")\n}'},
 {"name":"sheet-detents","apis":["sheet","presentationDetents"],"dim":"modifiers","anchor":"presentationDetents",
  "description":"A bottom sheet with height detents (.medium, .large, or custom fraction/height).",
  "template":'.sheet(isPresented: $showSheet) {\n  SheetContent()\n    .presentationDetents([.medium, .large])\n    .presentationDragIndicator(.visible)\n}'},
 {"name":"fullscreen-cover-flow","apis":["fullScreenCover"],"dim":"modifiers","anchor":"fullScreenCover",
  "description":"Full-screen modal cover (no drag-to-dismiss; typical for onboarding or immersive flows).",
  "template":'.fullScreenCover(isPresented: $showOnboarding) {\n  OnboardingView(isPresented: $showOnboarding)\n}'},
 {"name":"widget-scaffold","apis":["Widget","WidgetBundle"],"dim":"types","anchor":"Widget",
  "description":"WidgetKit home-screen widget: a Widget conformance with a Timeline provider and entry view.",
  "template":'struct MyWidget: Widget {\n  var body: some WidgetConfiguration {\n    StaticConfiguration(kind: "com.example.widget", provider: Provider()) { entry in\n      MyWidgetEntryView(entry: entry)\n    }\n    .configurationDisplayName("My Widget")\n    .description("Shows current status.")\n  }\n}'},
 {"name":"app-intent","apis":["AppIntent","AppShortcutsProvider"],"dim":"types","anchor":"AppIntent",
  "description":"App Intent exposed to Siri / Shortcuts: an AppIntent struct with @Parameter inputs and an AppShortcutsProvider.",
  "template":'struct OpenItemIntent: AppIntent {\n  static var title: LocalizedStringResource = "Open Item"\n  @Parameter(title: "Item") var item: ItemEntity\n  func perform() async throws -> some IntentResult {\n    // navigate to item\n    return .result()\n  }\n}\n\nstruct MyShortcuts: AppShortcutsProvider {\n  static var appShortcuts: [AppShortcut] {\n    AppShortcut(intent: OpenItemIntent(), phrases: ["Open \\(\\.$item) in MyApp"])\n  }\n}'},
 # ── Platform-neutral patterns ─────────────────────────────────────────────────
 {"name":"searchable-list","apis":["searchable","searchScopes"],"dim":"modifiers","anchor":"searchable",
  "description":"A list with a search field (and optional scopes).",
  "template":'List(results) { Text($0.title) }\n  .searchable(text: $query)\n  // bind @State private var query = ""'},
 {"name":"settings-form","apis":["Form","Section","Toggle","Picker","LabeledContent"],"dim":"types","anchor":"Form",
  "description":"A grouped settings/preferences Form (Toggle/Picker/LabeledContent).",
  "template":'Form {\n  Section("General") {\n    Toggle("Enable", isOn: $on)\n    Picker("Theme", selection: $theme) { /* … */ }\n    LabeledContent("Version", value: appVersion)\n  }\n}'},
 {"name":"observable-model","apis":["Observable","State","Bindable"],"dim":"propertyWrappers","anchor":"Observable",
  "description":"Modern Observation state: an @Observable model owned by a view.",
  "template":'@Observable final class Model { var count = 0 }\n\nstruct V: View {\n  @State private var model = Model()\n  var body: some View { Stepper("\\(model.count)", value: $model.count) }\n}'},
 {"name":"charts-bar","apis":["Chart","BarMark","chartXAxis"],"dim":"types","anchor":"BarMark",
  "description":"A Swift Charts bar chart with axis configuration.",
  "template":'Chart(data) { row in\n  BarMark(x: .value("Day", row.day), y: .value("Total", row.total))\n}\n.chartXAxis { AxisMarks() }'},
 {"name":"draggable-reorder","apis":["onMove","draggable","dropDestination","Transferable"],"dim":"modifiers","anchor":"onMove",
  "description":"Reorderable list rows. Classic: List + .onMove. Custom: .draggable/.dropDestination with a Transferable type.",
  "template":'List {\n  ForEach(items) { Text($0.name) }\n    .onMove { from, to in items.move(fromOffsets: from, toOffset: to) }\n}'},
 {"name":"cached-async-image","apis":["AsyncImage"],"dim":"types","anchor":"AsyncImage",
  "description":"Remote image with placeholder. AsyncImage is built-in (no cache); for lists/grids real apps add a cache (custom @Observable loader or a library).",
  "template":'AsyncImage(url: url) { phase in\n  switch phase {\n  case .success(let img): img.resizable().scaledToFit()\n  case .failure: Image(systemName: "photo")\n  case .empty: ProgressView()\n  @unknown default: EmptyView()\n  }\n}'},
]

def examples_for(dim, anchor, apis, k=5):
    """Examples of `anchor`, filtered to ones whose snippet actually uses one of the recipe's APIs
    (so a charts-bar recipe never surfaces a pie-chart example)."""
    shard = load(f"{dim}.json")
    rec = shard.get(anchor)
    if not rec: return [], 0
    want = [a for a in apis if a != anchor]   # the distinguishing APIs beyond the anchor itself
    picked = []
    for e in rec.get("examples", []):
        src = e.get("src", "")
        if want and not any(a in src for a in want + [anchor]): continue
        picked.append({"id": e.get("id"), "repo": e["repo"], "permalink": e["permalink"],
                       "src": e["src"], "provenance": e.get("provenance", {})})
        if len(picked) >= k: break
    if not picked:   # fall back to unfiltered if the filter is too strict
        picked = [{"id": e.get("id"), "repo": e["repo"], "permalink": e["permalink"],
                   "src": e["src"], "provenance": e.get("provenance", {})}
                  for e in rec.get("examples", [])[:k]]
    return picked, rec.get("repo_count", 0)

def main():
    recipes = []
    for r in CURATED:
        exs, n = examples_for(r["dim"], r["anchor"], r["apis"])
        recipes.append({"name":r["name"], "kind":"pattern", "apis":r["apis"],
                        "description":r["description"], "template":r["template"],
                        "repos":n, "examples":exs})
    # UIKit bridge recipe (UIViewRepresentable / UIViewControllerRepresentable) — point at real UIKit bridges
    bridges = load("bridges.json")
    if bridges:
        uikit_bridges = [b for b in bridges.get("bridges", []) if b.get("platform") == "uikit"]
        uikit_repos = len({b["repo"] for b in uikit_bridges})
        recipes.append({"name":"uiview-bridge","kind":"bridge","apis":["UIViewRepresentable","UIViewControllerRepresentable"],
            "description":f"Wrap a UIKit UIView or UIViewController in SwiftUI ({len(uikit_bridges)} real bridges across {uikit_repos} repos).",
            "template":'struct MyUIKitView: UIViewRepresentable {\n  func makeUIView(context: Context) -> UIScrollView { UIScrollView() }\n  func updateUIView(_ uiView: UIScrollView, context: Context) { }\n}',
            "repos":uikit_repos,
            "examples":[{"repo":b["repo"],"permalink":b["permalink"],"name":b["name"]}
                        for b in uikit_bridges[:8]]})
    out = {"count":len(recipes), "recipes":recipes}
    json.dump(out, open(os.path.join(CAT,"recipes.json"),"w"), indent=1)
    print(f"wrote catalog/recipes.json: {len(recipes)} recipes")
    for r in recipes: print(f"  {r['name']:18} apis={r['apis']} examples={len(r['examples'])} repos={r['repos']}")

if __name__ == "__main__":
    main()
