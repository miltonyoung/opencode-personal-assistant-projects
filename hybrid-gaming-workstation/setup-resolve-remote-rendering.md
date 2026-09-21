# Task #7: Configure DaVinci Resolve Studio for Remote Headless Rendering

## Prerequisites

- DaVinci Resolve Studio 21.1 installed and licensed on the Windows PC.
- PostgreSQL container running on `localhost:5432` (Task #6).
- Windows user has auto-login enabled and a display dummy plug is inserted in the RTX 2070 Super.

## Step 1: Connect Resolve to the PostgreSQL database

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

Resolve should connect to the database and display the project library.

## Step 2: Enable Remote Rendering on the Windows PC

1. In the Project Manager, right-click the **shared PostgreSQL database** you just connected.
2. Select **Remote Rendering** → **Enable Remote Rendering**.
3. Close Resolve normally.

## Step 3: Test launching Resolve headlessly

Open PowerShell and run:

```powershell
& "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe" -nogui
```

Expected behavior:
- No main Resolve window appears.
- Resolve appears in Task Manager.
- The render node is now polling the PostgreSQL database for jobs.

To stop it later, close the process in Task Manager or press Ctrl+C in the PowerShell window.

## Step 4: Connect the MacBook to the same PostgreSQL database

On the MacBook, open DaVinci Resolve Studio and connect to the database using the PC’s Tailscale hostname:

- **Host:** `powerhouse.tail006229.ts.net`
- **Port:** `5432`
- **Database:** `resolve`
- **Username:** `postgres`
- **Password:** `DaVinci`

Ensure the MacBook is connected to Tailscale.

## Step 5: Verify Remote Rendering from the MacBook

1. On the MacBook, create or open a Resolve project in the shared PostgreSQL database.
2. Add a timeline to the **Deliver** render queue.
3. In the **Deliver** page, look for the Windows PC in the render target list.
4. Start the render.
5. The Windows PC should pick up the job and render it headlessly.

## Step 6: Verify media path parity

Both machines must access media through the same relative path inside `CreativeBridge`.

- On Windows: `E:\CreativeBridge\...`
- On MacBook: `/Volumes/CreativeBridge/...`

When importing media into Resolve on either machine, use paths inside `CreativeBridge` so the other machine can resolve them.

## Step 7: Record completion

Once a render job dispatched from the MacBook completes on the Windows PC, return here so we can mark Task #7 complete and move to Task #8 (Photoshop batch watcher).

## Troubleshooting

- **Resolve cannot connect to PostgreSQL:** Verify the container is running (`docker ps`). Check Windows Firewall is not blocking outbound localhost connections. Verify the password is `DaVinci`.
- **MacBook cannot connect to PostgreSQL over Tailscale:** Ensure Tailscale is running on both machines. Verify `powerhouse.tail006229.ts.net` resolves from the MacBook (`ping powerhouse.tail006229.ts.net`). Check the Tailscale ACL allows port 5432 between the two devices.
- **Windows PC does not appear as a render target on MacBook:** Both must be connected to the exact same PostgreSQL project library. Restart Resolve on both machines after enabling Remote Rendering.
- **GPU acceleration not working headlessly:** Confirm the display dummy plug is inserted in the RTX 2070 Super and Windows detects a monitor in Display Settings.
- **Render fails due to missing media:** Verify the media files live inside `CreativeBridge` and both machines see the same relative path.
