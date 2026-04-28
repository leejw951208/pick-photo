# 실제 로컬 AI 첫 구현 설계

## 목표

Pick Photo의 Python AI 서버가 deterministic fake 응답만 반환하던 상태에서 벗어나, 로컬 파일을 읽어 실제 이미지 기반 얼굴 인식과 증명사진 스타일 결과 생성을 수행하게 한다.

첫 구현은 외부 API를 사용하지 않고 `apps/ai` 내부에서 OpenCV와 Pillow 기반으로 동작한다. 목적은 최종 고품질 AI 생성이 아니라, 기존 AI 서비스 계약을 유지하면서 실제 업로드 이미지가 얼굴 감지와 결과 이미지 생성 흐름을 통과하는 첫 번째 세로 slice를 만드는 것이다.

## 제품 정렬

이 설계는 `PRD.md`의 다음 요구사항에 맞춘다.

- `FR-002`: 업로드된 사진에서 얼굴을 찾는다.
- `FR-003`: 얼굴이 발견되면 얼굴 목록을 보여줄 수 있게 한다.
- `FR-004`: 얼굴이 없으면 실패 상태와 재시도 가능성을 제공한다.
- `FR-007`: 선택된 얼굴마다 증명사진 스타일 결과를 생성한다.
- `FR-008`: 선택되지 않은 얼굴은 생성하지 않는다.
- `NFR-001`: 결과가 단순 crop이 아니라 얼굴 중심 구도와 정돈된 인상을 갖도록 한다.
- `NFR-002`: 선택한 얼굴의 식별 가능성을 훼손하지 않는다.
- `NFR-006`: 사진, 얼굴, 생성 결과를 민감 정보로 취급한다.

국가별 공식 규격 보장, 고급 배경 제거, 정장 합성, 얼굴 보정, 유료 외부 모델 사용은 이번 범위가 아니다.

## 현재 맥락

- `apps/ai/app/main.py`는 `/detect-faces`, `/generate-id-photo` 두 엔드포인트를 제공한다.
- `apps/ai/app/fake_ai.py`는 storage key 문자열만 보고 deterministic face/result metadata를 만든다.
- NestJS 백엔드는 `AI_SERVICE_BASE_URL`이 있으면 Python AI HTTP API를 호출하고, 없으면 TypeScript fake AI를 사용한다.
- 백엔드는 업로드 파일을 `PHOTO_STORAGE_DIR` 또는 `apps/backend/storage` 아래에 저장하고, AI 서버에는 storage key를 전달한다.
- AI 계약 문서 `docs/contracts/ai-service.md`는 요청/응답 field names를 이미 고정하고 있다.

## 접근안

### 선택안: OpenCV/Pillow 기반 로컬 처리

Python AI 서버에 실제 처리 모듈을 추가한다.

- OpenCV `CascadeClassifier`로 얼굴 bbox를 감지한다.
- Pillow로 원본 이미지를 열고 선택된 얼굴 주변을 확장 crop한다.
- crop을 413x531 비율에 맞게 resize해 JPEG로 저장한다.
- 결과 JPEG를 `generated/<upload_id>/<face_id>.jpg` storage key에 저장한다.

이 방식은 외부 네트워크 전송 없이 동작하고, 기존 FastAPI 계약을 유지하며, 나중에 더 좋은 모델로 내부 구현을 교체하기 쉽다.

### 보류안: 외부 AI API 연동

결과 품질 가능성은 높지만 API key, 비용, 개인정보 전송, 실패/재시도 정책, 보관 정책이 먼저 필요하다. 현재 PRD의 개인정보 기대와 open decision이 정리되지 않아 첫 구현으로는 보류한다.

### 보류안: 딥러닝 모델 기반 로컬 파이프라인

장기적으로는 적합하지만 모델 artifact, 설치 크기, CPU/GPU 기대치, 추론 시간, 배포 방식 결정이 필요하다. 이번 첫 slice 이후 교체 가능한 내부 구현으로 다룬다.

## 구성 요소

### `storage.py`

AI 서버가 storage key를 안전하게 로컬 파일 경로로 변환한다.

- 환경 변수: `PICK_PHOTO_AI_STORAGE_DIR`
- 기본값: 현재 작업 디렉터리의 `storage`
- 입력 storage key는 상대 경로만 허용한다.
- `..`, 절대 경로, storage root 밖으로 벗어나는 경로는 거부한다.
- parent directory 생성은 결과 저장 시에만 수행한다.

### `local_ai.py`

실제 이미지 처리 구현을 담는다.

- `detect_faces(request)`: source image를 읽고 OpenCV로 얼굴 후보를 찾는다.
- `generate_id_photo(request)`: source image와 선택 bbox를 사용해 결과 JPEG를 저장한다.
- face id는 기존 fake와 같은 형태인 `<upload_id>-face-<index>`를 유지한다.
- confidence는 OpenCV cascade에서 직접 제공되지 않으므로 첫 구현에서는 deterministic value를 사용하되, 결과 목록 순서와 bbox는 실제 감지 결과에서 가져온다.

