# Launcher.ps1
# Parent process for the Photoshop watcher.
# - Starts Watcher.ps1 automatically.
# - Runs `git pull` periodically on the project repo.
# - Requests a graceful watcher restart when watcher source files change.
# - Restarts Watcher.ps1 if it crashes.
# - Designed to be started by Windows Task Scheduler at user logon.

$ErrorActionPreference = "Stop"

# Configuration
$RepoPath              = "C:\Users\milton\projects\opencode-personal-assistant-projects"
$WatcherDir            = Join-Path $RepoPath "hybrid-gaming-workstation\photoshop-watcher"
$WatcherPath           = Join-Path $WatcherDir "Watcher.ps1"
$ShutdownFlagPath      = "E:\CreativeBridge\watcher.shutdown"
$GitPullIntervalSeconds = 300   # Check for updates every 5 minutes
$LogFile               = Join-Path $env:TEMP "photoshop-watcher-launcher.log"

# Files to hash; if any change after a pull, request a graceful watcher restart
$WatchedFiles = @(
    Join-Path $WatcherDir "Watcher.ps1"
    Join-Path $WatcherDir "RunBatch.jsx"
    Join-Path $WatcherDir "RunBatch.jsx.template"
    Join-Path $WatcherDir "parse_atn.py"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [Launcher] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

function Test-GitAvailable {
    return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Invoke-GitPull {
    param([string]$Path)
    try {
        $output = git -C $Path pull 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Write-Log "git pull failed (exit $LASTEXITCODE): $output"
            return $false
        }
        if ($output -match "Already up to date|Already up-to-date") {
            return $false
        }
        Write-Log "git pull output: $output"
        return $true
    } catch {
        Write-Log "git pull exception: $_"
        return $false
    }
}

function Get-WatchedFilesHash {
    $hashes = foreach ($path in $WatchedFiles) {
        if (Test-Path $path) {
            (Get-FileHash -Path $path -Algorithm SHA256).Hash
        } else {
            "missing"
        }
    }
    return ($hashes -join "|")
}

function Request-GracefulShutdown {
    if (-not (Test-Path $ShutdownFlagPath)) {
        "shutdown requested" | Out-File -FilePath $ShutdownFlagPath -Encoding utf8 -Force
    }
}

function Clear-ShutdownFlag {
    if (Test-Path $ShutdownFlagPath) {
        Remove-Item -Path $ShutdownFlagPath -Force -ErrorAction SilentlyContinue
    }
}

function Start-WatcherProcess {
    Clear-ShutdownFlag

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName         = "powershell.exe"
    $psi.Arguments        = "-ExecutionPolicy Bypass -File `"$WatcherPath`""
    $psi.WorkingDirectory  = $WatcherDir
    $psi.UseShellExecute    = $false
    $psi.CreateNoWindow     = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true

    $proc = [System.Diagnostics.Process]::Start($psi)

    # Forward watcher stdout/stderr to the launcher log so everything is in one place
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    $proc.add_OutputDataReceived({
        param($sender, $e)
        if ($e.Data) { Write-Log "[Watcher] $($e.Data)" }
    })
    $proc.add_ErrorDataReceived({
        param($sender, $e)
        if ($e.Data) { Write-Log "[Watcher ERR] $($e.Data)" }
    })

    return $proc
}

function Stop-WatcherGracefully {
    param([System.Diagnostics.Process]$Proc)

    if (-not $Proc -or $Proc.HasExited) {
        return $true
    }

    Write-Log "Requesting graceful shutdown for watcher (PID $($Proc.Id))"
    Request-GracefulShutdown

    # Wait up to 30 minutes for the watcher to finish its current batch and exit.
    # This can take a long time if Photoshop is processing many files.
    $maxWaitSeconds = 1800
    $waited = 0
    while (-not $Proc.HasExited -and $waited -lt $maxWaitSeconds) {
        Start-Sleep -Seconds 5
        $waited += 5
    }

    if (-not $Proc.HasExited) {
        Write-Log "Watcher did not exit gracefully within $maxWaitSeconds seconds; forcing termination"
        try {
            $Proc.Kill()
            $Proc.WaitForExit(5000)
        } catch {
            Write-Log "Could not force-kill watcher: $_"
        }
        return $false
    }

    Write-Log "Watcher exited gracefully"
    return $true
}

# --- Main loop ---
Write-Log "Launcher started"
Write-Log "Repo: $RepoPath"
Write-Log "Watcher: $WatcherPath"
Write-Log "Shutdown flag: $ShutdownFlagPath"

if (-not (Test-Path $RepoPath)) {
    Write-Log "ERROR: Repo path does not exist: $RepoPath"
    exit 1
}

if (-not (Test-Path $WatcherPath)) {
    Write-Log "ERROR: Watcher script does not exist: $WatcherPath"
    exit 1
}

if (-not (Test-GitAvailable)) {
    Write-Log "ERROR: git is not available on PATH"
    exit 1
}

$currentWatcher = $null
$currentFilesHash = $null
$firstRun = $true

while ($true) {
    try {
        $pulledChanges = Invoke-GitPull -Path $RepoPath
        $newFilesHash = Get-WatchedFilesHash

        $needsRestart = $false
        if ($firstRun) {
            Write-Log "First run: starting watcher"
            $needsRestart = $true
            $firstRun = $false
        } elseif ($pulledChanges) {
            Write-Log "Git pull reported changes"
            $needsRestart = $true
        } elseif ($currentFilesHash -and $newFilesHash -ne $currentFilesHash) {
            Write-Log "Watched watcher files changed (local edit or pull)"
            $needsRestart = $true
        }

        if ($needsRestart) {
            if ($currentWatcher -and -not $currentWatcher.HasExited) {
                Stop-WatcherGracefully -Proc $currentWatcher
            }

            Write-Log "Starting watcher"
            $currentWatcher = Start-WatcherProcess
            $currentFilesHash = $newFilesHash
        }

        if ($currentWatcher -and $currentWatcher.HasExited) {
            Write-Log "Watcher process exited unexpectedly (exit code $($currentWatcher.ExitCode)). Restarting."
            $currentWatcher = Start-WatcherProcess
            $currentFilesHash = Get-WatchedFilesHash
        }
    } catch {
        Write-Log "ERROR in main loop: $_"
    }

    Start-Sleep -Seconds $GitPullIntervalSeconds
}
