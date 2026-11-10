# Start here on any new Jarvis session for Rolling Glide

## What this project is

Rolling Glide community content, operations, and brand assets. The video editing work uses a shared generic engine; only the Rolling Glide-specific style files live here.

## Current state (updated 2026-11-10)

- ✅ Recap style template written: `/app-projects/roll-n-glide/video-styles/recap.md`.
- ✅ Generic AI video editor architecture locked.
- ✅ Repos pushed to GitHub. Pull before working.
- ⏳ **Next active step for video work:** the generic engine is being provisioned on Milton's MacBook. See `/app-projects/video-editor/START-HERE.md`.

## If you are resuming Rolling Glide video work

1. Pull latest:
   ```bash
   cd /app && git pull origin main
   cd /app-projects && git pull origin main
   ```
2. Read the Rolling Glide recap style:
   `/app-projects/roll-n-glide/video-styles/recap.md`
3. Read the generic engine plan:
   `/app-projects/video-editor/plan.md`
4. Check the engine's progress tracker and do the **next uncompleted step**.

## Active next step

The generic video editor engine is being built first. The recap style is the first validation target, but all build work happens in `/app-projects/video-editor/`.

When the engine reaches Phase 4 (Validation), use Rolling Glide footage to test the recap style and refine `/app-projects/roll-n-glide/video-styles/recap.md`.

## Important rules

- Do not accept video files from Milton expecting to process them until the engine is implemented.
- The announcement/B-roll style has been skipped for now.
- Brand-specific styles stay in this folder. The engine stays generic.
- Always commit and push after each session.
