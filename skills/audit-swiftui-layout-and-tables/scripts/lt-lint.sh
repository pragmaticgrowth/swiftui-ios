#!/usr/bin/env bash
# lt-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE shared hybrid lint
# engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: lt-01..lt-05)
#                                 ../lint/ast-grep/*.yml       (tier 2 — structural: lt-01 Table-no-sizeclass,
#                                                               lt-03 Table-without-sortorder)
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-layout-and-tables "$@"
