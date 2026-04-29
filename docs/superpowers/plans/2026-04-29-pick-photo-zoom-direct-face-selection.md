# 확대 직접 얼굴 선택 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 사용자가 원본 사진 위 얼굴 박스를 직접 탭하고, 확대와 이동으로 작은 얼굴을 확인한 뒤, 선택한 얼굴만 증명사진 생성 대상으로 보낼 수 있게 만든다.

**Architecture:** 모바일 앱은 업로드한 로컬 사진 바이트와 백엔드가 제공한 얼굴 박스를 함께 보관하고, `InteractiveViewer` 기반 사진 캔버스에서 얼굴 선택 상태를 오버레이한다. 백엔드는 기존 `single_face`와 `all_faces` 생성 요청을 유지하면서, 임의의 여러 얼굴만 생성할 수 있는 `selected_faces` 요청을 추가해 앱의 실제 선택 상태와 생성 대상이 일치하게 한다.

**Tech Stack:** Flutter 3.22.1 / Dart 3.4.1, NestJS 11 / TypeScript, 기존 `http`, `flutter_test`, Jest, Supertest, Prisma 7 생성 흐름.

---

## 범위

- 원본 사진 직접 선택을 얼굴 검토 화면의 기본 조작으로 바꾼다.
- 사진 확대, 이동, 맞춤, 원본 보기 버튼을 제공한다.
- 하단 영역은 얼굴 목록이 아니라 선택 요약과 생성 액션으로 바꾼다.
- 백엔드 생성 요청에 `selected_faces`와 `faceIds`를 추가한다.
- 모바일 API 클라이언트가 얼굴 `box`를 파싱하고, 여러 얼굴 중 일부만 선택했을 때 `selected_faces`를 전송하게 한다.
- `docs/contracts/api.md`를 새 요청 계약에 맞춘다.

## 비범위

- 서버가 원본 사진 미리보기 URL이나 얼굴 crop 썸네일 URL을 새로 제공하지 않는다.
- AI 얼굴 인식 모델, 증명사진 생성 모델, 저장소 구조, Prisma 스키마는 바꾸지 않는다.
- 보관 기간, 삭제 정책, 계정, 결제, 국가별 증명사진 규격 UI는 확정하지 않는다.

## PRD 및 승인된 UX와의 정렬

- `PRD.md`는 얼굴 하나 선택과 전체 선택을 요구하고, 선택되지 않은 얼굴 결과가 생성되지 않아야 한다고 정의한다.
- 2026-04-29 UX 설계와 사용자 승인 방향은 얼굴 목록 대신 원본 사진 직접 선택, 확대 선택, 하단 선택 요약을 확정한다.
- 임의의 여러 얼굴 선택은 `FR-007`, `FR-008`, `NFR-004`를 더 안전하게 만족하기 위한 API 확장이다. 현재 `all_faces`만 사용하면 사용자가 두 명만 선택했는데 전체 얼굴이 생성될 수 있으므로, 백엔드 계약에 `selected_faces`를 추가한다.
- `PRD.md`는 제품 기준 문서이므로 이번 작업에서 기술 계약은 `docs/contracts/api.md`에만 반영한다. 별도 PRD 개정은 “전체가 아닌 여러 명 선택”을 제품 요구로 명시할지 결정할 때 진행한다.

## 파일 구조

- Modify: `AGENTS.md`
  - 얼굴 검토 UX 변경 시 원본 사진 직접 선택과 확대 선택 설계를 따르도록 이미 갱신했다.
- Modify: `docs/contracts/api.md`
  - `POST /photos/uploads/:uploadId/generations` 요청 계약에 `selected_faces`, `faceIds`를 추가한다.
- Modify: `apps/backend/src/photos/dto.ts`
  - `CreateGenerationRequestDto`에 `selected_faces`와 `faceIds`를 추가한다.
- Modify: `apps/backend/src/photos/photos.service.ts`
  - 선택 모드 검증과 얼굴 소유권 검증을 확장한다.
- Modify: `apps/backend/src/photos/photos.swagger.ts`
  - Swagger 요청 스키마에 `selected_faces`, `faceIds`를 추가한다.
- Modify: `apps/backend/test/photos.e2e-spec.ts`
  - `selected_faces` 성공, 빈 배열 거부, 다른 업로드 얼굴 ID 거부를 검증한다.
- Modify: `apps/mobile/lib/features/photo_flow/photo_flow_state.dart`
  - `FaceBox`, `DetectedFace.box`, 원본 사진 바이트 상태를 추가한다.
- Modify: `apps/mobile/lib/features/photo_flow/photo_flow_api.dart`
  - `box` 파싱과 `selected_faces` 요청 생성을 추가한다.
- Create: `apps/mobile/lib/features/photo_flow/face_selection_canvas.dart`
  - 원본 사진, 얼굴 박스, 확대/이동, 선택 토글, 접근성 라벨을 담당한다.
