$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$head = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot identify gate start head' }
$log = Join-Path $PSScriptRoot 'full_gate_v3.txt'
$result = Join-Path $PSScriptRoot 'full_gate_v3_result.json'
if ((Test-Path -LiteralPath $log) -or (Test-Path -LiteralPath $result)) {
    throw 'Fresh gate outputs already exist'
}
$env:GODOT_BIN = 'C:\Users\valexander\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$bash = 'C:\Program Files\Git\bin\bash.exe'
$started = (Get-Date).ToUniversalTime().ToString('o')
$exit = -1
try {
    & $bash tools/run_checks.sh *> $log
    $exit = $LASTEXITCODE
} finally {
    [ordered]@{
        head = $head
        started_utc = $started
        completed_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exit
        scope = 'Fresh complete eight-step run after interrupted v2; no partial-step substitution'
    } | ConvertTo-Json | Set-Content -LiteralPath $result -Encoding utf8
}
exit $exit
