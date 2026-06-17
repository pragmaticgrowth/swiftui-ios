#!/usr/bin/env bash
# design-capture.sh — thin pointer to the shared visual capture harness, so this skill can invoke
# capture without restating it. All logic lives in ${CLAUDE_PLUGIN_ROOT}/scripts/swiftui-capture.sh.
# Usage: bash design-capture.sh <project-dir> [--out DIR] [--variants minimal|full] [--no-idb] [--previews]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec bash "$ROOT/scripts/swiftui-capture.sh" "$@"
