# Runbook: CreativeBridge Sync via Tailscale + Syncthing

## Overview

This document records the working setup for keeping the MacBook's
`~/CreativeBridge` folder bidirectionally synchronized with the Windows PC's
`E:\CreativeBridge` folder over a Tailscale mesh network.

This replaces SMB as the primary file-transfer path. SMB remains temporarily
available as a fallback but should be disabled once Syncthing is proven.

---

## Devices

| Device | Role | Device ID | Tailscale IP | Syncthing config |
| ------ | ---- | --------- | -------------- | ---------------- |
| Windows PC ("powerhouse") | Server | `IIA6A5P-IZ5PPGK-JN7QDJJ-NDXHRSX-EOTHTLE-3VBY2Y7-QASIH55-EUQWWAP` | TBD | Runs as Windows service at boot |
| MacBook ("macbook-creativebridge") | Client | `ZGTIAUY-HNBHQ4W-63GTHBI-UIU3ABX-FDHZ6IJ-SV35TJG-IY6D7WU-UCOOKQK` | TBD | Homebrew service, starts at login |

---

## Windows PC (powerhouse) setup

### Installation

- Used **SyncthingWindowsSetup** in administrative mode:
  ```powershell
  .\SyncthingSetup-x64.exe /allusers
  ```
- Installed to: `C:\Program Files\Syncthing`
- Runs as Windows service: **Syncthing Service**
- Service account: `SyncthingServiceAcct`
- Config home: `C:\ProgramData\Syncthing`
- Firewall rule: created automatically by installer

### Service verification

```powershell
Get-Service Syncthing
sc.exe qc Syncthing
```

Expected: `Running`, `START_TYPE = AUTO_START (DELAYED)`, `SERVICE_START_NAME = .\SyncthingServiceAcct`.

### Folder permissions

Granted `SyncthingServiceAcct` Modify access to `E:\CreativeBridge`:

```powershell
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

### GUI credentials

- URL: `http://localhost:8384`
- Username: `milton`
- Password: <stored separately>
- **Start browser** disabled

### Tailscale binding

In **Settings → Connections**:

- Sync Protocol Listen Addresses: `tcp://<windows-tailscale-hostname>:22000`
  - Example: `tcp://powerhouse.tail1234.ts.net:22000`
- Global Discovery: disabled (optional, recommended for privacy)

In remote device settings for `macbook-creativebridge`:

- Allowed Networks: `100.64.0.0/10`

Also, in **Actions → Settings → General → Edit Device Defaults → Advanced →
Addresses**, set the default remote device address to `tcp://<remote-tailscale-hostname>:22000`
to prevent Syncthing from discovering unreachable LAN addresses when the
remote device leaves the home network.

---

## MacBook setup

### Installation

```bash
brew install syncthing
brew services start syncthing
```

This creates a user LaunchAgent that starts Syncthing at login.

### GUI credentials

- URL: `http://localhost:8384`
- Username: `milton`
- Password: <stored separately>
- **Start browser** disabled

### Tailscale binding

In **Settings → Connections**:

- Sync Protocol Listen Addresses: `tcp://<mac-tailscale-hostname>:22000`
  - Example: `tcp://macbook.tail1234.ts.net:22000`
- Global Discovery: disabled (optional, recommended for privacy)

In remote device settings for `powerhouse-pc`:

- Allowed Networks: `100.64.0.0/10`

Also, in **Actions → Settings → General → Edit Device Defaults → Advanced →
Addresses**, set the default remote device address to `tcp://<remote-tailscale-hostname>:22000`
to prevent Syncthing from discovering unreachable LAN addresses when the
remote device leaves the home network.

---

## Shared folder configuration

| Setting | Value | Reason |
| ------- | ----- | ------ |
| Folder ID | `creativebridge` | Same on both devices |
| Windows path | `E:\CreativeBridge` | Existing SMB share root |
| Mac path | `/Users/milton/CreativeBridge` | Local sync folder |
| Folder type | `Send & Receive` | Bidirectional sync |
| `fsWatcherEnabled` | `true` | Near-real-time change detection |
| `fsWatcherDelayS` | `10` | 10-second accumulation delay |
| `rescanIntervalS` | `60` | 1-minute full rescan safety net |
| `ignorePerms` | `true` | Windows/macOS permissions are incompatible |
| `versioning` | `trashcan` | Safety net for deletions |
| `versioning.params.keeptime` | `604800` (7 days) | Deleted files recoverable for 7 days |
| `versioning.cleanupIntervalS` | `86400` (1 day) | Daily cleanup of expired trash |
| `maxConflicts` | `10` | Limit conflict-file explosion |
| `minDiskFree` | `5 GB` | Warn before filling disk |

---

## Expected behavior

- New or changed files sync within roughly 10–60 seconds when both devices are
  online and Tailscale is connected.
- Deleted files are moved to `.stversions` on each side and kept for 7 days.
- Conflicts create `.sync-conflict-YYYYMMDD-HHMMSS` copies on both sides.
- If Tailscale is disconnected, changes queue and sync once reconnected.

---

## Integration with existing automation

### Photoshop watcher

- The watcher continues to monitor `E:\CreativeBridge\photoshop-projects`.
- It already ignores `.xmp` sidecar files (line 377 of `Watcher.ps1`):
  ```powershell
  $excludedExtensions = @('.xmp')
  ```
- It uses file-size stability detection (10 seconds) to avoid processing
  partially copied files. This also handles Syncthing's `.syncthing.*.tmp`
  temporary files in most cases.
- If `.syncthing.*.tmp` files ever appear in watcher logs, add `.syncthing.*.tmp`
  to the exclusion list.

### DaVinci Resolve remote rendering

- Resolve continues to read from `E:\CreativeBridge` as before.
- No configuration change was required.

---

## Operational commands

### Windows PC

```powershell
# Check service status
Get-Service Syncthing

# Restart Syncthing
Restart-Service Syncthing -Force

# Open GUI
Start-Process "http://localhost:8384"
```

### MacBook

```bash
# Check service status
brew services info syncthing

# Restart Syncthing
brew services restart syncthing

# Start manually (if not using brew services)
syncthing --no-browser

# Open GUI
open "http://localhost:8384"
```

---

## Monitoring and troubleshooting

1. **Check connection type:** in either Syncthing GUI, the remote device should
   show an address like `tcp://100.x.x.x:22000` if the Tailscale direct path
   is working. A `relay://` address indicates a problem.
2. **Verify Tailscale direct connection:**
   ```bash
   tailscale status
   ```
3. **Check folder sync state:** in the GUI, look for "Up to Date" on both sides.
4. **Review conflicts:** search for `.sync-conflict` files in
   `~/CreativeBridge` and `E:\CreativeBridge`.
5. **Recover deleted files:** look in `.stversions` inside the folder root.

---

## Future improvements

- Disable or remove SMB share after Syncthing has been stable for a few days.
- Add per-project sync selection in the GUI if desired.
- Enable true versioning (e.g., staggered) if 7-day trash can is not enough.
- Add a custom macOS menu-bar app for pause/resume/sync-now if the web GUI is
  not convenient enough.

---

## Files affected

- `/home/milton/Documents/opencode-personal-assistant-projects/hybrid-gaming-workstation/syncthing-prototype-plan.md`
- `/home/milton/Documents/opencode-personal-assistant-projects/hybrid-gaming-workstation/runbook-syncthing-creativebridge.md`
- `/home/milton/Documents/opencode-personal-assistant-projects/hybrid-gaming-workstation/photoshop-watcher/Watcher.ps1` (no change needed; already ignores `.xmp`)
