import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

// ── Model Pesan Diskusi ──────────────────────────────
class DiskusiMessage {
  final int id;
  final String nis;
  final String namaSiswa;
  final String kelas;
  final String pesan;
  final int? replyTo;
  final String? replyPesan;
  final String? replySender;
  int totalLikes;
  bool isLikedByMe;
  final DateTime createdAt;

  DiskusiMessage({
    required this.id,
    required this.nis,
    required this.namaSiswa,
    required this.kelas,
    required this.pesan,
    this.replyTo,
    this.replyPesan,
    this.replySender,
    required this.totalLikes,
    required this.isLikedByMe,
    required this.createdAt,
  });

  factory DiskusiMessage.fromJson(Map<String, dynamic> j) {
    return DiskusiMessage(
      id:           j['id'],
      nis:          j['nis'],
      namaSiswa:    j['nama_siswa'],
      kelas:        j['kelas'],
      pesan:        j['pesan'],
      replyTo:      j['reply_to'],
      replyPesan:   j['reply_pesan'],
      replySender:  j['reply_sender'],
      totalLikes:   j['total_likes'] ?? 0,
      isLikedByMe:  j['is_liked_by_me'] ?? false,
      createdAt:    DateTime.parse(j['created_at']),
    );
  }

  String get initial {
    final parts = namaSiswa.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  int get avatarColorValue {
    const colors = [
      0xFF3D5AFE, 0xFFE91E8C, 0xFF43A047,
      0xFFFF6D00, 0xFF00ACC1, 0xFF8E24AA,
      0xFF6D4C41, 0xFF0288D1,
    ];
    final hash = nis.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}

// ── Service Class ────────────────────────────────────
class DiskusiService {
  // Samakan gaya dengan materi_service.dart
  static String get baseUrl => AppConfig.baseUrl;

  final String _nis; 

  DiskusiService(this._nis);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_nis', // NIS dikirim lewat header
  };

  // ── GET: Ambil daftar pesan ──────────────────────
  Future<List<DiskusiMessage>> getMessages({String? idMateri, int page = 1}) async {
    // Bangun URL secara manual seperti di materi_service
    String url = '$baseUrl/diskusi.php?action=list&page=$page';
    if (idMateri != null) {
      url += '&id_materi=$idMateri';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'ok') {
        return (json['messages'] as List)
            .map((m) => DiskusiMessage.fromJson(m))
            .toList();
      } else {
        throw Exception(json['message']);
      }
    } else {
      // Fitur Detektif: Mencetak error asli ke Terminal VS Code
      print('=== ERROR GET DISKUSI ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('=========================');
      throw Exception('Gagal mengambil data diskusi');
    }
  }

  // ── POST: Kirim pesan baru ───────────────────────
  Future<DiskusiMessage> sendMessage({required String pesan, String? idMateri, int? replyTo}) async {
    final url = '$baseUrl/diskusi.php?action=send';
    
    final bodyData = jsonEncode({
      'pesan': pesan,
      'id_materi': ?idMateri,
      'reply_to': ?replyTo,
    });

    final response = await http.post(Uri.parse(url), headers: _headers, body: bodyData);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'ok') {
        return DiskusiMessage.fromJson(json['message']);
      } else {
        throw Exception(json['message']);
      }
    } else {
      print('=== ERROR SEND DISKUSI ===');
      print('Body: ${response.body}');
      throw Exception('Gagal mengirim pesan');
    }
  }

  // ── POST: Toggle like ────────────────────────────
  Future<Map<String, dynamic>> toggleLike(int idDiskusi) async {
    final url = '$baseUrl/diskusi.php?action=like';
    final bodyData = jsonEncode({'id_diskusi': idDiskusi});

    final response = await http.post(Uri.parse(url), headers: _headers, body: bodyData);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'ok') {
        return {'liked': json['liked'], 'total_likes': json['total_likes']};
      } else {
        throw Exception(json['message']);
      }
    } else {
      throw Exception('Gagal menyukai pesan');
    }
  }

  // ── DELETE: Hapus pesan milik sendiri ───────────
  Future<void> deleteMessage(int id) async {
    final url = '$baseUrl/diskusi.php?action=delete&id=$id';
    
    final response = await http.delete(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] != 'ok') {
        throw Exception(json['message']);
      }
    } else {
      throw Exception('Gagal menghapus pesan');
    }
  }

  static String formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60)  return 'Baru saja';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24)    return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)      return '${diff.inDays} hari lalu';
    return '${time.day}/${time.month}/${time.year}';
  }
}