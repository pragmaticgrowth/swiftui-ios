#!/usr/bin/env bash
# safe-area-keyboard-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE shared
# hybrid lint engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: sak-01..sak-05)
# The tier-1 grep tier STANDS ALONE (ast-grep is not installed; not required by selftest). Structural absence
# calls — a scrolling input form with no .scrollDismissesKeyboard (sak-02), a fixed bottom bar with no
# safeAreaInset (sak-03) — are LOCATED broadly by the grep tells and resolved by the agent in READ.
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-safe-area-keyboard "$@"
