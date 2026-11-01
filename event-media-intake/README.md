# Event Media Upload Service

A self-hosted upload manager for event media. Guests stream photos and videos directly to the organizer's Google Drive; this service only exchanges JSON metadata with the event coordinator and never sees the file bytes.

## What this service does

- Creates Google Drive resumable upload sessions.
- Detects duplicate uploads and offers Skip / Replace / Keep Both.
- Verifies files in Google Drive after upload completes.
- Enforces global safety limits (5 GB max file, 100 init-upload calls/min per API key).
- Prunes old database rows according to retention rules.

## What this service does NOT do

- Generate QR codes or event landing pages.
- Authenticate guests or manage event lifecycle.
- Create folders or manage sharing.

Those responsibilities live in the separate **event coordinator service**, which calls this upload service over a private Docker network.

## Architecture

```text
┌─────────────────────┐
│  Attendee Browser   │
└──────────┬──────────┘
           │
           │ Frontend talks to coordinator
           ▼
┌─────────────────────┐     ┌─────────────────────────┐
│ Event Coordinator   │────▶│ Event Media Upload      │
│ Service             │     │ Service (this repo)     │
└─────────────────────┘     └────────────┬────────────┘
                                         │
                                         │ JSON metadata
                                         ▼
                                ┌─────────────────┐
                                │   PostgreSQL    │
                                └────────┬────────┘
                                         │
                                         │ Organizer OAuth
                                         ▼
                                ┌─────────────────┐
                                │  Google Drive   │
                                └─────────────────┘
```

## Quick start

1. Copy `.env.example` to `.env` and fill in values.
2. Start PostgreSQL and the service:
   ```bash
   docker compose up --build
   ```
3. Run migrations:
   ```bash
   docker compose exec upload-service npm run migrate
   ```
4. Verify health:
   ```bash
   curl http://localhost:3000/api/health
   ```

## API for the coordinator service

See [`docs/coordinator-api.md`](docs/coordinator-api.md) for the full contract.

## Development

```bash
# Install dependencies
npm install

# Run migrations
npm run migrate

# Start in development mode
npm run dev

# Lint
npm run lint

# Run tests
npm test
```

## Project structure

```
.
├── docker-compose.yml
├── Dockerfile
├── migrations/
│   └── 001_initial_schema.sql
├── src/
│   ├── index.js              # HTTP server entry point
│   ├── app.js                # Express app wiring
│   ├── config.js             # Environment-based config
│   ├── db/
│   │   ├── pool.js           # PostgreSQL connection pool
│   │   ├── migrate.js        # Migration runner
│   │   └── queries.js        # SQL queries
│   ├── middleware/
│   │   ├── auth.js           # API key authentication
│   │   ├── error-handler.js  # Centralized error handler
│   │   └── rate-limit.js     # Init-upload rate limiter
│   ├── routes/
│   │   ├── health.js
│   │   ├── check-file.js
│   │   ├── init-upload.js
│   │   └── complete-upload.js
│   ├── services/
│   │   ├── drive.js          # Google Drive API helpers
│   │   └── files.js          # Filename / fingerprint utilities
│   └── lib/
│       └── retention.js      # Pruning logic
├── client-lib/
│   └── uploader.js           # Browser-side upload library (stub)
├── tests/
│   └── *.test.js
└── docs/
    └── coordinator-api.md
```

## License

MIT
