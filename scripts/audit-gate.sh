#!/usr/bin/env bash
# audit-gate.sh — the toolkit's PRE-SHIP GATE (mechanical LOCATE-tier, CI-friendly).
#
# Loops the ONE shared lint runner (swiftui-lint.sh) over the audit-swiftui-* skills against a target
# directory, tallies hard/warn/adv per skill + grand total, prints a per-skill + total summary to
# stderr, emits one combined JSON to stdout, and EXITS 2 if ANY skill reports a hard finding (else 0).
#
# STEER-gated by default: it first runs audit-scan.py to see which domains are actually present, then
# runs the 8 always-on + every present cond domain and marks absent cond domains `n/a — not present`
# (not run, not counted). This matches audit-ios-swiftui-full ("skipped, never run") so a SwiftData-free
# repo no longer hard-fails CI on swiftdata's broad LOCATE nets. Pass --all (or --no-steer) to force all
# 34. If python3/audit-scan.py is unavailable, it degrades to running all 34 with a notice.
#
# This is the mechanical gate: a hard finding here means a human-driven full audit
# (skills/audit-ios-swiftui-full) is required before shipping. It LOCATES only — it never decides a
# finding is real (an LLM agent READs each hit in the full audit). It does NOT reimplement the lint; it
# reuses swiftui-lint.sh.
#
# Usage:
#   bash scripts/audit-gate.sh <target-dir>           # STEER-gated; JSON → stdout, summary → stderr
#   bash scripts/audit-gate.sh <target-dir> --all     # force all 34 skills (old behavior)
#   bash scripts/audit-gate.sh <target-dir> > gate.json
#
# Make it executable once:  chmod +x scripts/audit-gate.sh
#
# Exit: 2 if any audited skill has a hard finding (CI block); 0 otherwise. (Matches the house lint contract.)
set -uo pipefail

# ---- resolve the plugin root (this script lives at ${PLUGIN}/scripts/, same as swiftui-lint.sh) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LINT="$SCRIPT_DIR/swiftui-lint.sh"

# ---- args: <target-dir> plus optional --all/--no-steer (run all 34, skip STEER gating) ------------
ALL=0; ARGS=()
for a in "$@"; do
  case "$a" in
    --all|--no-steer) ALL=1;;
    -h|--help) sed -n '2,26p' "$0"; exit 0;;
    *) ARGS+=("$a");;
  esac
done
TARGET="${ARGS[0]:-.}"
if [ ! -e "$TARGET" ]; then
  echo "audit-gate: target not found: $TARGET" >&2; exit 64
fi
if [ ! -x "$LINT" ] && [ ! -f "$LINT" ]; then
  echo "audit-gate: shared runner not found: $LINT" >&2; exit 64
fi
command -v jq >/dev/null 2>&1 || { echo "audit-gate: jq is required (brew install jq)." >&2; exit 69; }

# ---- discover all 34 audit skills (skills with a lint/ dir) -----------------------------------------
SKILLS=()
for d in "$PLUGIN_ROOT"/skills/audit-swiftui-*; do
  [ -d "$d/lint" ] || continue
  SKILLS+=("$(basename "$d")")
done
if [ "${#SKILLS[@]}" -eq 0 ]; then
  echo "audit-gate: no audit-swiftui-* skills with a lint/ dir under $PLUGIN_ROOT/skills" >&2; exit 64
fi

printf '== audit-gate: %d skills over %s ==\n' "${#SKILLS[@]}" "$TARGET" >&2

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---- STEER: consult audit-scan.py so absent domains aren't run as hard-fails (unless --all) --------
# The orchestrator (audit-ios-swiftui-full) skips domains whose presence signal is absent ("skipped,
# never run"). The mechanical gate must agree, else a SwiftData-free repo hard-fails CI on swiftdata's
# broad LOCATE nets (sd-01/sd-09). We reuse the SAME relevance decision (no duplicated logic): run the
# 8 always-on + every present cond domain; mark absent cond domains `n/a — not present` (not counted).
SCAN_PY="$SCRIPT_DIR/audit-scan.py"
RELEVANT=""; STEER_ON=0
if [ "$ALL" -eq 0 ] && command -v python3 >/dev/null 2>&1 && [ -f "$SCAN_PY" ]; then
  if python3 "$SCAN_PY" "$TARGET" --json "$TMP/_scan.json" >/dev/null 2>&1 && [ -s "$TMP/_scan.json" ]; then
    RELEVANT="$(jq -r '.relevant_skills[]?' "$TMP/_scan.json" 2>/dev/null)"
    [ -n "$RELEVANT" ] && STEER_ON=1
  fi
