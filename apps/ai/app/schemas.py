from pydantic import BaseModel, Field


class FaceBox(BaseModel):
    left: int = Field(ge=0)
    top: int = Field(ge=0)
    width: int = Field(gt=0)
    height: int = Field(gt=0)


class DetectFacesRequest(BaseModel):
    upload_id: str
    storage_key: str


class DetectedFace(BaseModel):
    face_id: str
    face_index: int = Field(ge=0)
    box: FaceBox
    confidence: float = Field(ge=0, le=1)


class DetectFacesResponse(BaseModel):
    upload_id: str
    faces: list[DetectedFace]


class GenerateIdPhotoRequest(BaseModel):
    upload_id: str
    face_id: str
    source_storage_key: str
    box: FaceBox


class GenerateIdPhotoResponse(BaseModel):
    upload_id: str
    face_id: str
    result_storage_key: str
    width: int = Field(gt=0)
    height: int = Field(gt=0)
    content_type: str
