from pathlib import Path

from app.fake_ai import detect_faces, generate_id_photo
from app.main import app
from app.schemas import DetectFacesRequest, GenerateIdPhotoRequest
from fastapi.testclient import TestClient
from PIL import Image


client = TestClient(app)


def test_detect_faces_request_accepts_storage_key():
    request = DetectFacesRequest(upload_id="upload-1", storage_key="uploads/source.jpg")

    assert request.upload_id == "upload-1"
    assert request.storage_key == "uploads/source.jpg"


def test_generate_id_photo_request_accepts_face_box():
    request = GenerateIdPhotoRequest(
        upload_id="upload-1",
        face_id="face-1",
        source_storage_key="uploads/source.jpg",
        box={"left": 10, "top": 20, "width": 100, "height": 120},
    )

    assert request.face_id == "face-1"
    assert request.box.width == 100


def test_fake_detection_returns_one_face_for_normal_key():
    response = detect_faces(
        DetectFacesRequest(upload_id="upload-1", storage_key="uploads/source.jpg"),
    )

    assert len(response.faces) == 1
    assert response.faces[0].face_index == 0


def test_fake_detection_returns_no_faces_for_no_face_key():
    response = detect_faces(
        DetectFacesRequest(upload_id="upload-1", storage_key="uploads/no-face.jpg"),
    )

    assert response.faces == []


def test_fake_generation_returns_result_reference():
    response = generate_id_photo(
        GenerateIdPhotoRequest(
            upload_id="upload-1",
            face_id="face-1",
            source_storage_key="uploads/source.jpg",
            box={"left": 10, "top": 20, "width": 100, "height": 120},
        )
    )

    assert response.result_storage_key == "generated/upload-1/face-1.jpg"
    assert response.content_type == "image/jpeg"


def save_endpoint_image(root: Path, key: str):
    path = root / key
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", (320, 240), color="white").save(path, format="JPEG")


def test_detect_faces_endpoint_uses_fake_mode(monkeypatch):
    monkeypatch.setenv("PICK_PHOTO_AI_MODE", "fake")
    response = client.post(
        "/detect-faces",
        json={"upload_id": "upload-1", "storage_key": "uploads/source.jpg"},
    )

    assert response.status_code == 200
    assert response.json()["faces"][0]["face_id"] == "upload-1-face-0"


def test_detect_faces_endpoint_uses_local_mode(tmp_path: Path, monkeypatch):
    monkeypatch.delenv("PICK_PHOTO_AI_MODE", raising=False)
    monkeypatch.setenv("PICK_PHOTO_AI_STORAGE_DIR", str(tmp_path))
    save_endpoint_image(tmp_path, "uploads/upload-1/blank.jpg")

    response = client.post(
        "/detect-faces",
        json={
            "upload_id": "upload-1",
            "storage_key": "uploads/upload-1/blank.jpg",
        },
    )

    assert response.status_code == 200
    assert response.json() == {"upload_id": "upload-1", "faces": []}


def test_generate_id_photo_endpoint_uses_local_mode(tmp_path: Path, monkeypatch):
    monkeypatch.delenv("PICK_PHOTO_AI_MODE", raising=False)
    monkeypatch.setenv("PICK_PHOTO_AI_STORAGE_DIR", str(tmp_path))
    save_endpoint_image(tmp_path, "uploads/upload-1/source.jpg")

    response = client.post(
        "/generate-id-photo",
        json={
            "upload_id": "upload-1",
            "face_id": "face-1",
            "source_storage_key": "uploads/upload-1/source.jpg",
            "box": {"left": 80, "top": 60, "width": 120, "height": 140},
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result_storage_key"] == "generated/upload-1/face-1.jpg"
    assert (tmp_path / body["result_storage_key"]).is_file()


def test_generate_id_photo_endpoint_rejects_unreadable_source_image(
    tmp_path: Path,
    monkeypatch,
):
    monkeypatch.delenv("PICK_PHOTO_AI_MODE", raising=False)
    monkeypatch.setenv("PICK_PHOTO_AI_STORAGE_DIR", str(tmp_path))
    source = tmp_path / "uploads" / "upload-1" / "source.jpg"
    source.parent.mkdir(parents=True, exist_ok=True)
    source.write_text("not an image")

    response = client.post(
        "/generate-id-photo",
        json={
            "upload_id": "upload-1",
            "face_id": "face-1",
            "source_storage_key": "uploads/upload-1/source.jpg",
            "box": {"left": 0, "top": 0, "width": 80, "height": 80},
        },
    )

    assert response.status_code == 422
