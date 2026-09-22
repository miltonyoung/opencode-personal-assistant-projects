# Watcher.ps1
# Monitors E:\CreativeBridge\photoshop-projects\ for projects with .atn files and unprocessed images.
# Processes images in batches of $MaxBatchSize, then restarts Photoshop to release memory.

$RootFolder = "E:\CreativeBridge\photoshop-projects"
$MaxBatchSize = 10
$PollIntervalSeconds = 30
$PhotoshopExe = "C:\Program Files\Adobe\Adobe Photoshop 2026\Photoshop.exe"
$RunBatchTemplate = "C:\Users\milton\projects\opencode-personal-assistant-projects\hybrid-gaming-workstation\photoshop-watcher\RunBatch.jsx.template"
$TempJsxFolder = Join-Path $env:TEMP "photoshop-watcher"

New-Item -ItemType Directory -Path $TempJsxFolder -Force | Out-Null

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

    # Wait up to 30 minutes for this batch to complete
    $timeoutSeconds = 1800
    $exited = $proc.WaitForExit($timeoutSeconds * 1000)
    if (-not $exited) {
        Write-Log -Project $projectName -Message "WARNING: Photoshop did not exit within timeout; forcing close"
        $proc.Kill()
        $proc.WaitForExit(5000)
    }

    # Ensure Photoshop process is gone even if ExtendScript quit failed
    Start-Sleep -Seconds 2
    $photoshopProcesses = Get-Process -Name "Photoshop" -ErrorAction SilentlyContinue
    if ($photoshopProcesses) {
        foreach ($psProc in $photoshopProcesses) {
            try {
                $psProc.Kill()
                $psProc.WaitForExit(5000)
                Write-Log -Project $projectName -Message "Force-closed lingering Photoshop process"
            } catch {
                Write-Log -Project $projectName -Message "Could not force-close Photoshop: $_"
            }
        }
    }

    # After Photoshop exits, verify outputs and move source files
    foreach ($sourcePath in $FilesToProcess) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($sourcePath)
        $outputPath = Join-Path $processedFolder "$fileName.jpg"

        if (Test-Path $outputPath) {
            # Move source to images\done
            $destination = Join-Path $doneFolder ([System.IO.Path]::GetFileName($sourcePath))
            Move-Item -Path $sourcePath -Destination $destination -Force
            Write-Log -Project $projectName -Message "Processed and moved to done: $fileName"
        } else {
            # Move source to failed
            $destination = Join-Path $failedFolder ([System.IO.Path]::GetFileName($sourcePath))
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

    # Find files in images\ that are not already in done\ or failed\
    $allImages = Get-ChildItem -Path $imagesFolder -File | Where-Object {
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
