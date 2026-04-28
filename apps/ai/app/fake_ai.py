from app.schemas import (
    DetectedFace,
    DetectFacesRequest,
    DetectFacesResponse,
    FaceBox,
    GenerateIdPhotoRequest,
    GenerateIdPhotoResponse,
)


def detect_faces(request: DetectFacesRequest) -> DetectFacesResponse:
    if "no-face" in request.storage_key:
        return DetectFacesResponse(upload_id=request.upload_id, faces=[])

    return DetectFacesResponse(
        upload_id=request.upload_id,
        faces=[
            DetectedFace(
                face_id=f"{request.upload_id}-face-0",
                face_index=0,
                box=FaceBox(left=80, top=60, width=240, height=280),
                confidence=0.98,
            )
        ],
    )


def generate_id_photo(request: GenerateIdPhotoRequest) -> GenerateIdPhotoResponse:
    return GenerateIdPhotoResponse(
        upload_id=request.upload_id,
        face_id=request.face_id,
        result_storage_key=f"generated/{request.upload_id}/{request.face_id}.jpg",
        width=413,
        height=531,
        content_type="image/jpeg",
    )
