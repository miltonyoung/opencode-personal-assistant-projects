# Windows Update Policy for Windows 11 Home

Windows 11 Home does not include the Local Group Policy editor (`gpedit.msc`).
Update reboot control must be done through the Settings UI plus Registry edits.

## Goal

Prevent automatic reboots that would kill running Docker containers, Resolve render queues, and the Photoshop watcher.

## Settings UI changes

1. Open **Settings → Windows Update → Advanced options**.
2. Set **Active hours** to the full 24-hour window (e.g., 6:00 AM – 5:59 AM) so Windows never reboots outside "active" time.
3. Enable **Notify me when a restart is required to finish updating**.
4. Disable **Restart this device as soon as possible when a restart is required to install an update**.
5. Set **Schedule the restart** to the maximum delay if offered.

## Registry changes

Run in PowerShell as Administrator:

```powershell
# Disable automatic restart with logged-on users
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force

# Set AU options to notify before download/install (2 = notify before download, 3 = auto download, notify for install)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 2 -Type DWord -Force

# Do not automatically install updates
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AutoInstallMinorUpdates" -Value 0 -Type DWord -Force

# Pause feature updates (optional, max 5 weeks via UI; registry can extend)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value "2026-09-21T00:00:00Z" -Type String -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -Value "2026-10-31T23:59:59Z" -Type String -Force
```

> **Note:** Some of these registry keys may not exist until created manually or until the Windows Update policy store is initialized. The script will create them with `-Force`.

## Operational habit

Because the PC must stay on for server duties, schedule a manual reboot window once per week (e.g., Sunday morning). Before rebooting, stop the Photoshop watcher gracefully and allow Resolve render jobs to finish.

## Rollback

If a specific update causes gaming or server issues, use:

```powershell
# View installed updates
Get-HotFix

# Uninstall a problematic update (replace KB ID)
wusa /uninstall /kb:1234567
```
