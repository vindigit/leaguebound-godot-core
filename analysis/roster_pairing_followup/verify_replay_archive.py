"""Independently verify completed replay evidence; never launches Godot."""
import argparse
import hashlib
import itertools
import json
import re
from pathlib import Path

OUT = Path(__file__).resolve().parent


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def exact(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False)


def check(folder):
    if not __debug__:
        raise RuntimeError('Do not optimize Python; independent verification requires assertions')
    summary = read(folder / 'summary.json')
    plan = read(folder / 'plan.json')
    protocol = read(OUT / 'protocol.json')
    freeze = read(OUT / 'candidate_freeze.json')
    amendment = read(OUT / 'consumer_width_amendment.json')
    assert summary['success'] is True and summary['cells'] == 20 and summary['games'] == 80
    assert plan['total_games'] == 80 and len(plan['cells']) == 20
    assert plan['protocol_sha256'] == sha(OUT / 'protocol.json')
    assert plan['freeze_sha256'] == sha(OUT / 'candidate_freeze.json')
    expected = {('diagnosis', v, c, a) for v, c, a in itertools.product(
        ('baseline', 'candidate'), protocol['competitions'], ('home', 'neutral'))}
    assert len(summary['completed_cells']) == 20
    assert {tuple(r['cell']) for r in summary['completed_cells']} == expected
    assert {tuple(r['cell']) for r in plan['cells']} == expected
    current = {}
    checked = []
    base = protocol['phases']['diagnosis']
    for reference in summary['completed_cells']:
        directory = folder / Path(reference['directory']).name
        assert directory.resolve() == Path(reference['directory']).resolve()
        assert sha(directory / 'result.json') == reference['result_sha256']
        result, command = read(directory / 'result.json'), read(directory / 'command.json')
        assert result['completed'] is True and result['exact_match'] is True and result['diffs'] == []
        assert not result.get('timed_out', False) and 'error' not in result
        assert result['exit_code'] in (0, 1) and command['cell'] == reference['cell']
        _, version, comp, arm = command['cell']
        assert command['games'] == 4 and command['shard'] * 4 == base
        assert command['shards'] == command['shard'] + 1
        assert command['variations'] == list(range(base, base+4))
        assert command['seeds'] == list(range(base+1, base+5))
        args = command['args']
        options = {s[2:].split('=', 1)[0]: s.split('=', 1)[1] for s in args if s.startswith('--') and '=' in s}
        assert options['games'] == '4' and int(options['shard']) * 4 == base
        assert options['label'] == command['label'] and options['competition'] == comp
        assert float(options['environment']) == (.5 if arm == 'home' else 0)
        tree = Path(command['cwd'])
        assert tree == Path(args[args.index('--path')+1])
        original_path, original_raw_path = Path(command['original_record']), Path(command['original_raw'])
        assert sha(original_path) == command['original_process_sha256']
        assert sha(original_raw_path) == command['original_raw_sha256']
        original, raw = read(original_path), read(original_raw_path)
        assert original['cell'] == command['cell'] and original['raw_sha256'] == sha(original_raw_path)
        original_report = OUT / 'reports' / f'competition_calibration_diagnosis_{version}_{arm}_{comp}.json'
        assert sha(original_report) == original['report_sha256']
        expected_rows_path = directory / 'expected_rows.json'
        assert sha(expected_rows_path) == command['expected_rows_sha256']
        assert exact(read(expected_rows_path)) == exact(raw['rows'][:4])
        raw_name = f'roster_raw_{command["label"]}_{comp}.json'
        report_name = f'competition_calibration_{command["label"]}.json'
        assert set(result['artifacts']) == {raw_name, report_name}
        for name, digest in result['artifacts'].items():
            assert sha(directory / name) == digest
        replay, report = read(directory / raw_name), read(directory / report_name)
        assert len(replay['rows']) == 4 and exact(replay['rows']) == exact(raw['rows'][:4])
        for key in ('competition', 'environment', 'catalog'):
            assert replay[key] == raw[key]
        assert (replay['seed_first'], replay['seed_last']) == (base+1, base+4)
        for row, variation in zip(replay['rows'], range(base, base+4)):
            assert row['variation'] == variation and row['seed'] == variation+1
        assert command['source_hashes'] == result['source_hashes_after']
        for path, digest in original['source_hashes'].items():
            assert command['source_hashes'][path] == digest
        for path, hashes in freeze['files'].items():
            if path.endswith('.gd') and path.startswith(('src/', 'calibration/')):
                wanted = original['source_hashes'].get(path, hashes[version])
                if version == 'candidate' and path == amendment['path']:
                    assert amendment['old_sha256'] == hashes['candidate']
                    wanted = amendment['new_sha256']
                assert command['source_hashes'][path] == wanted
        if version == 'candidate':
            assert command['consumer_width_amendment_sha256'] == sha(OUT / 'consumer_width_amendment.json')
            assert amendment['original_freeze_sha256'] == sha(OUT / 'candidate_freeze.json')
            assert amendment['probe_provenance_sha256'] == sha(OUT / 'mirror_boundary/provenance.json')
        else:
            assert command['consumer_width_amendment_sha256'] is None
        for path, digest in command['source_hashes'].items():
            key = tree / path
            if key not in current:
                current[key] = sha(key)
            assert current[key] == digest
        executable = Path(args[0])
        if executable not in current:
            current[executable] = sha(executable)
        assert current[executable] == command['godot_sha256']
        assert sha(OUT / 'replay_prefixes.py') == command['script_sha256']
        log_path = directory / 'process.log'
        assert sha(log_path) == result['log_sha256']
        log = log_path.read_text(encoding='utf-8-sig')
        assert 'Godot Engine v4.7.1.stable.official.a13da4feb' in log
        assert re.search(r'\b(?:SCRIPT ERROR|Parse Error|ERROR|FATAL|Exception|Traceback|WARNING)\b', log, re.I) is None
        failed = {m['metric'] for m in report['metrics'] if m['verdict'] == 'fail'}
        detail_ids = re.findall(r'^\s+FAIL ([a-z_]+\.[a-z0-9_]+): estimate ', log, re.M)
        assert len(detail_ids) == len(failed) and set(detail_ids) == failed
        assert result['exit_code'] == (1 if failed else 0)
        checked.append({'cell': reference['cell'], 'result_sha256': reference['result_sha256'],
                        'command_sha256': sha(directory / 'command.json'), 'raw_sha256': sha(directory / raw_name)})
    return {'verdict': 'ACCEPT exact observed raw-row replay', 'cells': 20, 'games': 80,
            'summary_sha256': sha(folder / 'summary.json'), 'checked_cells': checked,
            'scope': 'Complete canonical per-game raw rows exactly match archived prefixes. This is not event-ledger-byte replay and is not additional calibration evidence.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('run_id')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = check(OUT / 'replay_prefixes' / args.run_id)
    with args.output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(result, stream, indent=2)
        stream.write('\n')
    print(result['verdict'], result['cells'], result['games'])
