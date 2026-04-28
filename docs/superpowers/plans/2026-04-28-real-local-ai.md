# Real Local AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Python AI server's default deterministic fake behavior with a local OpenCV/Pillow image-processing slice while preserving the existing AI HTTP contract.

**Architecture:** Keep the public `/detect-faces` and `/generate-id-photo` schemas unchanged. Add a storage boundary that safely resolves storage keys inside a configured local root, then add a local AI module that reads source images, detects face boxes with OpenCV, and writes 413x531 JPEG results with Pillow. Keep fake AI available behind `PICK_PHOTO_AI_MODE=fake` for tests and local fallback.

**Tech Stack:** Python 3.12, FastAPI, Pydantic, pytest, OpenCV headless, Pillow.

---

## 진행 현황

이 계획은 `docs/superpowers/specs/2026-04-28-real-local-ai-design.md`를 구현한다.

## Feature Progress

| Feature ID | Feature / behavior | Status | Progress | Requirements | Validation / tests | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | 실제 이미지 기반 얼굴 감지 | Complete | 100% | FR-002, FR-003, FR-004 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-002 | 선택 얼굴 기반 ID-photo JPEG 생성 | Complete | 100% | FR-007, FR-008, NFR-001, NFR-002 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-003 | AI storage root 설정과 파일 IO 안전 처리 | Complete | 100% | NFR-006, FR-013 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |

## File Structure

- Modify: `apps/ai/pyproject.toml` to add `opencv-python-headless` and `Pillow`.
- Create: `apps/ai/app/storage.py` for storage root and storage key resolution.
- Create: `apps/ai/app/local_ai.py` for OpenCV/Pillow local AI behavior.
- Modify: `apps/ai/app/main.py` to route default requests to local AI and `PICK_PHOTO_AI_MODE=fake` requests to fake AI.
- Modify: `apps/ai/tests/test_ai_contract.py` to cover fake mode and local endpoint behavior.
- Create: `apps/ai/tests/test_storage.py` for storage key safety.
- Create: `apps/ai/tests/test_local_ai.py` for local detection and generation.
- Create: `apps/ai/README.md` for local run/configuration notes.
- Modify: `docs/contracts/ai-service.md` to document storage root semantics and fake/local modes.
- Modify: `docs/superpowers/plans/2026-04-28-real-local-ai.md` during execution to keep Feature Progress current.

### Task 1: Add Image Processing Dependencies

**Files:**
- Modify: `apps/ai/pyproject.toml`

- [x] **Step 1: Update Python dependencies**

Change `apps/ai/pyproject.toml` dependencies to include OpenCV and Pillow:

```toml
dependencies = [
  "fastapi>=0.110",
  "opencv-python-headless>=4.9",
  "Pillow>=10.0",
  "pydantic>=2.0",
  "uvicorn[standard]>=0.27",
]
```

- [x] **Step 2: Install updated dependencies**

Run:

```bash
cd apps/ai
.venv/bin/python -m pip install -e ".[dev]"
```

Expected: packages install without errors and `opencv-python-headless` plus `Pillow` are available in the virtualenv.

- [x] **Step 3: Verify dependency imports**

Run:

```bash
cd apps/ai
.venv/bin/python - <<'PY'
import cv2
from PIL import Image
print(cv2.__version__)
print(Image.__name__)
PY
```

Expected: prints an OpenCV version and `Image`.

### Task 2: Add Safe Storage Key Resolution

**Files:**
- Create: `apps/ai/app/storage.py`
- Test: `apps/ai/tests/test_storage.py`

- [x] **Step 1: Write failing storage tests**

Create `apps/ai/tests/test_storage.py`:

```python
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
```

- [x] **Step 2: Run storage tests and verify failure**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_storage.py -q
```

Expected: FAIL because `app.storage` does not exist yet.

- [x] **Step 3: Implement storage module**

Create `apps/ai/app/storage.py`:

```python
from pathlib import Path


class StorageKeyError(ValueError):
    pass


class StorageRoot:
    def __init__(self, root: str | Path):
        self.root = Path(root).expanduser().resolve()

    def resolve_existing(self, storage_key: str) -> Path:
        path = self._resolve(storage_key)
        if not path.is_file():
            raise StorageKeyError(f"Storage key does not point to a file: {storage_key}")
        return path

    def resolve_output(self, storage_key: str) -> Path:
        path = self._resolve(storage_key)
        path.parent.mkdir(parents=True, exist_ok=True)
        return path

    def _resolve(self, storage_key: str) -> Path:
        key_path = Path(storage_key)
        if key_path.is_absolute():
            raise StorageKeyError("Storage key must be relative.")

        candidate = (self.root / key_path).resolve()
        if candidate != self.root and self.root not in candidate.parents:
            raise StorageKeyError("Storage key escapes the storage root.")

        return candidate
