#!/usr/bin/env bash
# SessionStart hook: make the pinned Godot toolchain usable in a managed
# Claude Code session.
#
# Two things have to be true before any check in this repository can run:
#   1. The pinned Godot 4.7.1 editor build is installed and checksum-verified.
#   2. The project has been imported, so .godot/global_script_class_cache.cfg
#      exists and `class_name` identifiers resolve. Without it every typed
#      script fails to parse under the warnings-as-errors project settings.

set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

project_dir="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

godot_bin="$("${project_dir}/tools/install_godot.sh")"

"$godot_bin" --headless --path "$project_dir" --import >/dev/null

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
	printf 'export GODOT_BIN=%q\n' "$godot_bin" >> "$CLAUDE_ENV_FILE"
fi

printf 'Godot ready: %s (%s)\n' "$godot_bin" "$("$godot_bin" --version)"
printf 'Run the gated checks with: tools/run_checks.sh\n'
