# GenIdem Project Context

This file provides always-on context for any OpenCode session inside the `GenIdem Business Plan` directory or when the user mentions GenIdem.

## Auto-Load Trigger

When the user says anything like the following, the assistant should treat it as a request to continue working on the GenIdem business plan:

- "continue working on GenIdem"
- "let's work on GenIdem"
- "GenIdem business plan"
- "GenIdem"
- "photo booth business"
- "Milton and Idara business"

## First Action on Trigger

1. Read `/Users/milton/Documents/GenIdem Business Plan/00-start-here.md`.
2. Ask the user what they want to work on next.
3. Do not make assumptions about Idara Ekpoh's preferences or decisions without confirming.

## Document Map

| File | Purpose |
|------|---------|
| `00-start-here.md` | Living session continuation guide |
| `01-overview.md` | Business snapshot |
| `02-rollout-plan.md` | 3-stage rollout |
| `03-operations-technical.md` | Gear, workflow, setup |
| `04-legal-financial.md` | LLC, contracts, pricing, budgets |
| `05-marketing-launch.md` | Marketing and launch strategy |
| `06-next-steps.md` | 30/60/90-day action plan |
| `Supporting Research/glam-bot-marketing-analysis.md` | Glam Bot research |

## Maintenance Rule

Keep `00-start-here.md` updated whenever significant decisions, numbers, or priorities change during a session. At minimum, update the "Decisions Already Made" table and "Unresolved / Open Questions" section before ending work.

## Project Guardrails

- The MVP is intentionally lean. Avoid expensive gear, kiosk builds, or booth software subscriptions until Stage 1 is proven with paid events.
- Pricing is set: $150/hour, 2-hour minimum, $100 setup fee, $50/hour attendant fee.
- B2B is part of the strategy but positioned as affordable-quality, not luxury.
- Future video / Glam Bot-style activations are planned but not part of the MVP.
