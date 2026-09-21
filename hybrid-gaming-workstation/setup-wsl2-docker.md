# Task #4: Enable WSL2 and Install Docker Desktop

## Prerequisites

- Windows 11 Home, fully updated.
- `.wslconfig` already saved at `C:\Users\<username>\.wslconfig` per `wslconfig.md`.
- PowerShell run as Administrator.

## Step 1: Enable required Windows features

Run in PowerShell as Administrator:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reboot the PC.

## Step 2: Set WSL2 as default kernel

After reboot, run in PowerShell as Administrator:

```powershell
wsl --set-default-version 2
```

## Step 3: Install a Linux distribution

Recommended: Ubuntu 24.04 LTS.

```powershell
wsl --install -d Ubuntu-24.04
```

This installs Ubuntu and prompts you to create a UNIX username and password. Note the username for later Docker permission steps.

If the Microsoft Store is unavailable, download the distro package manually and install:

```powershell
wsl --install --from-file "C:\path\to\Ubuntu_2404.1_LTS.appx"
```

## Step 4: Verify WSL2 installation

```powershell
wsl -l -v
```

Expected output shows `Ubuntu-24.04` with `VERSION 2`.

## Step 5: Install Docker Desktop

1. Download Docker Desktop for Windows from https://www.docker.com/products/docker-desktop/.
2. Run the installer.
3. During installation, ensure **Use WSL 2 instead of Hyper-V** is selected.
4. Complete installation and reboot if prompted.

## Step 6: Configure Docker Desktop

1. Open Docker Desktop.
2. Go to **Settings → General**.
   - Check **Use the WSL 2 based engine**.
3. Go to **Settings → Resources → WSL integration**.
   - Enable integration for **Ubuntu-24.04**.
4. Apply and restart Docker Desktop.

## Step 7: Verify Docker

In PowerShell:

```powershell
docker --version
docker run hello-world
```

In WSL2 Ubuntu:

```bash
docker ps
```

If `docker ps` fails with permission denied, the WSL integration may not yet be active. Try:

```bash
sudo usermod -aG docker $USER
```

Then close and reopen the WSL terminal.

## Step 8: Verify `.wslconfig` took effect

In WSL2 Ubuntu:

```bash
nproc
free -h
```

Expected:
- `nproc` returns 4
- `free -h` shows approximately 8 GB total memory

## Step 9: Record completion

Once verified, return here and mark the task complete so we can proceed to the SMB storage bridge.

## Rollback / Troubleshooting

- If WSL2 fails to start, ensure virtualization is enabled in BIOS (Intel VT-x).
- If Docker Desktop is slow, confirm `.wslconfig` has no syntax errors and that `wsl --shutdown` was run after saving it.
- To uninstall a distro: `wsl --unregister Ubuntu-24.04`.
