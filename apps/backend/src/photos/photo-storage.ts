import { createHash } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { basename, extname, join } from 'node:path';

export interface SaveUploadInput {
  uploadId: string;
  originalName: string;
  contentType: string;
  bytes: Buffer;
}

export const PHOTO_STORAGE = Symbol('PHOTO_STORAGE');

export interface PhotoStorage {
  saveUpload(input: SaveUploadInput): Promise<string>;
}

export class LocalPhotoStorage implements PhotoStorage {
  constructor(
    private readonly rootDir = process.env.PHOTO_STORAGE_DIR ??
      join(process.cwd(), 'storage'),
  ) {}

  async saveUpload(input: SaveUploadInput): Promise<string> {
    const safeFilename = this.safeFilename(input.originalName, input.bytes);
    const storageKey = join('uploads', input.uploadId, safeFilename);
    const absolutePath = join(this.rootDir, storageKey);

    await mkdir(join(this.rootDir, 'uploads', input.uploadId), {
      recursive: true,
    });
    await writeFile(absolutePath, input.bytes);

    return storageKey.split('\\').join('/');
  }

  private safeFilename(originalName: string, bytes: Buffer): string {
    const baseName = basename(originalName);
    const extension = extname(baseName).toLowerCase();
    const stem = baseName.slice(0, baseName.length - extension.length);
    const safeStem = stem
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
    const fallbackStem = createHash('sha256')
      .update(bytes)
      .digest('hex')
      .slice(0, 16);

    return `${safeStem || fallbackStem}${extension || '.bin'}`;
  }
}

export function createPhotoStorage(): PhotoStorage {
  return new LocalPhotoStorage();
}
