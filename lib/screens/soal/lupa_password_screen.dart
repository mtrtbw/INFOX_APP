import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ✅ Import AppConfig, sesuaikan path ini jika posisi foldernya berbeda
import '../../config/app_config.dart';

class LupaPasswordScreen extends StatefulWidget {
  // Warna tema — hijau untuk harian, biru untuk quiz
  final List<Color> gradientColors;
  final String labelJenis; // '📅 Soal Harian' atau '⚡ Quiz Ujian'

  const LupaPasswordScreen({
    super.key,
    this.gradientColors = const [Color(0xFF2E7D52), Color(0xFF43A047)],
    this.labelJenis     = '📅 Soal Harian',
  });

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen>
    with SingleTickerProviderStateMixin {

  // ✅ Pakai AppConfig sesuai dengan referensi file Anda yang lain
  static String get _baseUrl => AppConfig.baseUrl;

  static const _bgColor = Color(0xFFF0F4FF);
  static const _dark    = Color(0xFF1A1A2E);

  final _nisCtrl    = TextEditingController();
  final _namaCtrl   = TextEditingController();
  final _pw1Ctrl    = TextEditingController();
  final _pw2Ctrl    = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String? _selectedKelas;
  bool _isLoading   = false;
  bool _showPw1     = false;
  bool _showPw2     = false;
  bool _terverifikasi = false; // Step 1 sudah lewat?
  String? _errorMsg;
  String? _successMsg;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  final List<String> _kelasList =
      ['7A','7B','7C','7D','7E','7F','7G','7H','7I','7J'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nisCtrl.dispose();
    _namaCtrl.dispose();
    _pw1Ctrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  // ── STEP 1: Verifikasi identitas ──
  Future<void> _verifikasi() async {
    if (!_formKey1.currentState!.validate()) return;
    if (_selectedKelas == null) {
      setState(() => _errorMsg = 'Pilih kelas terlebih dahulu');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'verifikasi',
          'nis'   : _nisCtrl.text.trim(),
          'nama'  : _namaCtrl.text.trim(),
          'kelas' : _selectedKelas,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(res.body);
      if (!mounted) return;

      if (json['status'] == 'success') {
        setState(() { _terverifikasi = true; _errorMsg = null; });
        // Animasi ulang
        _fadeCtrl.reset();
        _fadeCtrl.forward();
      } else {
        setState(() => _errorMsg = json['message'] ?? 'Verifikasi gagal');
      }
    } catch (_) {
      setState(() => _errorMsg = 'Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── STEP 2: Ganti password ──
  Future<void> _gantiPassword() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_pw1Ctrl.text != _pw2Ctrl.text) {
      setState(() => _errorMsg = 'Password tidak cocok');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action'       : 'ganti_password',
          'nis'          : _nisCtrl.text.trim(),
          'nama'         : _namaCtrl.text.trim(),
          'kelas'        : _selectedKelas,
          'password_baru': _pw1Ctrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(res.body);
      if (!mounted) return;

      if (json['status'] == 'success') {
        setState(() { _successMsg = 'Password berhasil diubah! Silakan login kembali.'; _errorMsg = null; });
      } else {
        setState(() => _errorMsg = json['message'] ?? 'Gagal mengubah password');
      }
    } catch (_) {
      setState(() => _errorMsg = 'Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            child: CustomPaint(painter: _BlobPainter(widget.gradientColors[0])))),
        SafeArea(child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),

              // ── APP BAR ──
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _dark, size: 18))),
                const SizedBox(width: 14),
                Text('Lupa Password', style: TextStyle(
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
                  gradient: LinearGradient(colors: widget.gradientColors,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(
                      color: widget.gradientColors[0].withOpacity(0.35),
                      blurRadius: 24, offset: const Offset(0, 10))]),
                child: Stack(children: [
                  Positioned(right: -15, top: -15,
                    child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08)))),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(widget.labelJenis,
                          style: TextStyle(color: Colors.white,
                              fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 10),
                    Text(_terverifikasi
                        ? 'Buat Password\nBaru 🔑'
                        : 'Reset\nPassword 🔐',
                        style: TextStyle(color: Colors.white,
                            fontSize: isTablet ? 22 : 19,
                            fontWeight: FontWeight.w800, height: 1.3)),
                    const SizedBox(height: 6),
                    Text(_terverifikasi
                        ? 'Masukkan password baru kamu.'
                        : 'Verifikasi data dirimu untuk reset password.',
                        style: TextStyle(color: Colors.white.withOpacity(0.80),
                            fontSize: isTablet ? 13 : 12)),
                  ]),
                ])),

              const SizedBox(height: 24),

              // ── STEP INDICATOR ──
              Row(children: [
                _stepBadge(1, 'Verifikasi', !_terverifikasi && _successMsg == null, _terverifikasi || _successMsg != null),
                Expanded(child: Container(height: 2,
                    color: (_terverifikasi || _successMsg != null)
                        ? widget.gradientColors[0] : Colors.grey.shade200)),
                _stepBadge(2, 'Password Baru', _terverifikasi && _successMsg == null, _successMsg != null),
                Expanded(child: Container(height: 2,
                    color: _successMsg != null
                        ? widget.gradientColors[0] : Colors.grey.shade200)),
                _stepBadge(3, 'Selesai', false, _successMsg != null),
              ]),

              const SizedBox(height: 24),

              // ── SUKSES ──
              if (_successMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Column(children: [
                    const Text('🎉', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text('Password Berhasil Diubah!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: _dark)),
                    const SizedBox(height: 8),
                    Text(_successMsg!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13,
                            color: Colors.grey.shade500, height: 1.5)),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity, height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: widget.gradientColors),
                          boxShadow: [BoxShadow(
                              color: widget.gradientColors[0].withOpacity(0.40),
                              blurRadius: 12, offset: const Offset(0, 5))]),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.login_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Kembali & Login', style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800, fontSize: 15)),
                        ])),
                    ),
                  ])),
              ]

              // ── STEP 1: VERIFIKASI ──
              else if (!_terverifikasi) ...[
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Form(
                    key: _formKey1,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Verifikasi Data Diri',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: _dark)),
                      const SizedBox(height: 4),
                      Text('Isi data sesuai yang terdaftar di sistem',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 20),

                      // NIS
                      _buildField(controller: _nisCtrl,
                          label: 'NIS', hint: 'Masukkan NIS kamu',
                          icon: Icons.badge_rounded,
                          keyboardType: TextInputType.number,
                          isTablet: isTablet,
                          validator: (v) => v!.isEmpty ? 'NIS wajib diisi' : null),
                      const SizedBox(height: 14),

                      // Nama
                      _buildField(controller: _namaCtrl,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap sesuai data',
                          icon: Icons.person_rounded,
                          isTablet: isTablet,
                          validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null),
                      const SizedBox(height: 14),

                      // Kelas dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedKelas,
                        validator: (v) => v == null ? 'Kelas wajib dipilih' : null,
                        onChanged: (val) => setState(() => _selectedKelas = val),
                        style: TextStyle(fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.w600, color: _dark),
                        decoration: InputDecoration(
                          labelText: 'Kelas',
                          prefixIcon: Container(margin: const EdgeInsets.all(10),
                            width: 36, height: 36,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(colors: widget.gradientColors)),
                            child: const Icon(Icons.class_rounded, color: Colors.white, size: 18)),
                          labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                          filled: true, fillColor: const Color(0xFFF8F9FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: widget.gradientColors[0], width: 2)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        items: _kelasList.map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k, style: const TextStyle(
                              fontWeight: FontWeight.w600, color: _dark)),
                        )).toList()),
                    ])),
                ),

                // Error
                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  _errorWidget(_errorMsg!),
                ],

                const SizedBox(height: 20),

                // Tombol verifikasi
                GestureDetector(
                  onTap: _isLoading ? null : _verifikasi,
                  child: _tombolUtama('Verifikasi Data', isTablet)),
              ]

              // ── STEP 2: GANTI PASSWORD ──
              else ...[
                // Info siswa terverifikasi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.gradientColors[0].withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: widget.gradientColors)),
                      child: const Icon(Icons.verified_user_rounded,
                          color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_namaCtrl.text, style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                          overflow: TextOverflow.ellipsis),
                      Text('NIS ${_nisCtrl.text} · Kelas $_selectedKelas',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ])),
                    Icon(Icons.check_circle_rounded,
                        color: widget.gradientColors[0], size: 22),
                  ])),

                const SizedBox(height: 16),

                // Form password baru
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Form(
                    key: _formKey2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Password Baru',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: _dark)),
                      const SizedBox(height: 4),
                      Text('Minimal 4 karakter',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 20),

                      // Password baru
                      TextFormField(
                        controller: _pw1Ctrl,
                        obscureText: !_showPw1,
                        keyboardType: TextInputType.text, // diubah dari number kalau pass bebas
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib diisi';
                          if (v.length < 4) return 'Minimal 4 karakter';
                          return null;
                        },
                        style: TextStyle(fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.w600, color: _dark),
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          hintText: 'Masukkan password baru',
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPw1 = !_showPw1),
                            child: Icon(_showPw1
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                                color: Colors.grey.shade400, size: 20)),
                          prefixIcon: Container(margin: const EdgeInsets.all(10),
                            width: 36, height: 36,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(colors: widget.gradientColors)),
                            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18)),
                          labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          filled: true, fillColor: const Color(0xFFF8F9FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: widget.gradientColors[0], width: 2)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),

                      const SizedBox(height: 14),

                      // Konfirmasi password
                      TextFormField(
                        controller: _pw2Ctrl,
                        obscureText: !_showPw2,
                        keyboardType: TextInputType.text,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                          if (v != _pw1Ctrl.text) return 'Password tidak cocok';
                          return null;
                        },
                        style: TextStyle(fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.w600, color: _dark),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          hintText: 'Ulangi password baru',
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _showPw2 = !_showPw2),
                            child: Icon(_showPw2
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                                color: Colors.grey.shade400, size: 20)),
                          prefixIcon: Container(margin: const EdgeInsets.all(10),
                            width: 36, height: 36,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(colors: widget.gradientColors)),
                            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 18)),
                          labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          filled: true, fillColor: const Color(0xFFF8F9FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: widget.gradientColors[0], width: 2)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
                    ])),
                ),

                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  _errorWidget(_errorMsg!),
                ],

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _isLoading ? null : _gantiPassword,
                  child: _tombolUtama('Simpan Password Baru', isTablet)),
              ],

              const SizedBox(height: 32),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _stepBadge(int no, String label, bool active, bool done) {
    final color = done
        ? widget.gradientColors[0]
        : active ? widget.gradientColors[0] : Colors.grey.shade300;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: done || active ? color : Colors.grey.shade200,
          border: Border.all(color: color, width: done || active ? 0 : 1.5)),
        child: Center(child: done
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Text('$no', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13,
                color: active ? Colors.white : Colors.grey.shade400)))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: active || done ? color : Colors.grey.shade400)),
    ]);
  }

  Widget _errorWidget(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(
          fontSize: 12, color: Color(0xFFE53935), fontWeight: FontWeight.w600))),
    ]));

  Widget _tombolUtama(String label, bool isTablet) => Container(
    width: double.infinity,
    height: isTablet ? 56 : 52,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: _isLoading
          ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
          : LinearGradient(colors: widget.gradientColors),
      boxShadow: _isLoading ? [] : [BoxShadow(
          color: widget.gradientColors[0].withOpacity(0.40),
          blurRadius: 16, offset: const Offset(0, 6))]),
    child: Center(child: _isLoading
        ? const SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_terverifikasi ? Icons.save_rounded : Icons.verified_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: isTablet ? 16 : 15)),
          ])));

  Widget _buildField({
    required TextEditingController controller,
    required String label, required String hint, required IconData icon,
    required bool isTablet, required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: isTablet ? 14 : 13,
          fontWeight: FontWeight.w600, color: _dark),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Container(margin: const EdgeInsets.all(10),
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(colors: widget.gradientColors)),
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
            borderSide: BorderSide(color: widget.gradientColors[0], width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  const _BlobPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (color,                    0.90, 0.05, 0.42),
      (const Color(0xFF5C6BC0),  0.05, 0.55, 0.35),
      (const Color(0xFFFF7043),  0.70, 0.85, 0.30),
    ]) {
      canvas.drawCircle(Offset(size.width * s.$2, size.height * s.$3),
        size.width * s.$4,
        Paint()..color = s.$1.withOpacity(0.09)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));
    }
  }
  @override
  bool shouldRepaint(_) => false;
}