import 'dart:convert';
import 'package:http/http.dart' as http;

class NilaiService {
  static const String baseUrl =
      'http://10.5.50.231/infox-backend/api';

  static Future<void> simpanNilai({
    required String nis,
    required String nama,
    required String kelas,
    required String noAbsen,
    required String idMateri,
    required int skor,
    String jenisSoal = 'QUIZ',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/simpan_nilai.php');

      final payload = {
        "nis": nis,
        "nama_siswa": nama,
        "kelas": kelas,
        "no_absen": noAbsen,
        "id_materi": idMateri,
        "skor": skor,
        "jenis_soal": jenisSoal,
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