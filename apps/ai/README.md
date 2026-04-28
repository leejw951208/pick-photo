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
