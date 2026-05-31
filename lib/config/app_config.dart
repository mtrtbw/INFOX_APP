// lib/config/app_config.dart
// ══════════════════════════════════════════════
// GANTI IP ADDRESS DI SINI SAJA — berlaku untuk semua file
// ══════════════════════════════════════════════

class AppConfig {
  // Ganti IP address di bawah ini sesuai server kamu
  //static const String _host = 'infox.my.id';
  static const String _host = '10.207.191.76';

  // Base URL API — dipakai di semua service & screen (DITAMBAH -fix)
  static const String baseUrl = 'http://$_host/infox-backend-fix/api';
  //static const String baseUrl = 'https://$_host/api';

  // Base URL uploads — dipakai untuk akses file/gambar (DITAMBAH -fix)
  static const String uploadsUrl = 'http://$_host/infox-backend-fix/uploads';
  //static const String uploadsUrl = 'https://$_host/uploads';
}