#!/usr/bin/env bash
# presentation-sheets-modals-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE
# shared hybrid lint engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: psm-01..psm-05)
#                                 (ast-grep is NOT installed in this environment; the grep tier stands alone)
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-presentation-sheets-modals "$@"