```

- [x] **Step 4: Run storage tests and verify pass**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_storage.py -q
```

Expected: PASS for all storage tests.

### Task 3: Add Local Face Detection

**Files:**
- Create: `apps/ai/app/local_ai.py`
- Test: `apps/ai/tests/test_local_ai.py`

- [x] **Step 1: Write failing local detection tests**

Create `apps/ai/tests/test_local_ai.py`:

```python
from pathlib import Path

from PIL import Image

from app.local_ai import detect_faces
from app.schemas import DetectFacesRequest


def save_image(path: Path, size: tuple[int, int] = (160, 120), color: str = "white"):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", size, color=color).save(path, format="JPEG")


def test_local_detection_returns_no_faces_for_blank_image(tmp_path: Path):
    source = tmp_path / "uploads" / "upload-1" / "blank.jpg"
    save_image(source)

    response = detect_faces(
        DetectFacesRequest(upload_id="upload-1", storage_key="uploads/upload-1/blank.jpg"),
        storage_root=tmp_path,
    )

    assert response.upload_id == "upload-1"
    assert response.faces == []


def test_local_detection_maps_detector_boxes_to_contract(tmp_path: Path, monkeypatch):
    source = tmp_path / "uploads" / "upload-1" / "face.jpg"
    save_image(source, size=(320, 240))

    monkeypatch.setattr(
        "app.local_ai.OpenCvFaceDetector.detect",
        lambda self, image_path: [(30, 40, 90, 110), (160, 50, 70, 80)],
    )

    response = detect_faces(
        DetectFacesRequest(upload_id="upload-1", storage_key="uploads/upload-1/face.jpg"),
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
```

- [x] **Step 2: Run local detection tests and verify failure**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_local_ai.py::test_local_detection_returns_no_faces_for_blank_image tests/test_local_ai.py::test_local_detection_maps_detector_boxes_to_contract -q
```

Expected: FAIL because `app.local_ai` does not exist yet.

- [x] **Step 3: Implement local detection**

Create `apps/ai/app/local_ai.py` with detection support:

```python
import os
from pathlib import Path

import cv2

from app.schemas import DetectedFace, DetectFacesRequest, DetectFacesResponse, FaceBox
from app.storage import StorageRoot


DEFAULT_CONFIDENCE = 0.9


def default_storage_root() -> Path:
    return Path(os.environ.get("PICK_PHOTO_AI_STORAGE_DIR", "storage"))


class OpenCvFaceDetector:
    def __init__(self):
        cascade_path = Path(cv2.data.haarcascades) / "haarcascade_frontalface_default.xml"
        self.classifier = cv2.CascadeClassifier(str(cascade_path))
        if self.classifier.empty():
            raise RuntimeError(f"Unable to load OpenCV face cascade: {cascade_path}")

    def detect(self, image_path: Path) -> list[tuple[int, int, int, int]]:
        image = cv2.imread(str(image_path))
        if image is None:
            raise ValueError(f"Unable to read image: {image_path}")

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        boxes = self.classifier.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=5,
            minSize=(30, 30),
        )

        return sorted(
            [(int(x), int(y), int(w), int(h)) for x, y, w, h in boxes],
            key=lambda box: (box[1], box[0]),
        )


def detect_faces(
    request: DetectFacesRequest,
    storage_root: str | Path | None = None,
    detector: OpenCvFaceDetector | None = None,
) -> DetectFacesResponse:
    storage = StorageRoot(storage_root or default_storage_root())
    image_path = storage.resolve_existing(request.storage_key)
    face_detector = detector or OpenCvFaceDetector()
    boxes = face_detector.detect(image_path)

    return DetectFacesResponse(
        upload_id=request.upload_id,
        faces=[
            DetectedFace(
                face_id=f"{request.upload_id}-face-{index}",
                face_index=index,
                box=FaceBox(left=left, top=top, width=width, height=height),
                confidence=DEFAULT_CONFIDENCE,
            )
            for index, (left, top, width, height) in enumerate(boxes)
        ],
    )
```

- [x] **Step 4: Run local detection tests and verify pass**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_local_ai.py::test_local_detection_returns_no_faces_for_blank_image tests/test_local_ai.py::test_local_detection_maps_detector_boxes_to_contract -q
```

