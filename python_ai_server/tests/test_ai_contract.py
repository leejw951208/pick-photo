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
