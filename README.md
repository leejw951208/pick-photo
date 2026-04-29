# Pick Photo

Pick Photo는 사용자가 업로드한 사진에서 얼굴을 찾고, 선택한 얼굴을 증명사진 스타일 이미지로 생성하는 모바일 앱 실험 프로젝트입니다.

이 저장소는 Flutter 모바일 앱, NestJS API 서버, FastAPI AI 서버, PostgreSQL 스키마를 함께 관리합니다.

## 프로젝트 구조

```text
apps/mobile/      Flutter 앱
apps/backend/     NestJS API 서버
apps/ai/          FastAPI AI 서버
database/         PostgreSQL 스키마와 시드 문서
docs/contracts/   서비스 간 계약 문서
```

요청 흐름은 다음과 같습니다.

```text
Flutter 앱 -> NestJS API 서버 -> FastAPI AI 서버
                         |
                         +-> PostgreSQL
                         +-> 공유 파일 저장소
```

Flutter 앱은 백엔드 API만 호출합니다. 백엔드는 업로드 파일 저장, 처리 흐름 기록, AI 서버 호출을 담당합니다. AI 서버는 로컬 저장소의 파일 키를 받아 얼굴 감지와 JPEG 생성 처리를 수행합니다.

## 요구사항

- Docker Desktop 또는 Docker Compose가 포함된 Docker Engine
- Flutter 3.22.1 stable / Dart 3.4.1
- Flutter 도구 체인이 설정된 `mise`

Docker 없이 각 서버를 직접 실행하려면 Node.js 22, npm, Python 3.12도 필요합니다.

## 빠른 시작

백엔드, AI 서버, PostgreSQL은 Docker Compose로 함께 실행합니다.

```bash
docker compose up --build
```

실행 후 다음 주소를 사용할 수 있습니다.

- 백엔드 API: `http://localhost:3000`
- Swagger UI: `http://localhost:3000/docs`
- AI 서버 문서: `http://localhost:8000/docs`
- PostgreSQL: `localhost:5432`

PostgreSQL 초기 스키마는 컨테이너가 처음 생성될 때 `database/migrations/001_initial_schema.sql`에서 적용됩니다. 데이터베이스 볼륨까지 초기화하려면 다음 명령을 사용합니다.

```bash
docker compose down -v
docker compose up --build
```

## Flutter 앱 실행

Flutter 앱은 Docker Compose 밖에서 로컬로 실행하고, Compose로 띄운 백엔드에 연결합니다.

```bash
cd apps/mobile
mise x flutter@3.22.1-stable -- flutter pub get
mise x flutter@3.22.1-stable -- flutter devices
mise x flutter@3.22.1-stable -- flutter run -d chrome --dart-define=PICK_PHOTO_API_BASE_URL=http://localhost:3000
```

macOS 앱으로 실행하려면 다음 명령을 사용합니다.

```bash
mise x flutter@3.22.1-stable -- flutter run -d macos --dart-define=PICK_PHOTO_API_BASE_URL=http://localhost:3000
```

Android 에뮬레이터에서는 호스트 게이트웨이 주소를 사용합니다.

```bash
mise x flutter@3.22.1-stable -- flutter run -d android --dart-define=PICK_PHOTO_API_BASE_URL=http://10.0.2.2:3000
```

앱에서 사진을 업로드하고 얼굴이 잘 보이는 이미지를 선택하면 얼굴 감지 결과가 표시됩니다. 감지된 얼굴 항목을 선택하면 생성 요청이 백엔드와 AI 서버로 전달됩니다.

## 로컬 개발

Docker 없이 서버를 직접 실행할 때는 백엔드와 AI 서버가 같은 저장소 경로를 보도록 설정해야 합니다.

### AI 서버

```bash
mkdir -p /tmp/pick-photo-storage
cd apps/ai
python3 -m venv .venv
.venv/bin/python -m pip install -e ".[dev]"
PICK_PHOTO_AI_STORAGE_DIR=/tmp/pick-photo-storage .venv/bin/python -m uvicorn app.main:app --reload --port 8000
```

### 백엔드

```bash
cd apps/backend
npm ci
PHOTO_STORAGE_DIR=/tmp/pick-photo-storage AI_SERVICE_BASE_URL=http://localhost:8000 npm run start:dev
```

`AI_SERVICE_BASE_URL`을 생략하면 백엔드는 TypeScript 가짜 AI 클라이언트를 사용합니다. `DATABASE_URL`을 생략하면 메모리 기반 처리 흐름 저장소를 사용합니다. `DATABASE_URL`을 설정하면 백엔드는 Prisma 7의 PostgreSQL driver adapter를 통해 처리 흐름 메타데이터를 저장합니다.

## 검증

Docker 구성은 다음 명령으로 확인합니다.

```bash
docker compose config
docker compose build
docker compose up -d
docker compose ps
docker compose exec -T postgres psql -U pick_photo -d pick_photo -c "select count(*) as tables from information_schema.tables where table_schema = 'public';"
```

AI 서버 테스트:

```bash
cd apps/ai
.venv/bin/python -m pytest -q
```

백엔드 테스트와 빌드:

```bash
cd apps/backend
npm run prisma:generate
npm test
npm run test:e2e
npm run build
```

Flutter 테스트와 포맷 확인:

```bash
cd apps/mobile
mise x flutter@3.22.1-stable -- flutter test
mise x flutter@3.22.1-stable -- dart format lib test
```

## 관련 문서

- [제품 요구사항](PRD.md)
- [시스템 설계](docs/superpowers/specs/2026-04-28-pick-photo-system-design.md)
- [구현 진행 문서](docs/superpowers/plans/2026-04-28-pick-photo-master.md)
- [애플리케이션 API 계약](docs/contracts/api.md)
- [AI 서비스 계약](docs/contracts/ai-service.md)
- [데이터 모델 계약](docs/contracts/data-model.md)
- [개인정보 계약](docs/contracts/privacy.md)

## 참고

- Python AI 서버는 기본적으로 로컬 OpenCV/Pillow 처리를 사용합니다.
- `PICK_PHOTO_AI_MODE=fake`를 설정하면 결정적인 fake AI 동작을 사용할 수 있습니다.
