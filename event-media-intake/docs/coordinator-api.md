# Coordinator API

This document describes the HTTP API that the **event coordinator service** uses to interact with the **event media upload service**.

All endpoints except `/api/health` require authentication via:

```
Authorization: Bearer <UPLOAD_SERVICE_API_KEY>
```

## Endpoints

### `POST /api/check-file`

Check whether a file should be uploaded, resumed, or skipped.

**Request body:**

```json
{
  "uploaderId": "uuid-string",
  "fingerprint": "sha256-hex-string",
  "fileName": "IMG_1234.jpg",
  "fileSize": 12345678,
  "mimeType": "image/jpeg"
}
```

**Response cases:**

| Case | HTTP | Response |
| ---- | ---- | -------- |
| New file | 200 | `{ "status": "new" }` |
| Unfinished resumable upload exists | 200 | `{ "status": "resumable", "uploadUrl": "..." }` |
| Completed duplicate exists | 200 | `{ "status": "duplicate", "fileId": "...", "fileName": "..." }` |

### `POST /api/init-upload`

Create a new resumable upload session.

**Request body:**

```json
{
  "uploaderId": "uuid-string",
  "uploaderName": "Alex S.",
  "fileName": "IMG_1234.jpg",
  "fileSize": 12345678,
  "mimeType": "image/jpeg",
  "fingerprint": "sha256-hex-string",
  "folderId": "1A2B3C...",
  "mode": "standard" | "replace" | "keep_both"
}
```

**Response:**

```json
{
  "uploadUrl": "https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&upload_id=..."
}
```

**Errors:**

| HTTP | Reason |
| ---- | ------ |
| 400 | Missing/invalid fields |
| 413 | File exceeds 5 GB |
| 429 | Too many init-upload requests |

### `POST /api/complete-upload`

Verify the file in Google Drive and finalize the upload record.

**Request body:**

```json
{
  "uploaderId": "uuid-string",
  "fingerprint": "sha256-hex-string",
  "copyIndex": 0,
  "driveFileId": "abc123..."
}
```

**Response:**

```json
{
  "status": "completed",
  "fileId": "abc123...",
  "fileName": "IMG_1234.jpg"
}
```

If `mode` was `replace`, the old Drive file is deleted and the old row is marked `replaced`.

### `GET /api/health`

Liveness/readiness check. No authentication required.

**Response:**

```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2026-11-01T18:00:00.000Z"
}
```

## Client upload flow

1. Coordinator calls `POST /api/check-file`.
2. If `status` is `new` or `replace`/`keep_both` is needed, call `POST /api/init-upload`.
3. Return the `uploadUrl` to the browser.
4. Browser uploads chunks directly to Google Drive using the resumable session URL.
5. Browser notifies coordinator when done.
6. Coordinator calls `POST /api/complete-upload` to verify and finalize.

## Limits

- Max single file: 5 GB
- `init-upload` calls: 100 per minute per API key
- Resumable session URLs expire after approximately 7 days of inactivity
