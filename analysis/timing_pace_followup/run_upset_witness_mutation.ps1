param([Parameter(Mandatory=$true)][string]$GodotBin)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$prior=Get-Content (Join-Path $repo 'analysis/stopped_clock_followup/final_pace_mutations/results.json') -Raw | ConvertFrom-Json
$isolated=$prior.isolated_copy
$engineRelative='src/domain/basketball/simulation/match_engine.gd'
$enginePath=Join-Path $isolated $engineRelative
foreach ($relative in @($engineRelative,'src/domain/basketball/config/competition_rule_profile.gd','src/domain/basketball/simulation/possession_engine.gd')) {
 if ((Get-FileHash (Join-Path $isolated $relative)).Hash -ne (Get-FileHash (Join-Path $repo $relative)).Hash) { throw "isolated source mismatch: $relative" }
}
$source=[IO.File]::ReadAllText((Join-Path $repo 'tests/simulation/test_score_margin.gd'))
$start=$source.IndexOf('func test_named_full_game_upset_proves_capability_does_not_force_winner()')
$end=$source.IndexOf('## Two identical teams still produce', $start)
$helperStart=$source.IndexOf('func _edge_match(')
$helperEnd=$source.IndexOf('## A snapshot in the final regulation period', $helperStart)
$suite='extends GdUnitTestSuite' + "`n`n" + $source.Substring($start,$end-$start) + "`n" + $source.Substring($helperStart,$helperEnd-$helperStart)
[IO.File]::WriteAllText((Join-Path $isolated 'tests/simulation/test_upset_witness_mutant.gd'),$suite)
$original=[IO.File]::ReadAllText($enginePath)
$needle="`treturn MatchSession.new(input, random_source).run_to_completion()"
if (($original.Split([string[]]@($needle),[StringSplitOptions]::None).Count-1) -ne 1) { throw 'mutation not unique' }
$mutation=@'
	var output: MatchSimulationOutput = MatchSession.new(input, random_source).run_to_completion()
	var home_total: int = 0
	var away_total: int = 0
	for player: PlayerMatchProfile in input.home.players:
		for rating: int in player.attributes.canonical_values():
			home_total += rating
	for player: PlayerMatchProfile in input.away.players:
		for rating: int in player.attributes.canonical_values():
			away_total += rating
	var rerolls: int = 0
	while home_total > away_total and output.final_result.home_score < output.final_result.away_score:
		rerolls += 1
		assert(rerolls <= 64, "mutation reroll safety bound")
		output = MatchSession.new(input, random_source.derive(StringName("force_favorite:%d" % rerolls))).run_to_completion()
	return output
'@
$rows=@()
try {
 foreach ($arm in @('baseline','force_favorite_valid_ledger')) {
  if ($arm -ne 'baseline') { [IO.File]::WriteAllText($enginePath,$original.Replace($needle,$mutation)) }
  $log=Join-Path $PSScriptRoot ('upset_witness_' + $arm + '.log')
  & $GodotBin --headless --path $isolated -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/simulation/test_upset_witness_mutant.gd *> $log
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
@{engine_sha256=(Get-FileHash $enginePath).Hash;isolated_copy=$isolated;test_source_sha256=(Get-FileHash (Join-Path $repo 'tests/simulation/test_score_margin.gd')).Hash;results=$rows} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $PSScriptRoot 'upset_witness_mutation.json')