- Modify: `apps/mobile/lib/features/photo_flow/photo_flow_screen.dart`
  - 기존 체크박스 리스트를 직접 선택 캔버스와 하단 선택 요약으로 교체한다.
- Modify: `apps/mobile/test/photo_flow_state_test.dart`
  - `FaceBox`와 원본 사진 바이트 상태를 검증한다.
- Modify: `apps/mobile/test/photo_flow_api_test.dart`
  - `box` 파싱과 단일/복수 선택 요청 본문을 검증한다.
- Modify: `apps/mobile/test/photo_flow_screen_test.dart`
  - 직접 선택, 전체 선택, 선택 초기화, 선택 없이 생성 방지, 실패 상태를 검증한다.

## Feature Progress

| Feature ID | Feature / behavior | Status | Progress | Requirements | Validation / tests | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | 얼굴 박스와 원본 사진 미리보기를 모바일 상태에 보관한다. | Not started | 0% | FR-002, FR-003, NFR-003 | `photo_flow_state_test.dart`, `photo_flow_api_test.dart` | 구현 시작 |
| F-002 | 원본 사진 위 얼굴 박스를 직접 선택하고 선택 상태를 표시한다. | Not started | 0% | FR-005, FR-008, AC-004, AC-008, NFR-003, NFR-004 | `photo_flow_screen_test.dart`, 수동 화면 확인 | 구현 시작 |
| F-003 | 확대, 이동, 맞춤, 원본 보기 버튼으로 작은 얼굴 선택을 지원한다. | Not started | 0% | NFR-003, NFR-007, NFR-008, 승인된 UX 설계 | `photo_flow_screen_test.dart`, 수동 확대 조작 확인 | 구현 시작 |
| F-004 | 선택된 얼굴만 생성하도록 `selected_faces` API 계약을 추가한다. | Not started | 0% | FR-007, FR-008, AC-006, AC-008, NFR-004 | `photos.e2e-spec.ts`, `photo_flow_api_test.dart` | 구현 시작 |
| F-005 | 얼굴 없음, 생성 실패, 선택 없음 상태를 모바일에서 명확히 보여준다. | Not started | 0% | FR-004, FR-009, FR-010, AC-003, AC-009, NFR-005 | `photo_flow_screen_test.dart` | 구현 시작 |

## Task 1: 백엔드 `selected_faces` 계약 추가

**Files:**
- Modify: `apps/backend/src/photos/dto.ts`
- Modify: `apps/backend/src/photos/photos.service.ts`
- Modify: `apps/backend/src/photos/photos.swagger.ts`
- Modify: `apps/backend/test/photos.e2e-spec.ts`
- Modify: `docs/contracts/api.md`

- [ ] **Step 1: E2E 실패 테스트를 먼저 추가한다**

`apps/backend/test/photos.e2e-spec.ts`에 다음 테스트를 추가한다. 기존 fake AI는 얼굴 1개를 반환하므로 성공 케이스는 1개 배열로 검증하고, 요청 검증은 빈 배열과 업로드에 속하지 않는 얼굴 ID로 검증한다.

```ts
it('generates selected faces when faceIds belong to the upload', async () => {
    const upload = await request(app.getHttpServer())
        .post('/photos/uploads')
        .attach('photo', Buffer.from('fake-image'), 'person.jpg')
        .expect(201)

    const faces = await request(app.getHttpServer())
        .get(`/photos/uploads/${upload.body.uploadId}/faces`)
        .expect(200)

    const selectedFaceId = faces.body.faces[0].id

    const generation = await request(app.getHttpServer())
        .post(`/photos/uploads/${upload.body.uploadId}/generations`)
        .send({
            selectionMode: 'selected_faces',
            faceIds: [selectedFaceId],
        })
        .expect(201)

    const result = await request(app.getHttpServer())
        .get(`/photos/generations/${generation.body.generationId}`)
        .expect(200)

    expect(result.body.results).toHaveLength(1)
    expect(result.body.results[0].faceId).toBe(selectedFaceId)
})

it('rejects selected-face generation without face ids', async () => {
    const upload = await request(app.getHttpServer())
        .post('/photos/uploads')
        .attach('photo', Buffer.from('fake-image'), 'person.jpg')
        .expect(201)

    const response = await request(app.getHttpServer())
        .post(`/photos/uploads/${upload.body.uploadId}/generations`)
        .send({ selectionMode: 'selected_faces', faceIds: [] })
        .expect(400)

    expect(response.body.errorCategory).toBe('selection_invalid')
})

it('rejects selected-face generation when a face id does not belong to the upload', async () => {
    const upload = await request(app.getHttpServer())
        .post('/photos/uploads')
        .attach('photo', Buffer.from('fake-image'), 'person.jpg')
        .expect(201)

    const response = await request(app.getHttpServer())
        .post(`/photos/uploads/${upload.body.uploadId}/generations`)
        .send({
            selectionMode: 'selected_faces',
            faceIds: ['another-upload-face-0'],
        })
        .expect(400)

    expect(response.body.errorCategory).toBe('selection_invalid')
})
```

