// lib/services/settings_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SettingsService {
  static bool? _antiScreenshot;
  static DateTime? _lastFetch;

  /// Fetch dari api/pengaturan.php
  /// Response: {"status":"ok","anti_screenshot":true/false}
  static Future<bool> isAntiScreenshotEnabled({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // UBAH: Cache diturunkan dari 60 detik menjadi 2 detik saja.
    // Ini agar Timer 3 detik di halaman ujian bisa menembus fungsi ini dan meminta data baru.
    if (!forceRefresh &&
        _lastFetch != null &&
        now.difference(_lastFetch!).inSeconds < 2 &&
        _antiScreenshot != null) {
      return _antiScreenshot!;
    }

    try {
      // UBAH: Tambahkan parameter `t` (timestamp) untuk mem-bypass cache jaringan
      final url = '${AppConfig.baseUrl}/pengaturan.php?t=${now.millisecondsSinceEpoch}';
      
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'ok') {
          _antiScreenshot = json['anti_screenshot'] == true;
          _lastFetch      = now;
          return _antiScreenshot!;
        }
      }
    } catch (_) {
      // Gagal fetch → pakai cache kalau ada
    }

    // Default: OFF kalau tidak bisa fetch (aman untuk siswa)
    return _antiScreenshot ?? false;
  }

  static void clearCache() {
    _antiScreenshot = null;
    _lastFetch      = null;
  }
}