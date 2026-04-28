# Pick Photo Mobile

Pick Photo의 Flutter 모바일 앱이다. 사용자는 사진을 선택하고, NestJS 백엔드에 업로드한 뒤, 감지된 얼굴 중 하나 또는 모든 얼굴에 대해 증명사진 스타일 생성 요청을 보낼 수 있다.

## 현재 동작

- 사진 선택은 `file_picker` 기반 `PhotoPicker`를 사용한다.
- 기본 API 대상은 `http://localhost:3000`이다.
- API 대상은 빌드 시 `PICK_PHOTO_API_BASE_URL`로 바꿀 수 있다.
- 현재 화면은 업로드 중, 얼굴 검토, 생성 중, 완료, 실패 상태를 표시한다.
- 생성 결과는 아직 실제 이미지 미리보기 대신 결과 URL 목록으로 표시한다.

## 실행

```bash
mise x flutter@3.22.1-stable -- flutter run
```

백엔드 기본 실행 주소는 `http://localhost:3000`이다.

## 검증

```bash
mise x flutter@3.22.1-stable -- flutter test
mise x flutter@3.22.1-stable -- dart format lib test
```

## 남은 작업

- 실제 결과 이미지 미리보기와 저장 UX.
- 개인정보 동의, 보관, 삭제 안내 UX.
- 모바일 화면 품질 보강.
- Android 빌드 검증.
