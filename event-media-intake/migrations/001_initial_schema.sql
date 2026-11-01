-- Initial schema for the event media upload service.
-- Designed for resumable-only uploads to Google Drive.

CREATE TABLE IF NOT EXISTS uploads (
    id SERIAL PRIMARY KEY,
    uploader_id UUID NOT NULL,
    display_name VARCHAR(100),
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(128),
    fingerprint VARCHAR(64) NOT NULL,
    copy_index INT NOT NULL DEFAULT 0,
    session_url TEXT,
    drive_file_id VARCHAR(128),
    folder_id VARCHAR(128) NOT NULL,
    status VARCHAR(32) DEFAULT 'pending',
    mode VARCHAR(32) DEFAULT 'standard',
    replaces_upload_id INT REFERENCES uploads(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT unique_uploader_fingerprint_copy UNIQUE (uploader_id, fingerprint, copy_index)
);

CREATE INDEX IF NOT EXISTS idx_uploads_uploader_fingerprint ON uploads(uploader_id, fingerprint);
CREATE INDEX IF NOT EXISTS idx_uploads_status ON uploads(status);
CREATE INDEX IF NOT EXISTS idx_uploads_folder_id ON uploads(folder_id);
CREATE INDEX IF NOT EXISTS idx_uploads_created_at ON uploads(created_at);
CREATE INDEX IF NOT EXISTS idx_uploads_completed_at ON uploads(completed_at) WHERE completed_at IS NOT NULL;

-- Migration bookkeeping table.
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
