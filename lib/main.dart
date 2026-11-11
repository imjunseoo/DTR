import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home.dart';

void main() => runApp(const ProviderScope(child: DontoriApp()));

class DontoriApp extends StatelessWidget {
  const DontoriApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DTR',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      splashFactory: InkRipple.splashFactory,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF216B52)),
      scaffoldBackgroundColor: const Color(0xFFF7F8F2),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const HomeScreen(),
  );
}
