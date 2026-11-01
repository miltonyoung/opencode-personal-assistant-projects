/**
 * Browser-side resumable upload library for the Event Media Upload Service.
 *
 * This is a stub / scaffolding file. The full implementation will:
 *  - Compute a fast composite fingerprint from file metadata + head/tail samples.
 *  - Call the coordinator service to check/init/complete uploads.
 *  - Stream chunks directly to the Google Drive resumable session URL.
 *  - Parse 308 Range headers and resume from the last received byte.
 *  - Enforce 3–5 concurrent uploads with a queue.
 *  - Retry chunks with exponential backoff + jitter.
 */

const DEFAULT_CHUNK_SIZE = 10 * 1024 * 1024; // 10 MB
const MAX_RETRIES = 5;

/**
 * Compute a fast composite fingerprint for same-device deduplication.
 *
 * Samples 1 MB from the head and 1 MB from the tail of the file.
 */
export async function computeFingerprint(file) {
  const sampleSize = Math.min(1024 * 1024, file.size);

  const head = file.slice(0, sampleSize);
  const tail = file.slice(Math.max(0, file.size - sampleSize), file.size);

  const [headHash, tailHash] = await Promise.all([
    digestBlob(head),
    digestBlob(tail),
  ]);

  const raw = `${file.name}-${file.size}-${file.lastModified}-${headHash}-${tailHash}`;
  return digestText(raw);
}

async function digestBlob(blob) {
  const buffer = await blob.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
  return bufferToHex(hashBuffer);
}

async function digestText(text) {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  return bufferToHex(hashBuffer);
}

function bufferToHex(buffer) {
  const bytes = new Uint8Array(buffer);
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export class ResumableUploader {
  constructor({ uploadUrl, file, chunkSize = DEFAULT_CHUNK_SIZE }) {
    this.uploadUrl = uploadUrl;
    this.file = file;
    this.chunkSize = chunkSize;
    this.startByte = 0;
    this.retries = 0;
  }

  async upload({ onProgress, onChunkUploaded }) {
    // 1. Query current status if resuming.
    await this.queryStatus();

    // 2. Chunk loop.
    while (this.startByte < this.file.size) {
      const endByte = Math.min(this.startByte + this.chunkSize, this.file.size);
      const chunk = this.file.slice(this.startByte, endByte);

      try {
        await this.uploadChunk(chunk, this.startByte, endByte, this.file.size, this.file.type);
      } catch (err) {
        if (this.retries >= MAX_RETRIES) {
          throw new Error(`Upload failed after ${MAX_RETRIES} retries: ${err.message}`);
        }
        this.retries += 1;
        await delay(1000 * 2 ** this.retries + Math.random() * 1000);
        continue;
      }

      this.startByte = endByte;
      this.retries = 0;

      if (onProgress) {
        onProgress({ loaded: this.startByte, total: this.file.size });
      }
      if (onChunkUploaded) {
        onChunkUploaded({ startByte, endByte });
      }
    }

    // 3. Final status query to confirm completion.
    await this.queryStatus();

    return { uploadedBytes: this.file.size };
  }

  async queryStatus() {
    const response = await fetch(this.uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Range': `bytes */${this.file.size}`,
      },
    });

    if (response.status === 200 || response.status === 201) {
      this.startByte = this.file.size;
      return;
    }

    if (response.status === 308) {
      const range = response.headers.get('Range');
      this.startByte = parseRangeEnd(range) + 1;
    }
  }

  async uploadChunk(chunk, startByte, endByte, totalBytes, mimeType) {
    const response = await fetch(this.uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Range': `bytes ${startByte}-${endByte - 1}/${totalBytes}`,
        'Content-Type': mimeType,
      },
      body: chunk,
    });

    if (response.status === 308) {
      const range = response.headers.get('Range');
      this.startByte = parseRangeEnd(range) + 1;
      throw new Error('Chunk accepted but incomplete; resuming.');
    }

    if (!response.ok) {
      throw new Error(`Chunk upload failed: ${response.status} ${response.statusText}`);
    }
  }
}

function parseRangeEnd(rangeHeader) {
  if (!rangeHeader) return -1;
  const match = rangeHeader.match(/bytes=\d+-(\d+)/);
  return match ? parseInt(match[1], 10) : -1;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
