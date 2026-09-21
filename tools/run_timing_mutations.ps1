param(
    [Parameter(Mandatory=$true)][string]$GodotBin,
    [string]$OutputDirectory = 'analysis/stopped_clock_followup/mutations'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$output = [IO.Path]::GetFullPath((Join-Path $repo $OutputDirectory))
New-Item -ItemType Directory -Force -Path $output | Out-Null
# Never mutate the shared checkout. Preserve the isolated copy for inspection.
$isolated = Join-Path ([IO.Path]::GetTempPath()) ('leaguebound-timing-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $isolated | Out-Null
& robocopy $repo $isolated /E /XD .git .godot reports analysis /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -gt 7) { throw 'isolated copy failed' }
& $GodotBin --headless --path $isolated --import *> (Join-Path $output 'import.log')
if ($LASTEXITCODE -ne 0) { throw 'isolated import failed' }
$strategy = 'src/domain/basketball/simulation/endgame_strategy.gd'
$engine = 'src/domain/basketball/simulation/possession_engine.gd'
$mutants = @(
    @{ id='floor_horn_equality'; file=$strategy; old='* pace))) + 1'; new='* pace)))' },
    @{ id='floor_ignores_competition_pace'; file=$strategy; old='1.0 if rules == null else rules.pace_multiplier'; new='1.0 if rules == null else 1.0' },
    @{ id='eligibility_wrong_deficit'; file=$strategy; old='context.offense_margin() == -INTENTIONAL_MISS_DEFICIT'; new='context.offense_margin() == -1' },
    @{ id='eligibility_first_attempt'; file=$strategy; old='if attempt_index != attempts - 1:'; new='if attempt_index != 0:' },
    @{ id='nonbonus_admin_charges_clock'; file=$engine; old="`tif attempts <= 0:`n"; new="`tif attempts <= 0:`n`t`t_consume(1000)`n`t`tif _terminated:`n`t`t`treturn`n" },
    @{ id='awarded_free_throw_charges_clock'; file=$engine; old="`tfor index in range(attempts):`n"; new="`tfor index in range(attempts):`n`t`t_consume(1000)`n`t`tif _terminated:`n`t`t`treturn`n" },
    @{ id='live_rebound_uncharged'; file=$engine; old='_consume(_clock.rebound_ms(rebound_stream.derive(&"time")))'; new='_consume(0)' },
    @{ id='putback_invents_action_time'; file=$engine; old="`t_resolve_shot(`n`t`tputback.actor_id"; new="`t_consume(1)`n`tif _terminated:`n`t`treturn`n`t_resolve_shot(`n`t`tputback.actor_id" },
    @{ id='floor_truncates_instead_of_rounding'; file=$strategy; old='int(roundf(float(balance.rebound_seconds_max) * 1000.0 * pace))'; new='int(float(balance.rebound_seconds_max) * 1000.0 * pace)' }
)
$records = @()
function Invoke-Focused([string]$name) {
    $log = Join-Path $output ($name + '.log')
    & $GodotBin --headless --path $isolated -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/simulation/test_stopped_clock_followup.gd *> $log
    $code = $LASTEXITCODE
    $content = (Get-Content -LiteralPath $log -Raw) -replace "`e\[[0-9;]*m", ''
    if ($content -match 'SCRIPT ERROR|Parse Error|No test cases found') { throw "$name invalid test execution" }
    $summary = [regex]::Match($content, 'Overall Summary: ([^\r\n]+)').Groups[1].Value
    if (-not $summary) { throw "$name has no test summary" }
    return @{ id=$name; exit_code=$code; summary=$summary }
}
$baseline = Invoke-Focused 'baseline'
if ($baseline.exit_code -ne 0 -or $baseline.summary -notmatch '7 test cases \| 0 errors \| 0 failures') { throw 'baseline is not green' }
$records += $baseline
foreach ($mutant in $mutants) {
    $path = Join-Path $isolated $mutant.file
    $original = [IO.File]::ReadAllText($path)
    $normalized = $original.Replace("`r`n", "`n")
    if (($normalized.Split([string[]]@($mutant.old), [StringSplitOptions]::None).Count - 1) -ne 1) { throw "$($mutant.id) must match exactly once" }
    try {
        [IO.File]::WriteAllText($path, $normalized.Replace($mutant.old, $mutant.new))
        $record = Invoke-Focused $mutant.id
        if ($record.exit_code -eq 0 -or $record.summary -notmatch '[1-9][0-9]* failures') { throw "$($mutant.id) survived or failed without assertion evidence" }
        $records += $record
    } finally {
        [IO.File]::WriteAllText($path, $original)
    }
}
$sourceHashes = @{}
foreach ($relative in @($strategy, $engine, 'src/domain/basketball/config/simulation_balance_profile.gd', 'calibration/targets/competition_catalog.gd', 'tests/simulation/test_stopped_clock_followup.gd')) {
    $snapshotPath = Join-Path $isolated $relative
    if (Test-Path -LiteralPath $snapshotPath) { $sourceHashes[$relative] = (Get-FileHash -LiteralPath $snapshotPath -Algorithm SHA256).Hash }
}
$result = @{ isolated_copy=$isolated; godot=(& $GodotBin --version); baseline_and_mutants=$records; killed=$mutants.Count; source_sha256=$sourceHashes }
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'results.json')
$result | ConvertTo-Json -Depth 6
