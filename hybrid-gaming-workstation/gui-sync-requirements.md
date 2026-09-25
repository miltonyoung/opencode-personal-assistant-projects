# GUI Bidirectional Sync Requirements — CreativeBridge

## Goal

Define and prototype a graphical application on the MacBook that keeps the
`CreativeBridge` folder bidirectionally synchronized with the Windows PC's
`E:\CreativeBridge` over Tailscale, similar to how Google Drive Desktop syncs
a local folder to the cloud.

For the first version, the GUI will sync the **entire CreativeBridge folder**.
Per-project selection will be added later.

---

## User requirements

### 1. Sync scope

- **MVP:** sync the entire `CreativeBridge` folder both ways.
  - MacBook local path: `~/CreativeBridge`.
  - PC remote path: `E:\CreativeBridge`.
  - *Note:* this is what you asked for. For large RAW sets, a full sync of
    `CreativeBridge` may take a long initial scan, but subsequent runs are
    incremental.
- Later: allow per-project selection.
  - Each project lives under `photoshop-projects/<project-name>/`.
  - The GUI can expose checkboxes for which projects to include in the
    bidirectional sync set.
  - Excluded projects are still reachable via manual `rclone copy` or mount.

### 2. Automatic sync + polling

| Behavior | Requirement |
| -------- | ----------- |
| File-system watcher | Use macOS `fsevents` (via RcloneView or a launch agent) to detect local changes and trigger sync quickly. |
| Poll fallback | When file-system events are unreliable, poll at a configurable interval (default 60 seconds). |
| Sync cadence | A background job runs continuously; user can pause/resume and set bandwidth limits. |
| On wake from sleep | Sync resumes automatically; run a quick scan to catch changes made while asleep. |
| Network awareness | Only sync when Tailscale is connected and the PC is reachable. Otherwise queue and retry. |

### 3. Bidirectional sync semantics (Google-Drive-style)

- **New files** on either side are copied to the other side.
- **Modified files** on either side are copied to the other side, preferring the
  newer version by modification time.
- **Deleted files** on one side are deleted on the other side **after
  confirmation or a grace period**.
  - *MVP:* deletions propagate both ways.
  - *Safer default:* deletions are held in a trash/backup folder on the PC for
    30 days before permanent removal.
- **Conflicts:** if the same file is modified on both sides between syncs, the
  GUI must surface a conflict and let the user pick:
  - Keep MacBook version
  - Keep PC version
  - Keep both (rename one with `.conflict-<date>` suffix)
- **Rename detection:** the sync engine should detect renames/moves where
  possible instead of deleting and re-uploading.

### 4. Performance + reliability

| Requirement | Approach |
| ----------- | -------- |
| Parallel transfers | `--transfers 8` or higher for many-file projects. |
| Chunk concurrency | `--sftp-concurrency 64` for large-file throughput. |
| Atomic staging | Large writes are staged to `__incoming` on the PC and moved into place only when complete. |
| Resume | Interrupted transfers resume from where they left off. |
| Checksumming | Optional `--checksum` verification for critical handoffs. |
| Bandwidth limit | Configurable caps for uploads/downloads, with "unlimited" option. |
| Quota / free-space check | Warn if the PC disk is low before starting a large sync. |

### 5. GUI presentation

- **Status panel:** show overall sync state (idle, scanning, uploading,
  downloading, error), last sync time, next sync time, and number of files
  pending.
- **Project list:** list projects under `CreativeBridge` with sync on/off
  toggles, last-sync timestamp, and conflict count per project.
- **Activity feed:** recent file changes (added/modified/deleted/conflicted)
  with timestamps.
- **Conflict resolver:** a simple modal or side panel listing conflicts with
  preview/action buttons.
- **Settings:**
  - Sync mode: bidirectional, upload-only, download-only.
  - Conflict resolution default: newer wins / ask / keep both.
  - Delete propagation: on / off / trash-on-PC.
  - Polling interval and bandwidth limits.
  - Auto-start on login.
- **Manual actions:**
  - "Sync now"
  - "Pause sync"
  - "Open mount in Finder"
  - "View remote folder"

### 6. Security and safety

- Host-key pinning for the SFTP connection.
- Password or key-based auth stored in macOS Keychain.
- `--max-delete` safety limit to prevent accidental mass deletion.
- `RCLONE_TEST` sentinel / `--check-access` to stop sync if the remote folder
  looks wrong (prevents syncing into an empty or wrong directory).

---

## GUI/engine options

### Option A: RcloneView + `rclone bisync` (recommended)

**Why it fits**

- Native macOS app with two-pane explorer, remotes, mounts, and job scheduler.
- Built on rclone, so it can talk directly to your `pc-sftp` remote.
- RcloneView supports **bisync** jobs and scheduling (requires PLUS license for
  scheduling).
- It exposes the conflict-resolution and filtering options you need.
- One app covers browsing, mount, sync, and future cloud providers.

**How it maps to requirements**

