"""Small independent arithmetic examples, separate from the Godot test count."""
import hashlib, json
from pathlib import Path
import numpy as np
import analyze

rows=[{'n':.5,'d':1}]*4+[{'n':1.5,'d':2}]*4
value,influence=analyze.ratio(rows,('n','d'))
assert abs(value-2/3)<1e-12  # Ratio of totals; mean of game ratios would be .625.
assert np.allclose(influence,[-1/9,1/9])
scaled,scaled_influence=analyze.ratio(rows,('n','d',100))
assert abs(scaled-value*100)<1e-12
assert np.allclose(scaled_influence,influence*100)
assert analyze.estimate(0,np.zeros(117))['interval'] is None
balanced=[{'event':i%2} for i in range(468)]
assert not analyze.event_counts(balanced,'event')['sparse_approximation_warning']
assert analyze.paired_event_counts(balanced,balanced,'event')['sparse_approximation_warning']
zero=[{'event':0} for _ in range(468)]
assert analyze.event_counts(zero,'event')['sparse_approximation_warning']
assert analyze.event_counts(zero,'event')['event_free_quartets']==117
margins=[{'margin':i%11-5} for i in range(468)]
identity=analyze.margin_bootstrap(margins,margins)
assert identity['delta']==0 and identity['paired_percentile_95_quartet_bootstrap'] is None
assert analyze.percentile_interval([0]*9999+[1]) is None
constant=analyze.margin_bootstrap([{'margin':0}]*468,[{'margin':0}]*468)
assert constant['before_interval'] is None and constant['after_interval'] is None
print(json.dumps({'status':'PASS','checks':['ratio of totals and independent influence example',
    'unit scaling','zero-variance and sparse-event guards','paired bootstrap identity'],
    'analyzer_sha256':hashlib.sha256(Path(analyze.__file__).read_bytes()).hexdigest()},indent=2))