- [ ] **Step 2: 실패를 확인한다**

Run: `cd apps/backend && npm run test:e2e`

Expected: 새 테스트가 `selectionMode must be single_face or all_faces.` 또는 같은 의미의 400 응답으로 실패한다.

- [ ] **Step 3: DTO를 확장한다**

`apps/backend/src/photos/dto.ts`의 생성 요청 타입을 다음 형태로 바꾼다.

```ts
export type GenerationSelectionMode =
    | 'single_face'
    | 'selected_faces'
    | 'all_faces'

export interface CreateGenerationRequestDto {
    selectionMode: GenerationSelectionMode
    faceId?: string
    faceIds?: string[]
}
```

- [ ] **Step 4: 서비스 선택 검증을 확장한다**

`apps/backend/src/photos/photos.service.ts`의 `resolveSelectedFaces`를 다음 로직으로 교체한다.

```ts
private resolveSelectedFaces(
    faces: DetectedFaceDto[],
    request: CreateGenerationRequestDto,
): DetectedFaceDto[] {
    if (
        request.selectionMode !== 'single_face' &&
        request.selectionMode !== 'selected_faces' &&
        request.selectionMode !== 'all_faces'
    ) {
        throw new BadRequestException({
            message:
                'selectionMode must be single_face, selected_faces, or all_faces.',
            errorCategory: 'selection_invalid',
        })
    }

    if (request.selectionMode === 'all_faces') {
        return faces
    }

    if (request.selectionMode === 'single_face') {
        if (!request.faceId) {
            throw new BadRequestException({
                message:
                    'faceId is required when selectionMode is single_face.',
                errorCategory: 'selection_invalid',
            })
        }

        const selectedFace = faces.find((face) => face.id === request.faceId)
        if (!selectedFace) {
            throw new BadRequestException({
                message: 'faceId does not belong to the upload.',
                errorCategory: 'selection_invalid',
            })
        }

        return [selectedFace]
    }

    const requestedFaceIds = Array.from(new Set(request.faceIds ?? []))
    if (requestedFaceIds.length === 0) {
        throw new BadRequestException({
            message:
                'faceIds must include at least one face when selectionMode is selected_faces.',
            errorCategory: 'selection_invalid',
        })
    }

    const selectedFaces = requestedFaceIds.map((faceId) => {
        const face = faces.find((candidate) => candidate.id === faceId)
        if (!face) {
            throw new BadRequestException({
                message: 'faceIds must belong to the upload.',
                errorCategory: 'selection_invalid',
            })
        }

        return face
    })

    return selectedFaces
}
```

- [ ] **Step 5: Swagger 계약을 확장한다**

`apps/backend/src/photos/photos.swagger.ts`에서 생성 요청 스키마를 다음 값이 포함되게 수정한다.

```ts
selectionMode: {
    type: 'string',
    enum: ['single_face', 'selected_faces', 'all_faces'] as string[],
    example: 'selected_faces',
},
faceId: {
    type: 'string',
    description: 'Required when selectionMode is single_face.',
    example: 'f4fdba79-09ec-44c4-8d95-61f4f61d282b',
},
faceIds: {
    type: 'array',
    description: 'Required when selectionMode is selected_faces.',
    items: { type: 'string' },
    example: [
        'f4fdba79-09ec-44c4-8d95-61f4f61d282b',
        '6c01c2dd-2734-4dd2-8ff6-5d31a86336e0',
    ],
},
```

- [ ] **Step 6: API 문서를 갱신한다**

`docs/contracts/api.md`의 생성 요청 설명을 다음 의미로 바꾼다.

```md
Requests ID-photo generation for one face, selected faces, or all faces.

Request fields:

- `selectionMode`: one of `single_face`, `selected_faces`, or `all_faces`.
- `faceId`: optional string identifier for the selected face; required when `selectionMode` is `single_face`.
- `faceIds`: optional array of selected face identifiers; required and non-empty when `selectionMode` is `selected_faces`.
```

- [ ] **Step 7: 백엔드 검증을 실행한다**

Run: `cd apps/backend && npm run test:e2e`

Expected: `PASS test/photos.e2e-spec.ts`.

Run: `cd apps/backend && npm test`

Expected: Jest unit tests pass.

- [ ] **Step 8: 백엔드 계약 변경을 커밋한다**

```bash
git add apps/backend/src/photos/dto.ts apps/backend/src/photos/photos.service.ts apps/backend/src/photos/photos.swagger.ts apps/backend/test/photos.e2e-spec.ts docs/contracts/api.md
git commit -m "feat: 선택한 얼굴 생성 API 추가"
```

## Task 2: 모바일 상태와 API 클라이언트 확장

**Files:**
- Modify: `apps/mobile/lib/features/photo_flow/photo_flow_state.dart`
- Modify: `apps/mobile/lib/features/photo_flow/photo_flow_api.dart`
- Modify: `apps/mobile/test/photo_flow_state_test.dart`
- Modify: `apps/mobile/test/photo_flow_api_test.dart`

