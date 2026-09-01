#!/usr/bin/env bash
# Run every headless check this repository gates on, in CI order.
#
# The import step is not optional. Godot resolves `class_name` identifiers from
# .godot/global_script_class_cache.cfg, which only the importer writes. On a
# fresh clone that file does not exist, so `godot --script` sees every global
# class as an undeclared identifier and each typed script fails to parse under
# the warnings-as-errors settings in project.godot. The symptom looks like a
# broken engine build rather than a missing cache, so import first, always.
#
# Usage:
#   tools/run_checks.sh              # every check
#   tools/run_checks.sh gdunit       # one or more named checks
#
# Checks: import, parse, acceptance, smoke, calibration, gdunit

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

log() { printf '\n=== %s\n' "$*"; }
die() { printf 'run_checks: error: %s\n' "$*" >&2; exit 1; }

resolve_godot() {
	if [ -n "${GODOT_BIN:-}" ]; then
		[ -x "$GODOT_BIN" ] || die "GODOT_BIN is set to '$GODOT_BIN', which is not executable"
		printf '%s\n' "$GODOT_BIN"
		return
	fi
	if [ -x "${project_dir}/tools/install_godot.sh" ]; then
		"${project_dir}/tools/install_godot.sh"
		return
	fi
	command -v godot >/dev/null 2>&1 || die "no Godot binary; set GODOT_BIN or run tools/install_godot.sh"
	command -v godot
}

GODOT_BIN="$(resolve_godot)"
export GODOT_BIN
printf 'Godot: %s (%s)\n' "$GODOT_BIN" "$("$GODOT_BIN" --version)"

godot_script() {
	"$GODOT_BIN" --headless --path "$project_dir" --script "$1"
}

check_import() {
	log "Import project (builds .godot/global_script_class_cache.cfg)"
	"$GODOT_BIN" --headless --path "$project_dir" --import
}

check_parse() {
	log "Parse-check every script under warnings-as-errors"
	godot_script res://tools/parse_check.gd
}

check_acceptance() {
	log "Project-owned headless acceptance runner"
	godot_script res://tests/run_all.gd
}

check_smoke() {
	log "Fixed-seed simulation smoke diagnostics"
	godot_script res://tools/simulation_smoke.gd
}

check_calibration() {
	log "Builder calibration harness (BALANCE_SPEC 7.3.2 bands)"
	godot_script res://tools/builder_calibration_harness.gd
}

check_gdunit() {
	# GdUnit4 refuses headless mode by default because it cannot deliver
	# InputEvents there. This project's suites are pure simulation with no UI
	# interaction, so the check is waived rather than worked around with a
	# virtual display.
	log "GdUnit4 suites"
	bash addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode --add res://tests
}

requested=("$@")
if [ ${#requested[@]} -eq 0 ]; then
	requested=(import parse acceptance smoke calibration gdunit)
elif [[ " ${requested[*]} " != *" import "* ]]; then
	# Every other check depends on the class cache, so never skip the import.
	requested=(import "${requested[@]}")
fi

for name in "${requested[@]}"; do
	case "$name" in
		import | parse | acceptance | smoke | calibration | gdunit) "check_${name}" ;;
		*) die "unknown check '${name}'" ;;
	esac
done

log "All requested checks passed"
