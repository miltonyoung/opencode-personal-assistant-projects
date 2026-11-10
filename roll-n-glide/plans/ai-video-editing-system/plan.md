# Plan: AI-Assisted Rolling Glide Video Editing System

## Goal and intention

- **Outcome:** A reusable system — callable through Jarvis — that can take Rolling Glide footage (from Tella, local storage, or other sources), apply one of Milton's defined video styles, and produce a publish-ready draft video with licensed music, captions, branded overlays, and proper export settings.
- **Why it matters:** Rolling Glide generates a steady stream of footage and needs recurring recap and announcement videos. Automating the repetitive editing decisions frees Milton to focus on capture, community, and higher-level creative choices.
- **Who it is for:** Rolling Glide community content, with templates that can be reused for Milton's broader videography work.
- **Domain tag:** photo-video / business
- **Kairos / kronos / both:** Both. Recurring recap/announcement videos are **kronos** (must keep shipping). Timely edits after events are **kairos** (engagement is highest in the first 24–48 hours).

## Done criteria

- [ ] System ingests source footage from at least one intake path (Tella API or a watched local folder).
- [ ] At least two Rolling Glide styles are encoded as reproducible templates: **event recap** and **announcement / talking-head with B-roll**.
- [ ] A multi-step pipeline exists, inspired by the reference workflow: editor (agent/LLM), transcriber, animator, researcher, screen editor, sound designer, finisher.
- [ ] Editor step: agent interprets the brief/style and coordinates the pipeline.
- [ ] Transcriber step: speech is transcribed so captions and timing can be derived (Parakeet or equivalent).
- [ ] Animator step: HyperFrames generates branded overlays, lower-thirds, intro cards, and motion graphics.
- [ ] Researcher step: browser/screenshot tool fetches reference images, stats, or clips if the script references external information.
- [ ] Screen editor step: Tella handles screen/webcam recordings or structured clip assembly.
- [ ] Sound designer step: licensed Artlist music/sfx matched to mood and duration.
- [ ] Finisher step: FFmpeg assembles, encodes, and exports the final draft.
- [ ] Milton can add a new style by describing it in natural language, without rebuilding the engine.
- [ ] Jarvis can invoke the system with a simple command and return the rendered file path or a review link.
- [ ] A fallback path exists so Milton can open any AI draft in DaVinci Resolve for manual finishing.

## Context check

- [x] Goal is clear: plan (not build yet) an AI-assisted editing system for Rolling Glide.
- [x] Intention is clear: reduce manual editing hours on recurring community videos.
- [ ] Constraints are partially known: Artlist API access for personal subscriptions is unconfirmed; infrastructure choice (Docker/Windows vs Proxmox) is open.
- [ ] "Good enough" needs confirmation: fully automatic exports, or AI-assisted drafts that Milton always reviews before publishing?

## Logical / chronological breakdown

