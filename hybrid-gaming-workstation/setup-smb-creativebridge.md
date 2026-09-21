# Task #5: Create and Mount SMB Network Share "CreativeBridge"

## Design

- **Windows host location:** `E:\CreativeBridge`
- **SMB share name:** `CreativeBridge`
- **MacBook mount point:** `/Volumes/CreativeBridge`
- **Purpose:** Shared drop zone for DaVinci Resolve source media/render queues and Photoshop batch raw/action/trigger files.

## Step 1: Create the folder on Windows

Open PowerShell as Administrator:

```powershell
New-Item -ItemType Directory -Path "E:\CreativeBridge" -Force
```

## Step 2: Share the folder over SMB

```powershell
$shareName = "CreativeBridge"
$path = "E:\CreativeBridge"
$description = "Hybrid gaming workstation shared drop zone for Resolve and Photoshop"

New-SmbShare -Name $shareName -Path $path -Description $description -FullAccess "$env:USERDOMAIN\$env:USERNAME"

# Verify
Get-SmbShare -Name $shareName
```

If your account is a local Microsoft account, use the local username. If it is a domain account, use the domain form. For a home setup you can also use `Everyone` but that is less secure:

```powershell
# Less secure, only use on a trusted home network
New-SmbShare -Name $shareName -Path $path -Description $description -FullAccess "Everyone"
```

## Step 3: Confirm SMB settings

Check that the share exists and note the Windows PC’s IP address:

```powershell
Get-SmbShare
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }
```

Write down the IPv4 address (e.g., `192.168.1.100`).

## Step 4: Test from the Windows side

Create a test file:

```powershell
"test" | Out-File -FilePath "E:\CreativeBridge\hello.txt" -Encoding utf8
Get-ChildItem "E:\CreativeBridge"
```

## Step 5: Mount on macOS

On the MacBook:

1. Open **Finder**.
2. Press **Cmd+K** or choose **Go → Connect to Server**.
3. Enter: `smb://192.168.1.100/CreativeBridge` (replace with the actual IP).
4. Click **Connect**.
5. Enter the Windows username and password.
6. macOS will mount it under `/Volumes/CreativeBridge`.

### Make it persistent on macOS

1. Open **System Settings → General → Login Items**.
2. Drag `/Volumes/CreativeBridge` into **Login Items** if it appears after mounting, or add a small AppleScript/launch agent to reconnect at login.

Alternative: mount via Terminal:

```bash
mkdir -p /Volumes/CreativeBridge
mount_smbfs //milton@192.168.1.100/CreativeBridge /Volumes/CreativeBridge
```

## Step 6: Verify bidirectional access

1. On the MacBook, create a file in `/Volumes/CreativeBridge/`:
   ```bash
   touch /Volumes/CreativeBridge/from-mac.txt
   ```
2. On the Windows PC, confirm it appears:
   ```powershell
   Get-ChildItem "E:\CreativeBridge"
   ```
3. On the Windows PC, create a file:
   ```powershell
   "windows test" | Out-File -FilePath "E:\CreativeBridge\from-pc.txt" -Encoding utf8
   ```
4. On the MacBook, confirm it appears:
   ```bash
   ls /Volumes/CreativeBridge
   ```

## Step 7: Make the Windows share survive reboots

The `New-SmbShare` command already creates a persistent SMB share. Verify it is still present after a reboot:

```powershell
Get-SmbShare -Name CreativeBridge
```

## Step 8: Record completion

Once bidirectional file creation works, return here so we can mark Task #5 complete and move to Task #6 (Docker services).

## Troubleshooting

- **Cannot connect from Mac:** Confirm both machines are on the same network. Check Windows Firewall is not blocking SMB. You may need to enable **File and Printer Sharing** in Windows Settings.
- **Wrong credentials:** On macOS, choose **Connect As** and enter the exact Windows local username and password.
- **Share not visible:** SMB shares do not need to be "discoverable" for manual `smb://` mounts.
- **Firewall on router:** Some routers block SMB between wired/wireless segments. Both your PC and MacBook are wired, so this is unlikely.
