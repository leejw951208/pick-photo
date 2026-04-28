from pathlib import Path

from PIL import Image

from app.local_ai import detect_faces, generate_id_photo
from app.schemas import DetectFacesRequest, GenerateIdPhotoRequest


def save_image(
    path: Path,
    size: tuple[int, int] = (160, 120),
    color: str = "white",
):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", size, color=color).save(path, format="JPEG")


def test_local_detection_returns_no_faces_for_blank_image(tmp_path: Path):
    source = tmp_path / "uploads" / "upload-1" / "blank.jpg"
    save_image(source)

    response = detect_faces(
        DetectFacesRequest(
            upload_id="upload-1",
            storage_key="uploads/upload-1/blank.jpg",
        ),
        storage_root=tmp_path,
    )

    assert response.upload_id == "upload-1"
    assert response.faces == []


def test_local_detection_maps_detector_boxes_to_contract(
    tmp_path: Path,
    monkeypatch,
):
    source = tmp_path / "uploads" / "upload-1" / "face.jpg"
    save_image(source, size=(320, 240))

    monkeypatch.setattr(
        "app.local_ai.OpenCvFaceDetector.detect",
        lambda self, image_path: [(30, 40, 90, 110), (160, 50, 70, 80)],
    )

    response = detect_faces(
        DetectFacesRequest(
            upload_id="upload-1",
            storage_key="uploads/upload-1/face.jpg",
        ),
        storage_root=tmp_path,
    )

    assert [face.face_id for face in response.faces] == [
        "upload-1-face-0",
        "upload-1-face-1",
    ]
    assert response.faces[0].box.left == 30
    assert response.faces[0].box.top == 40
    assert response.faces[0].box.width == 90
    assert response.faces[0].box.height == 110
    assert response.faces[0].confidence == 0.9


def test_local_generation_writes_413_by_531_jpeg(tmp_path: Path):
    source = tmp_path / "uploads" / "upload-1" / "source.jpg"
    save_image(source, size=(640, 480), color="lightblue")

    response = generate_id_photo(
        GenerateIdPhotoRequest(
            upload_id="upload-1",
            face_id="face-1",
            source_storage_key="uploads/upload-1/source.jpg",
            box={"left": 220, "top": 120, "width": 160, "height": 190},
        ),
        storage_root=tmp_path,
    )

    output = tmp_path / response.result_storage_key
    assert output.is_file()
    assert response.width == 413
    assert response.height == 531
    assert response.content_type == "image/jpeg"

    with Image.open(output) as generated:
        assert generated.size == (413, 531)
        assert generated.format == "JPEG"


def test_local_generation_rejects_unreadable_source_image(tmp_path: Path):
    source = tmp_path / "uploads" / "upload-1" / "source.jpg"
    source.parent.mkdir(parents=True, exist_ok=True)
    source.write_text("not an image")

    try:
        generate_id_photo(
            GenerateIdPhotoRequest(
                upload_id="upload-1",
                face_id="face-1",
                source_storage_key="uploads/upload-1/source.jpg",
                box={"left": 0, "top": 0, "width": 80, "height": 80},
            ),
            storage_root=tmp_path,
        )
    except ValueError as error:
        assert "Unable to read image" in str(error)
    else:
        raise AssertionError("Expected unreadable image to raise ValueError.")