- [ ] **Step 1: 상태 테스트를 먼저 바꾼다**

`apps/mobile/test/photo_flow_state_test.dart`에서 테스트용 얼굴을 다음 helper로 생성한다.

```dart
const testBox = FaceBox(left: 80, top: 60, width: 240, height: 280);
const face = DetectedFace(
  id: 'face-1',
  faceIndex: 0,
  box: testBox,
  confidence: 0.98,
);
```

원본 사진 바이트 보관 테스트를 추가한다.

```dart
test('state can keep source photo bytes for face review', () {
  final sourcePhotoBytes = Uint8List.fromList([1, 2, 3]);
  final state = const PhotoFlowState.initial().copyWith(
    sourcePhotoBytes: sourcePhotoBytes,
  );

  expect(state.sourcePhotoBytes, sourcePhotoBytes);

  final clearedState = state.copyWith(clearSourcePhotoBytes: true);

  expect(clearedState.sourcePhotoBytes, isNull);
});
```

- [ ] **Step 2: 상태 테스트 실패를 확인한다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test test/photo_flow_state_test.dart`

Expected: `FaceBox`, `DetectedFace.box`, `sourcePhotoBytes`, `clearSourcePhotoBytes`가 없어서 실패한다.

- [ ] **Step 3: 상태 모델을 확장한다**

`apps/mobile/lib/features/photo_flow/photo_flow_state.dart`를 다음 구조로 확장한다.

```dart
import 'dart:typed_data';

enum PhotoFlowStage {
  waitingForUpload,
  uploading,
  reviewingFaces,
  generating,
  completed,
  failed,
}

