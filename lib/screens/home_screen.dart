import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // Wajib ada untuk buka browser
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'tentang/tentang_screen.dart';
import 'info/info_screen.dart';
import 'materi/materi_screen.dart';
import 'soal/soal_menu_screen.dart';
import 'notifikasi/notifikasi_screen.dart';
import '../services/notifikasi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnim;
  late Animation<double> _fadeAnim;

  // ── VARIABEL DINAMIS UNTUK DATA SISWA ──
  String _nis = '';
  String _namaSiswa = 'Sobat Informatika';

  static const _gradientBlue = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];
  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _dark = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();

    _loadUserData();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _floatAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // ── Mulai polling notifikasi ──
    NotifikasiService.startPolling();
  }

  // ── FUNGSI AMBIL DATA LOGIN ──
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nis = prefs.getString('nis') ?? '';
      _namaSiswa = prefs.getString('nama_siswa') ?? 'Sobat Informatika';
    });
  }

  // ── FUNGSI LOGOUT UNTUK RESET MEMORI HP ──
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _nis = '';
      _namaSiswa = 'Sobat Informatika';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi dihapus! Silakan klik Materi untuk login ulang.')),
      );
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    NotifikasiService.stopPolling();
    super.dispose();
  }

  // ── HELPER DEKORASI INPUT (SAMA SEPERTI DI QUIZ FORM) ──
  InputDecoration _inputDeco(String label, String hint, IconData icon, bool isTablet, {Widget? suffix}) {
    return InputDecoration(
      labelText: label, 
      hintText: hint, 
      suffixIcon: suffix,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: _gradientBlue)
        ),
        child: Icon(icon, color: Colors.white, size: 18)
      ),
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true, fillColor: const Color(0xFFF8F9FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── MODAL FORM LOGIN MENGGUNAKAN API login_siswa.php ──
  Future<void> _showLoginSiswaModal(BuildContext context) async {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w > 600;

    final TextEditingController nisCtrl = TextEditingController();
    final TextEditingController passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    bool isLoading = false;
    bool showPassword = false;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text('Login Siswa', style: TextStyle(
                          fontSize: isTablet ? 22 : 19, fontWeight: FontWeight.w800, color: _dark)),
                      const SizedBox(height: 4),
                      Text('Masukkan NIS dan password untuk mulai berdiskusi',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 20),

                      // Input NIS
                      TextFormField(
                        controller: nisCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'NIS wajib diisi' : null,
                        style: TextStyle(fontSize: isTablet ? 14 : 13, fontWeight: FontWeight.w600, color: _dark),
                        decoration: _inputDeco('NIS', 'Masukkan NIS kamu', Icons.badge_rounded, isTablet),
                      ),
                      const SizedBox(height: 14),

                      // Input Password
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: !showPassword,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Password wajib diisi' : null,
                        style: TextStyle(fontSize: isTablet ? 14 : 13, fontWeight: FontWeight.w600, color: _dark),
                        decoration: _inputDeco(
                          'Password', '4 digit terakhir NISN', Icons.lock_rounded, isTablet,
                          suffix: GestureDetector(
                            onTap: () => setModalState(() => showPassword = !showPassword),
                            child: Icon(
                              showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.grey.shade400, size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Error Box
                      if (errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(errorMsg!, style: const TextStyle(
                                fontSize: 12, color: Color(0xFFE53935), fontWeight: FontWeight.w600))),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Info Password Default
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF1565C0), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'Password default: 4 digit terakhir NISN kamu.\nContoh NISN 0127542195 → password: 2195',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF1565C0), height: 1.5),
                          )),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // Tombol Login
                      GestureDetector(
                        onTap: isLoading ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() { isLoading = true; errorMsg = null; });

                          try {
                            final res = await http.post(
                              Uri.parse('${AppConfig.baseUrl}/login_siswa.php'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'nis': nisCtrl.text.trim(),
                                'password': passwordCtrl.text.trim(),
                              }),
                            ).timeout(const Duration(seconds: 10));

                            final json = jsonDecode(res.body);

                            if (json['status'] == 'success') {
                              final data = json['data'];
                              
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('nis', data['nis']);
                              await prefs.setString('nama_siswa', data['nama']);

                              setState(() {
                                _nis = data['nis'];
                                _namaSiswa = data['nama'];
                              });

                              if (context.mounted) {
                                Navigator.pop(context); // Tutup modal login
                                Navigator.push(context, _pageRoute(
                                  MateriScreen(nis: _nis, namaSiswa: _namaSiswa)
                                ));
                              }
                            } else {
                              setModalState(() => errorMsg = json['message'] ?? 'Login gagal');
                            }
                          } catch (e) {
                            setModalState(() => errorMsg = 'Tidak dapat terhubung ke server');
                          } finally {
                            if (mounted) setModalState(() => isLoading = false);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: isTablet ? 56 : 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(colors: _gradientGreen),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFF43A047).withOpacity(0.40),
                                blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Center(child: isLoading
                              ? const SizedBox(width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                    Text('Masuk & Lanjutkan',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isTablet ? 16 : 15)),
                                  ])),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final horizontalPadding = isLargeTablet ? 40.0 : (isTablet ? 28.0 : 20.0);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            const _BackgroundShapes(),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(isTablet),
                    SizedBox(height: isTablet ? 28 : 20),
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -_floatAnim.value),
                        child: child,
                      ),
                      child: _HeroBanner(isTablet: isTablet, namaSiswa: _namaSiswa),
                    ),
                    SizedBox(height: isTablet ? 24 : 18),
                    _StartButton(isTablet: isTablet),
                    SizedBox(height: isTablet ? 36 : 28),
                    _SectionTitle(text: 'Menu Utama', isTablet: isTablet),
                    SizedBox(height: isTablet ? 16 : 12),
                    GridView.count(
                      crossAxisCount: isLargeTablet ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      childAspectRatio: isLargeTablet ? 1.05 : (isTablet ? 1.0 : 0.90),
                      children: [
                        _MenuCard(
                          emoji: '📚',
                          title: 'Materi',
                          subtitle: 'Modul & Bacaan',
                          bgColor: const Color(0xFFEEF0FF),
                          accentColor: const Color(0xFF5C6BC0),
                          gradientColors: const [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                          onTap: () {
                            // ── LOGIKA LOGIN DINAMIS ──
                            if (_nis.isEmpty) {
                              _showLoginSiswaModal(context);
                            } else {
                              Navigator.push(context, _pageRoute(
                                MateriScreen(nis: _nis, namaSiswa: _namaSiswa)
                              ));
                            }
                          },
                        ),
                        _MenuCard(
                          emoji: '🧩',
                          title: 'Soal',
                          subtitle: 'Uji Pemahaman',
                          bgColor: const Color(0xFFEDFBF3),
                          accentColor: const Color(0xFF2E7D52),
                          gradientColors: const [Color(0xFF2E7D52), Color(0xFF43A047)],
                          onTap: () => Navigator.push(context, _pageRoute(const SoalMenuScreen())),
                        ),
                        _MenuCard(
                          emoji: '💡',
                          title: 'Info',
                          subtitle: 'Petunjuk Aplikasi',
                          bgColor: const Color(0xFFF9EEFF),
                          accentColor: const Color(0xFF8E24AA),
                          gradientColors: const [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                          onTap: () => Navigator.push(context, _pageRoute(const InfoScreen())),
                        ),
                        _MenuCard(
                          emoji: '👥',
                          title: 'Tentang',
                          subtitle: 'Profil Tim',
                          bgColor: const Color(0xFFFFF4E5),
                          accentColor: const Color(0xFFE65100),
                          gradientColors: const [Color(0xFFE65100), Color(0xFFFF7043)],
                          onTap: () => Navigator.push(context, _pageRoute(const TentangScreen())),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 32 : 24),
                    _KuesionerButton(isTablet: isTablet), 
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Image.asset(
          'assets/logo.png',
          height: isTablet ? 32 : 28,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Row(
            children: const [
              Text('⚡', style: TextStyle(fontSize: 22)),
              SizedBox(width: 6),
              Text('Informatika', style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.3,
              )),
            ],
          ),
        ),

        Row(
          children: [
            // ── TOMBOL LOGOUT (MUNCUL JIKA SUDAH LOGIN) ──
            if (_nis.isNotEmpty)
              GestureDetector(
                onTap: _logout,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFFFEBEE),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 20),
                ),
              ),

            // ── NOTIFIKASI BADGE ──
            ValueListenableBuilder<int>(
              valueListenable: NotifikasiService.badgeCount,
              builder: (context, count, _) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    _pageRoute(const NotifikasiScreen()),
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )],
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Color(0xFF5C6BC0),
                        size: 22,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ]),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  PageRoute _pageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SHAPES
