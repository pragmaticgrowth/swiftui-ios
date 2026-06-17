#!/usr/bin/env bash
# widgets-live-activities-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE
# shared hybrid lint engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: wla-01..wla-06)
#                                                              (wla-01 timeline .never · wla-02 ActivityConfiguration
#                                                               without DynamicIsland · wla-03 legacy IntentConfiguration
#                                                               · wla-04 Button/Toggle(intent:) · wla-05 supportedFamilies
#                                                               mismatch · wla-06 ungated ControlWidget* iOS 18)
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-widgets-live-activities "$@"
