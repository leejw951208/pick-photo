from pathlib import Path


class StorageKeyError(ValueError):
    pass


class StorageRoot:
    def __init__(self, root: str | Path):
        self.root = Path(root).expanduser().resolve()

    def resolve_existing(self, storage_key: str) -> Path:
        path = self._resolve(storage_key)
        if not path.is_file():
            raise StorageKeyError(
                f"Storage key does not point to a file: {storage_key}",
            )
        return path

    def resolve_output(self, storage_key: str) -> Path:
        path = self._resolve(storage_key)
        path.parent.mkdir(parents=True, exist_ok=True)
        return path

    def _resolve(self, storage_key: str) -> Path:
        key_path = Path(storage_key)
        if key_path.is_absolute():
            raise StorageKeyError("Storage key must be relative.")

        candidate = (self.root / key_path).resolve()
        if candidate != self.root and self.root not in candidate.parents:
            raise StorageKeyError("Storage key escapes the storage root.")

        return candidate
