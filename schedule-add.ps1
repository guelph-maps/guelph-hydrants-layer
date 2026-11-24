$taskName   = "kk-GuelphHydrantsLayer"
$projectDir = $PSScriptRoot
$logFile    = "$projectDir\logs\scheduler.log"

if (-not (Test-Path "$projectDir\logs")) {
    New-Item -ItemType Directory -Path "$projectDir\logs" | Out-Null
}

$action = New-ScheduledTaskAction `
    -Execute "cmd.exe" `
    -Argument "/c `"`"$projectDir\run-scheduled.cmd`" >> `"$logFile`" 2>&1`""

# Weekly is enough: the City's hydrant list changes slowly (+16 rows between the
# audit and its 2026-10-09 recalibration), and
# the City's service carries no edit date to poll anyway. The gap page is what
# actually moves week to week -- it diffs against live OSM. Fridays 16:30
# keeps this clear of guelph-bus-stops-layer's Thursday, guelph-buildings-layer's
# Wednesday, guelph-parks-layer's Tuesday and toronto-parks-layer's Monday
# slots, so none of them drive tippecanoe in the same WSL instance at once.
$trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At "16:30"
# Retries live in run-scheduled.cmd, not here: 'update' exits 75 when it sees no
# usable link, and 70 when no Overpass mirror answered and the gap page fell back
# to cached OSM (published first). The wrapper tries either again up to twice, half
# an hour apart, and the 3-hour limit leaves room for that. RestartCount covers only
# a launch that fails; Task Scheduler never re-runs on an exit code.
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 3) -StartWhenAvailable `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 30)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force

Write-Host "Scheduled '$taskName' to run weekly on Friday at 16:30."
Write-Host "Log: $logFile"
