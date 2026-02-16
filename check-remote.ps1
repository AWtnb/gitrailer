<#

Not works on PowerShell 6+.


About toast:

- https://qiita.com/relu/items/b7121487a1d5756dfcf9

About Exit:

- https://stackoverflow.com/questions/73584403/
- https://www.intellilink.co.jp/column/ms/2022/032300.aspx
- https://www.intellilink.co.jp/column/ms/2022/063000.aspx

#>

param([parameter(Mandatory)]$reposDir)

$xml = @"
<toast scenario="incomingCall">
  <visual>
    <binding template="ToastGeneric">
      <text id="1"></text>
      <text id="2"></text>
    </binding>
  </visual>
</toast>
"@

function Invoke-Toast{
    param (
        [parameter(ValueFromPipeline = $true)][string]$message,
        [string]$title,
        [string]$emojiCodepoint = "",
        [switch]$ephemeral
    )
    if ($emojiCodepoint) {
        $title = $title + " " + [System.Char]::ConvertFromUtf32([System.Convert]::toInt32($emojiCodepoint, 16))
    }
    $xmlDoc = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
    $xmlDoc.loadXml($xml)
    if ($ephemeral) {
        $xmlDoc.documentElement.removeAttribute("scenario")
    }
    $xmlDoc.selectSingleNode('//text[@id="1"]').InnerText = $title
    $xmlDoc.selectSingleNode('//text[@id="2"]').InnerText = $message
    $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($appId).Show($xmlDoc)
}

if (-not $reposDir) {
    "Directory path to check is not specified." -f $reposDir | Invoke-Toast -title "ERROR!" -emojiCodepoint "1F525"
    [System.Environment]::exit(1)
}

if (-not (Test-Path $reposDir -PathType Container)) {
    "``{0}`` not found..." -f $reposDir | Invoke-Toast -title "ERROR!" -emojiCodepoint "1F525"
    [System.Environment]::Exit(1)
}

if (-not (Get-Command git -ErrorAction SilentlyContinue).Source) {
    "Git not found on this PC." -f $reposDir | Invoke-Toast -title "ERROR!" -emojiCodepoint "1F525"
    [System.Environment]::exit(1)
}

$behind = @()
$failed = @()

Get-ChildItem -Path $reposDir -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $repoName = $_.Name

    if (Test-Path (Join-Path $repoPath ".git") -PathType Container) {

        "Checking " | Write-Host -NoNewline
        $repoName | Write-Host -BackgroundColor Yellow -ForegroundColor Black
        "==> " | Write-Host -NoNewline

        Push-Location $repoPath
        try {
            git fetch --quiet 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to fetch from remote."
            }
            $status = git status --porcelain --branch 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to get status."
            }
            if ($status -match "\[behind\s+\d+\]$") {
                "update available: {0}" -f $status | Write-Host -ForegroundColor Green
                $behind += [PSCustomObject]@{
                    Repo   = $repoName;
                    Status = $status -replace ".+(\[behind)", '$1';
                }
            }
            else {
                "up-to-date!" | Write-Host -ForegroundColor Cyan
            }
        }
        catch {
            "failed! {0}" -f $_ | Write-Host -ForegroundColor Magenta
            $failed += [PSCustomObject]@{
                Message = $_;
                Repo    = $repoName;
            }
        }
        finally {
            Pop-Location
        }
    }
}

if ($failed.Count -gt 0) {
    $failed | Group-Object -Property Message | ForEach-Object {
        $title = "ERROR! {0}" -f $_.Name
        ($_.Group.Repo | ForEach-Object {"[{0}]" -f $_}) -join ", " | Invoke-Toast -title $title -emojiCodepoint "1F525"
    }
    [System.Environment]::Exit(1)
}


if ($behind.Count -gt 0) {
    ($behind | ForEach-Object {
        return "``{0}`` {1}" -f $_.Repo, $_.Status
    }) -join ", " | Invoke-Toast -title "Update available!" -emojiCodepoint "1F9F2"
}
else {
    "`nAll repos are up-to-date!" | Write-Host -ForegroundColor Black -BackgroundColor White
}

[System.Environment]::Exit(0)
