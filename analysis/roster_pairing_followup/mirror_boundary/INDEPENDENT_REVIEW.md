# Independent consumer boundary review

Verdict: ACCEPT the narrow mirror-index width correction. Final test/mutation and complete-gate acceptance remain separate.

The actual Godot probe calls the home-court runner's fixture constructor and compares all ten players' rating vectors against the original int64 `team_for(variation * 2)` contract. Before correction, variation 1073741823 passes, while 1073741824, 1073741825 and 2147483648 fail because PackedInt32Array truncates the index. After correction, all four cases pass. Probe, before/after logs and current consumer hashes independently match the recorded provenance; the old hash matches the retained candidate freeze.

The scalar-int implementation restores the old mirror path. Generated-population mode still receives exactly the same bounded indices 0..116. The probe itself covers high-school forward mirrors; it does not replace the broader runtime test and actual-source mutation evidence.

Primary experiment observations remain valid. The measurement runner, standard competition runner, catalog and engine do not call or load this diagnostic consumer; source references found in that closure are explanatory comments only. Production source is unchanged. All measured variations are also below the exposed boundary. No main-cell outcome needs replacement or selective rerunning for this fix.

The historical freeze and original process records must remain intact. A replay exception is approved only for the candidate home-court consumer at the exact recorded old-to-new hash transition. The guard must validate the old hash against the freeze, the new hash against current bytes, and retain amendment identity plus a current source snapshot. No general calibration-file exemption is approved. A fresh complete regression gate is required after the correction.
