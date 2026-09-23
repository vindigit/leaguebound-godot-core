$ErrorActionPreference = 'Stop'
$out = $PSScriptRoot
$events = Join-Path $out 'resource_priority_events.jsonl'
$resumeResult = Join-Path $out 'resume_result.json'
$gateResult = Join-Path $out 'full_gate_v3_result.json'
$cutoff = [datetime]'2026-09-23T16:52:00'
# This watcher itself is pinned to the other four logical processors, so the
# process-visible count is four even though the host has eight.
if ([Environment]::ProcessorCount -lt 4) { throw 'Insufficient watcher processors' }
if (Test-Path -LiteralPath $events) { throw 'Priority event archive already exists' }
while (-not ((Test-Path -LiteralPath $resumeResult) -and (Test-Path -LiteralPath $gateResult))) {
    foreach ($p in @(Get-Process -Name 'Godot_v4.7.1-stable_win64' -ErrorAction SilentlyContinue)) {
        try {
            if ($p.StartTime -lt $cutoff -or $p.ProcessorAffinity.ToInt64() -ne 240 -or
                $p.PriorityClass -eq [System.Diagnostics.ProcessPriorityClass]::High) { continue }
            $before = $p.PriorityClass.ToString()
            $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
            [pscustomobject]@{
                recorded_utc = (Get-Date).ToUniversalTime().ToString('o')
                process_id = $p.Id
                previous_priority = $before
                new_priority = 'High'
                affinity_hex = 'F0'
                reason = 'LeagueBound child inherits bounded affinity but native launcher resets priority'
            } | ConvertTo-Json -Compress | Add-Content -LiteralPath $events -Encoding utf8
        } catch [System.InvalidOperationException] {
            # A child can finish between enumeration and inspection.
        }
    }
    Start-Sleep -Seconds 5
}
