#!/usr/bin/env python3
"""Stage 2a — flatten symbol graphs into symbols_all.tsv (module,kind,parent,title,access)
for 02_build_sdk_catalog.py, and build stdlib_method_names.json (instance-method base names
from the stdlib/denylist modules in sg_std/) which 02 subtracts to kill collisions."""
import json, glob, os
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..")
def rows_for(path):
    d = json.load(open(path)); mod = d.get("module", {}).get("name", "")
    for s in d.get("symbols", []):
        kind = s.get("kind", {}).get("identifier", "")
        pc = s.get("pathComponents", []) or []
        parent = pc[-2] if len(pc) >= 2 else ""
        title = s.get("names", {}).get("title", "") or (pc[-1] if pc else "")
        access = s.get("accessLevel", "")
        if title:
            yield "\t".join([mod, kind, parent, title, access])
def main():
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, "sg", "*.symbols.json"))):
        out.extend(rows_for(f))
    open(os.path.join(ROOT, "symbols_all.tsv"), "w").write("\n".join(out) + "\n")
    print(f"symbols_all.tsv: {len(out)} rows from {len(glob.glob(os.path.join(ROOT,'sg','*.symbols.json')))} graphs")
    std = set()
    for f in glob.glob(os.path.join(ROOT, "sg_std", "*.symbols.json")):
        d = json.load(open(f))
        for s in d.get("symbols", []):
            if s.get("kind", {}).get("identifier") == "swift.method":
                t = s.get("names", {}).get("title", "").split("(")[0]
                if t.isidentifier(): std.add(t)
    json.dump(sorted(std), open(os.path.join(ROOT, "stdlib_method_names.json"), "w"))
    print(f"stdlib_method_names.json: {len(std)} method names")
if __name__ == "__main__":
    main()
