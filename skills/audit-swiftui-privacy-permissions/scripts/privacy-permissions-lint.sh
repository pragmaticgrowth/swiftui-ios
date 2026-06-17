#!/usr/bin/env bash
# privacy-permissions-lint.sh — thin pointer. The toolkit ships ONE shared hybrid lint engine fed
# declarative rule files (the pattern every audit skill inherits); there is no bespoke grep script here.
#
# Rules for this skill live in:   ../lint/grep-tells.tsv       (tier 1 — flat grep tells: pp-01 … pp-06)
# This domain's OTHER half lives in Info.plist + PrivacyInfo.xcprivacy, which the runner does NOT scan —
# the SKILL.md ORIENT/READ steps inspect those two config files BY HAND (a .swift use is a finding only
# when its required usage-string / NSPrivacyAccessedAPITypes declaration is demonstrably absent).
# The engine + rule-file format + JSON/SARIF shape + safety rails:
#                                 ${CLAUDE_PLUGIN_ROOT}/references/_shared/lint-architecture.md
#
# Run the shared runner instead (it forwards every arg to swiftui-lint.sh):
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/swiftui-lint.sh" \
  --skill audit-swiftui-privacy-permissions "$@"
