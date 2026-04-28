from fastapi import FastAPI

from app.fake_ai import detect_faces, generate_id_photo
from app.schemas import (
    DetectFacesRequest,
    DetectFacesResponse,
    GenerateIdPhotoRequest,
    GenerateIdPhotoResponse,
)


app = FastAPI(title="Pick Photo AI Server")


@app.post("/detect-faces", response_model=DetectFacesResponse)
def post_detect_faces(request: DetectFacesRequest) -> DetectFacesResponse:
    return detect_faces(request)


@app.post("/generate-id-photo", response_model=GenerateIdPhotoResponse)
def post_generate_id_photo(request: GenerateIdPhotoRequest) -> GenerateIdPhotoResponse:
    return generate_id_photo(request)
