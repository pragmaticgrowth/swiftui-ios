#!/usr/bin/env python3
"""Generate the iOS floor table in references/_shared/floors-master.md from sdk_catalog.json introduced_ios."""
import json, os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
av=json.load(open(os.path.join(ROOT,"sdk_catalog.json"))).get("availability",{})
rows=sorted(((n,d["introduced_ios"]) for n,d in av.items() if d.get("introduced_ios")),
            key=lambda x:(tuple(int(p) for p in x[1].split(".")), x[0]))
# group by floor; write a concise reference (floor -> notable APIs), capped per floor
from collections import defaultdict
byfloor=defaultdict(list)
for n,v in rows: byfloor[v].append(n)
lines=["# iOS availability floors (generated from sdk_catalog.json `introduced_ios`)","",
       "> Min-iOS each SwiftUI symbol became available. Verify anything marked verify-SDK in Xcode.",""]
for floor in sorted(byfloor, key=lambda v:tuple(int(p) for p in v.split("."))):
    apis=sorted(byfloor[floor])
    lines.append(f"## iOS {floor}+  ({len(apis)} symbols)")
    lines.append(", ".join(f"`{a}`" for a in apis[:60]) + ("" if len(apis)<=60 else f", … (+{len(apis)-60} more)"))
    lines.append("")
open(os.path.join(ROOT,"references","_shared","floors-master.md"),"w").write("\n".join(lines))
print(f"floors-master.md: {len(rows)} symbols across {len(byfloor)} iOS floors")
