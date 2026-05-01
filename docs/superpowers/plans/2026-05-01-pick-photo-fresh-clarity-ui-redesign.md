# Pick Photo Fresh Clarity UI 리디자인 구현 계획

> **에이전트 작업자를 위한 참고:** 이 계획을 작업 단위로 실행할 때는 `superpowers:subagent-driven-development` 또는 `superpowers:executing-plans`를 사용한다. 체크박스는 구현 진행 상태 추적용이다.

**목표:** Pick Photo Flutter 앱의 기능 중심 UI를 사용자가 선택한 `Fresh Clarity` 디자인 방향으로 리디자인한다.

**구조:** 변경은 `apps/mobile/` Flutter UI 레이어에 한정한다. 기존 사진 선택, 업로드, 얼굴 직접 선택, 확대/이동, 생성 요청, 실패/결과 상태 로직은 유지하고 `ThemeData`, 화면 위젯 스타일, 테스트 기대 문구만 필요한 범위에서 조정한다.

**기술 스택:** Flutter 3.22.1 stable, Dart 3.4.1, Material 3, `flutter_test`.

---

## 범위

- `Fresh Clarity` 시각 방향을 앱 테마와 photo flow 화면에 반영한다.
- 기존 PRD 기준인 선택한 얼굴만 생성, 얼굴 직접 선택, 확대 선택, 하단 선택 요약을 유지한다.
- 새 Flutter 패키지, 외부 폰트, API, 백엔드, AI 서버, 데이터베이스 변경은 하지 않는다.

## 비범위

- 인증, 보관 기간, 삭제 정책, 공식 증명사진 규격, 다운로드/저장 권한 정책.
- 실제 이미지 처리 품질 개선.
- 백엔드/AI/API 계약 변경.
- Flutter Android 빌드 호환성 해결.

## 변경 파일

- 수정: `apps/mobile/lib/main.dart`
  - `Fresh Clarity` ColorScheme, AppBar, Card, Button, ProgressIndicator 기본 톤을 정의한다.
- 수정: `apps/mobile/lib/features/photo_flow/photo_flow_screen.dart`
  - 헤더, 단계 표시, 시작 안내, 검토 패널, 결과 카드, 진행/실패 패널, 하단 선택 요약 스타일을 C안에 맞춘다.
- 수정: `apps/mobile/lib/features/photo_flow/face_selection_canvas.dart`
  - 사진 캔버스와 얼굴 마커, 확대 컨트롤을 밝은 민트/블루 톤으로 조정한다.
- 수정: `apps/mobile/test/widget_test.dart`
  - 시작 화면 핵심 문구와 업로드 액션 기대값을 유지 또는 갱신한다.
- 수정: `apps/mobile/test/photo_flow_screen_test.dart`
  - 기존 동작 테스트가 새 문구와 구조에서도 통과하도록 필요한 기대값만 갱신한다.

## 제품 요구사항 정합성

- `FR-001`, `AC-001`: 사진 선택과 업로드 흐름 시작 버튼 유지.
- `FR-003`, `NFR-003`: 얼굴 검토 화면에서 얼굴 선택 상태가 명확해야 함.
- `FR-005`, `FR-006`, `FR-008`, `NFR-004`: 선택한 얼굴만 생성하는 흐름 유지.
- `FR-009`, `FR-010`, `AC-009`: 진행/실패 상태와 재시도 가능성 유지.
- `FR-011`, `AC-007`: 결과 확인 화면 유지.
- `FR-013`, `NFR-006`: 사진과 얼굴 정보가 민감하다는 기대를 과장 없이 전달.

## 보안과 개인정보 영향

- 사진, 얼굴 박스, 결과 이미지는 민감한 개인 정보로 취급한다.
- 이번 작업은 새 저장, 로그, 전송, API 호출, 다운로드를 추가하지 않는다.
- UI 문구에서 보관 기간, 삭제 보장, 공식 규격 충족 같은 미정 정책을 약속하지 않는다.

## 기능 진행 상태

