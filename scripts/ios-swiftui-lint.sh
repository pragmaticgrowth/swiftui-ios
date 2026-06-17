#!/usr/bin/env bash
# ios-swiftui-lint.sh — grep tells for iOS SwiftUI defects.
# Usage: ios-swiftui-lint.sh [file-or-dir ...]   (default: current dir)
# Exit: 2 if any [hard-fail] rule matched, else 0. Warnings never fail the run.
# Full rule list + replacements: skills/build-ios-swiftui/references/lint-checklist.md
set -uo pipefail

# ---- collect .swift files -------------------------------------------------
files=()
if [ "$#" -eq 0 ]; then set -- "."; fi
for arg in "$@"; do
  if [ -d "$arg" ]; then
    while IFS= read -r f; do files+=("$f"); done < <(find "$arg" -type f -name '*.swift' 2>/dev/null)
  elif [ -f "$arg" ] && case "$arg" in *.swift) true;; *) false;; esac; then
    files+=("$arg")
  fi
done
if [ "${#files[@]}" -eq 0 ]; then echo "ios-swiftui-lint: no .swift files in: $*"; exit 0; fi

hard=0; warn=0
# flag ID SEV ERE MESSAGE  — SEV is "hard" or "warn"
flag() {
  local id="$1" sev="$2" ere="$3" msg="$4" hit
  hit=$(grep -HnE "$ere" "${files[@]}" 2>/dev/null) || return 0
  [ -z "$hit" ] && return 0
  while IFS= read -r line; do
    printf '%s  [%s/%s] %s\n' "$line" "$id" "$sev" "$msg"
  done <<< "$hit"
  if [ "$sev" = "hard" ]; then hard=$((hard+1)); else warn=$((warn+1)); fi
}

echo "== ios-swiftui-lint: scanning ${#files[@]} file(s) =="

# ---- version drift / deprecation -----------------------------------------
flag R1  hard 'NavigationView[[:space:]]*\{'                         'NavigationView → NavigationStack (deprecated); NavigationSplitView only when gated to regular width / iPad'
flag R2  warn '\.foregroundColor\('                                  '.foregroundColor → .foregroundStyle (deprecated, iOS 15+)'
flag R3  warn 'edgesIgnoringSafeArea'                                'edgesIgnoringSafeArea → .ignoresSafeArea(_:edges:) (deprecated)'
flag R4  warn '\.onChange\(of:[^)]*\)[[:space:]]*\{[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in' 'single-param onChange → two-param { old, new in } (iOS 17+)'
flag R5  warn '\.tabItem[[:space:]]*\{'                               '.tabItem → Tab(...) {} (iOS 18+; gate or keep .tabItem for iOS 17 targets)'
flag R6  warn 'Text\([^)]*\)[[:space:]]*\+[[:space:]]*Text\('          'Text + Text concatenation deprecated (iOS 26) → string interpolation'
flag R7  warn '\.navigationBarTitle\('                               '.navigationBarTitle → .navigationTitle (+ .navigationBarTitleDisplayMode) (deprecated)'
flag R8  warn 'placement:[[:space:]]*\.navigationBar(Leading|Trailing)' 'navigationBarLeading/Trailing placement deprecated → .topBarLeading/.topBarTrailing/.principal/.primaryAction'
flag R9  warn '\.accentColor\('                                       '.accentColor deprecated → .tint(_:)'
flag R10 warn '\.autocapitalization\(|\.disableAutocorrection\('      'autocapitalization/disableAutocorrection deprecated → .textInputAutocapitalization / .autocorrectionDisabled'
flag R11 warn 'MagnificationGesture'                                  'MagnificationGesture deprecated → MagnifyGesture (iOS 17+)'
flag R12 warn 'RotationGesture'                                        'RotationGesture deprecated → RotateGesture (iOS 17+)'
flag R13 warn '\.cornerRadius\('                                      '.cornerRadius → prefer .clipShape(.rect(cornerRadius:)) / RoundedRectangle for clearer intent'

# ---- hallucination / gating ----------------------------------------------
flag R20 hard '\.glassBackground\(|\.liquidGlass\(|\.material\(\.glass|LiquidGlassView' 'INVENTED Liquid Glass API (does not exist) → .glassEffect()/GlassEffectContainer'
flag R21 warn '\.glassBackgroundEffect\('                            '.glassBackgroundEffect is visionOS-only — not iOS → use .glassEffect(_:in:)'
flag R22 warn '#available\(macOS [0-9]'                              'macOS-arm availability gate in an iOS skill — never fires on iOS (the * wildcard covers iOS); gate on #available(iOS …)'

