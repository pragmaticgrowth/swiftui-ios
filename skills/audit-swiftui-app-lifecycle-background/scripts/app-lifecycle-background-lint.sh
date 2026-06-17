#!/usr/bin/env bash
# app-lifecycle-background-lint.sh — thin pointer. There is no bespoke grep script: the toolkit ships ONE
# shared hybrid lint engine fed declarative rule files (the pattern every audit skill inherits).
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: alb-01..alb-07)
# The tier-1 grep tier STANDS ALONE (ast-grep is not installed; not required by selftest). Structural-absence
# calls (a scenePhase read with no .background save — alb-01, a submit with no register — alb-02, an
# identifier missing from Info.plist — alb-03) are LOCATED broadly by grep and resolved by the agent in READ.
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-app-lifecycle-background "$@"