| Phase | Step | Action | Estimated time | Dependencies | Owner |
| ----- | ---- | ------ | -------------- | ------------ | ----- |
| 0. Style discovery | 1 | Decide how to capture Milton's editing style: analyze existing final videos vs. interview him about clip selection, pacing, music, captions, and color. | 1 session | none | owner + Jarvis |
| 0. Style discovery | 2 | Gather 2–3 representative final videos for each style (recap, announcement/B-roll) and break them into editing decision records. | 2–3 hrs | step 1 | owner |
| 0. Style discovery | 3 | Write the first two style templates as structured files (YAML/JSON + Markdown) describing: source clip types, ideal shot length, music energy, B-roll rules, caption style, export spec. | 2–4 hrs | step 2 | Jarvis with owner review |
| 1. Architecture | 4 | Choose integration shape: **skill inside Jarvis** vs. **standalone video service/tool** that Jarvis calls. | 1 session | none | owner + Jarvis |
| 1. Architecture | 5 | Choose infrastructure: keep current Docker-on-Windows, or migrate host to Proxmox with Windows VM + GPU passthrough for DaVinci Resolve and LXC/container for Jarvis/video processing. | 1 session | none | owner |
| 1. Architecture | 6 | Provision the chosen environment with GPU-visible FFmpeg and HyperFrames CLI. | 2–6 hrs | step 5 | owner + Jarvis |
| 2. Core pipeline (reference workflow) | 7 | Build the **editor** step: an LLM/agent that reads the brief/style and coordinates the other pipeline steps. | 2–4 hrs | steps 3, 6 | Jarvis |
| 2. Core pipeline (reference workflow) | 8 | Build the **transcriber** step: transcribe speech to derive captions and timing. Evaluate Parakeet vs. built-in Whisper/FFmpeg or ElevenLabs Scribe. | 2–4 hrs | step 6 | Jarvis |
| 2. Core pipeline (reference workflow) | 9 | Build the **animator** step: HyperFrames renders branded overlays, lower-thirds, titles, and any HTML/CSS motion graphics. | 2–4 hrs | step 6 | Jarvis |
| 2. Core pipeline (reference workflow) | 10 | Build the **researcher** step: browser/screenshot tool that fetches reference images, stats, or clips if the script references external information. | 2–4 hrs | step 6 | Jarvis |
| 2. Core pipeline (reference workflow) | 11 | Build the **screen editor** step: Tella API/MCP integration or local folder intake for screen/webcam recordings. | 2–4 hrs | step 6 | owner + Jarvis |
| 2. Core pipeline (reference workflow) | 12 | Build the **sound designer** step: local Artlist library folder with mood/tempo metadata; select and trim music and SFX. | 2–4 hrs | none | owner + Jarvis |
| 2. Core pipeline (reference workflow) | 13 | Build the **finisher** step: FFmpeg assembles, adds captions, mixes audio, applies overlays, and encodes to platform specs. | 4–8 hrs | steps 6, 8, 9, 11, 12 | Jarvis |
| 3. Style engine | 14 | Build a style parser that maps a style template + available footage + music to an edit decision list (EDL / JSON). | 4–8 hrs | steps 3, 13 | Jarvis |
| 3. Style engine | 15 | Implement **recap** style generator: select best moments, sync to music beats, intersperse wide/crowd/detail shots, add captions for names/quotes if available. | 4–8 hrs | step 14 | Jarvis with owner feedback |
| 3. Style engine | 16 | Implement **announcement / talking-head with B-roll** style generator: place A-roll segments, insert illustrative B-roll from past events, add lower-thirds/titles. | 4–8 hrs | step 14 | Jarvis with owner feedback |
| 3. Style engine | 17 | Build "new style onboarding" flow: Milton describes a new format in natural language; Jarvis translates it into a new style template file and a checklist for validation. | 4–6 hrs | step 14 | Jarvis |
| 4. Validation | 18 | Run test renders on real Rolling Glide footage and compare side-by-side with Milton's manual edits. | 3–5 hrs | steps 15, 16 | owner + Jarvis |
| 4. Validation | 19 | Refine templates and prompt flows based on feedback until the draft is consistently usable. | ongoing | step 18 | Jarvis |
| 5. Jarvis wiring | 20 | Expose the system to Jarvis: either as a loadable skill or as a tool call to the standalone service. | 2–4 hrs | step 4, 19 | Jarvis |
| 5. Jarvis wiring | 21 | Add natural-language commands and session logging so Jarvis can track runs, outputs, and owner feedback. | 2–4 hrs | step 20 | Jarvis |

## Dialectical tensions

| Tension | Option A | Option B | Decision | Confidence |
| ------- | -------- | -------- | -------- | ---------- |
| **Where the engine lives** | **Skill inside Jarvis**: one system, natural language activation, shared vault memory, but video processing runs in the same process/container and can slow or crash Jarvis. | **Standalone video service**: separate container/VM with its own API; better isolation, can restart/redeploy independently and use GPU differently; slightly more setup and one more thing to maintain. | **Standalone service** ✅ (owner confirmed). Start as a separate service that Jarvis calls via API or MCP tools. | medium |
| **How to capture style** | **Analyze existing videos** with HyperFrames/AI to infer cuts, pacing, and music cues. More automated but may miss the "why" behind choices and needs a corpus. | **Interview Milton** about how he selects clips, times cuts, and pairs music. Slower upfront but captures intent and is easier to extend to new styles. | **Both** ✅ (owner confirmed). Interview first to capture intent, then validate against existing final videos. | high |
| **Infrastructure** | **MacBook local Jarvis**: simpler interaction, always with Milton, but may lack GPU power for heavy rendering and could strain the laptop during long renders. | **Windows gaming PC Docker**: much stronger GPU for FFmpeg/HyperFrames rendering, but currently runs in a Docker container and may be less convenient for day-to-day interaction. | **MacBook for the interaction workflow; consider Windows PC as render target for heavy exports once pipeline is proven** ✅. Owner wants to operate from the MacBook. | medium |
| **Music sourcing** | **Artlist Enterprise API**: true automation, but likely requires a business/enterprise account and sales approval. | **Local Artlist library**: Milton downloads tracks/sfx manually into a watched folder; system matches by mood/tempo/BPM metadata. Simpler and works with the current subscription. | **Local Artlist library** ✅ (owner confirmed). Upgrade to Enterprise API only if volume justifies it. | high |
| **Level of automation** | **Fully automatic**: Milton gives a prompt and gets a final export. Fastest, but may produce misses that hurt brand. | **AI-assisted draft**: system produces a rough cut with an EDL/render that Milton reviews in Resolve or a simple UI before publishing. Slightly slower but preserves quality control. | **AI-assisted drafts** ✅ (owner confirmed). Final creative veto stays with Milton. | high |

