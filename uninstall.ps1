$config = Get-Content -Path $($PSScriptRoot | Join-Path -ChildPath "config.json") | ConvertFrom-Json
$taskPath =$config.taskPath

Get-ScheduledTask -TaskPath $taskPath | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

$env:APPDATA | Join-Path -ChildPath $($PSScriptRoot | Split-Path -Leaf) | Get-Item -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

$schedule = New-Object -ComObject Schedule.Service
$schedule.connect()
$root = $schedule.GetFolder("\")
$root.DeleteFolder($taskPath.TrimStart("\").TrimEnd("\"), $null)