class FaceBox {
  const FaceBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class DetectedFace {
  const DetectedFace({
    required this.id,
    required this.faceIndex,
    required this.box,
    required this.confidence,
  });

  final String id;
  final int faceIndex;
  final FaceBox box;
  final double confidence;
}
```

`PhotoFlowState` 생성자, `initial`, 필드, `copyWith`에 `Uint8List? sourcePhotoBytes`와 `bool clearSourcePhotoBytes = false`를 추가한다.

```dart
final Uint8List? sourcePhotoBytes;

sourcePhotoBytes: clearSourcePhotoBytes
    ? null
    : sourcePhotoBytes ?? this.sourcePhotoBytes,
```

- [ ] **Step 4: API 테스트에 `box` 파싱과 복수 선택 요청을 추가한다**

`apps/mobile/test/photo_flow_api_test.dart`에서 얼굴 박스를 확인한다.

```dart
expect(detection.faces.single.box.left, 80);
expect(detection.faces.single.box.top, 60);
expect(detection.faces.single.box.width, 240);
expect(detection.faces.single.box.height, 280);
```

복수 선택 요청 테스트를 추가한다.

```dart
test('NestPhotoFlowApi sends selected_faces for multiple selected ids', () async {
  final api = NestPhotoFlowApi(
    baseUrl: 'http://server.test',
    client: MockClient((request) async {
      if (request.url.path == '/photos/uploads/upload-1/generations') {
        expect(request, isA<http.Request>());
        expect(
          (request as http.Request).body,
          '{"selectionMode":"selected_faces","faceIds":["face-1","face-2"]}',
        );
        return http.Response(
          '{"generationId":"generation-1","status":"succeeded"}',
          201,
        );
      }

      if (request.url.path == '/photos/generations/generation-1') {
        return http.Response(
          '{"generationId":"generation-1","status":"succeeded","results":[]}',
          200,
        );
      }

      return http.Response('not found', 404);
    }),
  );

  await api.generateForFaces('upload-1', {'face-1', 'face-2'});
});
```

- [ ] **Step 5: API 클라이언트를 구현한다**

`apps/mobile/lib/features/photo_flow/photo_flow_api.dart`의 요청 body 생성 로직을 다음처럼 분리한다.

```dart
Map<String, Object> _generationRequestBody(Set<String> faceIds) {
  final sortedFaceIds = faceIds.toList()..sort();
  if (sortedFaceIds.length == 1) {
    return {
      'selectionMode': 'single_face',
      'faceId': sortedFaceIds.single,
    };
  }

  return {
    'selectionMode': 'selected_faces',
    'faceIds': sortedFaceIds,
  };
}
```

`jsonEncode` 호출은 `body: jsonEncode(_generationRequestBody(faceIds))`로 바꾼다.

`_detectedFaceFromJson`은 `box`를 파싱한다.

```dart
DetectedFace _detectedFaceFromJson(Map<String, dynamic> json) {
  final box = json['box'] as Map<String, dynamic>;

  return DetectedFace(
    id: json['id'] as String,
    faceIndex: json['faceIndex'] as int,
    box: FaceBox(
      left: (box['left'] as num).toDouble(),
      top: (box['top'] as num).toDouble(),
      width: (box['width'] as num).toDouble(),
      height: (box['height'] as num).toDouble(),
    ),
    confidence: (json['confidence'] as num).toDouble(),
  );
}
```

`FakePhotoFlowApi`의 얼굴에도 `FaceBox`를 넣는다.

```dart
DetectedFace(
  id: 'face-1',
  faceIndex: 0,
  box: FaceBox(left: 40, top: 30, width: 80, height: 96),
  confidence: 0.98,
),
```

- [ ] **Step 6: 모바일 상태와 API 테스트를 통과시킨다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test test/photo_flow_state_test.dart test/photo_flow_api_test.dart`

Expected: 두 테스트 파일이 pass.

- [ ] **Step 7: 모바일 데이터 계약 변경을 커밋한다**

```bash
git add apps/mobile/lib/features/photo_flow/photo_flow_state.dart apps/mobile/lib/features/photo_flow/photo_flow_api.dart apps/mobile/test/photo_flow_state_test.dart apps/mobile/test/photo_flow_api_test.dart
git commit -m "feat: 얼굴 박스와 선택 생성 요청 추가"
```

## Task 3: 직접 선택 캔버스 추가

**Files:**
- Create: `apps/mobile/lib/features/photo_flow/face_selection_canvas.dart`
- Modify: `apps/mobile/test/photo_flow_screen_test.dart`

- [ ] **Step 1: 화면 테스트가 새 조작을 기대하게 바뀐다**

`apps/mobile/test/photo_flow_screen_test.dart`에서 기존 `Face 1` 체크박스 기대를 직접 선택 라벨로 바꾼다.

```dart
expect(find.text('얼굴 1 제외됨'), findsOneWidget);
expect(find.text('선택한 얼굴 0명'), findsOneWidget);
```

얼굴을 탭한 뒤 선택 상태를 확인하는 테스트를 추가한다.

```dart
await tester.tap(find.text('얼굴 1 제외됨'));
await tester.pumpAndSettle();

expect(find.text('얼굴 1 선택됨'), findsOneWidget);
expect(find.text('선택한 얼굴 1명'), findsOneWidget);
```

- [ ] **Step 2: 테스트 실패를 확인한다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test test/photo_flow_screen_test.dart`

Expected: 새 한국어 라벨과 직접 선택 캔버스가 없어서 실패한다.

- [ ] **Step 3: `FaceSelectionCanvas`를 만든다**

`apps/mobile/lib/features/photo_flow/face_selection_canvas.dart`를 생성한다. 이 위젯은 원본 사진 바이트를 디코딩해 원본 이미지 크기를 얻고, 화면에 맞춘 사진 영역 위에 얼굴 박스를 올린다.

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'photo_flow_state.dart';

class FaceSelectionCanvas extends StatefulWidget {
  const FaceSelectionCanvas({
    super.key,
    required this.photoBytes,
    required this.faces,
    required this.selectedFaceIds,
    required this.onFaceToggled,
  });

  final Uint8List photoBytes;
  final List<DetectedFace> faces;
  final Set<String> selectedFaceIds;
  final ValueChanged<String> onFaceToggled;

  @override
  State<FaceSelectionCanvas> createState() => _FaceSelectionCanvasState();
}

class _FaceSelectionCanvasState extends State<FaceSelectionCanvas> {
  final TransformationController _controller = TransformationController();
  Size? _imageSize;
  Object? _decodeError;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant FaceSelectionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoBytes != widget.photoBytes) {
      _decodeImage();
      _controller.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.photoBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        return;
      }
      setState(() {
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _decodeError = null;
      });
      frame.image.dispose();
      codec.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageSize = null;
        _decodeError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;
    if (_decodeError != null) {
      return const _CanvasMessage('사진 미리보기를 표시할 수 없습니다');
    }
    if (imageSize == null) {
      return const _CanvasMessage('사진 미리보기를 준비 중입니다');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ZoomControls(
          onZoomIn: () => _scaleBy(1.25),
          onZoomOut: () => _scaleBy(0.8),
          onFit: _resetZoom,
          onOriginal: _resetZoom,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF101820),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final fitted = _containRect(viewport, imageSize);

                  return InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1,
                    maxScale: 6,
                    child: Stack(
                      children: [
                        Positioned.fromRect(
                          rect: fitted,
                          child: Image.memory(
                            widget.photoBytes,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        ),
                        for (final face in widget.faces)
                          _FaceMarker(
                            face: face,
                            rect: _faceRect(fitted, imageSize, face.box),
                            selected:
                                widget.selectedFaceIds.contains(face.id),
                            onTap: () => widget.onFaceToggled(face.id),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Rect _containRect(Size viewport, Size imageSize) {
    final scale = math.min(
      viewport.width / imageSize.width,
      viewport.height / imageSize.height,
    );
    final width = imageSize.width * scale;
    final height = imageSize.height * scale;
    return Rect.fromLTWH(
      (viewport.width - width) / 2,
      (viewport.height - height) / 2,
      width,
      height,
    );
  }

  Rect _faceRect(Rect imageRect, Size imageSize, FaceBox box) {
    final scaleX = imageRect.width / imageSize.width;
    final scaleY = imageRect.height / imageSize.height;
    return Rect.fromLTWH(
      imageRect.left + box.left * scaleX,
      imageRect.top + box.top * scaleY,
      box.width * scaleX,
      box.height * scaleY,
    );
  }

  void _scaleBy(double factor) {
    _controller.value = _controller.value.scaled(factor, factor, 1);
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }
}
```

같은 파일에 `_FaceMarker`, `_ZoomControls`, `_CanvasMessage`를 둔다. 라벨은 색상만 의존하지 않게 텍스트로도 상태를 노출한다.

```dart
class _FaceMarker extends StatelessWidget {
  const _FaceMarker({
    required this.face,
    required this.rect,
    required this.selected,
    required this.onTap,
  });

  final DetectedFace face;
  final Rect rect;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '얼굴 ${face.faceIndex + 1} ${selected ? '선택됨' : '제외됨'}';
    final borderColor =
        selected ? const Color(0xFF2FBF71) : const Color(0xFFE5E7EB);

    return Positioned(
      left: rect.left - 8,
      top: rect.top - 8,
      width: math.max(rect.width + 16, 44),
      height: math.max(rect.height + 16, 44),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: Rect.fromLTWH(
                    8,
                    8,
                    math.max(rect.width, 28),
                    math.max(rect.height, 28),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2FBF71)
                          : const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 캔버스 테스트를 통과시킬 수 있게 유효한 이미지 바이트를 쓴다**

`apps/mobile/test/photo_flow_screen_test.dart`의 `FixedPhotoPicker`는 유효한 1x1 PNG 바이트를 반환하게 바꾼다.

```dart
Uint8List onePixelPngBytes() {
  return Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
    0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 15, 4, 0,
    9, 251, 3, 253, 167, 112, 129, 220, 0, 0, 0, 0, 73, 69, 78,
    68, 174, 66, 96, 130,
  ]);
}
```

- [ ] **Step 5: 직접 선택 캔버스 테스트를 실행한다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test test/photo_flow_screen_test.dart`

