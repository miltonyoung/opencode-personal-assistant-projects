import assert from 'node:assert';
import { describe, it } from 'node:test';
import { sanitizeFileName, generateCopyFileName } from '../src/services/files.js';

describe('sanitizeFileName', () => {
  it('preserves a normal filename', () => {
    assert.strictEqual(sanitizeFileName('IMG_1234.jpg'), 'IMG_1234.jpg');
  });

  it('removes path separators', () => {
    assert.strictEqual(sanitizeFileName('foo/bar.jpg'), 'foo_bar.jpg');
  });

  it('truncates long names while preserving extension', () => {
    const longName = 'a'.repeat(300) + '.png';
    const sanitized = sanitizeFileName(longName);
    assert.ok(sanitized.endsWith('.png'));
    assert.ok(sanitized.length <= 255);
  });
});

describe('generateCopyFileName', () => {
  it('returns the original name for copy index 0', () => {
    assert.strictEqual(generateCopyFileName('photo.jpg', 0), 'photo.jpg');
  });

  it('generates a Windows-style counter', () => {
    assert.strictEqual(generateCopyFileName('photo.jpg', 2), 'photo (2).jpg');
  });
});
