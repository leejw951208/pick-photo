import 'package:flutter_test/flutter_test.dart';

import 'package:pick_photo/main.dart';

void main() {
  testWidgets('Pick Photo app shows upload action', (tester) async {
    await tester.pumpWidget(const PickPhotoApp());

    expect(find.text('Pick Photo'), findsOneWidget);
    expect(find.text('사진 한 장으로 증명사진 스타일 결과를 만드세요'), findsOneWidget);
    expect(find.text('선택한 얼굴만 생성됩니다'), findsOneWidget);
    expect(find.text('사진 선택'), findsOneWidget);
  });
}
