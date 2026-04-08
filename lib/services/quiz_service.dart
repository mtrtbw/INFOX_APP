import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizService {
  static const String baseUrl = 'http://10.5.50.231/infox-backend/api';

  /// Ambil soal berdasarkan tipe (QUIZ atau HARIAN)
  static Future<List<Map<String, dynamic>>> getQuiz(
    String idMateri, {
    String tipe = 'QUIZ',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/get_quiz.php')
          .replace(queryParameters: {'tipe': tipe});

      print('[QuizService] GET $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      print('[QuizService] Status: ${response.statusCode}');
      print('[QuizService] Body: ${response.body}');

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body);
      if (json['status'] != 'success') return [];

      final List data = json['data'] ?? [];
      return data.cast<Map<String, dynamic>>();

    } catch (e) {
      print('[QuizService] Exception: $e');
      return [];
    }
  }
}