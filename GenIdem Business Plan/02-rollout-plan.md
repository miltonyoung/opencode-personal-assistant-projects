# GenIdem Rollout Plan

This plan moves GenIdem from a lean MVP to a fully unattended kiosk service in three stages. Each stage adds capability, automation, and scalability while keeping capital investment controlled.

---

## Stage 1: MVP Launch — "Studio Pop-Up"

**MVP = Minimum Viable Product.** The simplest version of the service that can be offered to paying customers.

**Goal:** Start booking paid events with minimal hardware and software investment.

### Setup
- Monitor stand serving as the central booth hub.
- Guest-facing monitor mounted on the monitor stand.
- Laptop stand mounted to the monitor stand; Mac runs Capture One or similar.
- Camera mounted via magic arm on the monitor stand.
- Handheld wired/tethered trigger for guests to take their own photos.
- Separate C-stand with Godox AD400Pro strobe and beauty dish.
- QR code printed and placed at the booth.
- QR code points to an empty gallery placeholder.

### Workflow
1. Guest picks up the hand trigger and presses to capture.
2. Images are saved to the Mac.
3. After the event, the operator manually edits and uploads images.
4. Client/guests are sent the gallery link within 24 hours.

### Delivery
- Cloud gallery (Pixieset, Pic-Time, ShootProof, or a custom solution).
- QR code from the event is activated once the gallery is live.

### Investment Required
- Existing camera, strobe, Mac, and tethering accessories.
- Maybe a small sign/QR card holder.

### Risks
- Manual upload delay breaks the instant-gratification expectation.
- Operator must be present or nearby during the event.

### Success Criteria
- 3 paid events booked and executed.
- Clean delivery within 24 hours confirmed.
- Client feedback proves demand for higher-end output.

---

## Stage 2: Instant View & Auto-Upload

**Goal:** Improve guest experience by adding wireless tethering and near-real-time gallery delivery.

### Additions
- Wireless tethering from the camera to the Mac (Capture One Pro).
- Watch-folder automation to sync photos to a live cloud gallery as they are captured.
- Optional branded start screen or overlay on the display.

### Workflow
1. Guest triggers the camera.
2. Image wirelessly transfers to the Mac.
3. Image appears on the guest-facing monitor within seconds.
4. Watch-folder script or app uploads approved images to the live gallery.
5. QR code at the booth now points to a real-time updating gallery.

### Technology Options
- **Tethering:** Capture One Pro Live View + wireless transfer via Canon software or CamFi/Camera Remote.
- **Auto-upload:** Folder Action script, Hazel, Keyboard Maestro, or a custom Node/Python watcher.
- **Gallery:** Cloud service with API or embeddable gallery.

### Investment Estimate
- Wireless tethering hardware/software: $100–$400
- Automation scripting: time-based

### Risks
- Wireless tethering reliability at event venues.
- Upload bandwidth limitations.
- Need a robust "inbox" review step to catch bad/blurry shots before they go live.

### Success Criteria
- Image appears on screen in under 5 seconds.
- Gallery updates within 30 seconds of capture.
- Stable operation across a full 4-hour event.

---

## Stage 3: Fully Unattended Kiosk

**Goal:** Transform the booth into a secure, unattended, branded self-service kiosk.

### Additions
- Custom physical enclosure (lockable, transportable, branded).
- Dedicated iPad/tablet booth software such as:
  - **Snappic**
  - **Salsa**
  - **Darkroom Booth**
  - **dslrBooth**
- Automated digital delivery via text or email with custom client branding.
- Payment/lead-capture integration.
- Remote monitoring via Jump Desktop or similar.

### Workflow
1. Guest walks up to the kiosk.
2. On-screen interface prompts for email/phone and terms.
3. Guest triggers capture via touchscreen or physical button.
4. Image is branded and delivered instantly via text/email.
5. Gallery and leads are available to the client after the event.

### Investment Estimate
- Custom enclosure (build or buy): $1,000–$3,000
- Booth software subscription: $50–$200/mo
- iPad/tablet and peripherals: $500–$1,000
- Shipping/transport cases: $300–$800

### Risks
- High upfront build cost.
- Software platform dependency.
- Security and theft risk at unattended events.
- Need to maintain liability and insurance coverage.

### Success Criteria
- Run a 4+ hour event with no on-site operator.
- 90%+ successful guest deliveries.
- Client-branded experience confirmed and praised.

---

## Rollout Timeline (Draft)

| Stage | Target Duration | Starts After |
|-------|-----------------|--------------|
| Stage 1 MVP | 8–12 weeks | Initial partnership/legal agreement |
| Stage 2 Instant View | 3–6 months after launch | MVP proven with 3+ events |
| Stage 3 Kiosk | 6–12 months after launch | Sustained demand justifies build |

---

## Decision Gates

Before moving to the next stage, confirm:

1. **Stage 1 → 2:**
   - 3+ paid events completed successfully.
   - Average event revenue justifies adding wireless tethering and gallery automation.
   - No major issues with manual delivery workflow.

2. **Stage 2 → 3:**
   - 8–10+ events completed.
   - Strong demand for unattended service specifically.
   - Average event revenue can support kiosk build and subscription costs.
   - Partnership agreement and insurance in place.

---

## Stage 1 Pre-Launch Checklist

- [ ] Confirm MVP gear list and pack list.
- [ ] Test hand trigger and tethered capture in a studio setting.
- [ ] Test QR code → placeholder gallery flow.
- [ ] Create a simple booking confirmation email template.
- [ ] Set pricing for MVP package.
- [ ] Schedule the mock-event portfolio shoot.
- [ ] Draft a one-page service description for clients.

---

## Notes

- It is okay to stay in Stage 1 longer than planned if paid demand is healthy. The MVP is a real business, not just a prototype.
- Stage 3 should not be rushed. The enclosure build is a capital investment that should pay for itself within the first 6–12 months of deployment.
