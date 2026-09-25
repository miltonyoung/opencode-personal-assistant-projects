# Tail-Logs.ps1
# Opens the Photoshop watcher and launcher logs in separate PowerShell windows
# for live tailing.

$WatcherLog = "E:\CreativeBridge\photoshop-projects\watcher.log"
$LauncherLog = Join-Path $env:TEMP "photoshop-watcher-launcher.log"

function Start-TailWindow {
    param(
        [string]$Title,
        [string]$LogPath
    )
    if (-not (Test-Path $LogPath)) {
        try {
            New-Item -ItemType File -Path $LogPath -Force | Out-Null
        } catch {
            Write-Warning "Could not create log file at $LogPath : $_"
        }
    }

    $command = "Get-Content -Path '$LogPath' -Tail 30 -Wait"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "$command" -WindowStyle Normal
}

Write-Host "Opening log tail windows..."
Write-Host "Watcher log: $WatcherLog"
Write-Host "Launcher log: $LauncherLog"

Start-TailWindow -Title "Watcher Log" -LogPath $WatcherLog
Start-TailWindow -Title "Launcher Log" -LogPath $LauncherLog
