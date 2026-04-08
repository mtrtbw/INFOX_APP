import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotifikasiService {
  static const baseUrl = 'http://10.5.50.231/infox-backend/api';

  static final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<int> badgeCount = ValueNotifier(0);
  static List<Map<String, dynamic>> _lastData = [];
  static Timer? _timer;

  // Navigator key — dipakai untuk navigasi dari luar context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ── Init plugin + minta permission + setup tap handler ──
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifPlugin.initialize(
      settings,
      // Dipanggil saat user tap notifikasi & app sudah terbuka / di background
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _bukaHalamanNotifikasi();
      },
    );

    // Cek apakah app dibuka dari notifikasi (app dalam keadaan terminated)
    final launchDetails =
        await _notifPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      // Delay sebentar agar Navigator sudah siap
      Future.delayed(const Duration(milliseconds: 500), _bukaHalamanNotifikasi);
    }

    // Minta permission notifikasi (Android 13+ / API 33+)
    if (Platform.isAndroid) {
      final androidPlugin = _notifPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  // ── Navigasi ke NotifikasiScreen ──
  static void _bukaHalamanNotifikasi() {
    navigatorKey.currentState?.pushNamed('/notifikasi');
  }

  // ── Mulai polling tiap 30 detik ──
  static void startPolling() {
    _timer?.cancel();
    _fetchAndNotify();
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => _fetchAndNotify());
  }

  static void stopPolling() => _timer?.cancel();

  // ── Fetch notifikasi dari server ──
  static Future<List<Map<String, dynamic>>> getNotifikasi() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/get_notifikasi.php'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        badgeCount.value = json['total_belum_dibaca'] ?? 0;
        return (json['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('[Notifikasi] error: $e');
    }
    return [];
  }

  // ── Tandai semua sudah dibaca ──
  static Future<void> tandaiSemuaDibaca() async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/tandai_dibaca.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_notif': 'all'}),
          )
          .timeout(const Duration(seconds: 10));
      badgeCount.value = 0;
    } catch (e) {
      print('[Notifikasi] tandai error: $e');
    }
  }

  // ── Tandai satu notifikasi dibaca ──
  static Future<void> tandaiSatuDibaca(String idNotif) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/tandai_dibaca.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_notif': idNotif}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('[Notifikasi] tandai satu error: $e');
    }
  }

  // ── Fetch + tampilkan notif baru di HP ──
  static Future<void> _fetchAndNotify() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/get_notifikasi.php'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final json     = jsonDecode(res.body);
      final List newData = json['data'] ?? [];
      badgeCount.value   = json['total_belum_dibaca'] ?? 0;

      final existingIds = _lastData.map((e) => e['id_notif']).toSet();
      for (final item in newData) {
        if (!existingIds.contains(item['id_notif']) &&
            item['dibaca'] == '0') {
          await _showLocalNotification(item);
        }
      }

      _lastData = newData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[Notifikasi] polling error: $e');
    }
  }

  // ── Tampilkan notif di status bar HP ──
  static Future<void> _showLocalNotification(
      Map<String, dynamic> item) async {
    final androidDetails = AndroidNotificationDetails(
      'infox_channel',
      'Infox Notifikasi',
      channelDescription: 'Notifikasi konten baru dari admin',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        item['isi'] ?? '',
        contentTitle: item['judul'] ?? '',
      ),
    );

    await _notifPlugin.show(
      item['id_notif'].hashCode,
      item['judul'],
      item['isi'] ?? '',
      NotificationDetails(android: androidDetails),
    );
  }
}