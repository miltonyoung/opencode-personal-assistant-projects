# Operations & Technical Logistics

This document covers the gear, software, workflow, and remote management systems needed to run GenIdem at each rollout stage.

---

## Core Gear Stack

| Category | Equipment | Notes |
|----------|-----------|-------|
| **Camera** | Canon EOS R6 | Full-frame mirrorless, excellent low-light AF |
| **Lens** | TBD (likely 24–70mm or prime) | Choose based on booth framing distance |
| **Lighting** | Godox AD400Pro strobe | Studio-quality light; requires AC or battery power |
| **Trigger** | Wired/tethered hand trigger (Stage 1) | Handheld guest-operated trigger for taking photos |
| **Monitor Stand** | Monitor stand with laptop mount and magic arm | Central booth hub; holds monitor, Mac, and camera |
| **Camera Mount** | Magic arm attached to monitor stand | Holds Canon EOS R6 in fixed booth position |
| **Light Stand** | C-stand | Supports strobe and modifier |
| **Modifier** | Beauty dish | Controls light quality and spread |
| **Computer** | Mac laptop / mini | Capture and processing hub |
| **Display** | Monitor (Stage 1+) | Guest-facing live preview on the monitor stand |
| **Tablet** | iPad (Stage 3) | Kiosk interface for unattended operation |
| **Backdrop** | TBD (neutral fabric default) | MVP uses a simple backdrop; custom backdrops sourced from a vendor as an add-on |
| **Transport** | Pelican cases / cart | Protect gear and ease load-in/load-out |

---

## Stage 1: MVP Workflow

### Physical Setup
1. Arrive 60–90 minutes before event start.
2. Set up the monitor stand — the central hub of the booth.
3. Mount the guest-facing monitor on the monitor stand.
4. Mount the laptop stand to the monitor stand and place the Mac on it.
5. Attach the camera mount magic arm to the monitor stand and mount the Canon EOS R6.
6. Run tether cable from camera to Mac.
7. Connect the handheld trigger so guests can take their own photos.
8. Set up a separate C-stand with the Godox AD400Pro and beauty dish.
9. Position the strobe/modifier at the desired angle for key light.
10. Connect a guest-facing display to the Mac for live preview.
11. Test exposure, focus, trigger, and display output.
12. Print/place QR card pointing to placeholder gallery.

### Capture Workflow
- Camera saves RAW + JPEG to Mac.
- Operator remains nearby for resets, battery swaps, and troubleshooting.
- Guest holds the trigger, sees the live preview on the monitor, and takes their own photo.


### Post-Event Workflow
1. Cull and lightly edit images (exposure, color, crop).
2. Upload to gallery service.
3. Activate QR code link.
4. Send client the final gallery link.

---

## Stage 2: Instant View & Auto-Upload

### Wireless Tethering Options

| Option | Pros | Cons |
|--------|------|------|
| **Canon EOS Utility / Camera Connect** | Free, direct wireless | Limited range, sometimes unstable |
| **Capture One Pro Wireless** | Professional workflow | Subscription cost |
| **CamFi / Case Air** | Reliable hardware transmitter | Extra cost, another battery to manage |

### Display Monitor
- HDMI or USB-C monitor facing guests.
- Capture One "Live View" or a full-screen slideshow of incoming images.
- Consider a branded screensaver between captures.

### Watch-Folder Automation

**Goal:** Any image dropped into a specific folder is automatically uploaded to the live gallery.

**Approaches:**
- **Hazel** (Mac) — visual automation, easy to set up.
- **Folder Actions + AppleScript** — built into macOS.
- **Keyboard Maestro** — powerful, reliable.
- **Custom script (Python/Node + AWS S3)** — most flexible, requires dev time.

**Example Flow:**
```
Camera → Capture One → export JPEG to /hot-folder/
                        ↓
               Watch-folder automation
                        ↓
               Upload to cloud gallery API
                        ↓
               Gallery updates live
```

