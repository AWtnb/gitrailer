param(
    [string][parameter(Mandatory)]$root
)

function pull {
    Get-ChildItem -Path $root -Directory | Where-Object {
        $p = ($_.FullName | Join-Path -ChildPath ".git")
        return (Test-Path $p -PathType Container)
    } | ForEach-Object {

        Push-Location $_.FullName
        "Updating repository: {0}" -f $_.Name | Write-Host -ForegroundColor Yellow

        $status = git status --porcelain --branch 2>$null
        if ($status -match "\[ahead \d+\]") {
            "Repository '{0}' has unpushed commits!" -f $_.Name | Write-Host -ForegroundColor Red -NoNewline
            "==> skipped." | Write-Host
        }
        else {
            git pull
        }

        Pop-Location
    }
}

if ($root -and (Test-Path $root -PathType Container)) {
    pull
}
else {
    "Usage: pull.ps1 <path-to-root-directory>" | Write-Host -ForegroundColor Red
    exit 1
}