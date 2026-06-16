#!/usr/bin/env python3
"""Stage 0 — Harvest GitHub owner/repo candidates from iOS app seed READMEs,
attaching the markdown section heading(s) each link appeared under as `categories`.
Primary seed: dkhamsing/open-source-ios-apps
Secondary seed: vsouza/awesome-ios (library-heavy; tagged accordingly)
Output: data/00_candidates.json
"""
import re, json, os, sys, urllib.request, pathlib

RAW = "https://raw.githubusercontent.com/dkhamsing/open-source-ios-apps/master/README.md"
SECONDARY = "https://raw.githubusercontent.com/vsouza/awesome-ios/master/README.md"
LOCAL = "/tmp/open-source-ios-apps.md"
OUT = "data/00_candidates.json"

RESERVED = {"sponsors","topics","about","features","marketplace","settings","apps",
            "orgs","users","collections","login","notifications","explore","pulls",
            "issues","new","search","trending","stars","watching"}
SELF = ("dkhamsing","open-source-ios-apps")

LINK = re.compile(r'https?://github\.com/([A-Za-z0-9][\w.-]*)/([A-Za-z0-9][\w.-]*)', re.I)
HEAD = re.compile(r'^(#{1,4})\s+(.*?)\s*#*\s*$')

def clean_repo(repo: str) -> str:
    # strip sub-paths, anchors, queries, trailing punctuation and .git
    repo = repo.split('#')[0].split('?')[0]
    repo = re.sub(r'\.git$', '', repo)
    repo = repo.rstrip(').,;:*"\'`')
    return repo

def fetch_md(url: str, local_cache: str):
    """Fetch markdown from URL (with local cache). Returns None on failure."""
    if os.path.exists(local_cache):
        return pathlib.Path(local_cache).read_text(errors="ignore")
    try:
        data = urllib.request.urlopen(url, timeout=30).read().decode("utf-8", "ignore")
        pathlib.Path(local_cache).write_text(data)
        return data
    except Exception as exc:
        print(f"WARNING: failed to fetch {url}: {exc}", file=sys.stderr)
        return None

def parse_md(md: str, self_skip, source_tag: str) -> dict:
    """Parse a README and return {(owner_lc, repo_lc): entry_dict}."""
    cands = {}
    heading_stack = {}
    for line in md.splitlines():
        hm = HEAD.match(line)
        if hm:
            lvl = len(hm.group(1)); txt = hm.group(2).strip()
            heading_stack[lvl] = txt
            for d in list(heading_stack):
                if d > lvl: del heading_stack[d]
            continue
        for m in LINK.finditer(line):
            owner = m.group(1); repo = clean_repo(m.group(2))
            if not owner or not repo: continue
            if repo.lower() in RESERVED: continue
            if (owner.lower(), repo.lower()) == (self_skip[0].lower(), self_skip[1].lower()): continue
            cats = [heading_stack[d] for d in sorted(heading_stack) if d >= 2]
            cat = cats[-1] if cats else (heading_stack.get(1, "Uncategorized"))
            key = (owner.lower(), repo.lower())
            e = cands.setdefault(key, {"owner": owner, "repo": repo,
                                       "url": f"https://github.com/{owner}/{repo}",
                                       "categories": set(),
                                       "source": source_tag})
            e["categories"].add(cat)
    return cands

def main():
    # Fetch primary seed
    md_primary = fetch_md(RAW, LOCAL)
    # Fetch secondary seed (vsouza/awesome-ios)
    md_secondary = fetch_md(SECONDARY, "/tmp/awesome-ios.md")

    if md_primary is None and md_secondary is None:
        print("ERROR: both fetches failed — no candidates produced.", file=sys.stderr)
        sys.exit(1)

    cands = {}

    if md_primary:
        primary_cands = parse_md(md_primary, SELF, "open-source-ios-apps")
        cands.update(primary_cands)
        print(f"primary (open-source-ios-apps): {len(primary_cands)} candidates")

    if md_secondary:
        secondary_cands = parse_md(md_secondary, ("vsouza", "awesome-ios"), "awesome-ios")
        merged = 0; added = 0
        for key, entry in secondary_cands.items():
            if key in cands:
                # merge categories into existing primary entry; keep primary source tag
                cands[key]["categories"].update(entry["categories"])
                merged += 1
            else:
                cands[key] = entry
                added += 1
        print(f"secondary (awesome-ios): {len(secondary_cands)} candidates "
              f"({added} new, {merged} merged into primary)")

    out = []
    for e in cands.values():
        e["categories"] = sorted(e["categories"])
        out.append(e)
    out.sort(key=lambda x: (x["owner"].lower(), x["repo"].lower()))

    os.makedirs("data", exist_ok=True)
    json.dump(out, open(OUT, "w"), indent=2)
    print(f"harvested {len(out)} unique owner/repo candidates -> {OUT}")

    from collections import Counter
    c = Counter(cat for e in out for cat in e["categories"])
    print("top categories:", c.most_common(8))

    src_counts = Counter(e["source"] for e in out)
    print("source breakdown:", dict(src_counts))

if __name__ == "__main__":
    main()