# ---- macOS-only primitives ported to iOS (won't compile) ------------------
flag R25 hard 'MenuBarExtra|\.commands[[:space:]]*\{|^[[:space:]]*Settings[[:space:]]*\{|CommandMenu|CommandGroup' 'macOS-only scene/menu API on iOS → Menu / .contextMenu / .swipeActions / App Intents; settings = Form + @AppStorage'
flag R26 hard ':[[:space:]]*NSViewRepresentable|:[[:space:]]*NSViewControllerRepresentable|NSHostingController|NSHostingView' 'AppKit bridge on iOS → use UIViewRepresentable / UIViewControllerRepresentable / UIHostingController'
flag R27 warn 'NSStatusItem|NSPasteboard|NSOpenPanel'               'AppKit-only symbol on iOS → no menu-bar status item; use UIPasteboard / fileImporter'
flag R28 warn '\.formStyle\(\.grouped\)'                            '.formStyle(.grouped) is the macOS knob — on iOS Form is already grouped; drop it'

# ---- state & observation --------------------------------------------------
flag R30 hard '@ObservedObject[[:space:]]+var[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*[A-Za-z_]' '@ObservedObject with an initializer → view owns it: use @State/@StateObject'
flag R31 warn '@Published'                                           '@Published is illegal inside @Observable — remove if model is @Observable'
flag R32 warn '@EnvironmentObject'                                   '@EnvironmentObject → @Environment(Type.self) for @Observable deps'

# ---- concurrency ----------------------------------------------------------
flag R35 warn 'DispatchQueue\.main\.async'                           'DispatchQueue.main.async → @MainActor / await MainActor.run'
flag R36 warn 'Task\.detached[[:space:]]*\{'                         'Task.detached can cross actor boundaries with non-Sendable capture — verify'

# ---- file access ----------------------------------------------------------
flag R40 warn 'NSPasteboard'                                         'NSPasteboard does not exist on iOS → UIPasteboard / Transferable'
flag R41 warn 'com\.apple\.security\.app-sandbox|withSecurityScope' 'App-Sandbox entitlements / .withSecurityScope are macOS — on iOS use bookmarkData(.minimalBookmark) + start/stopAccessingSecurityScopedResource()'

# ---- previews -------------------------------------------------------------
flag R45 warn 'PreviewProvider'                                      'PreviewProvider → #Preview {} macro (+ @Previewable @State)'

# ---- per-file structural checks (need absence detection) ------------------
for f in "${files[@]}"; do
  if grep -qE ':[[:space:]]*UIViewRepresentable|:[[:space:]]*UIViewControllerRepresentable' "$f" 2>/dev/null; then
    if ! grep -qE 'func[[:space:]]+updateUIView' "$f" 2>/dev/null; then
      printf '%s  [R50/hard] UIViewRepresentable with no updateUIView → SwiftUI state never propagates\n' "$f"
      hard=$((hard+1))
    fi
  fi
  # R51: `let` on the line right after an @Relationship → runtime crash
  awk 'prev ~ /@Relationship/ && $0 ~ /^[[:space:]]*let[[:space:]]/ {printf "%s:%d  [R51/hard] `let` on an @Relationship property → runtime crash, use var\n", FILENAME, NR} {prev=$0}' "$f" && \
    grep -qE '@Relationship' "$f" 2>/dev/null && awk 'prev ~ /@Relationship/ && $0 ~ /^[[:space:]]*let[[:space:]]/ {c++} {prev=$0} END{exit (c>0)?0:1}' "$f" 2>/dev/null && hard=$((hard+1))
done

# ---- positive checks (an iOS NavigationSplitView should be size-class gated) -
if grep -qE 'NavigationSplitView' "${files[@]}" 2>/dev/null; then
  if ! grep -qE 'horizontalSizeClass|UserInterfaceSizeClass|userInterfaceIdiom' "${files[@]}" 2>/dev/null; then
    echo "WARN  [P1] NavigationSplitView with no size-class / idiom gate — it collapses oddly on compact-width iPhone; gate to regular width / iPad"
    warn=$((warn+1))
  fi
fi

echo "== done: ${hard} hard-fail rule(s), ${warn} warning rule(s) =="
[ "$hard" -gt 0 ] && exit 2
exit 0
