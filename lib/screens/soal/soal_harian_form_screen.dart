// lib/screens/soal/soal_harian_form_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart'; // ✅ Ganti IP cukup di app_config.dart
import 'soal_harian_pertemuan_screen.dart';
import 'lupa_password_screen.dart';

class SoalHarianFormScreen extends StatefulWidget {
  final String idMateri;
  const SoalHarianFormScreen({super.key, required this.idMateri});

  @override
  State<SoalHarianFormScreen> createState() => _SoalHarianFormScreenState();
}

class _SoalHarianFormScreenState extends State<SoalHarianFormScreen>
    with SingleTickerProviderStateMixin {

  // ✅ Pakai AppConfig — tidak ada lagi hardcode IP di sini
  static String get _baseUrl => AppConfig.baseUrl;

  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _bgColor       = Color(0xFFF0F4FF);
  static const _dark          = Color(0xFF1A1A2E);

  final _formKey      = GlobalKey<FormState>();
  final _nisCtrl      = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading    = false;
  bool _showPassword = false;
  String? _errorMsg;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nisCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login_siswa.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nis'     : _nisCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(res.body);
      if (!mounted) return;

      if (json['status'] == 'success') {
        final data = json['data'];
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, anim, __) => SoalHarianPertemuanScreen(
            idMateri: widget.idMateri,
            nis:      data['nis'],
            nama:     data['nama'],
            kelas:    data['kelas'],
            noAbsen:  data['no_absen'],
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ));
      } else {
        setState(() => _errorMsg = json['message'] ?? 'Login gagal');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _bukaLupaPassword() {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, anim, __) => const LupaPasswordScreen(
        gradientColors: _gradientGreen,
        labelJenis: '📅 Soal Harian',
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad      = isTablet ? 28.0 : 20.0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(
            child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const SizedBox(height: 16),

                // ── APP BAR ──
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 12, offset: const Offset(0, 4))]),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _dark, size: 18)),
                  ),
                  const SizedBox(width: 14),
                  Text('Login Siswa', style: TextStyle(
                      fontSize: isTablet ? 22 : 19,
                      fontWeight: FontWeight.w800, color: _dark)),
                ]),

                const SizedBox(height: 24),

                // ── HERO BANNER ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: _gradientGreen,
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF43A047).withOpacity(0.35),
                        blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Stack(children: [
                    Positioned(right: -15, top: -15,
                      child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08)))),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('📅 Soal Harian',
                            style: TextStyle(color: Colors.white,
                                fontSize: isTablet ? 12 : 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 10),
                      Text('Masuk Dulu\nSebelum Mulai! 🔐',
                          style: TextStyle(color: Colors.white,
                              fontSize: isTablet ? 22 : 19,
                              fontWeight: FontWeight.w800, height: 1.3)),
                      const SizedBox(height: 6),
                      Text('Gunakan NIS dan password yang diberikan guru.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.80),
                              fontSize: isTablet ? 13 : 12)),
                    ]),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── FORM CARD ──
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Login Siswa', style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        fontWeight: FontWeight.w800, color: _dark)),
                    const SizedBox(height: 4),
                    Text('Masukkan NIS dan password kamu',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 20),

                    // NIS
                    TextFormField(
                      controller: _nisCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v!.isEmpty ? 'NIS wajib diisi' : null,
                      style: TextStyle(fontSize: isTablet ? 14 : 13,
                          fontWeight: FontWeight.w600, color: _dark),
                      decoration: _inputDeco('NIS', 'Masukkan NIS kamu',
                          Icons.badge_rounded, isTablet),
                    ),

                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v!.isEmpty ? 'Password wajib diisi' : null,
                      style: TextStyle(fontSize: isTablet ? 14 : 13,
                          fontWeight: FontWeight.w600, color: _dark),
                      decoration: _inputDeco(
                          'Password', '4 digit terakhir NISN',
                          Icons.lock_rounded, isTablet,
                          suffix: GestureDetector(
                            onTap: () => setState(
                                () => _showPassword = !_showPassword),
                            child: Icon(
                                _showPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.grey.shade400, size: 20),
                          )),
                    ),

                    // Error
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE53935)
                                  .withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFE53935), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMsg!,
                              style: const TextStyle(fontSize: 12,
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w600))),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _bukaLupaPassword,
                        child: const Text('Lupa password?',
                            style: TextStyle(fontSize: 13,
                                color: Color(0xFF2E7D52),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF2E7D52))),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── INFO ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF43A047).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2E7D52), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Password default: 4 digit terakhir NISN.\nContoh NISN 0127542195 → password: 2195',
                      style: TextStyle(fontSize: 12,
                          color: const Color(0xFF2E7D52), height: 1.5),
                    )),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── TOMBOL LOGIN ──
                GestureDetector(
                  onTap: _isLoading ? null : _login,
                  child: Container(
                    width: double.infinity,
                    height: isTablet ? 56 : 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: _gradientGreen),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF43A047).withOpacity(0.40),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(child: _isLoading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text('Masuk & Pilih Pertemuan',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: isTablet ? 16 : 15)),
                            ])),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        )),
      ]),
    );
  }

  InputDecoration _inputDeco(String label, String hint, IconData icon,
      bool isTablet, {Widget? suffix}) {
    return InputDecoration(
      labelText: label, hintText: hint, suffixIcon: suffix,
      prefixIcon: Container(margin: const EdgeInsets.all(10),
        width: 36, height: 36,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: _gradientGreen)),
        child: Icon(icon, color: Colors.white, size: 18)),
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500,
          fontWeight: FontWeight.w500),
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true, fillColor: const Color(0xFFF8F9FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF43A047), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (const Color(0xFF43A047), 0.90, 0.05, 0.42),
      (const Color(0xFF5C6BC0), 0.05, 0.55, 0.35),
      (const Color(0xFFFF7043), 0.70, 0.85, 0.30),
    ]) {
      canvas.drawCircle(
        Offset(size.width * s.$2, size.height * s.$3),
        size.width * s.$4,
        Paint()
          ..color = s.$1.withOpacity(0.09)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}