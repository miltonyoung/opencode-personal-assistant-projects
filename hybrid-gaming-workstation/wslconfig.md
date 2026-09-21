# WSL2 Configuration

## File location

`C:\Users\<username>\.wslconfig`

## Proposed contents

```ini
[wsl2]
# Reserve half the physical cores for Windows / gaming.
processors=4

# Reserve half the RAM for Windows / gaming.
memory=8GB

# Disable dynamic swap growth to prevent WSL2 from eating SSD space.
swap=0

# Use the Windows host kernel directly; no nested VM overhead.
localhostForwarding=true

# Optional: limit WSL2 VM disk size to avoid runaway VHD growth.
# Uncomment if the ext4.vhdx grows unexpectedly.
# diskSize=128GB
```

## Rationale

- CPU: i7-9700K has 8 threads. 4 for WSL2/Docker leaves 4 for Windows and games.
- RAM: 16 GB total. 8 GB for WSL2/Docker leaves 8 GB for Windows, Resolve, and Photoshop.
- Swap disabled to prevent VHD growth and reduce SSD wear. If a container truly needs swap, enable a fixed size (e.g., `swap=2GB`).

## Activation

After saving `.wslconfig`, run in PowerShell as Administrator:

```powershell
wsl --shutdown
```

WSL2 will read the file on next start.

## Verification

Inside WSL2:

```bash
nproc
free -h
```

Confirm 4 CPUs and ~8 GB total memory visible.
