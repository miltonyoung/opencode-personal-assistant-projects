# Task #7: Configure DaVinci Resolve Studio for Remote Headless Rendering

## Prerequisites

- DaVinci Resolve Studio 21.1 installed and licensed on the Windows PC.
- PostgreSQL container running on `localhost:5432` (Task #6).
- Windows user has auto-login enabled and a display dummy plug is inserted in the RTX 2070 Super.

## Step 1: Connect Resolve to the PostgreSQL database

### On the Windows PC

1. Open **DaVinci Resolve Studio**.
2. In the **Project Manager**, click the database icon or right-click in the project library area.
3. Choose **Connect** → **PostgreSQL**.
4. Enter:
   - **Host:** `localhost`
   - **Port:** `5432`
   - **Database:** `resolve`
   - **Username:** `postgres`
   - **Password:** `DaVinci`
5. Click **Save** or **Connect**.

### On the MacBook

1. Open **DaVinci Resolve Studio**.
2. In the **Project Manager**, connect to PostgreSQL.
3. Enter:
   - **Host:** `powerhouse.tail006229.ts.net`
   - **Port:** `5432`
   - **Database:** `resolve`
   - **Username:** `postgres`
   - **Password:** `DaVinci`
4. Click **Save**.

Ensure the MacBook is connected to Tailscale.

## Step 2: Configure Media Storage mapped mounts

Because macOS and Windows use different absolute paths for the same shared folder, Resolve must translate them automatically. This is required for both media import and render output paths.

### On the MacBook

1. Open **DaVinci Resolve → Preferences → System → Media Storage**.
2. Click **Add**.
3. Choose `/Volumes/CreativeBridge`.
4. In the **Mapped Mount** column for that entry, enter:
   ```
   E:\CreativeBridge
   ```
5. Click **Save**.
6. Restart Resolve.

### On the Windows PC

1. Open **DaVinci Resolve → Preferences → System → Media Storage**.
2. Click **Add**.
3. Choose `E:\CreativeBridge`.
4. In the **Mapped Mount** column for that entry, enter:
   ```
   /Volumes/CreativeBridge
   ```
5. Click **Save**.
6. Restart Resolve.

## Step 3: Enable Remote Rendering on the Windows PC

1. In the Project Manager, right-click the **shared PostgreSQL database** you just connected.
2. Select **Remote Rendering** → **Enable Remote Rendering**.
3. Close Resolve normally.

If the right-click menu does not show a Remote Rendering option, Resolve Studio may enable it automatically once both machines are connected to the same shared database.

## Step 4: Test launching Resolve headlessly

Open PowerShell and run:

```powershell
& "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe" -rr
```

Expected behavior:
- Resolve may briefly show a splash screen.
- No main Resolve editing window appears.
- Resolve appears in Task Manager as an active process.
- The render node is now polling the PostgreSQL database for jobs.

To stop it later, close the process in Task Manager or press Ctrl+C in the PowerShell window.

**Note:** In Resolve 21.1, the `-rr` flag is the correct way to start the remote render node. The `-nogui` flag is not required and may cause crashes in this version.

## Step 5: Verify Remote Rendering from the MacBook

1. On the MacBook, create or open a Resolve project in the shared PostgreSQL database.
2. Import source media from `/Volumes/CreativeBridge/...`.
3. Add a timeline to the **Deliver** render queue.
4. Set the render output to `/Volumes/CreativeBridge/Renders/`.
5. In the **Deliver** page, look for the Windows PC in the render target list.
6. Start the render.
7. The Windows PC should pick up the job and render it.

## Step 6: Create the render output folder on the Windows PC

```powershell
New-Item -ItemType Directory -Path "E:\CreativeBridge\Renders" -Force
```

## Step 7: Set up automatic launch of the remote render node

Choose one of the following methods.

### Method A: Desktop shortcut (manual start after login)

Create a PowerShell script on the desktop:

```powershell
New-Item -Path "$HOME\Desktop\Start-RemoteRender.ps1" -ItemType File -Value '& "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe" -rr' -Force
```

After logging in, right-click the `Start-RemoteRender.ps1` file and choose **Run with PowerShell**.

**Pros:** Simple, explicit control.  
**Cons:** Requires a manual click after every reboot.

### Method B: Scheduled task (automatic start after login)

1. Open **Task Scheduler**.
2. Click **Create Task** (not Basic Task).
3. On the **General** tab:
   - **Name:** `Resolve Remote Render Node`
   - Select **Run only when user is logged on**.
   - Check **Run with highest privileges**.
4. On the **Triggers** tab:
   - Click **New**.
   - Choose **Begin the task:** `At log on`.
   - Select **Specific user:** your Windows account.
   - Click **OK**.
5. On the **Actions** tab:
   - Click **New**.
   - **Action:** `Start a program`.
   - **Program/script:** `C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe`
   - **Add arguments:** `-rr`
   - **Start in:** `C:\Program Files\Blackmagic Design\DaVinci Resolve\`
   - Click **OK**.
6. On the **Conditions** tab:
   - Uncheck **Start the task only if the computer is on AC power**.
7. On the **Settings** tab:
   - Uncheck **Stop the task if it runs longer than**.
8. Click **OK**.
9. Test by signing out and signing back in, then check Task Manager for `Resolve.exe`.

**Pros:** Fully automatic after auto-login.  
**Cons:** Resolve runs continuously, consuming a small amount of resources even when idle.

**Recommendation:** Use Method B for a true server experience. Keep Method A as a fallback or for testing.

## Step 8: Record completion

Once a render job dispatched from the MacBook completes on the Windows PC using the `-rr` launch method, return here so we can mark Task #7 complete and move to Task #8 (Photoshop batch watcher).

## Troubleshooting

- **Resolve cannot connect to PostgreSQL:** Verify the container is running (`docker ps`). Check Windows Firewall is not blocking outbound localhost connections. Verify the password is `DaVinci`.
- **MacBook cannot connect to PostgreSQL over Tailscale:** Ensure Tailscale is running on both machines. Verify `powerhouse.tail006229.ts.net` resolves from the MacBook (`ping powerhouse.tail006229.ts.net`). Check the Tailscale ACL allows port 5432 between the two devices.
- **Windows PC does not appear as a render target on MacBook:** Both must be connected to the exact same PostgreSQL project library. Restart Resolve on both machines after enabling Remote Rendering.
- **"No write permission" error during remote render:** The MacBook output path is not mapped correctly on Windows. Confirm the Media Storage mapped mounts in Step 2 are configured on both machines and point to the same `CreativeBridge` folder.
- **GPU acceleration not working headlessly:** Confirm the display dummy plug is inserted in the RTX 2070 Super and Windows detects a monitor in Display Settings.
- **Render fails due to missing media:** Verify the media files live inside `CreativeBridge` and both machines resolve the same relative path.
