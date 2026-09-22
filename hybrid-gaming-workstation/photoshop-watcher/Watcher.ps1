# Watcher.ps1
# Monitors E:\CreativeBridge\photoshop-projects\ for projects with .atn files and unprocessed images.
# Processes images in batches of $MaxBatchSize, then restarts Photoshop to release memory.

$RootFolder = "E:\CreativeBridge\photoshop-projects"
$MaxBatchSize = 3
$PollIntervalSeconds = 30
$PhotoshopExe = "C:\Program Files\Adobe\Adobe Photoshop 2026\Photoshop.exe"
$RunBatchTemplate = "C:\Users\milton\projects\opencode-personal-assistant-projects\hybrid-gaming-workstation\photoshop-watcher\RunBatch.jsx.template"
$TempJsxFolder = Join-Path $env:TEMP "photoshop-watcher"
$FileSizeStableSeconds = 10

New-Item -ItemType Directory -Path $TempJsxFolder -Force | Out-Null

# Global tracker for file-size stability (copy completion detection)
# Key: file path. Value: @{ Size = N; FirstSeenAtSize = DateTime }
$global:FileSizeTracker = @{}

function Write-Log {
    param(
        [string]$Project,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [$Project] $Message"
    Write-Host $line
    Add-Content -Path "$RootFolder\watcher.log" -Value $line -ErrorAction SilentlyContinue
}

function Get-ActionDetails {
    param([string]$ProjectFolder)

    $actionFiles = Get-ChildItem -Path $ProjectFolder -Filter "*.atn" -File
    if ($actionFiles.Count -eq 0) {
        return $null
    }
    if ($actionFiles.Count -gt 1) {
        Write-Log -Project (Split-Path $ProjectFolder -Leaf) -Message "WARNING: Multiple .atn files found. Using first: $($actionFiles[0].Name)"
    }

    $configPath = Join-Path $ProjectFolder "action-config.json"
    $actionSetName = $actionFiles[0].BaseName
    $actionName = ""

    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.actionSet) { $actionSetName = $config.actionSet }
            if ($config.actionName) { $actionName = $config.actionName }
            Write-Log -Project (Split-Path $ProjectFolder -Leaf) -Message "Loaded action config: $actionSetName / $actionName"
        } catch {
            Write-Log -Project (Split-Path $ProjectFolder -Leaf) -Message "ERROR reading action-config.json: $_"
        }
    }

    if (-not $actionName) {
        $actionName = Get-FirstActionName -AtnPath $actionFiles[0].FullName
    }

    return @{
        ActionFile = $actionFiles[0].FullName
        ActionSet  = $actionSetName
        ActionName = $actionName
    }
}

function Get-FirstActionName {
    param([string]$AtnPath)

    # Read .atn file as binary/string and look for action names.
    # .atn files contain Pascal-style strings. We look for the first human-readable
    # action name after the action set header. This is heuristic.
    $bytes = [System.IO.File]::ReadAllBytes($AtnPath)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)

    # Find the first occurrence of a pattern that looks like an action name.
    # Action names appear after the set name and after some binary markers.
    # Heuristic: split on non-printable characters and take the longest plausible strings.
    $matches = [regex]::Matches($text, '[\x20-\x7E]{4,64}')
    $candidates = $matches | ForEach-Object { $_.Value } | Where-Object { $_ -notmatch '^[\s\d\-\.]+$' }

    if ($candidates.Count -gt 0) {
        # The set name is usually the first long string, the action name is the second.
        # Return the second candidate if available.
        if ($candidates.Count -gt 1) {
            return $candidates[1]
        }
        return $candidates[0]
    }

    return ""
}

function ConvertTo-JsString {
    param([string]$Value)
    # Escape backslashes and double quotes for JavaScript string literals
    return ($Value -replace '\\', '\\' -replace '"', '\"')
}

