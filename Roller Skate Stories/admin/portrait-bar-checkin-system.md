:

# Portrait Bar Check-In System — Technical Brief

**Status:** Idea / needs scoping  
**Owner:** Milton Young (engineering lead)  
**Goal:** Let guests check into the Portrait Bar by party, log their booth session time, and automatically sort photos by party/session.

---

## The problem

On a busy day, Skateland may have 3–4 birthday parties happening at the same time. Guests from different parties will use the Portrait Bar. Without a check-in system, the operator has to manually remember or ask which party every photo belongs to. That is slow, error-prone, and hard to scale.

## The solution

A simple check-in system at the booth:

1. Guest approaches the Portrait Bar.
2. On a tablet/kiosk, they select their party.
3. They tap **Start Session** before stepping in.
4. The system logs the start time.
5. They take photos.
6. They tap **End Session** when done.
7. Later, a script reads the session logs and the camera photos, grouping photos by active session.
8. Each party gets its own folder/gallery.

---

## Core requirements

### Must have

- [ ] A list of parties for the current day
- [ ] A way for a guest to select their party
- [ ] A way to start and end a booth session
- [ ] Session logs: start time, end time, party ID, optional guest name/phone/email
- [ ] A script that matches photo timestamps to session time windows
- [ ] Output: folders or galleries grouped by party

### Should have

- [ ] Simple admin UI for the operator to add/edit parties
- [ ] Automatic session timeout if guest forgets to tap End Session
- [ ] QR code or party code for faster lookup
- [ ] Offline mode (in case rink Wi-Fi is unreliable)
- [ ] Export session logs to CSV

### Could have

- [ ] SMS or email notification when a party’s gallery is ready
- [ ] Guest-facing preview screen in the booth
- [ ] Integration with Skateland booking system
- [ ] Cloud sync so owners can monitor remotely

---

## Suggested architecture

### Option A: Single-device local app (fastest to build)

- A tablet or laptop at the booth runs a local web app.
- SQLite file stores parties and sessions.
- Camera saves photos to a folder with timestamps in filenames or EXIF data.
- A Python script matches photos to sessions.

**Pros:** Works offline, simple, low cost.  
**Cons:** Manual setup per event, no remote access.

### Option B: Small web app with cloud backend

- A lightweight web app hosted somewhere (e.g., VPS, Firebase, or similar).
- Parties and sessions stored in a database.
- Operator checks in from any device.
- Photos still matched locally by script.

**Pros:** Multi-device, remote access, easier scaling.  
**Cons:** Needs internet, hosting cost, more setup.

### Option C: Hybrid

- Local first: app runs on a laptop/tablet at the booth.
- Syncs to cloud when internet is available.
- Photos matched locally.

**Pros:** Reliable on event day, cloud backup when possible.  
**Cons:** Slightly more complex.

**Recommendation for first version:** Option A. Build it as a local web app using Python/Flask or a simple static JavaScript app with a local JSON/SQLite store. Focus on reliability at the booth.

---

## Data model (simple version)

```
Party
- id
- name (e.g., "Ava's 8th Birthday")
- host_name
- host_contact
- event_date
- start_time
- end_time

Session
- id
- party_id
- guest_name (optional)
- start_timestamp
- end_timestamp
- status (active / completed / timeout)

Photo
- filename
- timestamp
- assigned_party_id (computed after matching)
```

---

## Photo matching logic

```
For each photo:
  read its timestamp
  find all sessions where photo timestamp is between session.start and session.end
  if exactly one session matches:
    assign photo to that party
  if multiple sessions match:
    flag for manual review (overlap)
  if no session matches:
    flag as unassigned / operator review
```

The script outputs one folder per party plus an `unassigned/` folder for review.

---

## First engineering tasks

These can be broken into separate task cards once the system is approved.

1. **Choose stack** — decide between local web app, Python GUI, or another option.
2. **Build party CRUD** — create, edit, list parties for the day.
3. **Build session start/end UI** — simple kiosk interface.
4. **Build session logger** — store start/end timestamps.
5. **Build photo timestamp reader** — read EXIF or filename timestamps.
6. **Build photo-to-party matcher** — group photos by session.
7. **Build output formatter** — create party folders and a summary report.
8. **Test at a practice shoot** — run the system at the Skateland test event.
9. **Iterate based on operator feedback** — simplify, fix bugs, add needed features.

---

## Open questions

- What device will run the check-in app? (tablet, laptop, phone)
- Will the camera timestamp sync with the app timestamp?
- Does the operator need a separate device for session management?
- Should guests enter a name/email, or just select a party?
- What happens if a session is accidentally left open?
- Should the system also trigger the camera, or only log times?

---

## Relation to the RSS mission

This system is not just a tech toy. It directly supports the mission:

- **Preserve the culture:** every party’s photos become a shareable story.
- **Serve the people:** hosts get clean, organized galleries without confusion.
- **Make stories visible:** sorted galleries are easier to share and promote.
