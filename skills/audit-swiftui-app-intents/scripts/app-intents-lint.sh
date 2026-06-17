#!/usr/bin/env bash
# app-intents-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE shared hybrid
# lint engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: ain-01..ain-05)
#                                 (ain-01 AppIntent-without-static-title, ain-02 provider-without-phrases,
#                                  ain-03 @Parameter-without-title, ain-04 perform()-off-actor,
#                                  ain-05 legacy SiriKit INIntent/IntentConfiguration — the structural
#                                  ABSENCE cases are confirmed by the agent after READ; ast-grep NOT installed)
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-app-intents "$@"