## Materials / tools / information needed

- [ ] HyperFrames CLI installed and working with GPU-accelerated rendering.
- [ ] FFmpeg compiled with desired codecs and hardware acceleration (NVENC/AMF/QuickSync depending on GPU).
- [ ] Tella API key and confirmed endpoint access, OR a local intake folder workflow.
- [ ] Parakeet or equivalent transcription setup (evaluate alongside Whisper/ElevenLabs Scribe options).
- [ ] Browser/screenshot tool for the researcher step (e.g., Playwright, Puppeteer, or a simple MCP browser server).
- [ ] Artlist subscription details and a decision on API vs. local music library.
- [ ] 2–3 representative Rolling Glide recap videos and 2–3 announcement/B-roll videos.
- [ ] Source footage for at least one upcoming or past event to use as a test set.
- [ ] Rolling Glide brand assets: logo, fonts, color hex codes, preferred lower-third style.
- [ ] Target export specs for each platform (Instagram Reel, Feed, Story, YouTube Short, etc.).
- [ ] DaVinci Resolve remote rendering workflow preserved so manual finishing remains possible.
- [ ] Input footage can remain log; system applies a default LUT only to log clips, and passes graded clips through.
- [ ] System outputs a Resolve-compatible timeline/EDL with selected source clips and a reference render so Milton can apply final color grading.

## Schedule proposal

| Phase | Proposed timing | Calendar event? |
| ----- | --------------- | --------------- |
| 0. Style discovery — recap style | This session or next; ~20–30 min | yes (if owner wants) |
| 0. Style discovery — announcement/B-roll style | After recap style is drafted and validated | yes |
| 1. Architecture decision | Within this week | yes |
| 2. Core integrations | After architecture locked; 1–2 weekends of focused work | yes |
| 3. Style engine | Once integrations work; 1–2 weeks | yes |
| 4. Validation | As soon as first styles render; ongoing | yes |
| 5. Jarvis wiring | Final step once draft quality is acceptable | yes |

## Risks and unknowns

- **Artlist API eligibility**: The personal Artlist subscription likely does not include the Enterprise API (developer.artlist.io appears to require account-manager access). We may be limited to a manually-curated local music library.
- **MacBook GPU limitations**: Rendering 30–60 second vertical videos with HyperFrames + FFmpeg may be slow on a MacBook without a dedicated GPU. We may need to keep the Windows gaming PC as a remote render target, or accept longer render times.
- **Two-instance Jarvis sync**: Milton has Jarvis on both MacBook and Windows. The video editing service needs to be reachable from whichever instance he is using, and project state must not get fragmented between the two.
- **HyperFrames maturity**: HyperFrames is agent-native and promising, but for some graphics we may still need fallback overlays rendered with FFmpeg or ImageMagick.
- **AI clip judgment**: Community footage has emotional nuance (a great fall, a teachable moment, a group cheer) that an automated selector may miss without explicit rules or examples.
- **Scope creep**: "Add new styles by describing them" is powerful but can expand quickly. We should lock the first two styles before building the general style-onboarding feature.

## Decisions confirmed

- Engine location: **Standalone service called by Jarvis** ✅
- Infrastructure timing: **Use local MacBook Jarvis instance for the editing workflow; Windows Docker/PC setup remains available but is no longer the primary target** ✅
- Music workflow: **Local Artlist library folder** ✅
- Automation level: **AI-assisted drafts reviewed by Milton before publishing** ✅
- Style capture: **Interview first + validate against existing videos** ✅
- Owner accepted Jarvis's recommendations for the remaining architecture and workflow choices ✅

## Approval requested

- [x] Approve the locked plan and begin Phase 0 (style discovery) — approved 2026-11-10 08:11 AM MST
- [ ] Approve scheduling the first style-discovery session
- [ ] Approve adding this project to Rolling Glide's active plans tracker
