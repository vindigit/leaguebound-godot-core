$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$start = 'a15bdd00debf2e75925c9376ff316650b46b516b'
$logPath = Join-Path $PSScriptRoot 'full_gate_v3.txt'
$xmlPath = Join-Path $PSScriptRoot 'full_gate_v3_results.xml'
$log = (Get-Content -LiteralPath $logPath -Raw) -replace "`e\[[0-9;]*m", ''
$result = Get-Content (Join-Path $PSScriptRoot 'full_gate_v3_result.json') -Raw | ConvertFrom-Json
if ($result.exit_code -ne 0 -or $result.head -ne $start) { throw 'Wrong gate provenance or exit' }
$originalXmlMatches = [regex]::Matches($log, '(?m)^ Open XML Report at: file://([^\r\n]+results\.xml)\r?$')
if ($originalXmlMatches.Count -ne 1) { throw 'Missing or duplicate original XML path' }
$originalXmlPath = $originalXmlMatches[0].Groups[1].Value
$resolvedOriginal = (Resolve-Path -LiteralPath $originalXmlPath).Path
$reportsRoot = (Resolve-Path -LiteralPath (Join-Path $repo 'reports')).Path + [IO.Path]::DirectorySeparatorChar
if (-not $resolvedOriginal.StartsWith($reportsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'XML path outside report root' }
[xml]$xml = Get-Content -LiteralPath $xmlPath -Raw
$rows = @()
foreach ($suite in $xml.testsuites.testsuite) {
    $path = "$($suite.package)/$($suite.name).gd"
    $source = Get-Content -LiteralPath $path -Raw
    $names = @([regex]::Matches($source, '(?m)^func (test_[A-Za-z0-9_]+)\(') | ForEach-Object { $_.Groups[1].Value })
    $cases = @($suite.testcase)
    $actual = @($cases | ForEach-Object { $_.name })
    if ($cases.Count -ne [int]$suite.tests -or $cases.Count -ne $names.Count) { throw "Count mismatch: $path" }
    if (@(Compare-Object ($names | Sort-Object) ($actual | Sort-Object)).Count -ne 0) { throw "Case name mismatch: $path" }
    if (@($actual | Sort-Object -Unique).Count -ne $actual.Count) { throw "Duplicate cases: $path" }
    foreach ($attr in @('failures','errors','skipped','flaky')) { if ([int]$suite.GetAttribute($attr) -ne 0) { throw "$attr in $path" } }
    if (@($suite.SelectNodes('.//failure|.//error|.//skipped')).Count -ne 0) { throw "Failure nodes: $path" }
    $rows += [pscustomobject]@{path=$path;declared=[int]$suite.tests;actual=$cases.Count;source_functions=$names.Count}
}
$sourceSuites = @(Get-ChildItem tests -Recurse -Filter 'test_*.gd')
if ($sourceSuites.Count -ne $rows.Count) { throw 'Missing source suite' }
$total = ($rows | Measure-Object actual -Sum).Sum
if ($total -ne [int]$xml.testsuites.tests -or $total -ne 693 -or $rows.Count -ne 55) { throw 'Unexpected full suite totals' }
$markers = @('Import project (builds .godot/global_script_class_cache.cfg)','Parse-check every script under warnings-as-errors','Project-owned headless acceptance runner','Fixed-seed simulation smoke diagnostics','Builder smoke portfolio (BALANCE_SPEC §7.3.2 bands)','Attribute sensitivity suite (PR-gate sample: 100000 resolutions)','Calibration smoke (PR-gate sample: 6 games)','GdUnit4 suites')
foreach ($marker in $markers) { if ([regex]::Matches($log, '(?m)^=== ' + [regex]::Escape($marker) + '\r?$').Count -ne 1) { throw "Missing/duplicate gate marker: $marker" } }
foreach ($required in @('Parse check: 266 script(s) checked, 0 failure(s)','LeagueBound headless acceptance: PASS','Invariants: PASS','Builder calibration: PASS','Builds evaluated: 810','80 metric(s), 80 judged, 0 failures: PASS','15 metric(s), 15 judged, 0 failures: PASS','Overall Summary: 693 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |','Executed test suites: (55/55)','Executed test cases : (693/693)','Exit code: 0','Run tests ends with 0','=== All requested checks passed')) { if (-not $log.Contains($required)) { throw "Missing completion proof: $required" } }
$changed = @(& git diff --name-only $start --)
$untracked = @(& git ls-files --others --exclude-standard)
$unexpected = @($changed + $untracked | Sort-Object -Unique | Where-Object { $_ -notlike 'analysis/*' -and $_ -notlike 'docs/*' -and $_ -ne 'PROJECT_STATUS.md' -and $_ -notlike '*.uid' })
if ($unexpected.Count) { throw ('Unexpected changes since gate start: ' + ($unexpected -join ', ')) }
$goldenPath = 'tests/golden/match_golden_hashes.json'
$golden = Get-Content $goldenPath -Raw | ConvertFrom-Json
$scenarioNames = @($golden.scenarios.psobject.Properties.Name)
if ($scenarioNames.Count -ne 6) { throw 'Golden scenario count differs' }
if (@(& git diff --name-only 11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4 -- $goldenPath tests/fixtures/golden_scenarios.gd tests/simulation/test_golden_ledgers.gd).Count) { throw 'Golden changes require separate review' }
$audit = [ordered]@{verdict='LOCAL GATE ACCEPT';gate_start=$start;review_head=(& git rev-parse HEAD);exit_code=0;steps=$markers;parse_scripts=266;suite_count=$rows.Count;test_count=$total;per_suite=$rows;golden_scenarios=$scenarioNames;goldens_unchanged_since_starting_head=$true;builder_builds=810;sensitivity_judged=80;smoke_judged=15;changed_since_gate_start=$changed;untracked_at_review=$untracked;unexpected_runtime_changes=$unexpected;log_sha256=(Get-FileHash $logPath).Hash;xml_sha256=(Get-FileHash $xmlPath).Hash;original_xml_path=$originalXmlPath;xml_matches_original=((Get-FileHash $xmlPath).Hash -eq (Get-FileHash -LiteralPath $originalXmlPath).Hash);scope='Local eight-step gate only; population, prefix replay, publication and exact-head CI remain separate';diagnostics='Expected detector parse self-test, assert_error cases, remote port 0 debugger messages and Builder shutdown resource warnings remain in stdout; zero XML test errors is not error-free stdout.'}
if (-not $audit.xml_matches_original) { throw 'Archived XML differs from original report' }
$audit | ConvertTo-Json -Depth 7 | Set-Content (Join-Path $PSScriptRoot 'full_gate_v3_independent_verification.json')
Write-Output "LOCAL GATE ACCEPT: $total tests, $($rows.Count) suites; all eight steps verified."
