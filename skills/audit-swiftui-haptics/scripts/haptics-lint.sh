#!/usr/bin/env bash
# haptics-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE shared hybrid lint
# engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: hap-01..hap-04)
#                                 (this skill ships GREP TELLS ONLY — no ast-grep/*.yml tier-2 rules; the
#                                  lifecycle/absence judgments — no .prepare() in scope, generator hoisted
#                                  vs inline, discrete-vs-hot-path event — are resolved by the agent on READ)
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-haptics "$@"
