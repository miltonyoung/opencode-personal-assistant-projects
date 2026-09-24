# Setup: Photoshop Watcher Autostart with Git Auto-Pull

## How it works

1. A Windows Task Scheduler task named `PhotoshopWatcher-Launcher` runs at user
   logon.
2. `Launcher.ps1` stays alive, pulls the latest `opencode-personal-assistant-projects`
   repo every 5 minutes, and restarts `Watcher.ps1` whenever the watcher source
   files change.
3. `Watcher.ps1` monitors `E:\CreativeBridge\photoshop-projects` and runs
   Photoshop batches.

---

## Step 1: Make sure the project repo path is correct

`Launcher.ps1` assumes the repo is at:

```
C:\Users\milton\projects\opencode-personal-assistant-projects
```

If your repo is somewhere else, edit the `$RepoPath` variable at the top of
`Launcher.ps1` before creating the scheduled task.

---

## Step 2: Create the Windows Task Scheduler task

### Option A: Run at user logon (recommended)

This is the safest choice because Photoshop and the watcher run under your
normal user profile, which has access to your Adobe installation and
`E:\CreativeBridge`.

Open PowerShell **as your normal user** (not Administrator) and run:

```powershell
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Users\milton\projects\opencode-personal-assistant-projects\hybrid-gaming-workstation\photoshop-watcher\Launcher.ps1"

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName "PhotoshopWatcher-Launcher" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

# Start now to test
Start-ScheduledTask -TaskName "PhotoshopWatcher-Launcher"
```

### Option B: Run at system startup as a service

Not recommended because Photoshop needs an interactive user session and GUI.
Only choose this if you have auto-login enabled and a real display session.

---

## Step 3: Verify the launcher is running

After starting the task, check Task Manager for:

- `powershell.exe` running `Launcher.ps1`
- A child `powershell.exe` running `Watcher.ps1`

Also check the launcher log:

```powershell
Get-Content $env:TEMP\photoshop-watcher-launcher.log -Tail 20
```

You should see entries like:

```
2026-09-23 17:00:00 [Launcher] First run: starting watcher
2026-09-23 17:00:00 [Launcher] Starting watcher
2026-09-23 17:05:00 [Launcher] git pull output: Already up to date.
```

---

## Step 4: Test the auto-pull / auto-restart behavior

1. Note the current watcher process ID in Task Manager.
2. From another machine, push a small change to
   `opencode-personal-assistant-projects/hybrid-gaming-workstation/photoshop-watcher/Watcher.ps1`
   (for example, change the `$PollIntervalSeconds` value).
3. Within 5 minutes, the launcher should:
   - detect the git change,
   - stop the old watcher process,
   - start a new watcher process with the updated code.
4. Verify in Task Manager that the watcher PID changed.

If you do not want to wait 5 minutes, temporarily edit a watched file locally
on the PC and the launcher will restart the watcher within the next poll cycle.

---

## Operational commands

```powershell
# Start
Start-ScheduledTask -TaskName "PhotoshopWatcher-Launcher"

# Stop
Stop-ScheduledTask -TaskName "PhotoshopWatcher-Launcher"

# View status
Get-ScheduledTask -TaskName "PhotoshopWatcher-Launcher"

# View recent launcher log
Get-Content $env:TEMP\photoshop-watcher-launcher.log -Tail 30

# Unregister
Unregister-ScheduledTask -TaskName "PhotoshopWatcher-Launcher" -Confirm:$false
```

---

## Notes

- The launcher runs `git pull` every 5 minutes. If there are local uncommitted
  changes, git will refuse to pull and the launcher will log a warning. Either
  commit local changes or stash them before pulling.
- The launcher only watches `Watcher.ps1`, `RunBatch.jsx`,
  `RunBatch.jsx.template`, and `parse_atn.py`. If you want other files to
  trigger a restart, edit the `$WatchedFiles` list in `Launcher.ps1`.
- If `Watcher.ps1` crashes or exits, the launcher restarts it automatically.
- To manually restart the watcher, stop and start the scheduled task.