Expected: PASS for both local detection tests.

### Task 4: Add Local ID-Photo Generation

**Files:**
- Modify: `apps/ai/app/local_ai.py`
- Test: `apps/ai/tests/test_local_ai.py`

- [x] **Step 1: Write failing generation tests**

Append to `apps/ai/tests/test_local_ai.py`:

```python
from app.local_ai import generate_id_photo
from app.schemas import GenerateIdPhotoRequest


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
```

- [x] **Step 2: Run generation test and verify failure**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_local_ai.py::test_local_generation_writes_413_by_531_jpeg -q
```

Expected: FAIL because `generate_id_photo` does not exist yet.

- [x] **Step 3: Implement local generation**

Append generation behavior to `apps/ai/app/local_ai.py`:

```python
from PIL import Image, ImageOps

from app.schemas import GenerateIdPhotoRequest, GenerateIdPhotoResponse


TARGET_WIDTH = 413
TARGET_HEIGHT = 531
TARGET_CONTENT_TYPE = "image/jpeg"


def generate_id_photo(
    request: GenerateIdPhotoRequest,
    storage_root: str | Path | None = None,
) -> GenerateIdPhotoResponse:
    storage = StorageRoot(storage_root or default_storage_root())
    source_path = storage.resolve_existing(request.source_storage_key)
    result_storage_key = f"generated/{request.upload_id}/{request.face_id}.jpg"
    output_path = storage.resolve_output(result_storage_key)

    with Image.open(source_path) as source:
        image = source.convert("RGB")
        crop_box = _expanded_crop_box(
            image_width=image.width,
            image_height=image.height,
            left=request.box.left,
            top=request.box.top,
            width=request.box.width,
            height=request.box.height,
        )
        cropped = image.crop(crop_box)
        fitted = ImageOps.fit(
            cropped,
            (TARGET_WIDTH, TARGET_HEIGHT),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.42),
        )
        fitted.save(output_path, format="JPEG", quality=92)

    return GenerateIdPhotoResponse(
        upload_id=request.upload_id,
        face_id=request.face_id,
        result_storage_key=result_storage_key,
        width=TARGET_WIDTH,
        height=TARGET_HEIGHT,
        content_type=TARGET_CONTENT_TYPE,
    )


def _expanded_crop_box(
    image_width: int,
    image_height: int,
    left: int,
    top: int,
    width: int,
    height: int,
) -> tuple[int, int, int, int]:
    if width <= 0 or height <= 0:
        raise ValueError("Face box must have positive size.")

    target_aspect = TARGET_WIDTH / TARGET_HEIGHT
    center_x = left + width / 2
    center_y = top + height * 0.55
    crop_height = max(height / 0.58, width / target_aspect)
    crop_width = crop_height * target_aspect

    crop_left = center_x - crop_width / 2
    crop_top = center_y - crop_height * 0.40
    crop_right = crop_left + crop_width
    crop_bottom = crop_top + crop_height

    if crop_left < 0:
        crop_right -= crop_left
        crop_left = 0
    if crop_top < 0:
        crop_bottom -= crop_top
        crop_top = 0
    if crop_right > image_width:
        crop_left -= crop_right - image_width
        crop_right = image_width
    if crop_bottom > image_height:
        crop_top -= crop_bottom - image_height
        crop_bottom = image_height

    crop_left = max(0, crop_left)
    crop_top = max(0, crop_top)
    crop_right = min(image_width, crop_right)
    crop_bottom = min(image_height, crop_bottom)

    if crop_right <= crop_left or crop_bottom <= crop_top:
        raise ValueError("Face box produced an empty crop.")

    return (
        int(round(crop_left)),
        int(round(crop_top)),
        int(round(crop_right)),
        int(round(crop_bottom)),
    )
```

- [x] **Step 4: Run generation test and verify pass**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_local_ai.py::test_local_generation_writes_413_by_531_jpeg -q
```

Expected: PASS.

### Task 5: Route FastAPI Endpoints To Local Or Fake Mode

**Files:**
- Modify: `apps/ai/app/main.py`
- Modify: `apps/ai/tests/test_ai_contract.py`

- [x] **Step 1: Update endpoint tests for fake and local modes**

In `apps/ai/tests/test_ai_contract.py`, replace direct endpoint expectations with mode-specific tests:

```python
from pathlib import Path

from PIL import Image


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
        json={"upload_id": "upload-1", "storage_key": "uploads/upload-1/blank.jpg"},
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
```

