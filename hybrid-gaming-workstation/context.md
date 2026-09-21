# Hybrid Gaming & Workstation Server — Context

## Hardware

- **OS:** Windows 11 Home
- **CPU:** Intel i7-9700K, 8 cores / 8 threads
- **RAM:** 16 GB
- **GPU:** NVIDIA RTX 2070 Super
- **Network:** wired Ethernet
- **Storage:**
  - C: 1 TB Samsung SSD 870 EVO (OS)
  - D: 1 TB WD Blue 3.5" HDD
  - E: 4 TB M.2 SSD (intended for shared media and scratch)

## Software

- **DaVinci Resolve Studio:** 21.1 (installed)
- **Adobe Photoshop:** 27.10 (installed)

## Open Questions

- MacBook macOS version and network connection type
- Power policy intent (24/7, sleep, wake-on-LAN)
- Security tolerance (trusted home network or isolated/scoped)
- OpenCode Server / OpenChamber install docs, ports, GPU needs
- Free space on E: drive

## Notes

- Windows 11 Home means no Local Group Policy editor; update reboot control must use Registry edits or the Windows Update active-hours UI.
- With 8C/8T and 16 GB RAM, WSL2 should be capped conservatively (likely 4 cores / 8 GB RAM) to protect weekend gaming performance.
- SMB share should live on E: for speed and capacity, with a junction or symlink at C:\Shared only if scripts hard-code that path.
