# Pick Photo Python AI Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## 진행 현황 (2026-04-28)

- 완료: Python 프로젝트 메타데이터, FastAPI 엔드포인트, Pydantic 계약 스키마, deterministic fake 얼굴 인식/증명사진 생성 동작, AI 계약 테스트.
- 완료: OpenCV/Pillow 기반 로컬 얼굴 감지와 413x531 JPEG 생성, `PICK_PHOTO_AI_STORAGE_DIR` storage root, storage key traversal 방어, `PICK_PHOTO_AI_MODE=fake` fallback.
- 남은 작업: 운영 품질 모델 stack 선택, model artifact 저장/배포 방식, 생성 결과 cleanup/retention 실행, 품질 기준과 공식 규격 지원 여부 결정.

**Goal:** Build an internal Python AI service contract for face detection and ID-photo generation, starting with deterministic fake behavior and then extending it with local image processing before production model integration.

**Architecture:** Keep the AI service isolated in `apps/ai/`. The first vertical slice returned deterministic responses so the NestJS server and Flutter app could integrate without waiting for model selection. The current default uses local OpenCV/Pillow processing while preserving fake mode for deterministic tests and fallback.

**Tech Stack:** Python HTTP service. Recommended first implementation uses FastAPI and pytest unless the implementation session selects different repository-local tooling before scaffolding.

---

## File Structure

- Create: `apps/ai/pyproject.toml`
- Create: `apps/ai/app/main.py`
- Create: `apps/ai/app/schemas.py`
- Create: `apps/ai/app/fake_ai.py`
- Create: `apps/ai/app/local_ai.py`
- Create: `apps/ai/app/storage.py`
- Create: `apps/ai/tests/test_ai_contract.py`
- Create: `apps/ai/tests/test_local_ai.py`
- Create: `apps/ai/tests/test_storage.py`
- Modify: `docs/contracts/ai-service.md`

### Task 1: Scaffold Python Service Metadata

**Files:**
- Create: `apps/ai/pyproject.toml`

- [x] **Step 1: Create Python project metadata**

```toml
[project]
name = "pick-photo-ai-server"
version = "0.1.0"
description = "Internal AI service for Pick Photo face detection and ID-photo generation"
requires-python = ">=3.11"
dependencies = [
  "fastapi>=0.110",
  "pydantic>=2.0",
  "uvicorn[standard]>=0.27",
]

[project.optional-dependencies]
dev = [
  "pytest>=8.0",
  "httpx>=0.27",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
```

- [x] **Step 2: Install dependencies in the implementation environment**

Run after Python tooling is available:

```bash
cd apps/ai
python -m pip install -e ".[dev]"
```

Expected: packages install without errors.

### Task 2: Define AI Contract Schemas

**Files:**
- Create: `apps/ai/app/schemas.py`
- Test: `apps/ai/tests/test_ai_contract.py`

- [x] **Step 1: Write schema tests**

```python
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
```

- [x] **Step 2: Implement schemas**

```python
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
```

- [x] **Step 3: Run schema tests**

Run:

```bash
cd apps/ai
pytest tests/test_ai_contract.py -q
```

Expected: both tests pass after dependencies are installed.

### Task 3: Implement Deterministic Fake AI Behavior

**Files:**
- Create: `apps/ai/app/fake_ai.py`
- Modify: `apps/ai/tests/test_ai_contract.py`

- [x] **Step 1: Add fake AI tests**

```python
from app.fake_ai import detect_faces, generate_id_photo
from app.schemas import DetectFacesRequest, GenerateIdPhotoRequest


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
```

- [x] **Step 2: Implement fake AI functions**

```python
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
```

### Task 4: Expose HTTP Endpoints

**Files:**
- Create: `apps/ai/app/main.py`

- [x] **Step 1: Implement FastAPI app**

```python
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
```

- [x] **Step 2: Run tests**

Run:

```bash
cd apps/ai
pytest -q
```

Expected: all Python AI tests pass.

### Task 5: Update AI Service Contract

**Files:**
- Modify: `docs/contracts/ai-service.md`

- [x] **Step 1: Document request and response fields**

Add the schema field names from `apps/ai/app/schemas.py` under each operation in `docs/contracts/ai-service.md`.

## Plan Self-Review

- Spec coverage: supports detection, no-face behavior, generation, and stable AI contract responses.
- Placeholder scan: no unfinished placeholder markers are present.
- Type consistency: request and response field names match the code snippets.
- Residual risk: real model selection, image IO, and storage integration are intentionally deferred behind the fake contract.
