import 'dart:convert';
import 'package:http/http.dart' as http;

class MateriService {
  static const String baseUrl =
      'http://192.168.100.82/infox-backend/api';

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