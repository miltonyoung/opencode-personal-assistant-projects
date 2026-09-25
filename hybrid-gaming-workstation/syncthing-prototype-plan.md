# Prototype Plan: Syncthing for CreativeBridge

## Decisions from requirements review

| Question | Answer |
| -------- | ----------- |
| Versioning | Trash-can safety net on both sides, 7-day retention. |
| Windows autostart | System service at boot. |
| macOS autostart | Optional: user can choose boot-start or manual start. |
| Sync cadence | Near-real-time with watcher; acceptable to be ~1 minute behind. |
| Sync scope | Whole `CreativeBridge` folder for now; per-project selection later. |

## Device IDs

| Device | Device ID |
| ------ | --------- |
| Windows PC (powerhouse) | `IIA6A5P-IZ5PPGK-JN7QDJJ-NDXHRSX-EOTHTLE-3VBY2Y7-QASIH55-EUQWWAP` |
| MacBook | TBD after install |

---

## Architecture

```
MacBook                                Tailscale tailnet                     Windows PC
+-----------------------------------+                                    +-----------------------------------+
| ~/CreativeBridge                  |<----------------------------------->| E:\CreativeBridge                 |
| Syncthing (user LaunchAgent)      |   direct WireGuard connection       | Syncthing (Windows service)         |
| GUI via web browser / SyncTrayzor |   100.x.x.x <-> 100.x.x.x          | GUI via web browser                 |
+-----------------------------------+                                    +-----------------------------------+
```

Both Syncthing instances communicate directly over Tailscale. No public ports,
no relay servers if direct connection is healthy.

---

## Phase 1: Install Syncthing

### Windows PC (server) — recommended path

Use **SyncthingWindowsSetup** in **administrative (all users)** mode.

1. Download `SyncthingSetup-x64.exe` from Bill Stewart's repository:
   <https://github.com/Bill-Stewart/SyncthingWindowsSetup/releases>
2. Run the installer as Administrator.
3. Choose **administrative (all users)** installation.
4. The installer will:
   - Install Syncthing to `C:\Program Files\Syncthing`.
   - Create a Windows service that starts at boot.
   - Create a local service account (default `SyncthingServiceAcct`).
   - Create a Windows Firewall rule for Syncthing.
   - Start the service after installation.
5. After installation, grant the service account access to `E:\CreativeBridge`:

```powershell
# Run as Administrator
$Path = "E:\CreativeBridge"
$User = "SyncthingServiceAcct"

$Acl = Get-Acl $Path
$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $User,
    "Modify,ReadAndExecute,ListDirectory,Read,Write",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$Acl.SetAccessRule($Rule)
Set-Acl $Path $Acl
```

6. Open the Syncthing GUI at `http://localhost:8384`.
   - The installer may have set a GUI password already; check its README if
     you cannot log in.
   - Disable **Start browser** in Settings → GUI.
   - Set/confirm a strong GUI username/password.

#### Alternative: NSSM path (manual)

If you prefer full control over the service account, config path, and startup
behavior, use NSSM. The steps are documented in many Syncthing guides. For
most users, the installer above is faster and less error-prone.

### MacBook (client)

```bash
brew install syncthing
```

For **manual start only**:

```bash
# Start now
syncthing --no-browser
```

For **start at login** via Homebrew services:

```bash
brew services start syncthing
```

For **optional boot-start or manual start**, we will create a small helper
script/app later. For the prototype, choose one:

- Option A: `brew services start syncthing` (starts at login, runs in
  background).
- Option B: launch manually from terminal when you want to sync.

Recommended for the prototype: **Option A** so sync is always available.

---

## Phase 2: Network configuration over Tailscale

### On both devices

1. Make sure Tailscale is running and both machines are on the same tailnet.
2. Note each machine's Tailscale IP:
   - Windows: `tailscale ip -4`
   - Mac: `tailscale ip -4`

### In each Syncthing GUI

