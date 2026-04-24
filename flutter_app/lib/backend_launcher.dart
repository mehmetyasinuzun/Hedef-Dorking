import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


class BackendLauncher {
  static Process? _process;

  /// Port 8080 kontrolü
  static Future<bool> _portAcikMi() async {
    try {
      final s = await Socket.connect(
        'localhost',
        8080,
        timeout: const Duration(milliseconds: 400),
      );
      await s.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Backend başlar
  static Future<void> baslat() async {
    if (await _portAcikMi()) return;

    try {
      final dir = File(Platform.resolvedExecutable).parent;
      await dir.create(recursive: true);

      final exeYol = '${dir.path}\\dorking.exe';

      final exeBytes = await rootBundle.load('assets/backend/dorking.exe');
      await File(exeYol)
          .writeAsBytes(exeBytes.buffer.asUint8List(), flush: true);

      _process = await Process.start(
        exeYol,
        [],
        workingDirectory: dir.path,
      );

      // asenkron yapı 
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {

      debugPrint('[BackendLauncher] Hata: $e');
    }
  }

  /// Backend öldür
  static void durdur() {
    _process?.kill();
    _process = null;
  }
}
