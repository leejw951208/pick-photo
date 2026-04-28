from app.fake_ai import detect_faces, generate_id_photo
from app.schemas import DetectFacesRequest, GenerateIdPhotoRequest


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
    response = detect_faces(DetectFacesRequest(upload_id="upload-1", storage_key="uploads/source.jpg"))

    assert len(response.faces) == 1
    assert response.faces[0].face_index == 0


def test_fake_detection_returns_no_faces_for_no_face_key():
    response = detect_faces(DetectFacesRequest(upload_id="upload-1", storage_key="uploads/no-face.jpg"))

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
