import 'package:flutter/material.dart';

import 'features/photo_flow/photo_flow_api.dart';
import 'features/photo_flow/photo_flow_screen.dart';
import 'features/photo_flow/photo_picker.dart';

void main() {
  runApp(const PickPhotoApp());
}

class PickPhotoApp extends StatelessWidget {
  const PickPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0369A1);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: seedColor,
      secondary: const Color(0xFF2FBF71),
      surface: Colors.white,
      onSurface: const Color(0xFF020617),
    );

    return MaterialApp(
      title: 'Pick Photo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF020617),
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: PhotoFlowScreen(
        api: NestPhotoFlowApi(),
        photoPicker: FilePickerPhotoPicker(),
      ),
    );
  }
}
