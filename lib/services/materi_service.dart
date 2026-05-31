// lib/services/materi_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MateriService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<List<dynamic>> getMateri(String tipe) async {
    final response = await http.get(
      Uri.parse('$baseUrl/materi.php?tipe=$tipe'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception('Gagal mengambil data');
    }
  }
}