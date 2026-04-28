import os
from pathlib import Path

import cv2
from PIL import Image, ImageOps

from app.schemas import (
    DetectedFace,
    DetectFacesRequest,
    DetectFacesResponse,
    FaceBox,
    GenerateIdPhotoRequest,
    GenerateIdPhotoResponse,
)
from app.storage import StorageRoot


DEFAULT_CONFIDENCE = 0.9
TARGET_WIDTH = 413
TARGET_HEIGHT = 531
TARGET_CONTENT_TYPE = "image/jpeg"


def default_storage_root() -> Path:
    return Path(os.environ.get("PICK_PHOTO_AI_STORAGE_DIR", "storage"))


class OpenCvFaceDetector:
    def __init__(self):
        cascade_path = (
            Path(cv2.data.haarcascades) / "haarcascade_frontalface_default.xml"
        )
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


def generate_id_photo(
    request: GenerateIdPhotoRequest,
    storage_root: str | Path | None = None,
) -> GenerateIdPhotoResponse:
    storage = StorageRoot(storage_root or default_storage_root())
    source_path = storage.resolve_existing(request.source_storage_key)
    result_storage_key = f"generated/{request.upload_id}/{request.face_id}.jpg"
    output_path = storage.resolve_output(result_storage_key)

    try:
        with Image.open(source_path) as source:
            image = source.convert("RGB")
    except OSError as error:
        raise ValueError(f"Unable to read image: {source_path}") from error

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
