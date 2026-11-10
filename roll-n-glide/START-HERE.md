# Start here on any new Jarvis session for Rolling Glide video editing

## What this project is

Building an AI-assisted video editing system for Rolling Glide, starting with a **recap video** style.

## Current state (updated 2026-11-10)

- ✅ Recap style template captured from interview + existing videos.
- ✅ Architecture locked: standalone service, hosted on Milton's MacBook, called by Jarvis.
- ✅ Repos pushed to GitHub. Pull before working.
- ⏳ **Next active step:** discover and provision the MacBook.

## If you are resuming this project

1. Pull latest:
   ```bash
   cd /app && git pull origin main
   cd /app-projects && git pull origin main
   ```
2. Read the current plan:
   `/app-projects/roll-n-glide/plans/ai-video-editing-system/plan.md`
3. Check the progress tracker in that plan.
4. Do the **next uncompleted step only**. Do not jump ahead.

## Active next step: MacBook discovery and provisioning

Run these commands on Milton's MacBook and save results:

```bash
system_profiler SPHardwareDataType | head -20
sw_vers
which ffmpeg && ffmpeg -version | head -1
which ffprobe && ffprobe -version | head -1
which hyperframes && hyperframes --version 2>/dev/null || echo "HyperFrames CLI not found"
ls -d /Applications/DaVinci\ Resolve/DaVinci\ Resolve.app 2>/dev/null || echo "Resolve not in /Applications"
which brew && brew --version
which npm && npm --version
which node && node --version
which uv && uv --version
which python3 && python3 --version
ls -d ~/Music/Artlist 2>/dev/null || echo "No ~/Music/Artlist"
ls -d ~/Downloads/Artlist 2>/dev/null || echo "No ~/Downloads/Artlist"
```

Then:

1. Save the output to `/app-projects/roll-n-glide/video-styles/.context/macbook-context.md`.
2. Ask Milton to confirm the path to his local Artlist music library if it wasn't auto-detected.
3. Install anything missing (`brew install ffmpeg`, install HyperFrames CLI, ensure `uv` is available).
4. Update the plan's progress tracker and commit.

## Important rules

- This is a **build project**, not a working editor. Do not accept video files from Milton expecting to process them until the pipeline is implemented.
- The only active style is **recap**. The announcement/B-roll style has been skipped.
- Always commit and push after each session so both Jarvis instances stay in sync.
