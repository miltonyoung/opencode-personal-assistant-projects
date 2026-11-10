# Plan: AI-Assisted Rolling Glide Video Editing System

## Goal and intention

- **Outcome:** A reusable system — callable through Jarvis — that takes Rolling Glide footage, applies Milton's defined video styles, and produces a publish-ready draft video with licensed music, captions, branded overlays, and proper export settings.
- **Why it matters:** Rolling Glide generates a steady stream of footage and needs recurring recap videos. Automating the repetitive editing decisions frees Milton to focus on capture, community, and higher-level creative choices.
- **Who it is for:** Rolling Glide community content, with templates that can be reused for Milton's broader videography work.
- **Domain tag:** photo-video / business
- **Kairos / kronos / both:** Both. Recurring recap videos are **kronos** (must keep shipping). Timely edits after events are **kairos** (engagement is highest in the first 24–48 hours).

## Current warning

> ⚠️ **This plan is not implemented yet.** No video ingestion, transcoding, or rendering pipeline exists. Jarvis cannot analyze, preview, or edit video files until the build phases below are executed. Phase 0 style discovery is done for the recap style; Phase 1 architecture is locked.

## Done criteria

- [x] Phase 0: Interview + existing-video style capture approach locked.
- [x] First style template written: **Rolling Glide recap** (`/app-projects/roll-n-glide/video-styles/recap.md`).
- [ ] System ingests source footage from at least one intake path (local watched folder; Tella optional later).
- [ ] Architecture implemented: standalone service on MacBook, callable by Jarvis.
- [ ] MacBook environment provisioned: FFmpeg, HyperFrames CLI, and any needed acceleration.
- [ ] A multi-step pipeline exists: editor, transcriber, animator, researcher, screen editor, sound designer, finisher.
- [ ] **Recap** style generator produces a Resolve-compatible EDL + reference render from a folder of source clips.
- [ ] Milton can review the draft in DaVinci Resolve or a simple UI.
- [ ] Jarvis can invoke the system with a simple command and return the rendered file path or a review link.

## Progress tracker

| Phase | Status | Notes |
| ----- | ------ | ----- |
| 0. Style discovery | ✅ Done | Recap style captured from interview + existing videos. Announcement/B-roll style skipped per owner request. |
| 1. Architecture | 🔄 In progress | Standalone service + MacBook primary host approved. Next: auto-discover MacBook specs and provision tools. |
| 2. Core pipeline | ⏳ Not started | Build editor → transcriber → animator → researcher → screen editor → sound designer → finisher. |
| 3. Style engine | ⏳ Not started | Map recap template + footage + music to an edit decision list and reference render. |
| 4. Validation | ⏳ Not started | Test renders on real Rolling Glide footage; compare with Milton's manual edits. |
| 5. Jarvis wiring | ⏳ Not started | Expose service to Jarvis via skill or tool call; add natural-language commands. |

## Phase 0 — Completed

- ✅ Step 1: Style capture approach decided — **interview first, validate against existing videos**.
- ✅ Step 2: Representative recap videos reviewed by Milton.
- ✅ Step 3: First style template written and saved to `/app-projects/roll-n-glide/video-styles/recap.md`.

**Key decisions from Phase 0:**

- Skip the announcement / talking-head with B-roll style for now.
- Focus the entire build on the **recap** style.

## Phase 1 — Current: MacBook architecture

### Already decided

- **Engine shape:** standalone service called by Jarvis.
- **Primary host:** Milton's MacBook (local Jarvis instance).
- **Render fallback:** Windows gaming PC remains available as a remote render target later if MacBook rendering is too slow.
- **Automation level:** AI-assisted drafts reviewed by Milton before publishing.
- **Music workflow:** local Artlist library folder, not Enterprise API yet.
- **Output handoff:** Resolve-compatible EDL/timeline + reference render + notes file.

### Next step: discover and provision the MacBook

Run on the MacBook in a new session and record results in `/app-projects/roll-n-glide/video-styles/.context/macbook-context.md`.

```bash
# 1. Hardware and OS
system_profiler SPHardwareDataType | head -20
sw_vers

# 2. Video tools
which ffmpeg && ffmpeg -version | head -1
which ffprobe && ffprobe -version | head -1
which hyperframes && hyperframes --version 2>/dev/null || echo "HyperFrames CLI not found"
ls -d /Applications/DaVinci\ Resolve/DaVinci\ Resolve.app 2>/dev/null || echo "Resolve not in /Applications"

# 3. Package managers
which brew && brew --version
which npm && npm --version
which node && node --version
which uv && uv --version
which python3 && python3 --version

# 4. Local music library (ask Milton for the actual path)
ls -d ~/Music/Artlist 2>/dev/null || echo "Artlist folder not found at ~/Music/Artlist"
ls -d ~/Downloads/Artlist 2>/dev/null || echo "Artlist folder not found at ~/Downloads/Artlist"
```

