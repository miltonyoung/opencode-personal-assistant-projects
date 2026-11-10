# AI-Assisted Video Editor

A brand-agnostic, Jarvis-callable video editing service.

## How it works

1. **Brand style templates** live in each project's own folder (e.g., `/app-projects/roll-n-glide/video-styles/recap.md`).
2. **This engine** ingests source footage, reads the style template, and produces a draft edit.
3. **Output:** a Resolve-compatible EDL + reference render + notes file so Milton can finish in DaVinci Resolve.

## Current status

- The first validation style is the Rolling Glide recap style.
- The engine itself is not yet built.
- See `plan.md` for the build roadmap and `START-HERE.md` for the active next step.

## Project layout

```
video-editor/
├── plan.md              # Build plan and progress tracker
├── README.md            # This file
├── START-HERE.md        # Resume pointer for Jarvis
├── src/                 # Service source code (to be created)
├── styles/              # Generic style parser and shared templates
└── tests/               # Test fixtures and sample footage
```
