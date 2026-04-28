from pathlib import Path

import pytest

from app.storage import StorageKeyError, StorageRoot


def test_resolve_existing_accepts_key_inside_root(tmp_path: Path):
    source = tmp_path / "uploads" / "upload-1" / "source.jpg"
    source.parent.mkdir(parents=True)
    source.write_bytes(b"image-bytes")

    storage = StorageRoot(tmp_path)

    assert storage.resolve_existing("uploads/upload-1/source.jpg") == source


def test_resolve_existing_rejects_path_traversal(tmp_path: Path):
    storage = StorageRoot(tmp_path)

    with pytest.raises(StorageKeyError):
        storage.resolve_existing("../outside.jpg")


def test_resolve_output_creates_parent_inside_root(tmp_path: Path):
    storage = StorageRoot(tmp_path)

    output = storage.resolve_output("generated/upload-1/face-1.jpg")

    assert output == tmp_path / "generated" / "upload-1" / "face-1.jpg"
    assert output.parent.is_dir()


def test_resolve_output_rejects_absolute_path(tmp_path: Path):
    storage = StorageRoot(tmp_path)

    with pytest.raises(StorageKeyError):
        storage.resolve_output("/tmp/outside.jpg")