Expected: 새 라벨을 아직 화면에 연결하지 않았으므로 실패한다.

- [ ] **Step 6: 직접 선택 캔버스 파일을 커밋한다**

이 단계는 화면 연결 전 위젯 파일과 테스트 helper만 분리해 검토하기 위한 커밋이다.

```bash
git add apps/mobile/lib/features/photo_flow/face_selection_canvas.dart apps/mobile/test/photo_flow_screen_test.dart
git commit -m "feat: 얼굴 직접 선택 캔버스 추가"
```

## Task 4: 얼굴 검토 화면을 직접 선택 UX로 교체

**Files:**
- Modify: `apps/mobile/lib/features/photo_flow/photo_flow_screen.dart`
- Modify: `apps/mobile/test/photo_flow_screen_test.dart`

- [ ] **Step 1: 화면 테스트를 최종 UX에 맞춘다**

`apps/mobile/test/photo_flow_screen_test.dart`에 다음 흐름을 추가한다.

```dart
testWidgets('generates only directly selected faces', (tester) async {
  final api = MultiFacePhotoFlowApi();
  await tester.pumpWidget(
    MaterialApp(
      home: PhotoFlowScreen(
        api: api,
        photoPicker: FixedPhotoPicker('person.jpg'),
      ),
    ),
  );

  await tester.tap(find.text('사진 선택'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('얼굴 1 제외됨'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('선택한 얼굴 생성'));
  await tester.pumpAndSettle();

  expect(api.generatedFaceIds, {'face-1'});
  expect(find.text('생성이 완료되었습니다'), findsOneWidget);
  expect(find.text('Generated result for face-1'), findsOneWidget);
  expect(find.text('Generated result for face-2'), findsNothing);
});
```

선택 없이 생성을 누르면 API를 호출하지 않는 테스트도 추가한다.

```dart
testWidgets('shows selection message before generating without selected faces', (tester) async {
  final api = MultiFacePhotoFlowApi();
  await tester.pumpWidget(
    MaterialApp(
      home: PhotoFlowScreen(
        api: api,
        photoPicker: FixedPhotoPicker('person.jpg'),
      ),
    ),
  );

  await tester.tap(find.text('사진 선택'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('선택한 얼굴 생성'));
  await tester.pumpAndSettle();

  expect(api.generatedFaceIds, isEmpty);
  expect(find.text('생성할 얼굴을 먼저 선택해 주세요'), findsOneWidget);
});
```

