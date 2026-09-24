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
$GitPullIntervalSeconds = 20    # Check for updates every 20 seconds (testing)
$LogFile               = Join-Path $env:TEMP "photoshop-watcher-launcher.log"

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

function Get-LocalHeadHash {
    param([string]$Path)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "git"
        $psi.Arguments = "-C `"$Path`" rev-parse HEAD"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $Path

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd().Trim()
        $stderr = $proc.StandardError.ReadToEnd().Trim()
        $proc.WaitForExit()

        if ($proc.ExitCode -ne 0) {
            Write-Log "git rev-parse failed: $stderr"
            return $null
        }
        return $stdout
    } catch {
        Write-Log "git rev-parse exception: $_"
        return $null
    }
}

function Get-RemoteHeadHash {
    param([string]$Path)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "git"
        $psi.Arguments = "-C `"$Path`" ls-remote origin HEAD"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $Path

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd().Trim()
        $stderr = $proc.StandardError.ReadToEnd().Trim()
        $proc.WaitForExit()

        if ($proc.ExitCode -ne 0) {
            Write-Log "git ls-remote failed: $stderr"
            return $null
        }
        # Output format: "<hash>\tHEAD"
        return ($stdout -split "\s+")[0]
    } catch {
        Write-Log "git ls-remote exception: $_"
        return $null
    }
}

function Test-UpdateAvailable {
    param([string]$Path)
    $localHash = Get-LocalHeadHash -Path $Path
    $remoteHash = Get-RemoteHeadHash -Path $Path

    if (-not $localHash -or -not $remoteHash) {
        Write-Log "Could not compare hashes; assuming no update"
        return $false
    }

    if ($localHash -eq $remoteHash) {
        return $false
    }

    Write-Log "Update available: local $localHash -> remote $remoteHash"
    return $true
}

function Invoke-GitPull {
    param([string]$Path)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "git"
        $psi.Arguments = "-C `"$Path`" pull"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $Path

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd().Trim()
        $stderr = $proc.StandardError.ReadToEnd().Trim()
        $proc.WaitForExit()

        $output = ($stdout + "`n" + $stderr).Trim()
        if ($proc.ExitCode -ne 0) {
            Write-Log "git pull failed (exit $($proc.ExitCode)): $output"
            return $false
        }
        if ($output) {
            Write-Log "git pull output: $output"
        }
        return $true
    } catch {
        Write-Log "git pull exception: $_"
        return $false
    }
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
    $psi.Arguments        = "-ExecutionPolicy Bypass -NoProfile -File `"$WatcherPath`""
    $psi.WorkingDirectory  = $WatcherDir
    $psi.UseShellExecute    = $false
    $psi.CreateNoWindow     = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true

    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
    } catch {
        Write-Log "ERROR: Failed to start watcher process: $_"
        return $null
    }

    Write-Log "Watcher process started with PID $($proc.Id)"

    # Wait a moment and capture an early crash (syntax errors, missing path, etc.)
    Start-Sleep -Seconds 3
    if ($proc.HasExited) {
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        Write-Log "ERROR: Watcher exited immediately (exit code $($proc.ExitCode))"
        if ($stdout) { Write-Log "Watcher stdout: $stdout" }
        if ($stderr) { Write-Log "Watcher stderr: $stderr" }
        return $null
    }

    # Forward watcher stdout/stderr to the launcher log so everything is in one place
    $proc.add_OutputDataReceived({
        param($sender, $e)
        if ($e.Data) { Write-Log "[Watcher] $($e.Data)" }
    })
    $proc.add_ErrorDataReceived({
        param($sender, $e)
        if ($e.Data) { Write-Log "[Watcher ERR] $($e.Data)" }
    })

    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    Write-Log "Watcher is running and output is being forwarded"
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
$firstRun = $true

while ($true) {
    try {
        $updateAvailable = Test-UpdateAvailable -Path $RepoPath
        $pulledChanges = $false

        $needsRestart = $false
        if ($firstRun) {
            Write-Log "First run: starting watcher"
            $needsRestart = $true
            $firstRun = $false
        } elseif ($updateAvailable) {
            Write-Log "Remote repo has new commits; pulling"
            $pulledChanges = Invoke-GitPull -Path $RepoPath
            if (-not $pulledChanges) {
                Write-Log "git pull did not apply changes; will retry next cycle"
            }
            $needsRestart = $pulledChanges
        }

        if ($needsRestart) {
            if ($currentWatcher -and -not $currentWatcher.HasExited) {
                Stop-WatcherGracefully -Proc $currentWatcher
            }

            Write-Log "Starting watcher"
            $currentWatcher = Start-WatcherProcess
            if (-not $currentWatcher) {
                Write-Log "ERROR: Watcher did not start; will retry on next cycle"
            }
        }

        if ($currentWatcher -and $currentWatcher.HasExited) {
            Write-Log "Watcher process exited unexpectedly (exit code $($currentWatcher.ExitCode)). Restarting."
            $currentWatcher = Start-WatcherProcess
        }
    } catch {
        Write-Log "ERROR in main loop: $_"
        Write-Log "Stack: $($_.ScriptStackTrace)"
    }

    Start-Sleep -Seconds $GitPullIntervalSeconds
}