### `fake_ai.py`

테스트와 fallback을 위해 유지한다. 실제 엔드포인트 기본 동작은 local AI로 전환하되, `PICK_PHOTO_AI_MODE=fake` 같은 명시적 설정으로 fake를 사용할 수 있게 한다.

### `main.py`

요청을 local/fake backend로 routing한다.

- 기본값: local
- `PICK_PHOTO_AI_MODE=fake`: 기존 fake 동작
- 처리 중 파일 없음, unreadable image, invalid path는 FastAPI error로 노출되어 NestJS에서 `face_detection_failed` 또는 `generation_failed`로 mapping된다.

## 데이터 흐름

1. Flutter 앱이 사진을 NestJS 백엔드에 업로드한다.
2. NestJS 백엔드가 파일을 local storage에 저장하고 storage key를 만든다.
3. NestJS 백엔드가 Python AI 서버 `/detect-faces`에 `upload_id`, `storage_key`를 보낸다.
4. Python AI 서버가 storage root에서 원본 이미지를 읽고 얼굴 bbox 목록을 반환한다.
5. 사용자가 한 얼굴 또는 전체 얼굴을 선택한다.
6. NestJS 백엔드가 `/generate-id-photo`에 `upload_id`, `face_id`, `source_storage_key`, `box`를 보낸다.
7. Python AI 서버가 선택 얼굴 중심의 JPEG 결과를 저장하고 result storage key를 반환한다.
8. NestJS 백엔드는 기존 계약대로 `resultUrl`을 만든다.

## 오류 처리

- 얼굴이 없으면 `/detect-faces`는 `faces: []`를 반환한다.
- source 파일이 없으면 AI 서버가 400 오류를 반환하고, 이미지로 읽을 수 없으면 422 오류를 반환한다.
- generation 시 bbox가 이미지 밖으로 벗어나면 이미지 경계로 clamp한다.
- crop 가능 영역이 없으면 generation 실패로 처리한다.
- storage key path traversal 시도는 거부한다.

## 보안 및 개인정보

보안 민감 영역은 파일 업로드, 로컬 파일 접근, 생성 이미지 저장, 민감 이미지 처리다.

- storage key는 storage root 내부 상대 경로로 제한한다.
- 원본 이미지나 결과 이미지 byte를 로그에 남기지 않는다.
- 외부 네트워크 API를 호출하지 않는다.
- 이번 작업은 보관 기간, 삭제 정책, 접근 권한을 확정하지 않는다. 해당 항목은 기존 open decision으로 유지한다.

## 테스트 전략

검증 명령은 `AGENTS.md`에 기록된 다음 명령을 사용한다.

```bash
cd apps/ai && .venv/bin/python -m pytest -q
```

테스트는 다음을 포함한다.

- storage key가 storage root 밖으로 벗어나지 못한다.
- no-face 이미지에서 빈 얼굴 목록을 반환한다.
- detector가 반환한 bbox를 AI 계약의 얼굴 응답으로 매핑한다.
- 선택 bbox로 413x531 JPEG 결과 파일을 생성한다.
- 읽을 수 없는 source 이미지가 generation endpoint에서 422로 처리된다.
- `PICK_PHOTO_AI_MODE=fake`에서 기존 fake 계약이 유지된다.
- FastAPI endpoint가 local AI 응답을 계약 field names로 직렬화한다.

## Feature Progress

| Feature ID | Feature / behavior | Status | Progress | Requirements | Validation / tests | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | 실제 이미지 기반 얼굴 감지 | Complete | 100% | FR-002, FR-003, FR-004 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-002 | 선택 얼굴 기반 ID-photo JPEG 생성 | Complete | 100% | FR-007, FR-008, NFR-001, NFR-002 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-003 | AI storage root 설정과 파일 IO 안전 처리 | Complete | 100% | NFR-006, FR-013 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |

## 열린 결정

- production storage 위치와 접근 권한.
- 생성 결과 URL을 실제 static file download로 제공하는 방식.
- 보관 기간과 삭제 정책.
- 장기적으로 사용할 딥러닝 모델 stack.
- 공식 증명사진 규격 지원 여부.

## 설계 자체 검토

- Placeholder scan: 미완성 placeholder 없음.
- Internal consistency: AI 계약은 유지하고 내부 구현만 fake에서 local processing으로 확장한다.
- Scope check: 첫 구현 범위는 Python AI 서버와 AI 계약 문서/README 수준으로 제한한다.
- Ambiguity check: 첫 결과 품질은 “OpenCV/Pillow 기반 얼굴 중심 JPEG 생성”으로 명시하며, 국가별 규격과 고급 보정은 제외한다.
