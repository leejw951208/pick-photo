import os

from fastapi import FastAPI, HTTPException

from app import fake_ai, local_ai
from app.schemas import (
    DetectFacesRequest,
    DetectFacesResponse,
    GenerateIdPhotoRequest,
    GenerateIdPhotoResponse,
)
from app.storage import StorageKeyError


app = FastAPI(title="Pick Photo AI Server")


def use_fake_ai() -> bool:
    return os.environ.get("PICK_PHOTO_AI_MODE", "local").lower() == "fake"


@app.post("/detect-faces", response_model=DetectFacesResponse)
def post_detect_faces(request: DetectFacesRequest) -> DetectFacesResponse:
    try:
        if use_fake_ai():
            return fake_ai.detect_faces(request)
        return local_ai.detect_faces(request)
    except StorageKeyError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/generate-id-photo", response_model=GenerateIdPhotoResponse)
def post_generate_id_photo(request: GenerateIdPhotoRequest) -> GenerateIdPhotoResponse:
    try:
        if use_fake_ai():
            return fake_ai.generate_id_photo(request)
        return local_ai.generate_id_photo(request)
    except StorageKeyError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
