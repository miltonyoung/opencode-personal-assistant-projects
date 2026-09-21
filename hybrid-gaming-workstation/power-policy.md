# Power Policy

## Decision

**Always-on server with auto-login and screen lock.**

Sleep, hibernate, or hybrid sleep would break both Photoshop (needs interactive session) and Resolve `-nogui` (needs graphics subsystem initialized). Wake-on-LAN does not re-establish an interactive user session.

## Power plan settings

1. Open **Settings → System → Power & battery**.
2. Set **Screen** to turn off after **10 minutes**.
3. Set **Sleep** to **Never**.
4. Disable **Hibernate**.
5. Select **Best performance** or **High performance** power plan.

## Registry / command-line alternative

Run in PowerShell as Administrator:

```powershell
# Disable sleep on AC power
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

# Disable hibernate completely
powercfg /hibernate off

# Set active power plan to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

## Auto-login

Required so the user session is available after a reboot for Photoshop and Resolve.

### Configure auto-login

Run `netplwiz`, uncheck **Users must enter a user name and password to use this computer**, enter the password, and reboot.

Alternative registry method:

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "1" -Type String -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value "<username>" -Type String -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "<password>" -Type String -Force
```

> **Security note:** Storing the password in the registry is insecure. Use `netplwiz` if possible. Either way, the screen should be locked immediately after login.

### Lock screen after auto-login

Create a shortcut in the user’s **Startup** folder:

```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\lock-screen.lnk
```

Target:

```
rundll32.exe user32.dll,LockWorkStation
```

This locks the desktop but keeps the interactive session alive for Photoshop and Resolve.

## Display dummy plug

Insert an HDMI or DisplayPort dummy plug into the RTX 2070 Super. Windows must believe a monitor is attached or it will suspend GPU acceleration, which Resolve Remote Rendering requires.

## Verification

- After reboot, confirm the user is logged in (Task Manager shows explorer.exe and user processes).
- Confirm screen is locked.
- Confirm GPU is active in Device Manager and Task Manager Performance tab.
