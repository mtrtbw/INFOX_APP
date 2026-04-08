import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'quiz_form_screen.dart';
import 'soal_harian_form_screen.dart';

class SoalMenuScreen extends StatefulWidget {
  const SoalMenuScreen({super.key});

  @override
  State<SoalMenuScreen> createState() => _SoalMenuScreenState();
}

class _SoalMenuScreenState extends State<SoalMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  int jumlahQuiz   = 0;
  int jumlahHarian = 0;
  bool isLoading   = true;

  static const baseUrl     = 'http://10.5.50.231/infox-backend/api';
  static const _gradientGreen  = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _gradientBlue   = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];
  static const _gradientOrange = [Color(0xFFE65100), Color(0xFFFF7043)];
  static const _bgColor        = Color(0xFFF0F4FF);
  static const _dark           = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fetchJumlahSoal();
  }

  Future<void> _fetchJumlahSoal() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/get_jumlah_soal.php'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          setState(() {
            jumlahQuiz   = json['data']['quiz'];
            jumlahHarian = json['data']['harian'];
            isLoading    = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad      = isTablet ? 28.0 : 20.0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _BlobPainter())),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(context, isTablet),
                    SizedBox(height: isTablet ? 24 : 18),
                    _HeroBanner(isTablet: isTablet),
                    SizedBox(height: isTablet ? 24 : 18),
                    _sectionTitle('Mode Latihan', isTablet),
                    SizedBox(height: isTablet ? 14 : 12),

                    // ── CARD QUIZ ──
                    _ModeCard(
                      emoji: '⚡',
                      title: 'Ujian',
                      subtitle: 'Uji kecepatan & ketepatan menjawab',
                      description:
                          'Soal pilihan ganda dengan batas waktu. Cocok untuk pemanasan sebelum ujian.',
                      gradientColors: _gradientBlue,
                      bgColor: const Color(0xFFEEF0FF),
                      accentColor: const Color(0xFF3D5AFE),
                      badgeLabel: isLoading
                          ? '⏳ Memuat...'
                          : '$jumlahQuiz Soal · Timed',
                      buttonLabel: 'Mulai Ujian',
                      isTablet: isTablet,
                      onTap: jumlahQuiz > 0
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizFormScreen(
                                    idMateri: 'MAT694ab7dfa8906',
                                  ),
                                ),
                              )
                          : () => _showNoSoalDialog('Quiz'),
                    ),

                    SizedBox(height: isTablet ? 14 : 12),

                    // ── CARD HARIAN ──
                    _ModeCard(
                      emoji: '📅',
                      title: 'Soal Harian',
                      subtitle: 'Latihan rutin setiap hari',
                      description:
                          'Soal baru setiap hari. Konsisten berlatih adalah kunci nilai terbaik.',
                      gradientColors: _gradientGreen,
                      bgColor: const Color(0xFFEDFBF3),
                      accentColor: const Color(0xFF2E7D52),
                      badgeLabel: isLoading
                          ? '⏳ Memuat...'
                          : '$jumlahHarian Soal · Harian',
                      buttonLabel: 'Mulai Soal Harian',
                      isTablet: isTablet,
                      onTap: jumlahHarian > 0
    ? () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SoalHarianFormScreen(
            idMateri: 'MAT694ab7dfa8906',
          )))
    : () => _showNoSoalDialog('Soal Harian'),
                    ),

                    SizedBox(height: isTablet ? 24 : 20),
                    _StreakCard(isTablet: isTablet),
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

  void _showNoSoalDialog(String tipe) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Soal Belum Tersedia', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('$tipe belum memiliki soal. Hubungi admin untuk menambahkan soal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D5AFE))),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _dark, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Text('Latihan Soal',
            style: TextStyle(
                fontSize: isTablet ? 22 : 19,
                fontWeight: FontWeight.w800,
                color: _dark)),
      ],
    );
  }

  Widget _sectionTitle(String text, bool isTablet) {
    return Row(
      children: [
        Container(
          width: 5, height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFFAB47BC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w800,
                color: _dark)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final bool isTablet;
  const _HeroBanner({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 22 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D52), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFF2E7D52).withOpacity(0.40),
          blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _DotPainter()),
            ),
          ),
          Positioned(right: -28, top: -28,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.09)))),
          Positioned(right: 30, bottom: -35,
            child: Container(width: 70, height: 70,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07)))),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('🧩 Mode Latihan',
                          style: TextStyle(color: Colors.white,
                              fontSize: isTablet ? 12.5 : 11.5,
                              fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(height: isTablet ? 10 : 8),
                    Text('Asah Kemampuan\nSetiap Hari! 💪',
                        style: TextStyle(color: Colors.white,
                            fontSize: isTablet ? 22 : 19,
                            fontWeight: FontWeight.w900,
                            height: 1.25)),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text('Pilih mode latihan yang sesuai\ndengan kebutuhanmu.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: isTablet ? 13 : 12,
                            height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('🧩', style: TextStyle(fontSize: isTablet ? 52 : 44)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MODE CARD
// ─────────────────────────────────────────────
class _ModeCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradientColors;
  final Color bgColor;
  final Color accentColor;
  final String badgeLabel;
  final String buttonLabel;
  final bool isTablet;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradientColors,
    required this.bgColor,
    required this.accentColor,
    required this.badgeLabel,
    required this.buttonLabel,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: widget.accentColor.withOpacity(0.12),
                  blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: Colors.black.withOpacity(0.03),
                  blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.gradientColors),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(widget.isTablet ? 18 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: widget.isTablet ? 50 : 46,
                            height: widget.isTablet ? 50 : 46,
                            decoration: BoxDecoration(
                              color: widget.bgColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(widget.emoji,
                                style: TextStyle(fontSize: widget.isTablet ? 24 : 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.title,
                                    style: TextStyle(
                                        fontSize: widget.isTablet ? 17 : 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A1A2E))),
                                const SizedBox(height: 2),
                                Text(widget.subtitle,
                                    style: TextStyle(
                                        fontSize: widget.isTablet ? 13 : 12,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          // Badge jumlah soal
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(widget.badgeLabel,
                                style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      SizedBox(height: widget.isTablet ? 12 : 10),
                      Text(widget.description,
                          style: TextStyle(
                              fontSize: widget.isTablet ? 13 : 12,
                              color: Colors.grey.shade500,
                              height: 1.5)),
                      SizedBox(height: widget.isTablet ? 14 : 12),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Container(
                          width: double.infinity,
                          height: widget.isTablet ? 46 : 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(colors: widget.gradientColors),
                            boxShadow: [BoxShadow(
                                color: widget.accentColor.withOpacity(0.35),
                                blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.buttonLabel,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: widget.isTablet ? 14 : 13)),
                              const SizedBox(width: 8),
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.22),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STREAK CARD
// ─────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final bool isTablet;
  const _StreakCard({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFFE65100).withOpacity(0.30),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 48 : 44, height: isTablet ? 48 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.20),
            ),
            child: Center(
              child: Text('🔥', style: TextStyle(fontSize: isTablet ? 24 : 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Semangat Belajar!',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: isTablet ? 15 : 14)),
                const SizedBox(height: 3),
                Text('Kamu belum mengerjakan soal hari ini.\nYuk, mulai sekarang!',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: isTablet ? 13 : 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (const Color(0xFF5C6BC0), 0.90, 0.05, 0.42),
      (const Color(0xFF43A047), 0.05, 0.40, 0.35),
      (const Color(0xFFFF7043), 0.70, 0.80, 0.30),
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

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2.0, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}