| Requirement | RcloneView capability |
| ----------- | --------------------- |
| Whole-folder sync | Create a bisync job: `~/CreativeBridge` <-> `pc-sftp:/`. |
| Auto-sync / polling | Job scheduler (PLUS) at a configured interval, plus auto-mount on startup. |
| Bidirectional semantics | `bisync` handles new/modified/deleted files in both directions. |
| Conflicts | `--conflict-resolve newer` or `--conflict-loser num` for side-by-side copies. |
| Atomic staging | Use a `--filter-from` file to exclude `__incoming/`; bisync moves are server-side when possible. |
| Bandwidth limits | Built into job settings. |
| Mount in Finder | Mount Manager with `nfsmount` on macOS. |

**Caveats**

- PLUS license needed for scheduling. Without it, you trigger jobs manually or
  via an external cron/launchd script.
- `rclone bisync` is considered advanced; a bad config or interrupted initial
  `--resync` can require manual recovery.
- Real-time file-system watching is not as tight as Syncthing's native watcher;
  it is poll/schedule driven.

### Option B: Syncthing over Tailscale

**Why it fits**

- Purpose-built for exactly this use case: continuous, bidirectional,
  peer-to-peer sync with a native GUI.
- Real-time file-system watchers on both sides.
- Automatic conflict handling and versioning.
- Runs over Tailscale IPs directly; no separate SFTP server needed.

**How it maps to requirements**

| Requirement | Syncthing capability |
| ----------- | -------------------- |
| Whole-folder sync | Add `~/CreativeBridge` as a folder, share with the Windows PC device. |
| Auto-sync / polling | Continuous; `fsWatcherEnabled` plus periodic scan. |
| Bidirectional semantics | Native two-way sync with versioning and conflict copies. |
| Conflicts | Creates `.sync-conflict-...` files automatically. |
| Atomic staging | Not built-in; partial files are `.tmp` and renamed on completion. |
| Bandwidth limits | Global/device limits configurable in GUI. |
| Mount in Finder | Not a mount; it is a local sync folder, which is actually closer to Google Drive Desktop behavior. |

**Caveats**

- Adds a second sync engine alongside rclone SFTP, which may feel redundant.
- Needs Syncthing installed and configured on **both** the MacBook and the
  Windows PC.
- The PC must be awake and online; conflicts still happen if both sides edit
  the same file offline.
- Versioning can fill disk if not capped.

### Option C: rclone Web GUI + custom scripts

- Free, bundled with rclone.
- No scheduling, no real-time watcher.
- You would write launchd + shell scripts for polling and conflict handling.
- Not recommended for the Google-Drive-style experience you described.

---

## Recommendation

For a Google-Drive-like experience with a real GUI, **Syncthing is the better
fit** because:

1. It is purpose-built for bidirectional peer-to-peer sync.
2. It has a native web GUI, real-time watchers, and robust conflict/version
  handling.
3. It runs directly over Tailscale without requiring an SFTP server on the PC.

However, if you want to stay inside the rclone ecosystem and use one app for
both cloud storage and this PC link, **RcloneView + bisync** is the coherent
choice. It will feel more like scheduled backup jobs than continuous sync.

Given your statement "kind of like google drive desktop app," **I recommend
prototyping Syncthing first**. If it works well, it can replace the need for
`rclone serve sftp` entirely, or you can keep SFTP as a manual fast-lane for
initial large seeding.

---

## Prototype plan

1. **Install Syncthing on both machines**
   - MacBook: `brew install syncthing` and `brew services start syncthing`.
   - Windows PC: download from <https://syncthing.net/downloads/> or use
     Chocolatey: `choco install syncthing`.

2. **Bind each Syncthing instance to the Tailscale IP only**
   - In Syncthing GUI → Settings → Connections, set the listen address to
     `tcp://100.x.x.x:22000` or use `dynamic` with Tailscale providing the
     reachability.
   - Alternatively, let Syncthing use global discovery but rely on Tailscale
     for transport; restrict allowed networks to the tailnet in device
     settings.

3. **Pair the devices**
   - On each device, add the other device by its Syncthing Device ID.
   - Both must be on the same Tailscale tailnet.

4. **Share `CreativeBridge`**
   - MacBook folder: `~/CreativeBridge`.
   - Windows PC folder: `E:\CreativeBridge`.
   - Mark folder type "Send & Receive" on both sides for bidirectional sync.

5. **Configure versioning and conflicts**
   - On the Windows PC side, enable "Simple File Versioning" with a 30-day cap.
   - Set conflict copies to be kept.
   - Set bandwidth limits if needed.

6. **Verify in the GUI**
   - Watch the web GUI status panel.
   - Add a small test file on each side and confirm propagation.
   - Disconnect Tailscale and confirm sync pauses/retries.

7. **Benchmark**
   - Compare Syncthing throughput to `rclone copy` and SMB for the same test
     set.

8. **Decide**
   - If Syncthing works well, it becomes the primary sync engine and the
     rclone SFTP server can be demoted to a manual bulk-transfer tool or
     removed.
   - If Syncthing underperforms or conflicts are too noisy, switch to
     RcloneView + bisync.

---

## Open questions

1. Do you want versioning on the PC side, the MacBook side, or both?
2. Are you comfortable running Syncthing on the Windows PC as a user service, or
   do you prefer it as a Windows service running at boot?
3. Is "continuous real-time sync" essential, or would a 5-minute or 15-minute
   scheduled sync feel like "Google Drive Desktop" enough?
4. Do you want per-project sync selection in the first version, or whole-folder
   sync first?
