# Pick Photo

Pick Photo는 사용자가 업로드한 일반 사진에서 얼굴을 찾고, 선택한 얼굴 하나 또는 모든 얼굴을 증명사진 스타일 이미지로 생성하는 실험적 모바일 서비스다.

현재 저장소는 Flutter 모바일 앱, NestJS 백엔드, Python AI 서버, PostgreSQL 스키마를 분리된 프로젝트로 관리한다. 서비스 간 계약은 `docs/contracts/` 문서에 기록한다.

## 현재 상태

- Flutter 앱은 사진 선택, 업로드, 얼굴 검토, 단일 또는 전체 얼굴 생성 요청, 결과 URL 목록 표시 흐름을 제공한다.
- NestJS 백엔드는 사진 업로드 API, 얼굴 목록 API, 생성 요청 API, 생성 결과 API, Swagger 문서, 로컬 파일 저장소, PostgreSQL 저장소 어댑터, Python AI HTTP 어댑터를 제공한다.
- Python AI 서버는 기본적으로 OpenCV/Pillow 기반 로컬 이미지 처리를 사용해 얼굴을 감지하고 413x531 JPEG 결과를 생성한다.
- Python AI 서버의 deterministic fake 모드는 `PICK_PHOTO_AI_MODE=fake`로 유지된다.
- PostgreSQL 초기 스키마는 `database/migrations/001_initial_schema.sql`에 있다.

## 프로젝트 구조

```text
apps/mobile/      Flutter 모바일 앱
apps/backend/     NestJS 애플리케이션 서버
apps/ai/          FastAPI 기반 Python AI 서버
database/         PostgreSQL migration 및 seed 문서
docs/contracts/   앱, AI, 데이터, 개인정보 계약 문서
docs/superpowers/ 설계와 구현 계획, 진행상황 추적 문서
```

## 로컬 실행

### 1. Python AI 서버

백엔드와 AI 서버가 같은 파일 저장소를 보도록 storage root를 맞춘다.

```bash
mkdir -p /tmp/pick-photo-storage
cd apps/ai
python3 -m venv .venv
.venv/bin/python -m pip install -e ".[dev]"
PICK_PHOTO_AI_STORAGE_DIR=/tmp/pick-photo-storage .venv/bin/python -m uvicorn app.main:app --reload --port 8000
```

### 2. NestJS 백엔드

```bash
cd apps/backend
npm ci
PHOTO_STORAGE_DIR=/tmp/pick-photo-storage AI_SERVICE_BASE_URL=http://localhost:8000 npm run start:dev
```

백엔드는 기본적으로 `http://localhost:3000`에서 실행되며, Swagger UI는 `http://localhost:3000/docs`에서 확인할 수 있다.

`AI_SERVICE_BASE_URL`을 생략하면 백엔드는 TypeScript fake AI 클라이언트를 사용한다. `DATABASE_URL`을 생략하면 in-memory 저장소를 사용한다.

### 3. Flutter 앱

```bash
cd apps/mobile
mise x flutter@3.22.1-stable -- flutter run --dart-define=PICK_PHOTO_API_BASE_URL=http://localhost:3000
```

## 검증

```bash
cd apps/ai
.venv/bin/python -m pytest -q
```

```bash
cd apps/backend
npm test
npm run test:e2e
npm run build
```

```bash
cd apps/mobile
mise x flutter@3.22.1-stable -- flutter test
mise x flutter@3.22.1-stable -- dart format lib test
```

## 주요 문서

- 제품 요구사항: `PRD.md`
- 시스템 설계: `docs/superpowers/specs/2026-04-28-pick-photo-system-design.md`
- 통합 진행상황: `docs/superpowers/plans/2026-04-28-pick-photo-master.md`
- 애플리케이션 API 계약: `docs/contracts/api.md`
- AI 서비스 계약: `docs/contracts/ai-service.md`
- 데이터 모델 계약: `docs/contracts/data-model.md`
- 개인정보 계약: `docs/contracts/privacy.md`

## 남은 작업

- `/results/...` URL이 실제 생성 이미지 byte를 제공하도록 백엔드 result serving/download API 구현.
- Flutter 앱에서 실제 결과 이미지 미리보기와 저장 UX 구현.
- 개인정보 동의, 보관, 삭제 안내와 cleanup 실행 정책 확정.
- 운영 품질 AI 모델 stack, model artifact 저장/배포 방식, 추론 환경 결정.
- 로컬 PostgreSQL migration 검증 명령과 Android build 검증 정리.
