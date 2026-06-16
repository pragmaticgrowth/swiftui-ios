#!/usr/bin/env python3
"""Regression check for swiftui-scan: run it on fixtures/Sample.swift and assert every
construct class is captured correctly. Exit non-zero on any failure."""
import json, subprocess, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.path.join(HERE, "..", ".build", "release", "swiftui-scan")
SRC = os.path.join(HERE, "Sample.swift")

r = subprocess.run([BIN], input=(SRC+"\n").encode(), capture_output=True)
obj = json.loads(r.stdout.decode().splitlines()[0])
occ = obj["occurrences"]; decls = obj["decls"]

def has_occ(kind, sym, **kw):
    for o in occ:
        if o["kind"]==kind and o["sym"]==sym and all(o.get(k)==v for k,v in kw.items()):
            return True
    return False
def has_decl(kind, name, **kw):
    return any(d["kind"]==kind and d["name"]==name and all(d.get(k)==v for k,v in kw.items()) for d in decls)

checks = [
    ("@ViewBuilder func captured",        has_occ("attribute","ViewBuilder",attach="func")),
    ("@Observable on class (attach=class)", has_occ("attribute","Observable",attach="class")),
    ("multi-binding @State → 2 occurrences", sum(1 for o in occ if o["kind"]=="attribute" and o["sym"]=="State")>=3),
    ("@AppStorage key captured",          has_occ("attribute","AppStorage")),
    ("env keypath dismiss (@Environment)", has_occ("keypath","dismiss")),
    ("env keypath locale (.environment)",  has_occ("keypath","locale")),
    ("generic List<Item>() as type",      has_occ("type","List")),
    (".system implicit value-builder",    has_occ("modifier","system",implicit=True)),
    ("occurrence scoped to enclosing type", has_occ("modifier","system",scope="SettingsView")),
    ("NSViewRepresentable → appkit_bridge",  has_decl("appkit_bridge","GraphView")),
    ("macOS Sample file platform=appkit",   obj.get("platform")=="appkit"),
    ("View component inventoried",         has_decl("view","SettingsView")),
    ("body view-builder inventoried",      has_decl("viewbuilder","body",scope="SettingsView")),
    ("#Preview macro",                     has_occ("macro","Preview")),
]
fails = [name for name, ok in checks if not ok]
for name, ok in checks: print(f"  [{'PASS' if ok else 'FAIL'}] {name}")
if fails:
    print(f"\n{len(fails)} FAILED"); sys.exit(1)
print(f"\nALL {len(checks)} CHECKS PASS")

ios = json.loads(subprocess.run([BIN], input=(os.path.join(HERE,"Sample_iOS.swift")+"\n").encode(),
                                 capture_output=True).stdout.decode().splitlines()[0])
iocc, idecls = ios["occurrences"], ios["decls"]
def ihas_decl(kind, name): return any(d["kind"]==kind and d["name"]==name for d in idecls)
def ihas_occ(kind, sym): return any(o["kind"]==kind and o["sym"]==sym for o in iocc)
ios_checks = [
    ("iOS file platform=uikit (import UIKit)", ios.get("platform")=="uikit"),
    ("UIViewRepresentable → uikit_bridge",     ihas_decl("uikit_bridge","MapBox")),
    ("UIViewControllerRepresentable → uikit_bridge", ihas_decl("uikit_bridge","PlayerVC")),
    ("presentationDetents modifier captured",  ihas_occ("modifier","presentationDetents")),
    ("tabItem modifier captured",              ihas_occ("modifier","tabItem")),
]
for name, ok in ios_checks: print(f"  [{'PASS' if ok else 'FAIL'}] {name}")
if any(not ok for _, ok in ios_checks):
    print(f"\n{sum(1 for _,ok in ios_checks if not ok)} iOS CHECKS FAILED"); sys.exit(1)
print(f"ALL {len(ios_checks)} iOS CHECKS PASS")