Keep the existing schema tests and direct fake function tests.

- [x] **Step 2: Run endpoint tests and verify failure**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_ai_contract.py -q
```

Expected: FAIL because endpoints still always use fake AI.

- [x] **Step 3: Update FastAPI routing**

Replace `apps/ai/app/main.py` with:

```python
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
```

- [x] **Step 4: Run endpoint tests and verify pass**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest tests/test_ai_contract.py -q
```

Expected: PASS.

### Task 6: Update AI Docs

**Files:**
- Create: `apps/ai/README.md`
- Modify: `docs/contracts/ai-service.md`

- [x] **Step 1: Create AI README**

Create `apps/ai/README.md`:

```markdown
# Pick Photo AI Server

Pick Photo의 내부 Python AI 서버다. 기본 모드는 로컬 OpenCV/Pillow 처리이며, 업로드 이미지에서 얼굴을 감지하고 선택 얼굴 중심의 413x531 JPEG 결과를 생성한다.

## 실행

```bash
.venv/bin/python -m pip install -e ".[dev]"
.venv/bin/python -m uvicorn app.main:app --reload
```

## 환경 변수

- `PICK_PHOTO_AI_MODE`: `local` 또는 `fake`. 기본값은 `local`.
- `PICK_PHOTO_AI_STORAGE_DIR`: AI 서버가 `storage_key`를 해석할 로컬 storage root. 기본값은 현재 작업 디렉터리의 `storage`.

NestJS 백엔드와 함께 로컬 실행할 때는 백엔드 `PHOTO_STORAGE_DIR`와 AI 서버 `PICK_PHOTO_AI_STORAGE_DIR`가 같은 디렉터리를 가리켜야 한다.

## 검증

```bash
.venv/bin/python -m pytest -q
```

## 현재 한계

- 첫 구현은 OpenCV Haar cascade 기반 얼굴 감지와 Pillow 기반 crop/resize를 사용한다.
- 국가별 공식 증명사진 규격, 고급 배경 제거, 얼굴 보정, 정장 합성은 아직 지원하지 않는다.
- 보관 기간과 삭제 정책은 별도 결정이 필요하다.
```

- [x] **Step 2: Update AI service contract**

Add this section to `docs/contracts/ai-service.md` before `## Stable Error Categories`:

```markdown
## Runtime Storage Semantics

- `storage_key` and `source_storage_key` are relative file references.
- The Python AI server resolves those keys inside its configured local storage root.
- The local storage root is configured with `PICK_PHOTO_AI_STORAGE_DIR`.
- Storage keys must not be absolute paths or escape the configured storage root.
- The default AI mode is local image processing. `PICK_PHOTO_AI_MODE=fake` preserves deterministic fake behavior for local fallback and tests.
```

### Task 7: Run Full AI Validation And Update Progress

**Files:**
- Modify: `docs/superpowers/plans/2026-04-28-real-local-ai.md`

- [x] **Step 1: Run all AI tests**

Run:

```bash
cd apps/ai
.venv/bin/python -m pytest -q
```

Expected: PASS for all AI tests.

- [x] **Step 2: Update Feature Progress**

In this plan's Feature Progress table, set:

```markdown
| F-001 | 실제 이미지 기반 얼굴 감지 | Complete | 100% | FR-002, FR-003, FR-004 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-002 | 선택 얼굴 기반 ID-photo JPEG 생성 | Complete | 100% | FR-007, FR-008, NFR-001, NFR-002 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-003 | AI storage root 설정과 파일 IO 안전 처리 | Complete | 100% | NFR-006, FR-013 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
```

## Plan Self-Review

- Spec coverage: Tasks 1-5 implement local storage, face detection, ID-photo generation, fake fallback, and endpoint routing from `2026-04-28-real-local-ai-design.md`; Task 6 covers docs; Task 7 covers validation and feature progress.
- Placeholder scan: no `TBD`, `TODO`, or implementation-later placeholders are present.
- Type consistency: request and response types use existing `DetectFacesRequest`, `DetectFacesResponse`, `GenerateIdPhotoRequest`, `GenerateIdPhotoResponse`, `FaceBox`, and `DetectedFace` names.
- Security check: storage key traversal is explicitly tested and rejected; no external API calls are introduced.
- Review fix: unreadable source images in generation are converted to a `ValueError` and surfaced as HTTP 422 instead of leaking as an unhandled Pillow error.
- Residual risk: OpenCV Haar cascade quality is basic and may miss difficult faces; production model selection remains open.
