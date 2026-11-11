import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';

class AndroidBridge {
  static const channel = MethodChannel('com.dontori/platform');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<void> sync(LedgerState? state) async {
    if (!supported) return;
    final b = state?.today;
    await channel.invokeMethod<void>('syncWidget', {
      'configured': state != null,
      'remaining': b?.remaining ?? 0,
      'hp': b?.hp ?? 0,
      'date': b == null ? '' : b.date.toIso8601String().split('T').first,
      'expired': b?.expired ?? false,
    });
  }

  static Future<bool> consumeQuickEntry() async => supported
      ? (await channel.invokeMethod<bool>('consumeQuickEntry') ?? false)
      : false;
  static Future<bool> export(String data) async =>
      await channel.invokeMethod<bool>('exportBackup', data) ?? false;
  static Future<String?> import() =>
      channel.invokeMethod<String>('importBackup');
}
