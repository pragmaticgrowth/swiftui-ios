import importlib.util, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cat", os.path.join(HERE,"..","05_catalog.py"))
cat = importlib.util.module_from_spec(spec); spec.loader.exec_module(cat)

def classify(imports, syms, swiftui_occ=1, has_app=False):
    return cat.classify_platform(set(imports), set(syms), swiftui_occ, has_app)

assert classify(["UIKit"], []) == "ios"
assert classify([], ["UIViewRepresentable"]) == "ios"
assert classify(["AppKit"], []) == "macos"
assert classify(["UIKit","AppKit"], []) == "cross_platform"
assert classify([], ["MenuBarExtra"]) == "macos"
assert classify([], [], swiftui_occ=0) == "library"
assert classify([], [], swiftui_occ=5) == "ios"   # default low-confidence
print("classify_platform: ALL PASS")