- [ ] **Step 2: 실패를 확인한다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test test/photo_flow_screen_test.dart`

Expected: 버튼 문구와 직접 선택 흐름이 아직 연결되지 않아 실패한다.

- [ ] **Step 3: 화면 상태 전환에 원본 사진 바이트를 보관한다**

`_uploadPhoto` 시작 시 기존 원본 사진을 지우고, 얼굴 인식 성공 시 새 사진 바이트를 보관한다.

```dart
state = state.copyWith(
  stage: PhotoFlowStage.uploading,
  faces: const [],
  selectedFaceIds: const {},
  results: const [],
  clearUploadId: true,
  clearSourcePhotoBytes: true,
  message: '사진을 업로드하고 있습니다',
);
```

성공 상태는 다음 메시지를 사용한다.

```dart
state = state.copyWith(
  stage: PhotoFlowStage.reviewingFaces,
  faces: detectionResult.faces,
  selectedFaceIds: const {},
  results: const [],
  uploadId: detectionResult.uploadId,
  sourcePhotoBytes: photo.bytes,
  message: '사진에서 얼굴을 선택해 주세요',
);
```

- [ ] **Step 4: 선택 토글과 선택 검증 메서드를 추가한다**

`_PhotoFlowScreenState`에 다음 메서드를 추가한다.

```dart
void _toggleFace(String faceId) {
  final selectedFaceIds = Set<String>.from(state.selectedFaceIds);
  if (selectedFaceIds.contains(faceId)) {
    selectedFaceIds.remove(faceId);
  } else {
    selectedFaceIds.add(faceId);
  }

  setState(() {
    state = state.copyWith(
      selectedFaceIds: selectedFaceIds,
      clearMessage: true,
    );
  });
}

void _selectAllFaces() {
  setState(() {
    state = state.copyWith(
      selectedFaceIds: state.faces.map((face) => face.id).toSet(),
      clearMessage: true,
    );
  });
}

void _clearSelection() {
  setState(() {
    state = state.copyWith(
      selectedFaceIds: const {},
      clearMessage: true,
    );
  });
}

Future<void> _generateSelectedFaces() async {
  if (state.selectedFaceIds.isEmpty) {
    setState(() {
      state = state.copyWith(message: '생성할 얼굴을 먼저 선택해 주세요');
    });
    return;
  }

  await _generate(state.selectedFaceIds);
}
```

- [ ] **Step 5: build를 직접 선택 화면으로 바꾼다**

`photo_flow_screen.dart`에 새 위젯을 import한다.

```dart
import 'face_selection_canvas.dart';
```

기존 `CheckboxListTile` 반복 렌더링 대신 다음 구조를 사용한다.

```dart
final sourcePhotoBytes = state.sourcePhotoBytes;