// ─────────────────────────────────────────────
class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _ShapesPainter())),
    );
  }
}

class _ShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shapes = [
      _ShapeData(color: const Color(0xFF5C6BC0).withOpacity(0.10),
          center: Offset(size.width * 0.90, size.height * 0.05), radius: size.width * 0.42),
      _ShapeData(color: const Color(0xFF43A047).withOpacity(0.08),
          center: Offset(size.width * 0.05, size.height * 0.40), radius: size.width * 0.35),
      _ShapeData(color: const Color(0xFFFF7043).withOpacity(0.09),
          center: Offset(size.width * 0.75, size.height * 0.72), radius: size.width * 0.32),
    ];
    for (final s in shapes) {
      canvas.drawCircle(s.center, s.radius,
          Paint()..color = s.color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShapeData {
  final Color color;
  final Offset center;
  final double radius;
  const _ShapeData({required this.color, required this.center, required this.radius});
}

// ─────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isTablet;
  const _SectionTitle({required this.text, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 5, height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF5C6BC0), Color(0xFFAB47BC)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(text, style: TextStyle(
        fontSize: isTablet ? 22 : 19,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A2E),
        letterSpacing: 0.2,
      )),
    ]);
  }
}

// ─────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final bool isTablet;
  final String namaSiswa;
  const _HeroBanner({required this.isTablet, required this.namaSiswa});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTablet ? 240 : 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFF3D5AFE).withOpacity(0.40),
          blurRadius: 28, offset: const Offset(0, 10),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
          Positioned(right: -40, top: -40,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10)))),
          Positioned(right: 20, bottom: -50,
            child: Container(width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07)))),
          Positioned(right: 0, bottom: 0, top: 0, width: isTablet ? 190 : 155,
            child: Image.asset('assets/banner.jpg', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('🎓', style: TextStyle(fontSize: 80))))),
          Positioned(right: 0, bottom: 0, top: 0, width: isTablet ? 210 : 170,
            child: Container(decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFF5E35B1), Colors.transparent],
              begin: Alignment.centerLeft, end: Alignment.centerRight)))),
          Padding(
            padding: EdgeInsets.all(isTablet ? 26 : 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('✨ Belajar Jadi Seru!', style: TextStyle(
                  color: Colors.white, fontSize: isTablet ? 12.5 : 11.5,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3))),
              SizedBox(height: isTablet ? 12 : 10),
              Text('Halo,\n$namaSiswa! 👋', style: TextStyle(
                color: Colors.white, fontSize: isTablet ? 30 : 25,
                fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.2)),
              SizedBox(height: isTablet ? 10 : 8),
              Text('Siap belajar hal baru hari ini?', style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: isTablet ? 15 : 13.5)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius = 2.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// START BUTTON
// ─────────────────────────────────────────────
class _StartButton extends StatefulWidget {
  final bool isTablet;
  const _StartButton({required this.isTablet});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: () {},
      child: ScaleTransition(scale: _ctrl),
    );
  }
}