1. Go to **Settings → Connections**.
2. Under **Sync Protocol Listen Addresses**, set:
   - `tcp://100.x.x.x:22000` (replace with this device's Tailscale IP).
   - Also keep `dynamic+https://relays.syncthing.net/endpoint` as a fallback
     only if Tailscale direct fails.
3. Under **Global Discovery**, you can leave it enabled or disable it if you
   want to rely purely on Tailscale. Disabling it reduces external exposure.
4. Under **Allowed Networks** for the remote device, add the other device's
   Tailscale IP or the whole tailnet CIDR (e.g., `100.64.0.0/10`).

This forces Syncthing to use the Tailscale path first.

---

## Phase 3: Pair devices

1. On the Windows PC, go to **Actions → Show ID** and copy the Device ID.
   - Recorded: `IIA6A5P-IZ5PPGK-JN7QDJJ-NDXHRSX-EOTHTLE-3VBY2Y7-QASIH55-EUQWWAP`
2. On the MacBook, go to **Add Remote Device**, paste the Windows Device ID,
   give it a name like `powerhouse-pc`, and save.
3. On the Windows PC, accept the MacBook's pairing request.
4. Verify in the GUI that both devices show as `Connected` and ideally
   `Address: 100.x.x.x:22000` (direct over Tailscale).

---

## Phase 4: Share the CreativeBridge folder

### MacBook

1. In Syncthing GUI, **Add Folder**:
   - Folder ID: `creativebridge`
   - Folder Path: `/Users/milton/CreativeBridge`
   - Folder Type: `Send & Receive`
   - Share with: `powerhouse-pc`

### Windows PC

1. Accept the folder share request.
2. Set Folder Path to `E:\CreativeBridge`.
3. Folder Type: `Send & Receive`.

:

| Setting | Value | Reason |
| ------- | ----- | ------ |
| `fsWatcherEnabled` | `true` | Detect file changes in near real time. |
| `fsWatcherDelayS` | `10` | Accumulate changes for 10 seconds before scanning. |
| `rescanIntervalS` | `60` | Full rescan every minute as a safety net. |
| `ignorePerms` | `true` | Windows and macOS permissions are not compatible. |
| `versioning` | `trashcan` | Safety net on both sides. |
| `versioning.cleanupIntervalS` | `86400` | Clean trash older than the retention. |
| `versioning.params.keeptime` | `604800` (7 days) | Keep deleted files for 7 days before permanent removal. |
| `maxConflicts` | keep 10 | Limit conflict file explosion. |
| `minDiskFree` | warn at 5 GB | Prevent filling the PC disk. |

This gives you a target lag of roughly 10–60 seconds, meeting your "close to
real time but can be 1 minute behind" requirement.

---

## Phase 5: Handle conflicts and deletions

### Conflicts

- Syncthing creates `.sync-conflict-YYYYMMDD-HHMMSS` files automatically when
  a file changes on both sides between syncs.
- For the prototype, keep this default behavior.
- Later we can add a cleanup script or GUI helper to surface and resolve
  conflicts.

### Deletions

- With `Send & Receive`, deletions propagate both ways.
- Because **trash-can versioning** is enabled on both sides, deleted files are
  moved to a hidden `.stversions` folder instead of being permanently removed.
- Files in `.stversions` are kept for 7 days, then automatically cleaned up.
- To recover a deleted file, browse to `.stversions` on the side where the
  deletion was recorded and move the file back.
- During destructive tests, you can temporarily set one side to `Receive Only`
  to prevent local deletions from propagating.

---

## Phase 6: Verify behavior

### Basic sync tests

1. Create a small text file on the MacBook in `~/CreativeBridge/test.txt`.
2. Confirm it appears in `E:\CreativeBridge\test.txt` within ~30 seconds.
3. Edit the file on the PC.
4. Confirm the edit appears on the MacBook.
5. Delete the file on one side and confirm it deletes on the other.

### Large file test

1. Copy a 1 GB test video to `~/CreativeBridge/`.
2. Monitor the Syncthing GUI for transfer speed and completion.
3. Note whether the connection is direct or relayed.

### Offline / Tailscale-down test

1. Disconnect Tailscale on the MacBook.
2. Add a file locally.
3. Reconnect Tailscale.
4. Confirm the queued file syncs once the PC is reachable again.

---

## Phase 7: Benchmark against SMB and rclone SFTP

Use the same 100-file RAW + sidecar test set from the earlier plan:

| Method | Time | Notes |
| ------ | ---- | ----- |
| SMB over Tailscale | TBD | Baseline for Finder-style access. |
| rclone SFTP `--transfers 8` | TBD | Optimized bulk push. |
| Syncthing continuous sync | TBD | Google-Drive-like behavior. |

Capture:

- Wall time for initial sync.
- CPU usage on the Windows PC.
- Tailscale connection type (`tailscale status`).
- Perceived lag for small file changes.

---

## Phase 8: Integrate with existing Photoshop watcher and Resolve

Because Syncthing writes directly to `E:\CreativeBridge`, the existing
Photoshop watcher and Resolve remote-rendering paths do **not** need to
change.

However, one consideration: if you add large RAW files on the MacBook and
Syncthing is still writing them to the PC, the Photoshop watcher may see
partial files. Syncthing writes to a temporary file and renames on completion,
but the watcher currently uses file-size stability detection. The 10-second
stability window should handle this, but monitor `watcher.log` during the
prototype.

If partial-file issues appear, two mitigations:

1. Keep the file-size stability check at 10 seconds (or increase it).
2. Add an ignore pattern in the watcher for Syncthing temporary files
   (`.syncthing.*.tmp`).

---

## Phase 9: Decide on final stack

After the benchmark and a few days of real use, decide:

- **If Syncthing works well:** make it the primary sync engine.
  - Remove or disable the SMB share.
  - Keep the rclone SFTP server as an optional manual fast-lane, or remove it
    to simplify.
- **If Syncthing is too slow or conflict-prone:** fall back to RcloneView +
  `rclone bisync` or keep rclone SFTP as the primary bulk transfer.

## Installer recommendation summary

- **Windows PC:** use **SyncthingWindowsSetup** in administrative mode. It is
  the most reliable, maintained path for boot-start service installation.
- **MacBook:** use **Homebrew** (`brew install syncthing`) for easy install and
  optional `brew services start syncthing` for login-start.

---

## Notes and warnings

- Do not sync the `.syncthing` database folder or the Syncthing config itself.
- Avoid syncing files that are actively being written by another process
  (e.g., a video render in progress).
- Syncthing's block-level sync is efficient for renames and appends, but a
  newly imported RAW folder will still require a full initial upload.
- On the Windows PC, the Syncthing service account must have full access to
  `E:\CreativeBridge` and to its own home/config directory.
- Watch `.stversions` growth during the first week. If you delete large
  folders frequently, the trash can can consume significant disk space.

---

## Next actions

1. Install Syncthing on the Windows PC as a service.
2. Install Syncthing on the MacBook via Homebrew and start it.
3. Pair the devices over Tailscale.
4. Share `CreativeBridge` as `Send & Receive` on both sides.
5. Set folder settings: watcher on, 10s delay, 60s rescan, ignore perms.
6. Run basic sync tests.
7. Run benchmark against SMB and rclone SFTP.
8. Decide whether to keep, demote, or remove SMB and rclone SFTP.
