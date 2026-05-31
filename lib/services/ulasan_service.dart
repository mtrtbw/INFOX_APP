// lib/services/ulasan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UlasanService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<bool> simpanUlasan({
    required String nis,
    required String namaSiswa,
    required String jenisSoal,
    required int rating,
    required String komentar,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/simpan_ulasan.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nis'       : nis,
          'nama_siswa': namaSiswa,
          'jenis_soal': jenisSoal,
          'rating'    : rating,
          'komentar'  : komentar,
        }),
      );

      print('[UlasanService] Response: ${res.body}');

      final json = jsonDecode(res.body);
      return json['status'] == 'success';
    } catch (e) {
      print('[UlasanService] error: $e');
      return false;
    }
  }
}