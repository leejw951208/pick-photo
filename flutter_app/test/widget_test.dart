import 'package:flutter_test/flutter_test.dart';

import 'package:pick_photo/main.dart';

void main() {
  testWidgets('Pick Photo app shows upload action', (tester) async {
    await tester.pumpWidget(const PickPhotoApp());

    expect(find.text('Pick Photo'), findsOneWidget);
    expect(find.text('Upload photo'), findsOneWidget);
  });
}