return Scaffold(
  appBar: AppBar(title: const Text('Pick Photo')),
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(state.message ?? '사진을 선택해 시작하세요'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _pickAndUploadPhoto,
            child: const Text('사진 선택'),
          ),
          const SizedBox(height: 12),
          if (state.stage == PhotoFlowStage.reviewingFaces &&
              sourcePhotoBytes != null)
            Expanded(
              child: FaceSelectionCanvas(
                photoBytes: sourcePhotoBytes,
                faces: state.faces,
                selectedFaceIds: state.selectedFaceIds,
                onFaceToggled: _toggleFace,
              ),
            )
          else
            const Spacer(),
          if (state.faces.isNotEmpty)
            _SelectionSummary(
              selectedCount: state.selectedFaceIds.length,
              totalCount: state.faces.length,
              onSelectAll: _selectAllFaces,
              onClear: _clearSelection,
              onGenerate: _generateSelectedFaces,
            ),
          for (final result in state.results)
            ListTile(
              title: Text('Generated result for ${result.faceId}'),
              subtitle: Text(result.url),
            ),
        ],
      ),
    ),
  ),
);
```

같은 파일 아래에 `_SelectionSummary`를 추가한다.

```dart
class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClear,
    required this.onGenerate,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('선택한 얼굴 $selectedCount명 / 전체 $totalCount명'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onSelectAll,
                child: const Text('전체 선택'),
              ),
              OutlinedButton(
                onPressed: onClear,
                child: const Text('선택 초기화'),
              ),
              FilledButton(
                onPressed: onGenerate,
                child: const Text('선택한 얼굴 생성'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: 생성 완료와 실패 문구를 화면 테스트와 맞춘다**

`_generate` 성공 메시지는 `생성이 완료되었습니다`, 실패 메시지는 `생성에 실패했습니다. 다시 시도해 주세요`로 정리한다. 업로드 실패는 `업로드에 실패했습니다. 다시 시도해 주세요`, 얼굴 없음은 `얼굴을 찾지 못했습니다`로 정리한다.

- [ ] **Step 7: 화면 테스트를 통과시킨다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test test/photo_flow_screen_test.dart`

Expected: `photo_flow_screen_test.dart` pass.

- [ ] **Step 8: 화면 교체를 커밋한다**

```bash
git add apps/mobile/lib/features/photo_flow/photo_flow_screen.dart apps/mobile/test/photo_flow_screen_test.dart
git commit -m "feat: 원본 사진 직접 얼굴 선택 화면 적용"
```

## Task 5: 전체 검증과 문서 정리

**Files:**
- Modify: `AGENTS.md`, if implementation reveals a new stable repository fact.
- Modify: `docs/contracts/api.md`, if request or response wording changed during implementation.

- [ ] **Step 1: Dart 포맷을 실행한다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test`

Expected: changed Dart files are formatted.

- [ ] **Step 2: 모바일 테스트 전체를 실행한다**

Run: `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`

Expected: all Flutter tests pass.

- [ ] **Step 3: Prisma client 생성을 확인한다**

Run: `cd apps/backend && npm run prisma:generate`

Expected: Prisma client generation succeeds under `apps/backend/src/generated/prisma/` and generated files remain untracked.

- [ ] **Step 4: 백엔드 테스트 전체를 실행한다**

Run: `cd apps/backend && npm test`

Expected: Jest unit tests pass.

Run: `cd apps/backend && npm run test:e2e`

Expected: e2e tests pass.

- [ ] **Step 5: 백엔드 빌드를 실행한다**

Run: `cd apps/backend && npm run build`

Expected: NestJS TypeScript build succeeds.

- [ ] **Step 6: 변경 파일을 점검한다**

Run: `git diff --check`

Expected: whitespace errors are not reported.

Run: `git status --short`

Expected: implementation files are modified as planned, generated/cache artifacts under `src/generated`, `node_modules`, `.dart_tool`, `build`, and virtualenv paths are not staged.

- [ ] **Step 7: 최종 구현 변경을 커밋한다**

```bash
git add AGENTS.md docs/contracts/api.md apps/backend/src/photos/dto.ts apps/backend/src/photos/photos.service.ts apps/backend/src/photos/photos.swagger.ts apps/backend/test/photos.e2e-spec.ts apps/mobile/lib/features/photo_flow/photo_flow_state.dart apps/mobile/lib/features/photo_flow/photo_flow_api.dart apps/mobile/lib/features/photo_flow/face_selection_canvas.dart apps/mobile/lib/features/photo_flow/photo_flow_screen.dart apps/mobile/test/photo_flow_state_test.dart apps/mobile/test/photo_flow_api_test.dart apps/mobile/test/photo_flow_screen_test.dart
git commit -m "feat: 확대 직접 얼굴 선택 구현"
```

## 보안 점검

- Security-sensitive areas: 사진 업로드, 원본 사진 바이트, 얼굴 박스, 생성 결과 URL, 외부 AI 서비스 호출 경계.
- Existing controls preserved: 업로드 MIME 검증, 백엔드 얼굴 소유권 검증, `selection_invalid` 안정 에러 카테고리, 저장소 abstraction, AI adapter abstraction.
- New controls: `selected_faces` 요청에서 빈 배열을 거부하고, 모든 `faceIds`가 해당 업로드의 얼굴인지 검증한다. 모바일은 선택이 비어 있으면 생성 API를 호출하지 않는다.
- Residual risks: 원본 사진 미리보기는 모바일 메모리에만 보관하고 서버 미리보기 URL은 만들지 않는다. 보관 기간과 삭제 정책은 기존 열린 질문으로 남긴다.
- Tests: `photos.e2e-spec.ts`의 selected face validation, `photo_flow_screen_test.dart`의 선택 없이 생성 방지.

## 언어 및 런타임 점검

- 새 런타임, 패키지 매니저, Flutter 플러그인, npm dependency를 추가하지 않는다.
- Flutter는 기존 `Material`, `InteractiveViewer`, `Image.memory`, `flutter_test`를 사용한다.
- NestJS는 기존 DTO type, service validation, Swagger schema, Supertest e2e 패턴을 유지한다.
- Prisma 스키마와 migration은 변경하지 않는다.

## 롤백과 격리

- 모바일 UI 변경은 `photo_flow` feature 폴더 안에 격리한다.
- 백엔드 API 확장은 기존 `single_face`와 `all_faces`를 유지하므로 이전 클라이언트 요청은 계속 동작한다.
- 문제가 생기면 `selected_faces` 전송을 모바일에서 단일 선택만 허용하는 방식으로 되돌릴 수 있지만, 그렇게 하면 승인된 임의 다중 선택 UX는 제한된다.

## Plan Review

Decision: Approved

Reasons:

- 승인된 UX 설계의 핵심인 원본 사진 직접 선택, 확대 선택, 하단 선택 요약이 구현 작업에 모두 매핑되어 있다.
- `selected_faces` API 확장을 포함해 선택 상태와 생성 대상 불일치 위험을 제거한다.
- 변경 범위는 `photo_flow`, `photos` API, API 계약 문서로 제한되어 있고 AI 모델, 저장소, Prisma 스키마를 건드리지 않는다.
- 검증은 AGENTS에 기록된 verified command만 사용한다.
- 사진과 얼굴 데이터가 민감 정보라는 보안 경계를 계획에 포함했다.

Required revisions or blockers:

- 없음.

Approved implementation scope:

- 이 계획에 적힌 파일과 테스트 범위 안에서 구현을 시작할 수 있다. 프로젝트 하네스 규칙에 따라 사용자의 구현 확인을 받은 뒤 진행한다.
