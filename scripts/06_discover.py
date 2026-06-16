#!/usr/bin/env python3
"""Stage 6 — Discover NEW iOS SwiftUI apps via GitHub code search.

Pass 1 (positive terms): runs iOS-leaning SwiftUI symbols (APIs that are iOS-first or
iOS-exclusive, so a Swift file containing them is almost certainly an iOS SwiftUI app) through
`gh search code`, aggregates the unique owner/repo across terms, records term provenance, and
dedupes against the known corpus.

Pass 2 (inverted / broadening): queries broad SwiftUI app-structure markers (WindowGroup, TabView,
NavigationStack) and post-filters OUT any repo whose returned match-file snippets contain a macOS
signal token (MenuBarExtra, NSApplicationDelegateAdaptor, etc.), catching iOS apps that don't use
the niche iOS-only tokens above. Results are merged into the same output.

Writes data/06_discovered.jsonl — one JSON object per discovered repo:
  {full_name, owner, repo, found_by:[terms], match_files, in_awesome_mac, in_corpus_207, discovered_via}

Reusable downstream: feed the NEW repos into scripts/01_gate.py-style gating + scanning.

Rate-limit aware: GitHub code search = 10 req/min; we throttle between terms and back off on 403.
Resumable: re-running merges with any existing data/06_discovered.jsonl.
"""
import json, os, subprocess, time, sys, argparse

HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..")
OUT  = os.path.join(ROOT, "data", "06_discovered.jsonl")
CAND = os.path.join(ROOT, "data", "00_candidates.json")
INCL = os.path.join(ROOT, "data", "01_included.json")

# iOS-leaning SwiftUI discriminators — APIs that are iOS-first or iOS-exclusive.
# Generic words are intentionally omitted: too noisy as bare tokens.
TERMS = [
    # Tier A — iOS-distinctive SwiftUI/iOS APIs
    "UIViewControllerRepresentable", "UIViewRepresentable", "UIApplicationDelegateAdaptor",
    "presentationDetents", "fullScreenCover", "navigationBarTitleDisplayMode",
    # Tier B — iOS extension/intent surface (no macOS analogue)
    "ControlWidget", "ControlWidgetButton", "ActivityAttributes", "ActivityConfiguration",
    "AppShortcutsProvider", "DynamicIsland",
    # Tier C — iOS interaction idioms
    "sensoryFeedback", "swipeActions", "tabViewStyle", "UIHostingController",
]

# Inverted broadening pass: broad SwiftUI app-structure markers that catch iOS apps which don't
# happen to use any niche iOS-only token above.
INVERTED = [
    '"import SwiftUI" "@main" "WindowGroup"',
    '"import SwiftUI" TabView NavigationStack',
]

# macOS-signal tokens used as a post-filter on inverted-pass snippet text: any repo whose
# returned match-file content contains one of these is almost certainly macOS-only and is dropped.
MACOS_EXCLUDE = {
    "MenuBarExtra", "NSApplicationDelegateAdaptor",
    "windowResizability", "NSHostingController",
}

def known_sets():
    import glob
    awesome, corpus, scanned = set(), set(), set()
    if os.path.exists(CAND):
        for c in json.load(open(CAND)): awesome.add(f"{c['owner']}/{c['repo']}".lower())
    if os.path.exists(INCL):
        for c in json.load(open(INCL)): corpus.add(c.get("full_name","").lower())
    # everything already scanned into repos/ (awesome-mac + any prior discovery wave)
    for f in glob.glob(os.path.join(ROOT,"repos","*.jsonl")):
        try:
            h = json.loads(open(f).readline())
            if h.get("full_name"): scanned.add(h["full_name"].lower())
        except Exception: pass
    return awesome, corpus, scanned

def search(term, limit):
    """Return list of nameWithOwner for a term, retrying on secondary-rate-limit."""
    for attempt in range(4):
        r = subprocess.run(
            ["gh","search","code", term, "--language","swift","--limit",str(limit),
             "--json","repository","--jq",".[].repository.nameWithOwner"],
            capture_output=True, text=True)
        if r.returncode == 0:
            return [x.strip() for x in r.stdout.splitlines() if x.strip()]
        if "rate limit" in (r.stderr or "").lower() or "403" in (r.stderr or ""):
            wait = 20*(attempt+1); print(f"    rate-limited on '{term}', sleeping {wait}s", flush=True)
            time.sleep(wait); continue
        print(f"    error on '{term}': {r.stderr.strip()[:160]}", flush=True)
        return []
    return []

