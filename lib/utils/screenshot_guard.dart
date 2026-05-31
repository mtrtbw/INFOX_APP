// lib/utils/screenshot_guard.dart
// Widget pembungkus yang mengaktifkan/nonaktifkan anti screenshot
// berdasarkan setting dari server

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';

class ScreenshotGuard extends StatefulWidget {
  final Widget child;

  const ScreenshotGuard({super.key, required this.child});

  @override
  State<ScreenshotGuard> createState() => _ScreenshotGuardState();
}

class _ScreenshotGuardState extends State<ScreenshotGuard> {
  bool _isLoading = true;
  bool _protect   = true; // default aktif sampai setting dimuat

  @override
  void initState() {
    super.initState();
    _loadAndApply();
  }

  Future<void> _loadAndApply() async {
    final enabled = await SettingsService.isAntiScreenshotEnabled();
    if (!mounted) return;

    setState(() {
      _protect   = enabled;
      _isLoading = false;
    });

    _applyProtection(enabled);
  }

  void _applyProtection(bool enabled) {
    if (enabled) {
      // Aktifkan flag secure — layar hitam saat screenshot/screen record
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _setSecureFlag(true);
    } else {
      _setSecureFlag(false);
    }
  }

  // Channel ke native untuk FLAG_SECURE (Android) / allowScreenshot (iOS)
  static const _channel = MethodChannel('infox/screenshot');

  Future<void> _setSecureFlag(bool secure) async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'secure': secure});
    } catch (_) {
      // Fallback jika channel belum diimplementasi — tidak crash
    }
  }

  @override
  void dispose() {
    // Hapus proteksi saat keluar dari halaman soal
    _setSecureFlag(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan child langsung — proteksi bekerja di level OS
    // Tidak perlu loading screen karena default sudah aman
    return widget.child;
  }
}