Then install missing tools:

- **FFmpeg:** `brew install ffmpeg` (if missing). Verify it has VideoToolbox (`-hwaccel videotoolbox`) for Apple Silicon acceleration.
- **HyperFrames CLI:** follow current install instructions from `hyperframes.io` (likely `npm install -g @hyperframes/cli` or similar; confirm on the site).
- **Python environment:** ensure `uv` is available and can run the service.

### After discovery

1. Save MacBook specs and installed-tool versions to `/app-projects/roll-n-glide/video-styles/.context/macbook-context.md`.
2. Create the empty project skeleton for the standalone video service under `/app-projects/roll-n-glide/services/video-editor/`.
3. Update this plan to mark Phase 1 complete and move to Phase 2.

## Phase 2 — Core pipeline (reference workflow)

| Step | Role | Build target |
| ---- | ---- | -------------- |
| 7 | Editor | LLM/agent reads style template + brief and coordinates steps. |
| 8 | Transcriber | Speech → captions and timing. Evaluate Parakeet vs. Whisper vs. ElevenLabs Scribe. |
| 9 | Animator | HyperFrames renders branded overlays, lower-thirds, titles. |
| 10 | Researcher | Browser/screenshot tool fetches reference images or stats if script needs them. |
| 11 | Screen editor | Local folder intake for screen/webcam recordings; Tella optional later. |
| 12 | Sound designer | Match Artlist tracks by mood/tempo and trim to duration. |
| 13 | Finisher | FFmpeg assembles clips, overlays, captions, audio mix, and encodes to 9:16 specs. |

For the recap MVP we can initially skip the animator, researcher, and transcriber if there is no speech to caption. The minimum viable pipeline is:

1. **Intake:** read a source footage folder.
2. **Editor:** apply the recap style rules (shot priority, pacing, structure).
3. **Sound designer:** pick music from local Artlist library.
4. **Finisher:** cut clips to music beats, add logo overlay, encode reference render, output EDL.

## Phase 3 — Style engine

- Build a parser that maps the recap style template + available clips + music → EDL JSON.
- Implement the recap generator:
  - Select best moments using the 75/25 social-joy/technical-connection rule.
  - Avoid falls/embarrassment.
  - Sync cuts to music beats.
  - Apply default LUT only to log clips.
  - Add persistent Rolling Glide logo overlay.
- Output Resolve-compatible EDL + reference MP4 + notes.

## Phase 4 — Validation

- Run test renders on one past Rolling Glide event folder.
- Milton compares the AI draft to his manual recap.
- Iterate on the style template and editor rules until the draft is consistently usable.

## Phase 5 — Jarvis wiring

- Expose the video service to Jarvis:
  - Option A: loadable skill inside Jarvis that calls the service API.
  - Option B: direct tool call from Jarvis to the service.
- Add natural-language commands:
  - “Jarvis, make a Rolling Glide recap from `/path/to/event-folder`.”
  - “Jarvis, show me the last recap draft.”
- Track runs, outputs, and owner feedback in session logs.

## Risks and unknowns

- **Artlist API eligibility:** Personal Artlist subscription likely has no public API. Local library is the fallback.
- **MacBook GPU limitations:** Rendering on Apple Silicon may be slower than the Windows PC. Accept longer renders or add remote render node later.
- **HyperFrames maturity:** May need FFmpeg/ImageMagick fallback for some overlays.
- **AI clip judgment:** Emotional moments in community footage may need explicit rules or examples.
- **Scope creep:** Lock recap MVP before adding new styles or platforms.

## Decisions confirmed

- Engine location: **Standalone service called by Jarvis** ✅
- Infrastructure timing: **MacBook as primary host; Windows PC as optional future render target** ✅
- Music workflow: **Local Artlist library folder** ✅
- Automation level: **AI-assisted drafts reviewed by Milton before publishing** ✅
- Style capture: **Interview first + validate against existing videos** ✅
- First style: **Recap only** ✅ (announcement/B-roll skipped)

## Files affected

- `/app-projects/roll-n-glide/plans/ai-video-editing-system/plan.md`
- `/app-projects/roll-n-glide/video-styles/recap.md`
- `/app-projects/roll-n-glide/video-styles/.context/macbook-context.md` (to be created in Phase 1)
- `/app-projects/roll-n-glide/services/video-editor/` (to be created in Phase 1)