function Test-FileReady {
    param([string]$Path)
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

function Test-FileSizeStable {
    param([string]$Path)

    $file = Get-Item -Path $Path
    $size = $file.Length

    # Never process zero-byte placeholder files
    if ($size -eq 0) {
        return $false
    }

    $now = Get-Date
    if (-not $global:FileSizeTracker.ContainsKey($Path)) {
        $global:FileSizeTracker[$Path] = @{
            Size = $size
            FirstSeenAtSize = $now
        }
        Write-Log -Project (Split-Path (Split-Path $Path -Parent) -Leaf) -Message "Tracking $($file.Name): size = $size bytes"
        return $false
    }

    $tracker = $global:FileSizeTracker[$Path]
    if ($tracker.Size -ne $size) {
        $tracker.Size = $size
        $tracker.FirstSeenAtSize = $now
        Write-Log -Project (Split-Path (Split-Path $Path -Parent) -Leaf) -Message "Size changed for $($file.Name): $size bytes; resetting stability timer"
        return $false
    }

    $stableFor = ($now - $tracker.FirstSeenAtSize).TotalSeconds
    if ($stableFor -lt $FileSizeStableSeconds) {
        Write-Log -Project (Split-Path (Split-Path $Path -Parent) -Leaf) -Message "Size stable for $([int]$stableFor)s for $($file.Name); waiting for $FileSizeStableSeconds`s"
        return $false
    }

    Write-Log -Project (Split-Path (Split-Path $Path -Parent) -Leaf) -Message "Size stable for $([int]$stableFor)s for $($file.Name); ready to process"
    return $true
}

function Wait-ForBatchCompletion {
    param(
        [string]$LogFile,
        [int]$TimeoutSeconds = 1800,
        [int]$StartLineCount = 0
    )

    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSeconds) {
        if (Test-Path $LogFile) {
            $lines = Get-Content -Path $LogFile
            if ($lines.Count -gt $StartLineCount) {
                $newLines = $lines | Select-Object -Skip $StartLineCount
                foreach ($line in $newLines) {
                    if ($line -match 'Processed: \d+, Successful: \d+, Failed: \d+') {
                        return $true
                    }
                }
            }
        }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Close-Photoshop {
    param([string]$ProjectName)

    Write-Log -Project $ProjectName -Message "Closing Photoshop now"
    Start-Sleep -Seconds 2
    $photoshopProcesses = Get-Process -Name "Photoshop" -ErrorAction SilentlyContinue
    if ($photoshopProcesses) {
        foreach ($psProc in $photoshopProcesses) {
            try {
                $psProc.CloseMainWindow() | Out-Null
                $closed = $psProc.WaitForExit(5000)
                if (-not $closed) {
                    $psProc.Kill()
                    $psProc.WaitForExit(5000)
                    Write-Log -Project $ProjectName -Message "Force-killed lingering Photoshop process"
                } else {
                    Write-Log -Project $ProjectName -Message "Gracefully closed Photoshop"
                }
            } catch {
                Write-Log -Project $ProjectName -Message "Could not close Photoshop: $_"
            }
        }
    } else {
        Write-Log -Project $ProjectName -Message "No Photoshop process found to close"
    }
}

function Invoke-PhotoshopBatch {
    param(
        [string]$ProjectFolder,
        [array]$FilesToProcess,
        [hashtable]$ActionDetails
    )

    $projectName = Split-Path $ProjectFolder -Leaf
    $processedFolder = Join-Path $ProjectFolder "processed"
    $failedFolder = Join-Path $ProjectFolder "failed"
    $doneFolder = Join-Path $ProjectFolder "images\done"
    $logFile = Join-Path $ProjectFolder "batch.log"

    New-Item -ItemType Directory -Path $processedFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $failedFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $doneFolder -Force | Out-Null

    # Capture starting log line count so we can detect a fresh completion summary
    $startLineCount = 0
    if (Test-Path $logFile) {
        $startLineCount = (Get-Content -Path $logFile).Count
        Write-Log -Project $projectName -Message "Existing batch.log has $startLineCount lines; watching for fresh summary after line $startLineCount"
    }

    # Build JavaScript string for source files array
    $jsSourceFiles = ($FilesToProcess | ForEach-Object { '"' + (ConvertTo-JsString $_) + '"' }) -join ", "

    # Generate temporary JSX file with literal argument values
    $template = Get-Content -Path $RunBatchTemplate -Raw
    $jsxContent = $template `
        -replace "<<ACTION_FILE>>", (ConvertTo-JsString $ActionDetails.ActionFile) `
        -replace "<<ACTION_SET>>", (ConvertTo-JsString $ActionDetails.ActionSet) `
        -replace "<<ACTION_NAME>>", (ConvertTo-JsString $ActionDetails.ActionName) `
        -replace "<<OUTPUT_FOLDER>>", (ConvertTo-JsString $processedFolder) `
        -replace "<<JPEG_QUALITY>>", 12 `
        -replace "<<LOG_FILE>>", (ConvertTo-JsString $logFile) `
        -replace "<<SOURCE_FILES_ARRAY>>", $jsSourceFiles

    $tempJsxPath = Join-Path $TempJsxFolder "RunBatch-$projectName-$(Get-Date -Format 'yyyyMMddHHmmssfff').jsx"
    $jsxContent | Out-File -FilePath $tempJsxPath -Encoding UTF8

    Write-Log -Project $projectName -Message "Starting batch of $($FilesToProcess.Count) files"
    Write-Log -Project $projectName -Message "Using action: $($ActionDetails.ActionSet) / $($ActionDetails.ActionName)"
    Write-Log -Project $projectName -Message "Generated temp JSX: $tempJsxPath"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PhotoshopExe
    $psi.Arguments = "-r `"$tempJsxPath`""
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = (Split-Path $PhotoshopExe)

    $proc = [System.Diagnostics.Process]::Start($psi)

    # Wait for the batch script to log its fresh summary line, then close Photoshop
    $completed = Wait-ForBatchCompletion -LogFile $logFile -TimeoutSeconds 1800 -StartLineCount $startLineCount
    if (-not $completed) {
        Write-Log -Project $projectName -Message "WARNING: Batch did not report completion within timeout"
    } else {
        Write-Log -Project $projectName -Message "Batch completion detected in batch.log"
    }

    Close-Photoshop -ProjectName $projectName

    # After Photoshop exits, verify outputs and move source files
    foreach ($sourcePath in $FilesToProcess) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($sourcePath)
        $sourceFileName = [System.IO.Path]::GetFileName($sourcePath)
        $outputPath = Join-Path $processedFolder "$fileName.jpg"

        if (Test-Path $outputPath) {
            Write-Log -Project $projectName -Message "Output file created: $outputPath"
            # Move source to images\done
            $destination = Join-Path $doneFolder $sourceFileName
            Write-Log -Project $projectName -Message "Moving source file to done: $sourceFileName -> $destination"
            Move-Item -Path $sourcePath -Destination $destination -Force
            Write-Log -Project $projectName -Message "Processed and moved to done: $fileName"
        } else {
            Write-Log -Project $projectName -Message "Output file missing: $outputPath"
            # Move source to failed
            $destination = Join-Path $failedFolder $sourceFileName
            Write-Log -Project $projectName -Message "Moving source file to failed: $sourceFileName -> $destination"
            Move-Item -Path $sourcePath -Destination $destination -Force
            Write-Log -Project $projectName -Message "FAILED: $fileName (output missing)"
        }
    }
}

function Process-Project {
    param([string]$ProjectFolder)

    $projectName = Split-Path $ProjectFolder -Leaf
    $imagesFolder = Join-Path $ProjectFolder "images"
    $doneFolder = Join-Path $imagesFolder "done"

    if (-not (Test-Path $imagesFolder)) {
        return
    }

    New-Item -ItemType Directory -Path $doneFolder -Force | Out-Null

    # Find files in images\ that are not already in done\ or failed\, excluding sidecars like .xmp
    $excludedExtensions = @('.xmp')
    $allImages = Get-ChildItem -Path $imagesFolder -File | Where-Object {
        $ext = $_.Extension.ToLower()
        if ($ext -in $excludedExtensions) { return $false }

        # Skip placeholder files and files that are still copying
        if (-not (Test-FileSizeStable -Path $_.FullName)) {
            return $false
        }

        # Skip files that are still locked
        if (-not (Test-FileReady -Path $_.FullName)) {
            Write-Log -Project $projectName -Message "Skipping $($_.Name): file is currently locked"
            return $false
        }

        $donePath = Join-Path $doneFolder $_.Name
        $failedPath = Join-Path (Join-Path $ProjectFolder "failed") $_.Name
        -not (Test-Path $donePath) -and -not (Test-Path $failedPath)
    } | Select-Object -ExpandProperty FullName

    if ($allImages.Count -eq 0) {
        return
    }

    $actionDetails = Get-ActionDetails -ProjectFolder $ProjectFolder
    if (-not $actionDetails -or -not $actionDetails.ActionName) {
        Write-Log -Project $projectName -Message "ERROR: Could not determine action name from .atn file"
        return
    }

    Write-Log -Project $projectName -Message "Found $($allImages.Count) unprocessed file(s)"

    while ($allImages.Count -gt 0) {
        $batch = $allImages | Select-Object -First $MaxBatchSize
        $allImages = $allImages | Select-Object -Skip $MaxBatchSize

        Invoke-PhotoshopBatch -ProjectFolder $ProjectFolder -FilesToProcess $batch -ActionDetails $actionDetails

        if ($allImages.Count -gt 0) {
            Write-Log -Project $projectName -Message "$($allImages.Count) file(s) remaining; restarting Photoshop after brief pause"
            Start-Sleep -Seconds 5
            # Ensure Photoshop is fully gone before starting the next batch
            Close-Photoshop -ProjectName $projectName
            Start-Sleep -Seconds 10
            $stillRunning = Get-Process -Name "Photoshop" -ErrorAction SilentlyContinue
            if ($stillRunning) {
                Write-Log -Project $projectName -Message "Photoshop still running after close; waiting additional 15 seconds"
                Start-Sleep -Seconds 15
                Close-Photoshop -ProjectName $projectName
            }
        }
    }
}

# Main loop
Write-Log -Project "Watcher" -Message "Started monitoring $RootFolder"

while ($true) {
    try {
        if (Test-Path $RootFolder) {
            $projects = Get-ChildItem -Path $RootFolder -Directory
            foreach ($project in $projects) {
                Process-Project -ProjectFolder $project.FullName
            }
        } else {
            Write-Log -Project "Watcher" -Message "ERROR: Root folder does not exist: $RootFolder"
        }
    } catch {
        Write-Log -Project "Watcher" -Message "ERROR in main loop: $_"
    }

    Start-Sleep -Seconds $PollIntervalSeconds
}