// ─────────────────────────────────────────────
// MENU CARD
// ─────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.bgColor, required this.accentColor,
    required this.gradientColors, this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.95, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: widget.accentColor.withOpacity(0.12),
                  blurRadius: 18, offset: const Offset(0, 6)),
              BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(children: [
              Positioned(top: 0, left: 0, right: 0, height: 6,
                child: Container(decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.gradientColors)))),
              Positioned(right: -18, top: -10,
                child: Container(width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.bgColor))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(width: 54, height: 54,
                    decoration: BoxDecoration(color: widget.bgColor,
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 26)))),
                  const Spacer(),
                  Text(widget.title, style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 3),
                  Text(widget.subtitle, style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(width: 28, height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: LinearGradient(colors: widget.gradientColors)),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 15)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// KUESIONER BUTTON
// ─────────────────────────────────────────────
class _KuesionerButton extends StatelessWidget {
  final bool isTablet;
  const _KuesionerButton({required this.isTablet});

  Future<void> _openKuesionerModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📝', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bantu Kami Berkembang!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Pendapat kamu sangat berharga. Yuk, luangkan waktu sebentar untuk mengisi kuesioner aplikasi ini.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final Uri url = Uri.parse('https://forms.gle/GZpfkVbTkaX763du6');
                  
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat membuka link kuesioner')),
                      );
                    }
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5AFE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Isi Kuesioner Sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Nanti Saja',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 58 : 52,
      child: OutlinedButton(
        onPressed: () => _openKuesionerModal(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3D5AFE),
          side: const BorderSide(color: Color(0xFFE8EAF6), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.assignment_turned_in_rounded, size: 20, color: Color(0xFF3D5AFE)),
          SizedBox(width: isTablet ? 10 : 8),
          Text('Kuesioner Aplikasi', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: isTablet ? 15 : 14,
              color: const Color(0xFF3D5AFE), letterSpacing: 0.2)),
        ]),
      ),
    );
  }
}