"""Verify the fixture change against the roster follow-up's 11c4eae baseline.

Read-only except for an explicitly requested new evidence file. This is a
source-scope check, not a replacement for execution or statistical validation.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = '11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4'
EXISTING_CALIBRATION_CHANGES = {
    'calibration/targets/competition_catalog.gd',
    'calibration/runners/run_competition_calibration.gd',
    'calibration/runners/run_contest_sweep.gd',
    'calibration/runners/run_fg_counterfactual.gd',
    'calibration/runners/run_home_court_diagnostics.gd',
}
NEW_CALIBRATION_FILES = {
    'calibration/runners/run_roster_pairing_followup.gd',
    'calibration/runners/run_roster_pairing_followup.gd.uid',
}
PROTECTED = ['src', '.github', 'BALANCE_SPEC.md', 'SIMULATION_SPEC.md',
             'project.godot', 'tests/golden', 'tests/fixtures/golden_scenarios.gd',
             'tests/simulation/test_golden_ledgers.gd']


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def source(ref, path):
    return git('show', f'{ref}:{path}').decode('utf-8-sig').replace('\r\n', '\n')


def code_lines(text):
    # Only whole comment/empty lines are ignored. Inline code and comments,
    # string literals, whitespace, assertions and tolerances stay comparable.
    return [line for line in text.splitlines()
            if line.strip() and not line.lstrip().startswith('#')]


def function(text, name):
    match = re.search(r'(?ms)^static func ' + re.escape(name)
                      + r'\(.*?(?=^static func |\Z)', text)
    assert match, name
    return code_lines(match[0])


def verify():
    if not __debug__:
        raise RuntimeError('Optimized Python disables this verifier; run without -O/PYTHONOPTIMIZE')
    head = git('rev-parse', 'HEAD').decode().strip()
    assert not git('diff', '--name-only', BASE, head, '--', *PROTECTED).strip(), 'Protected tree changed'
    assert not git('diff', '--name-only', head, '--', 'src', 'calibration', 'tests', '.github',
                   'BALANCE_SPEC.md', 'SIMULATION_SPEC.md', 'project.godot').strip(), 'Uncommitted source changes'
    untracked = git('ls-files', '--others', '--exclude-standard', '--', 'src', 'calibration',
                    'tests', '.github').decode().splitlines()
    assert not untracked, f'Untracked source: {untracked}'
    calibration = git('diff', '--name-status', BASE, head, '--', 'calibration').decode().splitlines()
    modified = {line.split('\t')[1] for line in calibration if line.startswith('M\t')}
    added = {line.split('\t')[1] for line in calibration if line.startswith('A\t')}
    assert len(calibration) == len(modified) + len(added), 'Unexpected calibration status'
    assert modified == EXISTING_CALIBRATION_CHANGES and added == NEW_CALIBRATION_FILES
    tests = git('diff', '--name-status', BASE, head, '--', 'tests').decode().splitlines()
    assert set(tests) == {
        'M\ttests/calibration/test_fg_decomposition.gd',
        'A\ttests/calibration/test_population_pairing.gd',
        'A\ttests/calibration/test_population_pairing.gd.uid',
    }, 'Unexpected test changes'
    path = 'tests/calibration/test_fg_decomposition.gd'
    before, after = source(BASE, path), source(head, path)
    pins = [('0.1122', '0.1192'), ('0.2356', '0.2429'), ('0.6449', '0.6328')]
    for old, new in pins:
        pattern = f'.is_equal_approx({old}, CHANNEL_TOLERANCE)'
        assert before.count(pattern) == 1, f'Nonunique pin: {old}'
        before = before.replace(pattern, f'.is_equal_approx({new}, CHANNEL_TOLERANCE)')
    assert code_lines(before) == code_lines(after), 'More than disclosed pin changes'
    catalog = 'calibration/targets/competition_catalog.gd'
    unchanged_functions = ['team_for', 'balance_profile']
    for name in unchanged_functions:
        assert function(source(BASE, catalog), name) == function(source(head, catalog), name), name
    standard = 'calibration/runners/run_competition_calibration.gd'
    assert code_lines(source(BASE, standard)) == code_lines(source(head, standard)), 'Standard runner code changed'
    protected_blobs = {}
    for path in ['BALANCE_SPEC.md', 'SIMULATION_SPEC.md', 'project.godot']:
        data = git('show', f'{head}:{path}')
        protected_blobs[path] = hashlib.sha256(data).hexdigest()
    return {
        'verdict': 'PASS bounded change scope', 'baseline': BASE, 'review_head': head,
        'production_src_tree': git('rev-parse', f'{head}:src').decode().strip(),
        'protected_paths_unchanged': PROTECTED,
        'protected_git_blob_sha256': protected_blobs,
        'calibration_changes': calibration, 'test_changes': tests,
        'unchanged_catalog_function_code': unchanged_functions,
        'standard_runner_code_unchanged': True,
        'existing_test_code_changes_only': [{'before': a, 'after': b} for a, b in pins],
        'scope': 'Source bytes/code scope only. Execution, matched outcomes, replay and publication require separate evidence.',
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify()
    if args.output:
        with args.output.open('x', encoding='utf-8', newline='\n') as stream:
            json.dump(result, stream, indent=2)
            stream.write('\n')
    print(json.dumps(result, indent=2))
