param(
    [Parameter(Mandatory=$true)][string]$GodotBin,
    [string]$OutputDirectory = 'analysis/roster_pairing_followup/mutations'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$output = [IO.Path]::GetFullPath((Join-Path $repo $OutputDirectory))
New-Item -ItemType Directory -Force -Path $output | Out-Null
$isolated = Join-Path ([IO.Path]::GetTempPath()) ('leaguebound-pairing-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $isolated | Out-Null
& robocopy $repo $isolated /E /XD .git .godot reports analysis /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -gt 7) { throw 'isolated copy failed' }
& $GodotBin --headless --path $isolated --import *> (Join-Path $output 'import.log')
if ($LASTEXITCODE -ne 0) { throw 'isolated import failed' }
$catalog = 'calibration/targets/competition_catalog.gd'
$mutants = @(
    @{ id='restore_adjacent_population'; file=$catalog; old='var roster_variations: PackedInt32Array = population_roster_variations(variation)'; new='var roster_variations: PackedInt32Array = PackedInt32Array([variation * 2, variation * 2 + 1])' },
    @{ id='opener_correlated_orientation'; file=$catalog; old='if phase == 1 or phase == 2:'; new='if phase == 1 or phase == 3:' },
    @{ id='noncoprime_marginal'; file=$catalog; old='(2 * first + round_index)'; new='(3 * first + round_index)' },
    @{ id='missing_cartesian_round'; file=$catalog; old='(2 * first + round_index)'; new='(2 * first + 0 * round_index)' },
    @{ id='collapse_noise_states'; file=$catalog; old='const ROSTER_VARIATION_PERIOD: int = 117'; new='const ROSTER_VARIATION_PERIOD: int = 13' },
    @{ id='swap_explicit_away_offset'; file=$catalog; old='roster_variations[1], balance, away_offset)'; new='roster_variations[1], balance, home_offset)' },
    @{ id='contest_consumer_legacy'; file='calibration/runners/run_contest_sweep.gd'; old='CompetitionCatalog.population_roster_variations(variation)'; new='PackedInt32Array([variation * 2, variation * 2 + 1])' },
    @{ id='homecourt_consumer_legacy'; file='calibration/runners/run_home_court_diagnostics.gd'; old='CompetitionCatalog.population_roster_variations(variation)'; new='PackedInt32Array([variation * 2, variation * 2 + 1])' }
)
function Invoke-Focused([string]$name) {
    $log = Join-Path $output ($name + '.log')
    & $GodotBin --headless --path $isolated -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/calibration/test_population_pairing.gd *> $log
    $code = $LASTEXITCODE
    $content = (Get-Content -LiteralPath $log -Raw) -replace "`e\[[0-9;]*m", ''
    if ($content -match 'SCRIPT ERROR|Parse Error|No test cases found') { throw "$name invalid test execution" }
    $summary = [regex]::Match($content, 'Overall Summary: ([^\r\n]+)').Groups[1].Value
    if (-not $summary) { throw "$name has no test summary" }
    return @{ id=$name; exit_code=$code; summary=$summary }
}
$records = @()
$baseline = Invoke-Focused 'baseline'
if ($baseline.exit_code -ne 0 -or $baseline.summary -notmatch '8 test cases \| 0 errors \| 0 failures') { throw 'baseline is not green' }
$records += $baseline
foreach ($mutant in $mutants) {
    $path = Join-Path $isolated $mutant.file
    $originalBytes = [IO.File]::ReadAllBytes($path)
    $original = [IO.File]::ReadAllText($path)
    $normalized = $original.Replace("`r`n", "`n")
    if (($normalized.Split([string[]]@($mutant.old), [StringSplitOptions]::None).Count - 1) -ne 1) { throw "$($mutant.id) must match exactly once" }
    try {
        [IO.File]::WriteAllText($path, $normalized.Replace($mutant.old, $mutant.new))
        $record = Invoke-Focused $mutant.id
        if ($record.exit_code -ne 100 -or $record.summary -notmatch '0 errors \| [1-9][0-9]* failures') { throw "$($mutant.id) survived or failed without assertion evidence" }
        $records += $record
    } finally {
        [IO.File]::WriteAllBytes($path, $originalBytes)
    }
}
$sourceHashes = @{}
foreach ($relative in @($catalog, 'calibration/runners/run_contest_sweep.gd', 'calibration/runners/run_fg_counterfactual.gd', 'calibration/runners/run_home_court_diagnostics.gd', 'tests/calibration/test_population_pairing.gd')) {
    $sourceHashes[$relative] = (Get-FileHash -LiteralPath (Join-Path $isolated $relative) -Algorithm SHA256).Hash
    if ($sourceHashes[$relative] -ne (Get-FileHash -LiteralPath (Join-Path $repo $relative) -Algorithm SHA256).Hash) { throw "shared source changed during mutation run: $relative" }
}
$result = @{ source_commit=(& git -C $repo rev-parse HEAD); isolated_copy=$isolated; godot=(& $GodotBin --version); baseline_and_mutants=$records; killed=$mutants.Count; source_sha256=$sourceHashes }
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'results.json')
$result | ConvertTo-Json -Depth 6
