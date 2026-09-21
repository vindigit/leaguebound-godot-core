param([Parameter(Mandatory=$true)][string]$GodotBin)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$meta=@()
foreach ($arm in @(@{label='baseline';ref='15225e8cab5fca2bca9dc2ea4757e2f9e74bbc87'},@{label='timing';ref='928ebcf'})) {
 $root=Join-Path ([IO.Path]::GetTempPath()) ('leaguebound-scoremargin-' + $arm.label + '-' + [Guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $root | Out-Null
 $zip=$root + '.zip'
 & git -C $repo archive --format=zip --output=$zip $arm.ref
 if ($LASTEXITCODE -ne 0) { throw 'archive failed' }
 Expand-Archive -LiteralPath $zip -DestinationPath $root
 $out=Join-Path $root 'analysis/timing_pace_followup'
 New-Item -ItemType Directory -Force -Path $out | Out-Null
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'audit_score_margin.gd') -Destination (Join-Path $out 'audit_score_margin.gd')
 & $GodotBin --headless --path $root --import *> (Join-Path $PSScriptRoot ('score_margin_' + $arm.label + '_import.log'))
 if ($LASTEXITCODE -ne 0) { throw 'import failed' }
 & $GodotBin --headless --path $root -s analysis/timing_pace_followup/audit_score_margin.gd -- --label=$($arm.label) --edges=5 --search=no *> (Join-Path $PSScriptRoot ('score_margin_' + $arm.label + '.log'))
 if ($LASTEXITCODE -ne 0) { throw 'audit failed' }
 Copy-Item -LiteralPath (Join-Path $out ('score_margin_' + $arm.label + '.json')) -Destination (Join-Path $PSScriptRoot ('score_margin_' + $arm.label + '.json'))
 $meta+=@{label=$arm.label;ref=$arm.ref;isolated_copy=$root}
}
$meta | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot 'score_margin_snapshot_provenance.json')
