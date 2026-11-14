import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home.dart';
import 'ui/design.dart';

void main() => runApp(const ProviderScope(child: DontoriApp()));

class DontoriApp extends StatelessWidget {
  const DontoriApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DTR',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'NotoSansKR',
      splashFactory: InkRipple.splashFactory,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DtrDesign.accent,
        primary: DtrDesign.accent,
        surface: DtrDesign.background,
        onSurface: DtrDesign.ink,
      ),
      scaffoldBackgroundColor: DtrDesign.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: DtrDesign.background,
        foregroundColor: DtrDesign.ink,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DtrDesign.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: DtrDesign.card,
          foregroundColor: DtrDesign.accent,
          side: const BorderSide(color: DtrDesign.border),
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: DtrDesign.card,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: DtrDesign.text(
          14,
          color: DtrDesign.muted,
          weight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        counterStyle: const TextStyle(height: 0, fontSize: 0),
        border: const UnderlineInputBorder(borderSide: BorderSide.none),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide.none),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide.none),
        isDense: true,
      ),
    ),
    home: const HomeScreen(),
  );
}
