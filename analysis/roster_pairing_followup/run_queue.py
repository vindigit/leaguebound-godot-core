"""Continue the declared finite experiment after baseline and review barriers."""
import json, subprocess, sys, time
from pathlib import Path

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]

def launch(*arguments):
    result=subprocess.run([sys.executable,'-X','utf8',str(OUT/'run_cells.py'),*arguments],cwd=ROOT)
    if result.returncode:
        raise RuntimeError(f'Cell batch failed: {arguments}')

if __name__=='__main__':
    print('Waiting for all ten baseline diagnostic cells and structural-review release.',flush=True)
    while len(list((OUT/'processes').glob('diagnosis_baseline_*.json')))<10 or not (OUT/'structural_release.json').exists():
        time.sleep(10)
    release=json.loads((OUT/'structural_release.json').read_text(encoding='utf-8-sig'))
    assert release['approved'] is True
    launch('--phases','diagnosis','--versions','candidate','--workers','5')
    launch('--phases','validation_a','validation_b','--versions','baseline','candidate','--workers','5')
    for phase in ['diagnosis','validation_a','validation_b']:
        subprocess.run([sys.executable,'-X','utf8',str(OUT/'analyze.py'),phase],cwd=ROOT,check=True)
    print('All declared cells and reconciled summaries complete.',flush=True)
