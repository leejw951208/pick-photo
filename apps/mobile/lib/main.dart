import 'package:flutter/material.dart';

import 'features/photo_flow/photo_flow_api.dart';
import 'features/photo_flow/photo_flow_screen.dart';
import 'features/photo_flow/photo_picker.dart';

void main() {
  runApp(const PickPhotoApp());
}

class PickPhotoApp extends StatefulWidget {
  const PickPhotoApp({super.key});

  @override
  State<PickPhotoApp> createState() => _PickPhotoAppState();
}

class _PickPhotoAppState extends State<PickPhotoApp> {
  late final PhotoFlowApi _api = NestPhotoFlowApi();
  late final PhotoPicker _photoPicker = FilePickerPhotoPicker();

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return MaterialApp(
      title: 'Pick Photo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: scaffold,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: scaffold,
          foregroundColor: primary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: outline),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: primary,
            minimumSize: const Size(44, 44),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFEAF4FF),
            foregroundColor: primary,
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: outline),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: secondary,
        ),
      ),
      home: PhotoFlowScreen(
        api: _api,
        photoPicker: _photoPicker,
      ),
    );
  }
}
