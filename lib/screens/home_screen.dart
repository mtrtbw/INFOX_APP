import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    NotifikasiService.stopPolling();
    super.dispose();
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
                      child: _HeroBanner(isTablet: isTablet),
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
                          onTap: () => Navigator.push(context, _pageRoute(const MateriScreen())),
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
                    _LogoutButton(isTablet: isTablet),
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
                // Badge merah
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
  const _HeroBanner({required this.isTablet});

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
            child: Container(decoration: BoxDecoration(gradient: LinearGradient(
              colors: [const Color(0xFF5E35B1), Colors.transparent],
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
              Text('Halo,\nSobat Informatika! 👋', style: TextStyle(
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
// LOGOUT BUTTON
// ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final bool isTablet;
  const _LogoutButton({required this.isTablet});

  Future<void> _confirmExit(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(children: [
          Text('🚪', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Keluar Aplikasi', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        ]),
        content: Text('Apakah kamu yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Batal', style: TextStyle(
                color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF7043)])),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Keluar', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 58 : 52,
      child: OutlinedButton(
        onPressed: () => _confirmExit(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade600,
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout_rounded, size: isTablet ? 20 : 18, color: Colors.grey.shade500),
          SizedBox(width: isTablet ? 10 : 8),
          Text('Keluar Aplikasi', style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: isTablet ? 15 : 14,
              color: Colors.grey.shade600, letterSpacing: 0.2)),
        ]),
      ),
    );
  }
}