| Feature ID | 기능 / 동작 | Status | Progress | 요구사항 | 검증 / 테스트 | 차단 요소 / 다음 행동 |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | Fresh Clarity 테마와 시작 화면 리디자인 | Complete | 100% | 사용자 요청, FR-001, AC-001, FR-013 | `cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test`; `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`; `widget_test.dart` Fresh Clarity 테마 기대값 | 없음 |
| F-002 | 얼굴 검토/선택 캔버스 리디자인 | Complete | 100% | FR-003, FR-005, FR-006, FR-008, NFR-003, NFR-004 | `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`; `photo_flow_screen_test.dart` 선택/전체 선택/선택 없음/캔버스 줌 테스트 | 없음 |
| F-003 | 진행, 실패, 결과 상태 리디자인 | Complete | 100% | FR-009, FR-010, FR-011, AC-007, AC-009 | `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`; `photo_flow_screen_test.dart` 업로드 실패/생성 실패/결과 테스트 | 없음 |

## 작업 1: 시작 화면과 앱 테마 테스트 갱신

**파일:**
- 수정: `apps/mobile/test/widget_test.dart`
- 수정: `apps/mobile/test/photo_flow_screen_test.dart`

- [x] **단계 1: 실패하는 위젯 기대값 작성**

`apps/mobile/test/widget_test.dart`가 시작 화면의 `Fresh Clarity` 테마, 진입 문구, 주요 사진 선택 액션을 검증하도록 갱신했다.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pick_photo/main.dart';

