// lib/services/nilai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class NilaiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<void> simpanNilai({
    required String nis,
    required String nama,
    required String kelas,
    required String noAbsen,
    required String idMateri,
    required int skor,
    String jenisSoal   = 'QUIZ',
    String idPertemuan = '',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/simpan_nilai.php');

      final payload = {
        "nis"        : nis,
        "nama_siswa" : nama,
        "kelas"      : kelas,
        "no_absen"   : noAbsen,
        "id_materi"  : idMateri.isNotEmpty ? idMateri : 'UMUM',
        "skor"       : skor,
        "jenis_soal" : jenisSoal,
        if (idPertemuan.isNotEmpty) "id_pertemuan": idPertemuan,
      };

      print('[NilaiService] POST $url');
      print('[NilaiService] Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print('[NilaiService] Status: ${response.statusCode}');
      print('[NilaiService] Response: ${response.body}');
    } catch (e) {
      print('[NilaiService] ERROR: $e');
    }
  }
}