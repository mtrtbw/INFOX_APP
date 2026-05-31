// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/materi.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<List<Materi>> fetchMateri() async {
    final response = await http.get(Uri.parse('$baseUrl/materi.php'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List list = jsonData['data'];
      return list.map((e) => Materi.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil data materi');
    }
  }
}