void main() {
  testWidgets('Pick Photo app shows Fresh Clarity upload action',
      (tester) async {
    await tester.pumpWidget(const PickPhotoApp());

    expect(find.text('Pick Photo'), findsOneWidget);
    expect(find.text('사진 한 장으로 증명사진 스타일 결과를 만드세요'), findsOneWidget);
    expect(find.text('선택한 얼굴만 생성됩니다'), findsOneWidget);
    expect(find.text('사진 선택'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, const Color(0xFF102033));
    expect(app.theme?.colorScheme.tertiary, const Color(0xFF6EE7B7));
  });
}
```

이 테스트는 구현 전 현재 앱 테마의 primary color가 `Color(0xFF0369A1)`였기 때문에 실패해야 했다.

- [x] **단계 2: 현재 상태 테스트 실패 확인**

실행:

```bash
cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test
```

기대 결과:

- 실패한다. 아직 `app.theme?.colorScheme.primary`가 `Color(0xFF102033)`이 아니기 때문이다.

## 작업 2: 앱 테마를 Fresh Clarity로 변경

**파일:**
- 수정: `apps/mobile/lib/main.dart`

- [x] **단계 1: 테마 상수 갱신**

기존 blue/green seed theme를 밝은 clarity 팔레트로 교체했다.

```dart
const primary = Color(0xFF102033);
const secondary = Color(0xFF2878C7);
const accent = Color(0xFF6EE7B7);
const surface = Color(0xFFFFFFFF);
const scaffold = Color(0xFFF6FAFF);
const outline = Color(0xFFD6E4F2);

final colorScheme = ColorScheme.fromSeed(
  seedColor: secondary,
  brightness: Brightness.light,
).copyWith(
  primary: primary,
  secondary: secondary,
  tertiary: accent,
  surface: surface,
  onSurface: primary,
  outline: outline,
);
```

`ThemeData`는 다음 기준으로 갱신했다.

- `scaffoldBackgroundColor` is `scaffold`.
- `appBarTheme` uses transparent or scaffold background with primary foreground.
- `cardTheme` uses white, radius 20, subtle blue outline, and low elevation.
- `filledButtonTheme` uses primary text on mint accent for primary actions.
- `outlinedButtonTheme` uses light blue surfaces and primary text.

- [x] **단계 2: 포맷 실행**

실행:

```bash
cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test
```

기대 결과: Dart 파서 오류 없이 formatter가 종료된다.

## 작업 3: Photo flow screen 표면 리디자인

**파일:**
- 수정: `apps/mobile/lib/features/photo_flow/photo_flow_screen.dart`

- [x] **단계 1: 로컬 디자인 상수 추가**

import 하단에 private color helper를 추가했다.

```dart
abstract final class _FreshColors {
  static const ink = Color(0xFF102033);
  static const muted = Color(0xFF55708C);
  static const blue = Color(0xFF2878C7);
  static const paleBlue = Color(0xFFEAF4FF);
  static const mint = Color(0xFF6EE7B7);
  static const mintStrong = Color(0xFF22C58B);
  static const warning = Color(0xFFE09A2D);
  static const line = Color(0xFFD6E4F2);
  static const surface = Color(0xFFFFFFFF);
}
```

- [x] **단계 2: 페이지 shell spacing 갱신**

In `PhotoFlowScreen.build`, keep the `contentWidth` cap but use:

```dart
padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
```

기존 `Column` 구조를 유지하고 upload/generation 로직은 변경하지 않았다.

- [x] **단계 3: `_FlowHeader` 스타일 변경**

기존 compact/non-compact 동작과 문구를 유지하고, pale blue surface와 더 큰 radius를 적용했다.

```dart
decoration: BoxDecoration(
  color: const Color(0xFFEAF4FF),
  border: Border.all(color: const Color(0xFFD6E4F2)),
  borderRadius: BorderRadius.circular(24),
  boxShadow: const [
    BoxShadow(
      color: Color(0x1437587C),
      blurRadius: 28,
      offset: Offset(0, 16),
    ),
  ],
),
```

non-compact title은 다음 문구를 유지했다.

```dart
'사진 한 장으로 증명사진 스타일 결과를 만드세요'
```

title color는 `_FreshColors.ink`, 본문 color는 `_FreshColors.muted`를 사용했다.

- [x] **단계 4: `_InfoPill`, `_StageChip`, `_StatusBanner` 스타일 변경**

pale background, blue/mint accent, 더 강한 텍스트 대비를 적용하고 다음 label은 유지했다.

- `선택한 얼굴만 생성됩니다`
- `저장 전 결과 확인`
- `업로드`
- `얼굴 선택`
- `결과 확인`

아이콘은 semantic 구조 안정성을 위해 제거하지 않았다.

- [x] **단계 5: `_StartGuidance`와 `_GuidanceRow` 스타일 변경**

기존 세 안내 row와 문구를 유지하면서 각 row를 softer tile로 정리했다.

- background `Colors.white`
- border `_FreshColors.line`
- radius `20`
- icon container 40x40 with pale blue or mint background

- [x] **단계 6: `_ReviewPanel` 스타일 변경**

`FaceSelectionCanvas`를 primary control로 유지하고, surrounding panel은 다음 기준으로 조정했다.

- radius `24`
- white surface
- border `_FreshColors.line`
- subtle shadow

하단 face list는 추가하지 않았다.

- [x] **단계 7: `_ResultsPanel`과 `_GeneratedResultCard` 스타일 변경**

result list 동작과 `Image.network`는 유지하고, card는 더 큰 preview row로 조정했다.

- image size about `88 x 112`
- radius `22`
- blue fallback background
- title color `_FreshColors.ink`
- secondary text `_FreshColors.muted`

테스트가 result URL을 검증하므로 URL text는 유지했다.

- [x] **단계 8: `_ProgressPanel`과 `_FailurePanel` 스타일 변경**

`_ProgressPanel`은 단순함을 유지하되 빈 화면처럼 보이지 않도록 조정했다.

```dart
return const Center(
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: Color(0xFFFFFFFF),
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    child: Padding(
      padding: EdgeInsets.all(22),
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    ),
  ),
);
```

`_FailurePanel`은 pale warning styling을 사용하고 기존 실패 문구를 유지했다.

- [x] **단계 9: `_SelectionSummary` 스타일 변경**

버튼과 callback은 유지하고, C mockup에 맞춰 summary를 조정했다.

- white bottom panel
- radius `24`
- blue outline and subtle top shadow
- selected count in ink
- primary generate button uses mint filled style from theme

## 작업 4: Face selection canvas 리디자인

**파일:**
- 수정: `apps/mobile/lib/features/photo_flow/face_selection_canvas.dart`

- [x] **단계 1: 로컬 색상 상수 추가**

다음 색상 상수를 추가했다.

```dart
abstract final class _CanvasColors {
  static const ink = Color(0xFF102033);
  static const muted = Color(0xFF55708C);
  static const blue = Color(0xFF2878C7);
  static const paleBlue = Color(0xFFEAF4FF);
  static const mint = Color(0xFF6EE7B7);
  static const mintStrong = Color(0xFF22C58B);
  static const warning = Color(0xFFE09A2D);
  static const line = Color(0xFFD6E4F2);
}
```

- [x] **단계 2: zoom control 스타일 변경**

`확대`, `축소`, `맞춤`, `원본` label을 유지하고 horizontal control을 rounded pale blue surface로 감쌌다.

```dart
DecoratedBox(
  decoration: BoxDecoration(
    color: _CanvasColors.paleBlue,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _CanvasColors.line),
  ),
  child: Padding(
    padding: const EdgeInsets.all(6),
    child: SingleChildScrollView(...)
  ),
)
```

- [x] **단계 3: photo canvas container 스타일 변경**

dark canvas background를 light blue frame으로 변경했다.

```dart
color: const Color(0xFFDCEAF7),
borderRadius: BorderRadius.circular(24),
```

`ClipRRect`에도 동일한 radius를 사용했다.

- [x] **단계 4: `_FaceMarker` 스타일 변경**

semantics, minimum tap target, label text, tap behavior는 유지하고 다음 스타일을 적용했다.

- selected border: `_CanvasColors.mintStrong`
- excluded border: `Colors.white` with blue shadow
- selected label background: `_CanvasColors.mint`
- excluded label background: `_CanvasColors.ink`
- label text remains white or ink with enough contrast
- border radius `16`

`selected` semantics는 제거하지 않았다.

- [x] **단계 5: `_CanvasMessage` 스타일 변경**

loading/error text는 `_CanvasColors.muted`를 사용하고 pale rounded panel 안에 중앙 정렬했다.

## 작업 5: 동작과 포맷 검증

**파일:**
- 검증만 수행했다. 테스트가 실제 문제를 드러내지 않는 한 추가 source 변경은 하지 않았다.

- [x] **단계 1: Dart format 실행**

실행:

```bash
cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test
```

기대 결과: formatter가 exit `0`으로 종료된다.

- [x] **단계 2: Flutter widget test 실행**

실행:

```bash
cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test
```

기대 결과: 모든 테스트가 통과한다.

- [x] **단계 3: diff scope 검토**

실행:

```bash
git diff -- apps/mobile/lib/main.dart apps/mobile/lib/features/photo_flow/photo_flow_screen.dart apps/mobile/lib/features/photo_flow/face_selection_canvas.dart apps/mobile/test/widget_test.dart apps/mobile/test/photo_flow_screen_test.dart docs/superpowers/specs/2026-05-01-pick-photo-fresh-clarity-ui-redesign-design.md docs/superpowers/plans/2026-05-01-pick-photo-fresh-clarity-ui-redesign.md
```

기대 결과:

- 이 작업으로 backend, AI, database, contract, generated, cache 파일은 변경하지 않는다.
- 기존 API 동작과 비동기 순서 보호 로직은 변경하지 않는다.
- 보관 기간, 삭제 동작, 공식 증명사진 규격 충족을 약속하는 UI 문구는 추가하지 않는다.

## 문서 영향

- 이 계획과 `docs/superpowers/specs/2026-05-01-pick-photo-fresh-clarity-ui-redesign-design.md`는 선택된 C 방향을 기록한다.
- 제품 요구사항과 범위가 바뀌지 않았으므로 `PRD.md` 업데이트는 필요하지 않다.
- API 또는 데이터 shape 변경이 없으므로 contract 문서 업데이트는 필요하지 않다.

## 구현 리뷰

- 계획 범위와 일치한다. 변경은 Flutter UI, Flutter 테스트, C안 스펙/계획/목업 문서에 한정된다.
- 사진 선택, 업로드, 얼굴 직접 선택, 확대/축소, 전체 선택, 선택 초기화, 선택한 얼굴 생성, 실패/결과 표시 로직은 유지했다.
- 새 패키지, API, 백엔드, AI 서버, 데이터베이스, 계약 문서 변경은 추가하지 않았다.
- 보관 기간, 삭제 방법, 공식 규격 보장처럼 아직 결정되지 않은 정책을 앱 UI 문구로 약속하지 않았다.
- 기존 작업 트리에 이미 있던 `.agents/**`, `photo_flow_api.dart`, `photo_flow_api_test.dart`, `photo_flow_screen_test.dart`, `main.dart`의 일부 변경은 되돌리지 않았고 이번 UI 작업과 충돌하지 않는 범위에서 보존했다.

## 검증 결과

- `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`
  - RED 단계: Fresh Clarity primary color 기대값에서 실패를 확인했다.
  - GREEN 단계: 전체 Flutter 테스트가 통과했다.
- `cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test`
  - Dart 포맷이 통과했다.

## 계획 자체 점검

- 스펙 커버리지: 작업은 C 방향 theme, 시작 화면, 얼굴 검토, 캔버스, 하단 요약, 진행, 실패, 결과 상태를 포함한다.
- 미완성 표기 점검: 미완성 표기나 비어 있는 구현 단계는 남아 있지 않다.
- 타입 일관성: 새 helper class는 private Flutter UI constant이며 공개 인터페이스에 영향을 주지 않는다.
- 범위 점검: Flutter UI 파일과 Flutter test만 구현 범위에 포함한다.
