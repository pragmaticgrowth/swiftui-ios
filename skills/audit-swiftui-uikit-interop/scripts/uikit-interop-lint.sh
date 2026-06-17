#!/usr/bin/env bash
# uikit-interop-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE shared hybrid
# lint engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: uik-01..uik-06)
#                                 ../lint/ast-grep/*.yml       (tier 2 — optional structural: representable
#                                                               with no updateUIView, delegate with no
#                                                               makeCoordinator; ast-grep is NOT installed,
#                                                               so the grep tier stands alone)
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-uikit-interop "$@"