fi
is_relevant() { case $'\n'"$RELEVANT"$'\n' in *$'\n'"$1"$'\n'*) return 0;; *) return 1;; esac; }
if [ "$STEER_ON" -eq 1 ]; then
  printf '   STEER: %d of %d domain(s) present; absent domains marked n/a (--all to force all).\n' \
    "$(printf '%s\n' "$RELEVANT" | grep -c .)" "${#SKILLS[@]}" >&2
elif [ "$ALL" -eq 1 ]; then
  printf '   STEER disabled (--all) — running all %d skills.\n' "${#SKILLS[@]}" >&2
else
  printf '   STEER unavailable (no python3/audit-scan.py or no SwiftUI files) — running all %d skills.\n' "${#SKILLS[@]}" >&2
fi

T_HARD=0; T_WARN=0; T_ADV=0; ANY_HARD=0; NA_COUNT=0
PER_SKILL_JSON=(); NA_SKILLS=()

for skill in "${SKILLS[@]}"; do
  # absent domain (STEER says its signal isn't in the code) → not run, not counted, recorded as n/a.
  if [ "$STEER_ON" -eq 1 ] && ! is_relevant "$skill"; then
    printf '  %-34s n/a — not present (STEER)\n' "$skill" >&2
    PER_SKILL_JSON+=("$(jq -cn --arg d "$skill" '{domain:$d, status:"n/a-not-present", hard:0, warn:0, adv:0, total:0, parse_warnings:0}')")
    NA_SKILLS+=("$skill"); NA_COUNT=$((NA_COUNT+1))
    continue
  fi
  out="$TMP/$skill.json"
  # Reuse the shared runner; --quiet so only OUR summary hits stderr. It exits 2 on a hard hit — that
  # is expected and tallied, so don't let `set -e`-style propagation abort the loop.
  bash "$LINT" --skill "$skill" --dir "$TARGET" --json "$out" --quiet >/dev/null 2>&1 || true
  if [ ! -s "$out" ]; then
    printf '{"domain":"%s","error":"no-output","counts":{"hard":0,"warn":0,"adv":0,"total":0}}' "$skill" > "$out"
  fi
  hard=$(jq -r '.counts.hard // 0' "$out"); warn=$(jq -r '.counts.warn // 0' "$out"); adv=$(jq -r '.counts.adv // 0' "$out")
  T_HARD=$((T_HARD+hard)); T_WARN=$((T_WARN+warn)); T_ADV=$((T_ADV+adv))
  [ "$hard" -gt 0 ] && ANY_HARD=1
  flag=""; [ "$hard" -gt 0 ] && flag="  <-- HARD"
  printf '  %-34s hard=%-3s warn=%-3s adv=%-3s%s\n' "$skill" "$hard" "$warn" "$adv" "$flag" >&2
  PER_SKILL_JSON+=("$(jq -c '{domain: (.domain // "?"), status: "audited", hard: (.counts.hard // 0), warn: (.counts.warn // 0), adv: (.counts.adv // 0), total: (.counts.total // 0), parse_warnings: (.parse_warnings // 0)}' "$out")")
done

printf -- '-----------------------------------------------------------------\n' >&2
printf '  TOTAL  hard=%s  warn=%s  adv=%s  (audited=%d · n/a=%d · of %d)\n' \
  "$T_HARD" "$T_WARN" "$T_ADV" "$(( ${#SKILLS[@]} - NA_COUNT ))" "$NA_COUNT" "${#SKILLS[@]}" >&2
if [ "$ANY_HARD" -eq 1 ]; then
  printf '== GATE: FAIL (hard findings present) — full audit required before ship ==\n' >&2
else
  printf '== GATE: PASS (no hard findings) ==\n' >&2
fi

# ---- combined JSON → stdout ------------------------------------------------------------------------
printf '%s\n' "${PER_SKILL_JSON[@]}" | jq -s \
  --arg target "$TARGET" \
  --argjson hard "$T_HARD" --argjson warn "$T_WARN" --argjson adv "$T_ADV" \
  --argjson nskills "${#SKILLS[@]}" --argjson anyhard "$ANY_HARD" \
  --argjson na "$NA_COUNT" --argjson steer "$STEER_ON" '
  {
    tool: "audit-gate",
    role: "pre-ship-locator-gate",
    note: "Mechanical LOCATE-tier tally. STEER-gated: domains whose presence signal is absent are marked n/a (not run, not blocking) — matching audit-ios-swiftui-full. A hard finding blocks; an LLM-driven full audit must READ each hit before shipping. Use --all to force all skills.",
    target: $target,
    steer: (if $steer==1 then "on" else "off" end),
    skills_total: $nskills,
    skills_audited: ($nskills - $na),
    skills_na: $na,
    gate: (if $anyhard==1 then "fail" else "pass" end),
    totals: { hard: $hard, warn: $warn, adv: $adv },
    per_skill: .
  }'

[ "$ANY_HARD" -eq 1 ] && exit 2
exit 0