### Bandwidth Considerations
- Confirm venue Wi-Fi speed and reliability before the event.
- Have a backup: mobile hotspot or pre-event upload after capture.
- Consider compressing JPEGs for gallery while keeping RAWs for final delivery.

---

## Stage 3: Fully Unattended Kiosk

### Kiosk Software Comparison

| Software | Best For | Pricing | Notes |
|----------|----------|---------|-------|
| **Snappic** | High-end events, social sharing | Subscription per event/month | Strong branding options |
| **Salsa** | Modern interface, GIFs/boomerangs | Subscription | Good for social-first clients |
| **Darkroom Booth** | DSLR-based booths | One-time + support | Mature, Windows/Mac |
| **dslrBooth** | DSLR + iPad control | One-time license | Flexible layouts |

### Kiosk Hardware Enclosure

**Requirements:**
- Lockable to deter theft.
- Ventilated for the Mac/tablet.
- Branded front panel.
- Cable management.
- Transportable by one person.

**Build vs. Buy:**
- **Buy:** Photo booth shells from companies like PBU, Salsa, or custom fabricators.
- **Build:** Wood/ aluminum frame + custom wrap. Lower cost, higher time investment.

### Self-Service Flow
1. Guest taps screen to start.
2. Branded landing screen asks for phone/email.
3. Terms/photo release accepted.
4. Capture triggered on-screen or via physical button.
5. Image is processed with overlay and sent instantly.
6. Optional: share screen with GIF, print, or retake.

---

## Remote Management

**Tool:** Jump Desktop

### Use Cases
- Access the on-site Mac while it is on the lock screen.
- Multi-monitor support for troubleshooting.
- Restart software, clear error dialogs, or change settings remotely.

### Setup Checklist
- [ ] Jump Desktop installed and licensed on both operator and booth Mac.
- [ ] Always-on internet connection at the booth (Wi-Fi + hotspot backup).
- [ ] Mac configured to allow remote access and stay awake during events.
- [ ] Test remote login from a different location before first live event.

### Security Notes
- Use strong, unique passwords.
- Enable two-factor authentication if available.
- Limit remote access to known devices.
- Avoid storing client or guest personal data longer than necessary.

---

## Backdrop & Customization Options

### Default Stage 1 Backdrop
- A neutral, high-quality fabric or collapsible backdrop that works for most events.
- Easy to transport, set up, and light with the Godox AD400Pro.

### Custom Backdrops (Add-On)
- Partner with a local print shop or backdrop vendor to offer branded or themed backdrops.
- Positioned as an **upsell** for B2B brand activations, weddings, and themed events.
- Client provides artwork, or GenIdem coordinates design for an additional fee.

### Vendor Relationship
- Identify 1–2 reliable vendors for backdrop printing and design.
- Establish turnaround time, standard sizes, and wholesale/reseller pricing.
- Keep a small library of sample backdrop designs or textures for inspiration.

---

## Data & Privacy

- Guest phone/email data is collected only for delivery.
- Delete personal data after a defined retention period (e.g., 30–90 days).
- B2B contracts must specify who owns the images and usage rights.
- Consider whether opt-in is required for marketing use of guest photos.

---

## Backup Plan

| Failure | Backup Action |
|---------|---------------|
| Tethering drops | Switch to card backup; continue manual capture |
| Power outage | Battery-powered strobe; UPS for Mac and router |
| Internet fails | Queue uploads; deliver gallery within 24 hours |
| Camera fails | Secondary camera body if available |
| Software crash | Restart capture app remotely via Jump Desktop |

---

## Open Technical Questions

- Which gallery platform will we use for Stage 1? (Pixieset, Pic-Time, ShootProof, custom?)
- Do we have a second camera body as a backup?
- Will we shoot RAW + JPEG, or JPEG only for speed?
- What is the exact mobile hotspot/data plan for events?
- Do we need a UPS for the Mac and lighting trigger?
