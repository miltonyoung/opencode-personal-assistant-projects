export function sanitizeFileName(fileName) {
  if (!fileName || typeof fileName !== 'string') {
    return 'untitled';
  }

  // Remove null bytes and control characters.
  let sanitized = fileName.replace(/[\x00-\x1f\x7f]/g, '');

  // Remove path separators.
  sanitized = sanitized.replace(/[/\\]/g, '_');

  // Trim whitespace.
  sanitized = sanitized.trim();

  // Limit length, preserving extension if possible.
  const maxLength = 255;
  if (sanitized.length > maxLength) {
    const extMatch = sanitized.match(/\.([a-zA-Z0-9]{1,10})$/);
    const ext = extMatch ? extMatch[0] : '';
    const base = ext ? sanitized.slice(0, -ext.length) : sanitized;
    sanitized = base.slice(0, maxLength - ext.length) + ext;
  }

  return sanitized || 'untitled';
}

export function generateCopyFileName(fileName, copyIndex) {
  if (copyIndex <= 0) {
    return fileName;
  }

  const match = fileName.match(/^(.*)(\.[^.]+)$/);
  if (match) {
    return `${match[1]} (${copyIndex})${match[2]}`;
  }

  return `${fileName} (${copyIndex})`;
}
