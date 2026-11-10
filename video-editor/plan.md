# Plan: Generic AI-Assisted Video Editing System

## Goal and intention

- **Outcome:** A reusable, Jarvis-callable video editing service that ingests source footage, applies a brand-specific style template, and produces a publish-ready draft video with licensed music, captions, branded overlays, and proper export settings. The first style to validate against is Rolling Glide's **recap** style.
- **Why it matters:** Milton produces recurring community and event videos across multiple brands. A generic engine lets each brand define its own style without rebuilding the pipeline.
- **Who it is for:** Any brand or project Milton runs that needs repeatable short-form video edits.
- **Domain tag:** photo-video / tooling
- **Kairos / kronos / both:** Both. Recurring brand videos are **kronos** (must keep shipping). Timely edits after events are **kairos** (engagement is highest in the first 24–48 hours).

## Current warning

> ⚠️ **This plan is not implemented yet.** No video ingestion, transcoding, or rendering pipeline exists. Jarvis cannot analyze, preview, or edit video files until the build phases below are executed. Phase 0 is done for the first test style (Rolling Glide recap); Phase 1 architecture is locked.

## Done criteria

- [x] Phase 0: Style capture approach locked and first test style written.
- [ ] Generic engine ingests source footage from at least one intake path (local watched folder; Tella optional later).
- [ ] Architecture implemented: standalone service on MacBook, callable by Jarvis.
- [ ] MacBook environment provisioned: FFmpeg, HyperFrames CLI, and any needed acceleration.
- [ ] A multi-step pipeline exists: editor, transcriber, animator, researcher, screen editor, sound designer, finisher.
- [ ] Style engine maps any valid style template + footage + music → an edit decision list (EDL) + reference render.
- [ ] **First validation:** Rolling Glide recap style produces a Resolve-compatible EDL + reference render from a folder of source clips.
- [ ] Milton can review the draft in DaVinci Resolve or a simple UI.
- [ ] Jarvis can invoke the system with a simple command and return the rendered file path or a review link.

## Progress tracker

| Phase | Status | Notes |
| ----- | ------ | ----- |
| 0. Style discovery | ✅ Done | Rolling Glide recap style captured as the first test style. |
| 1. Architecture | 🔄 In progress | Standalone service + MacBook primary host approved. Next: auto-discover MacBook specs and provision tools. |
| 2. Core pipeline | ⏳ Not started | Build editor → transcriber → animator → researcher → screen editor → sound designer → finisher. |
| 3. Style engine | ⏳ Not started | Generic parser maps any style template + footage + music to an EDL and reference render. |
| 4. Validation | ⏳ Not started | Test on Rolling Glide recap footage; compare with Milton's manual edits. |
| 5. Jarvis wiring | ⏳ Not started | Expose service to Jarvis via skill or tool call; add natural-language commands. |

## Phase 0 — Completed

- ✅ Style capture approach decided — **interview first, validate against existing videos**.
- ✅ First test style written and saved to `/app-projects/roll-n-glide/video-styles/recap.md`.
- ✅ Decision: skip announcement / talking-head with B-roll style for now; validate the engine with recap first.

## Phase 1 — Current: MacBook architecture

### Already decided

- **Engine shape:** standalone service called by Jarvis.
- **Primary host:** Milton's MacBook (local Jarvis instance).
- **Render fallback:** Windows gaming PC remains available as a remote render target later if MacBook rendering is too slow.
- **Automation level:** AI-assisted drafts reviewed by Milton before publishing.
- **Music workflow:** local Artlist library folder, not Enterprise API yet.
- **Output handoff:** Resolve-compatible EDL/timeline + reference render + notes file.

### Next step: discover and provision the MacBook

Run on the MacBook in a new session and record results in `/app-projects/video-editor/.context/macbook-context.md`.

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
- **HyperFrames CLI:** follow current install instructions from `hyperframes.io`.
- **Python environment:** ensure `uv` is available and can run the service.

### After discovery

1. Save MacBook specs and installed-tool versions to `/app-projects/video-editor/.context/macbook-context.md`.
2. Create the empty project skeleton for the standalone video service under `/app-projects/video-editor/src/`.
3. Update this plan to mark Phase 1 complete and move to Phase 2.

## Phase 2 — Core pipeline (reference workflow)

| Step | Role | Build target |
| ---- | ---- | -------------- |
| 7 | Editor | LLM/agent reads style template + brief and coordinates steps. |
| 8 | Transcriber | Speech → captions and timing. Evaluate Parakeet vs. Whisper vs. ElevenLabs Scribe. |
| 9 | Animator | HyperFrames renders branded overlays, lower-thirds, titles. |
| 10 | Researcher | Browser/screenshot tool fetches reference images or stats if script needs them. |
| 11 | Screen editor | Local folder intake for screen/webcam recordings; Tella optional later. |
| 12 | Sound designer | Match local music library tracks by mood/tempo and trim to duration. |
| 13 | Finisher | FFmpeg assembles clips, overlays, captions, audio mix, and encodes to platform specs. |

For the recap MVP we can initially skip the animator, researcher, and transcriber if there is no speech to caption. The minimum viable pipeline is:

1. **Intake:** read a source footage folder.
2. **Editor:** apply a brand style template (shot priority, pacing, structure).
3. **Sound designer:** pick music from a configured local library.
4. **Finisher:** cut clips to music beats, add logo overlay, encode reference render, output EDL.

## Phase 3 — Style engine

- Build a generic parser that maps any valid style template + available clips + music → EDL JSON.
- Implement a generator harness that executes brand-specific rules from the style file while keeping the engine itself brand-agnostic.
- For the Rolling Glide recap style specifically:
  - Select best moments using the 75/25 social-joy/technical-connection rule.
  - Avoid falls/embarrassment.
  - Sync cuts to music beats.
  - Apply default LUT only to log clips.
  - Add persistent Rolling Glide logo overlay.
- Output Resolve-compatible EDL + reference MP4 + notes.

## Phase 4 — Validation

- Run test renders on one Rolling Glide event folder.
- Milton compares the AI draft to his manual recap.
- Iterate on the style template and generic editor rules until the draft is consistently usable.

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
- **AI clip judgment:** Emotional moments in community footage may need explicit rules or examples in each style.
- **Style portability:** The engine must not hard-code brand assumptions; style templates must carry all brand-specific behavior.
- **Scope creep:** Lock recap MVP before adding new styles or platforms.

## Decisions confirmed

- Engine location: **Standalone service called by Jarvis** ✅
- Infrastructure timing: **MacBook as primary host; Windows PC as optional future render target** ✅
- Music workflow: **Local music library folder** ✅
- Automation level: **AI-assisted drafts reviewed by Milton before publishing** ✅
- Style capture: **Interview first + validate against existing videos** ✅
- First validation style: **Rolling Glide recap** ✅

## Files affected

- `/app-projects/video-editor/plan.md`
- `/app-projects/video-editor/START-HERE.md`
- `/app-projects/video-editor/.context/macbook-context.md` (to be created in Phase 1)
- `/app-projects/video-editor/src/` (to be created in Phase 1)
- `/app-projects/roll-n-glide/video-styles/recap.md`
