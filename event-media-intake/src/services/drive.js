import { OAuth2Client } from 'google-auth-library';
import { config } from '../config.js';

let authClient = null;

export function getAuthClient() {
  if (authClient) {
    return authClient;
  }

  if (!config.google.refreshToken) {
    throw new Error('Google refresh token is not configured');
  }

  authClient = new OAuth2Client(
    config.google.clientId,
    config.google.clientSecret
  );
  authClient.setCredentials({
    refresh_token: config.google.refreshToken,
    scope: config.google.scope,
  });

  return authClient;
}

/**
 * Create a Google Drive resumable upload session.
 * Returns the upload URL.
 */
export async function createResumableSession({
  fileName,
  mimeType,
  folderId,
}) {
  const auth = getAuthClient();
  const accessToken = await auth.getAccessToken();

  const metadata = {
    name: fileName,
    mimeType,
    parents: folderId ? [folderId] : undefined,
  };

  const response = await fetch('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Upload-Content-Type': mimeType,
    },
    body: JSON.stringify(metadata),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to create resumable session: ${response.status} ${text}`);
  }

  const uploadUrl = response.headers.get('Location');
  if (!uploadUrl) {
    throw new Error('Google did not return a resumable upload URL');
  }

  return uploadUrl;
}

/**
 * Verify a file exists in Google Drive and optionally matches expected size.
 */
export async function getDriveFile(fileId) {
  const auth = getAuthClient();
  const accessToken = await auth.getAccessToken();

  const response = await fetch(
    `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?fields=id,name,size,mimeType`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );

  if (!response.ok) {
    if (response.status === 404) {
      return null;
    }
    const text = await response.text();
    throw new Error(`Failed to get Drive file: ${response.status} ${text}`);
  }

  return response.json();
}

/**
 * Delete a file from Google Drive.
 */
export async function deleteDriveFile(fileId) {
  const auth = getAuthClient();
  const accessToken = await auth.getAccessToken();

  const response = await fetch(
    `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}`,
    {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );

  if (!response.ok && response.status !== 404) {
    const text = await response.text();
    throw new Error(`Failed to delete Drive file: ${response.status} ${text}`);
  }

  return true;
}
