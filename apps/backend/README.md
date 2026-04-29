# Pick Photo Backend

Pick Photo의 NestJS 백엔드 서버다. Flutter 앱의 공개 API를 받고, 업로드 저장, 얼굴 인식 요청, 얼굴 선택, 증명사진 생성 요청, 생성 결과 조회 흐름을 조율한다.

## 실행

```bash
npm install
npm run start:dev
```

기본 포트는 `3000`이다. Swagger UI는 서버 실행 후 `http://localhost:3000/docs`에서 확인할 수 있다.

## 환경 변수

- `PORT`: 서버 포트. 기본값은 `3000`.
- `PHOTO_STORAGE_DIR`: 업로드 파일을 저장할 로컬 디렉터리. 기본값은 `apps/backend/storage`.
- `AI_SERVICE_BASE_URL`: 설정하면 Python AI 서버의 HTTP API를 호출한다. 없으면 deterministic fake AI 클라이언트를 사용한다.
- `DATABASE_URL`: 설정하면 Prisma 7 PostgreSQL driver adapter 기반 저장소를 사용한다. 없으면 로컬 테스트용 in-memory 저장소를 사용한다.

## Prisma

- Prisma 설정 파일은 `prisma.config.ts`다.
- Prisma schema는 `prisma/schema.prisma`다.
- Prisma Client는 `npm run prisma:generate`로 `src/generated/prisma/`에 생성되며 git에는 포함하지 않는다.
- `npm test`, `npm run test:e2e`, `npm run build`, `npm run start:dev`는 실행 전에 Prisma Client를 자동 생성한다.
- 현재 데이터베이스 초기화는 기존 `database/migrations/001_initial_schema.sql`을 기준으로 하며, Prisma Migrate는 아직 도입하지 않았다.

## 현재 저장 동작

- 원본 업로드 파일은 로컬 파일 저장소에 저장된다.
- PostgreSQL에는 원본 이미지 바이트가 아니라 업로드, 얼굴, 생성 작업, 결과 파일 참조 메타데이터만 저장한다.
- `DATABASE_URL`이 없는 로컬 기본 실행은 PostgreSQL 없이도 전체 fake 워크플로를 테스트할 수 있다.
- 로컬 저장 디렉터리 `apps/backend/storage/`는 민감 이미지 파일이 포함될 수 있으므로 git에 포함하지 않는다.

## 검증

```bash
npm test
npm run test:e2e
npm run build
```
