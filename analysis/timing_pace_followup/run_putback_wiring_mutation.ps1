param([Parameter(Mandatory=$true)][string]$GodotBin)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$prior=Get-Content (Join-Path $repo 'analysis/stopped_clock_followup/final_pace_mutations/results.json') -Raw | ConvertFrom-Json
$isolated=$prior.isolated_copy
$engineRelative='src/domain/basketball/simulation/possession_engine.gd'
$enginePath=Join-Path $isolated $engineRelative
$actualHash=(Get-FileHash -LiteralPath (Join-Path $repo $engineRelative)).Hash
if ((Get-FileHash -LiteralPath $enginePath).Hash -ne $actualHash) { throw 'isolated engine mismatch' }
$source=[IO.File]::ReadAllText((Join-Path $repo 'tests/simulation/test_endgame_corrections.gd'))
$start=$source.IndexOf('func test_putbacks_carry_the_endgame_decision_in_force()')
$end=$source.IndexOf('## A profile whose two quick-two numbers', $start)
$suite='extends GdUnitTestSuite' + "`n`n" + $source.Substring($start,$end-$start)
[IO.File]::WriteAllText((Join-Path $isolated 'tests/simulation/test_putback_wiring.gd'),$suite)
$original=[IO.File]::ReadAllText($enginePath)
$needle='EndgameStrategy.active_tag(_context, _balance), ShotZone.id_of(putback.zone)'
if (($original.Split([string[]]@($needle),[StringSplitOptions]::None).Count-1) -ne 1) { throw 'mutation not unique' }
$rows=@()
try {
 foreach ($arm in @('baseline','remove_putback_tag')) {
  if ($arm -eq 'remove_putback_tag') { [IO.File]::WriteAllText($enginePath,$original.Replace($needle,'&"", ShotZone.id_of(putback.zone)')) }
  $log=Join-Path $PSScriptRoot ('putback_wiring_' + $arm + '.log')
  & $GodotBin --headless --path $isolated -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/simulation/test_putback_wiring.gd *> $log
  $exit=$LASTEXITCODE
  $text=(Get-Content $log -Raw) -replace "`e\[[0-9;]*m",''
  if ($text -match 'SCRIPT ERROR|Parse Error|No test cases found') { throw 'invalid execution' }
  $summary=[regex]::Match($text,'Overall Summary: ([^\r\n]+)').Groups[1].Value
  if (-not $summary) { throw 'missing summary' }
  if ($arm -eq 'baseline' -and ($exit -ne 0 -or $summary -notmatch '1 test cases \| 0 errors \| 0 failures')) { throw 'baseline failed' }
  if ($arm -ne 'baseline' -and ($exit -eq 0 -or $summary -notmatch '[1-9][0-9]* failures')) { throw 'mutant survived' }
  $rows+=@{arm=$arm;exit_code=$exit;summary=$summary}
 }
} finally { [IO.File]::WriteAllText($enginePath,$original) }
@{engine_sha256=$actualHash;isolated_copy=$isolated;test_source_sha256=(Get-FileHash (Join-Path $repo 'tests/simulation/test_endgame_corrections.gd')).Hash;results=$rows} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'putback_wiring_mutation.json')
