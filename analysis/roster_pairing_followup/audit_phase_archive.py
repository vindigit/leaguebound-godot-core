"""Read-only, phase-complete archive/log gate; never launches games.

Requires all 20 cells before reading any outcomes. Writes an optional new audit
artifact, never modifies measurements. Canonical failures are allowed only when
the exact metric identity and count agree with the archived canonical report.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

OUT = Path(__file__).resolve().parent
COMPS = ('high_school', 'college', 'development', 'overseas', 'top_domestic_pro')
STARTS = {'diagnosis': 23400000, 'validation_a': 28080000, 'validation_b': 32760000}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def audit(phase):
    labels = [(f'{phase}_{version}_{arm}_{comp}', version, arm, comp)
              for comp in COMPS for version in ('baseline', 'candidate')
              for arm in ('home', 'neutral')]
    # Refuse partial-phase analysis, including when invoked accidentally early.
    for label, _, _, comp in labels:
        for path in (OUT / 'processes' / f'{label}.json', OUT / 'logs' / f'{label}.txt',
                     OUT / 'reports' / f'roster_raw_{label}_{comp}.json',
                     OUT / 'reports' / f'competition_calibration_{label}.json'):
            require(path.is_file(), f'Phase incomplete: {path.name}')
    freeze = read(OUT / 'candidate_freeze.json')
    amendment = read(OUT / 'freeze_comment_amendment.json')
    cells = []
    contracts = {}
    for label, version, arm, comp in labels:
        process_path = OUT / 'processes' / f'{label}.json'
        log_path = OUT / 'logs' / f'{label}.txt'
        raw_path = OUT / 'reports' / f'roster_raw_{label}_{comp}.json'
        report_path = OUT / 'reports' / f'competition_calibration_{label}.json'
        process, raw, report = read(process_path), read(raw_path), read(report_path)
        require(process['cell'] == [phase, version, comp, arm], f'{label}: process identity')
        require(digest(raw_path) == process['raw_sha256'] and
                digest(report_path) == process['report_sha256'], f'{label}: artifact hash')
        for path, actual in process['source_hashes'].items():
            if path.endswith('run_roster_pairing_followup.gd'):
                expected = freeze['runner_sha256']
            elif version == 'candidate' and path.endswith('competition_catalog.gd'):
                expected = amendment['catalog_sha256']
            else:
                expected = freeze['files'][path][version]
            require(actual.lower() == expected.lower(), f'{label}: source hash {path}')
        require(set(process['source_hashes']) == {
            'calibration/runners/run_roster_pairing_followup.gd',
            'calibration/targets/competition_catalog.gd',
            'src/domain/basketball/config/competition_rule_profile.gd'}, f'{label}: source set')
        rows = raw['rows']
        require(len(rows) == 468 and raw['competition'] == comp and
                raw['environment'] == (0.5 if arm == 'home' else 0.0), f'{label}: raw identity')
        require([r['variation'] for r in rows] == list(range(STARTS[phase], STARTS[phase] + 468))
                and all(r['seed'] == r['variation'] + 1 for r in rows), f'{label}: seeds')
        require(all(r['games'] == 1 and r['team_games'] == 2 and r['decided_games'] == 1
                    for r in rows), f'{label}: incomplete games')
        metrics = {m['metric']: m for m in report['metrics']}
        require(len(metrics) == len(report['metrics']), f'{label}: duplicate metrics')
        contract = {name: {key: m.get(key) for key in ('definition', 'denominator', 'target')}
                    for name, m in metrics.items()}
        if comp in contracts:
            require(contract == contracts[comp], f'{label}: changed canonical contract')
        else:
            contracts[comp] = contract
        failed = {name for name, m in metrics.items() if m['verdict'] == 'fail'}
        judged = sum(m['verdict'] != 'informational' for m in metrics.values())
        require(process['exit_code'] == (1 if failed else 0), f'{label}: exit/report disagreement')
        log = log_path.read_text(encoding='utf-8-sig')
        # No runtime error or warning is whitelisted by a calibration failure.
        runtime = re.search(r'\b(?:SCRIPT ERROR|Parse Error|ERROR|FATAL|Exception|Traceback|WARNING)\b', log, re.I)
        require(runtime is None, f'{label}: runtime diagnostic: {runtime.group(0) if runtime else ""}')
        require('Godot Engine v4.7.1.stable.official.a13da4feb' in log, f'{label}: runtime version')
        table_failures, detail_failures, summaries = [], [], []
        for line in log.splitlines():
            if 'FAIL' not in line:
                continue
            detail = re.fullmatch(r'\s+FAIL ([a-z_]+\.[a-z_]+): estimate (-?[0-9.]+) outside (.+) target \[(-?[0-9.]+), (-?[0-9.]+)\]', line)
            table = re.fullmatch(r'\s+([a-z_]+\.[a-z_]+)\s+.*\s+FAIL', line)
            summary = re.fullmatch(r'\s+(\d+) metric\(s\), (\d+) judged, (\d+) failure\(s\): FAIL', line)
            if detail:
                name = detail[1]
                require(name in failed, f'{label}: unknown failed metric {name}')
                metric = metrics[name]
                require(abs(float(detail[2]) - metric['estimate']) <= 0.00005001 and
                        detail[3] == metric['target']['source'] and
                        abs(float(detail[4]) - metric['target']['minimum']) <= 0.00005001 and
                        abs(float(detail[5]) - metric['target']['maximum']) <= 0.00005001,
                        f'{label}: failure detail mismatch {name}')
                detail_failures.append(name)
            elif table:
                require(table[1] in failed, f'{label}: unknown table failure')
                table_failures.append(table[1])
            elif summary:
                summaries.append(tuple(map(int, summary.groups())))
            else:
                raise RuntimeError(f'{label}: unrecognized failure line: {line}')
        require(sorted(table_failures) == sorted(failed) == sorted(detail_failures),
                f'{label}: omitted/duplicate canonical failures')
        require(summaries == [(len(metrics), judged, len(failed))], f'{label}: terminal summary')
        require(f'report: res://reports/competition_calibration_{label}.json' in log,
                f'{label}: report identity in log')
        cells.append({'cell': label, 'games': 468, 'canonical_failures': sorted(failed),
                      'log_sha256': digest(log_path), 'process_sha256': digest(process_path),
                      'raw_sha256': digest(raw_path), 'report_sha256': digest(report_path)})
    return {'phase': phase, 'verdict': 'PASS archive/log integrity', 'cells': cells,
            'scope': 'All 20 completed cells only. No outcome acceptance or certification. Statistical formulas and source freeze exceptions reviewed separately.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=STARTS)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = audit(args.phase)
    if args.output:
        with args.output.open('x', encoding='utf-8', newline='\n') as file:
            json.dump(result, file, indent=2, ensure_ascii=True)
            file.write('\n')
    print(f'{args.phase}: PASS, 20 complete cells, runtime logs clean, all canonical failures retained')
