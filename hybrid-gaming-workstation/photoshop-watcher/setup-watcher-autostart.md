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

### Option A: `shell:startup` shortcut (recommended)

Task Scheduler can fail with access-denied errors on some Windows builds.
A `shell:startup` shortcut launches the watcher automatically after you log in,
without requiring elevation, and avoids a visible PowerShell window by wrapping
PowerShell in a `cmd /c start /min` command.

1. Press **Win + R**, type `shell:startup`, and press Enter.
2. Right-click in the folder → **New → Shortcut**.
3. In the location field, paste:
   ```
   cmd /c start "" /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\milton\projects\opencode-personal-assistant-projects\hybrid-gaming-workstation\photoshop-watcher\Launcher.ps1"
   ```
4. Click **Next**, name it `Photoshop Watcher Launcher`, and click **Finish**.
5. Reboot (or double-click the shortcut to test).
6. Check Task Manager for `powershell.exe` running `Launcher.ps1` and a child
   `powershell.exe` running `Watcher.ps1`.

### Option B: Windows Task Scheduler

Not recommended because Task Scheduler may deny registration or run in a
non-interactive context that conflicts with Photoshop. If you want to try it,
set it to **Run only when user is logged on** and do **not** run with highest
privileges.

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

## Step 4: Create a shortcut to tail the logs

A helper script `Tail-Logs.ps1` opens the watcher and launcher logs in two
separate PowerShell windows.

1. Right-click the desktop → **New → Shortcut**.
2. In the location field, paste:
   ```
   cmd /c start "" /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\milton\projects\opencode-personal-assistant-projects\hybrid-gaming-workstation\photoshop-watcher\Tail-Logs.ps1"
   ```
3. Name it `Tail Watcher Logs` and click **Finish**.
4. Double-click it to open two live log windows.

---

## Step 5: Test the auto-pull / auto-restart behavior

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
