# Hybrid Gaming & Workstation Server — Research Notes

## DaVinci Resolve Studio 21.1 — PostgreSQL Compatibility

**Confidence level:** owner-provided operational facts.

- Resolve Studio 21.1 supports PostgreSQL 13 and above for network project libraries.
- **Recommendation:** Use PostgreSQL 14 in the Docker container. It is recent enough to have Docker image support and old enough to satisfy Resolve.
- **Connection defaults:** port `5432`, username `postgres`, password `DaVinci`. Provide the host IP of the database container.
- **Remote Rendering is Studio-only.** Both the primary workstation (MacBook) and the render node (this PC) need a Studio license activation or USB dongle.
- **`-nogui` behavior on Windows:** `Resolve.exe -nogui` (also `-rr`) prevents the main window from drawing, but it is not a true service. It still runs under the active user session and needs the OS graphics subsystem initialized.
- **GPU acceleration in headless mode:** Windows suspends GPU hardware acceleration when no display is detected. The PC needs a physical HDMI/DisplayPort dummy plug inserted into the RTX 2070 Super to keep the GPU active for Remote Rendering.
- **Render node discovery:** Done through the shared database, not network broadcast. Both machines must connect to the same PostgreSQL project library. The secondary node polls the DB for render jobs.

## Adobe Photoshop 27.10 — Headless ExtendScript Automation

**Confidence level:** owner-provided operational facts.

- Photoshop does **not** support true headless execution. The engine must initialize in an interactive desktop session.
- Creative Cloud licensing requires an active user session. Launching from a non-interactive SYSTEM or isolated background service will fail license entitlement.
- **Recommended pattern:** Configure Windows auto-login for the user account, lock the screen at boot, and run `Watcher.ps1` via a scheduled task set to “Run only when user is logged in.”
- **Command-line invocation:** `"C:\Program Files\Adobe\Adobe Photoshop 2026\Photoshop.exe" "C:\path\to\script.jsx"`.
- **Batch action execution via ExtendScript:** `app.doAction("Action Name", "Action Set Name");` inside a loop over files from `Folder.getFiles()`.
- **File watcher reliability:** Use a scheduled-task polling loop (e.g., every 30 seconds), not PowerShell `FileSystemWatcher`. `FileSystemWatcher` fires multiple rapid events for a single file transfer and can spawn conflicting Photoshop instances.
- **Error handling and logging:** ExtendScript cannot return an exit code to PowerShell. Use ExtendScript's `File` object to write a status log; PowerShell reads the log to verify completion.

## Hardware Implications

- A display dummy plug must be purchased or already available.
- Windows 11 Home limits update-reboot policy to Registry edits and active-hours UI.
- Auto-login + screen lock is required for Photoshop; Resolve `-nogui` also benefits from an interactive session.