def search_with_text(term, limit):
    """Return list of (nameWithOwner, text_snippet) for a term (used by inverted pass).

    Fetches repository.nameWithOwner and textMatches[].fragment so we can post-filter
    on MACOS_EXCLUDE tokens present in the actual file content returned by GitHub.
    """
    for attempt in range(4):
        r = subprocess.run(
            ["gh","search","code", term, "--language","swift","--limit",str(limit),
             "--json","repository,textMatches",
             "--jq",'.[] | [.repository.nameWithOwner, ([.textMatches[]?.fragment] | join(" "))] | @tsv'],
            capture_output=True, text=True)
        if r.returncode == 0:
            results = []
            for line in r.stdout.splitlines():
                line = line.strip()
                if not line: continue
                parts = line.split("\t", 1)
                nwo = parts[0]; snippet = parts[1] if len(parts) > 1 else ""
                results.append((nwo, snippet))
            return results
        if "rate limit" in (r.stderr or "").lower() or "403" in (r.stderr or ""):
            wait = 20*(attempt+1); print(f"    rate-limited on '{term}', sleeping {wait}s", flush=True)
            time.sleep(wait); continue
        print(f"    error on '{term}': {r.stderr.strip()[:160]}", flush=True)
        return []
    return []

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100, help="results per term")
    ap.add_argument("--sleep", type=float, default=7.0, help="seconds between terms (10/min cap)")
    ap.add_argument("--terms", default="", help="comma-separated subset (pilot)")
    ap.add_argument("--out", default=OUT, help="output JSONL path")
    args = ap.parse_args()
    terms = [t.strip() for t in args.terms.split(",") if t.strip()] or TERMS

    awesome, corpus, scanned = known_sets()
    found = {}   # full_name -> {found_by:set, match_files:int}
    for i, term in enumerate(terms, 1):
        hits = search(term, args.limit)
        repos = {}
        for nwo in hits:
            repos[nwo] = repos.get(nwo, 0) + 1
        for nwo, n in repos.items():
            e = found.setdefault(nwo, {"found_by": set(), "match_files": 0})
            e["found_by"].add(term); e["match_files"] += n
        print(f"  [{i}/{len(terms)}] {term:30} hits={len(hits):>3} unique_repos={len(repos)} total_found={len(found)}", flush=True)
        if i < len(terms): time.sleep(args.sleep)

    # Inverted broadening pass — broad SwiftUI app-structure markers, macOS repos excluded.
    # Uses the same aggregation/dedup helpers as the positive-term pass above.
    print("\n--- inverted broadening pass (SwiftUI minus macOS) ---", flush=True)
    for i, inv_term in enumerate(INVERTED, 1):
        time.sleep(args.sleep)   # respect rate-limit between passes
        hits_with_text = search_with_text(inv_term, args.limit)
        repos_inv = {}
        skipped = 0
        for nwo, snippet in hits_with_text:
            # Post-filter: drop any repo whose snippet contains a macOS-exclusive token.
            if any(tok in snippet for tok in MACOS_EXCLUDE):
                skipped += 1
                continue
            repos_inv[nwo] = repos_inv.get(nwo, 0) + 1
        for nwo, n in repos_inv.items():
            e = found.setdefault(nwo, {"found_by": set(), "match_files": 0})
            e["found_by"].add(f"inverted:{inv_term}"); e["match_files"] += n
        print(
            f"  [inv {i}/{len(INVERTED)}] hits={len(hits_with_text):>3}"
            f" macos_skipped={skipped} accepted={len(repos_inv)} total_found={len(found)}",
            flush=True,
        )

    os.makedirs(os.path.join(ROOT,"data"), exist_ok=True)
    rows = []
    for nwo, e in sorted(found.items()):
        if "/" not in nwo: continue
        owner, repo = nwo.split("/", 1)
        low = nwo.lower()
        found_by_sorted = sorted(e["found_by"])
        has_inverted = any(t.startswith("inverted:") for t in found_by_sorted)
        has_positive = any(not t.startswith("inverted:") for t in found_by_sorted)
        if has_positive and has_inverted:
            via = "github-code-search+inverted"
        elif has_inverted:
            via = "github-code-search-inverted"
        else:
            via = "github-code-search"
        rows.append({"full_name": nwo, "owner": owner, "repo": repo,
                     "found_by": found_by_sorted, "match_files": e["match_files"],
                     "in_awesome_mac": low in awesome, "in_corpus_207": low in corpus,
                     "already_scanned": low in scanned, "is_new": low not in scanned,
                     "discovered_via": via})
    with open(args.out, "w") as f:
        for r in rows: f.write(json.dumps(r) + "\n")
    new = [r for r in rows if r["is_new"]]
    print(f"\nwrote {args.out}: {len(rows)} repos discovered")
    print(f"  already scanned (in current corpus): {len(rows)-len(new)}")
    print(f"  NEW (not yet in corpus):             {len(new)}")
    print("  sample new:", [r["full_name"] for r in new[:10]])

if __name__ == "__main__":
    main()
