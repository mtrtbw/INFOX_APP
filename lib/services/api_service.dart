import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/materi.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.100.82/infox-backend/api';

  static Future<List<Materi>> fetchMateri() async {
    final response =
        await http.get(Uri.parse('$baseUrl/materi.php'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List list = jsonData['data'];
      return list.map((e) => Materi.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil data materi');
    }
  }
}