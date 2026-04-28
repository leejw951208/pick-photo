import 'package:flutter/material.dart';

import 'features/photo_flow/photo_flow_api.dart';
import 'features/photo_flow/photo_flow_screen.dart';

void main() {
  runApp(const PickPhotoApp());
}

class PickPhotoApp extends StatelessWidget {
  const PickPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pick Photo',
      theme: ThemeData(useMaterial3: true),
      home: PhotoFlowScreen(api: FakePhotoFlowApi()),
    );
  }
}
