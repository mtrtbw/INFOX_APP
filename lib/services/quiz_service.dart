// lib/services/quiz_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class QuizService {
  static String get baseUrl => AppConfig.baseUrl;

  /// Konversi path gambar relatif ke URL absolut (safety net di Flutter)
  static String _resolveGambar(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http') || raw.startsWith('data:')) return raw;
    // Path relatif: "uploads/soal/xxx.jpg" → prepend uploadsUrl base
    // AppConfig.uploadsUrl = "http://IP/infox-backend/uploads"
    // Kita butuh "http://IP/infox-backend/" + "uploads/soal/xxx.jpg"
    final base = AppConfig.uploadsUrl.replaceAll(RegExp(r'/uploads$'), '');
    if (raw.contains('uploads/')) {
      final idx = raw.indexOf('uploads/');
      return '$base/${raw.substring(idx)}';
    }
    return '$base/$raw';
  }

  /// Decode field pertanyaan/opsi dari DB: bisa JSON atau string biasa
  static Map<String, String> _decode(dynamic raw) {
    if (raw == null) return {'teks': '', 'gambar': ''};
    final s = raw.toString();
    try {
      final d = jsonDecode(s);
      if (d is Map && d.containsKey('teks')) {
        return {
          'teks'   : d['teks']?.toString()   ?? '',
          'gambar' : _resolveGambar(d['gambar']?.toString() ?? ''),
        };
      }
    } catch (_) {}
    return {'teks': s, 'gambar': ''};
  }

  /// Ambil soal berdasarkan tipe (QUIZ atau HARIAN)
  static Future<List<Map<String, dynamic>>> getQuiz(
    String idMateri, {
    String tipe        = 'QUIZ',
    String idPertemuan = '',
  }) async {
    try {
      final params = <String, String>{'tipe': tipe};
      if (idPertemuan.isNotEmpty) params['id_pertemuan'] = idPertemuan;

      final uri = Uri.parse('$baseUrl/get_quiz.php')
          .replace(queryParameters: params);

      print('[QuizService] GET $uri');

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      print('[QuizService] Status: ${response.statusCode}');
      print('[QuizService] Body: ${response.body}');

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body);
      if (json['status'] != 'success') return [];

      final List data = json['data'] ?? [];

      // Normalisasi gambar di setiap soal dan opsi (safety net)
      return data.map<Map<String, dynamic>>((item) {
        final soal = Map<String, dynamic>.from(item);

        // Decode & fix pertanyaan
        final pertanyaanDecoded = _decode(soal['pertanyaan']);
        soal['pertanyaan'] = jsonEncode(pertanyaanDecoded);

        // Decode & fix tiap opsi jawaban
        final opsiRaw = soal['opsi'];
        if (opsiRaw is Map) {
          final opsiFixed = <String, dynamic>{};
          opsiRaw.forEach((key, value) {
            final opsiDecoded = _decode(value);
            opsiFixed[key.toString()] = jsonEncode(opsiDecoded);
          });
          soal['opsi'] = opsiFixed;
        }

        return soal;
      }).toList();

    } catch (e) {
      print('[QuizService] Exception: $e');
      return [];
    }
  }
}