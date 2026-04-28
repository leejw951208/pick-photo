import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_api.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_screen.dart';

void main() {
  testWidgets('shows face selection after upload', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoFlowScreen(api: FakePhotoFlowApi())),
    );

    await tester.tap(find.text('Upload sample photo'));
    await tester.pumpAndSettle();

    expect(find.text('Face 1'), findsOneWidget);
  });
}
