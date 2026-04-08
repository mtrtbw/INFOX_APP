import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'materi_list.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final horizontalPadding =
        isLargeTablet ? 40.0 : (isTablet ? 28.0 : 20.0);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Background shapes (same as HomeScreen)
            const _BackgroundShapes(),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── APP BAR ──
                    _buildAppBar(context, isTablet),

                    SizedBox(height: isTablet ? 28 : 20),

                    // ── HEADER BANNER ──
                    _HeaderBanner(isTablet: isTablet),

                    SizedBox(height: isTablet ? 32 : 24),

                    // ── SECTION TITLE ──
                    _SectionTitle(
                        text: 'Pilih Jenis Materi', isTablet: isTablet),

                    SizedBox(height: isTablet ? 16 : 12),

                    // ── MATERI CARDS ──
                    _MateriCard(
                      emoji: '📄',
                      label: 'MODUL',
                      labelGradient: const [
                        Color(0xFF3D5AFE),
                        Color(0xFF7C4DFF)
                      ],
                      title: 'Materi Bacaan',
                      description:
                          'Kumpulan modul dan rangkuman dalam bentuk PDF yang lengkap dan mudah dipahami.',
                      buttonText: 'Mulai Membaca',
                      bgColor: const Color(0xFFEEF0FF),
                      accentColor: const Color(0xFF3D5AFE),
                      gradientColors: const [
                        Color(0xFF3D5AFE),
                        Color(0xFF7C4DFF)
                      ],
                      image: 'assets/buku.jpg',
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                      onTap: () => Navigator.push(
                        context,
                        _pageRoute(const MateriListScreen(type: 'FILE')),
                      ),
                    ),

                    SizedBox(height: isTablet ? 16 : 12),

                    _MateriCard(
                      emoji: '🎬',
                      label: 'VIDEO',
                      labelGradient: const [
                        Color(0xFFE53935),
                        Color(0xFFFF7043)
                      ],
                      title: 'Video Pembelajaran',
                      description:
                          'Tonton penjelasan materi secara visual dan interaktif agar lebih mudah dimengerti.',
                      buttonText: 'Tonton Video',
                      bgColor: const Color(0xFFFFEEEC),
                      accentColor: const Color(0xFFE53935),
                      gradientColors: const [
                        Color(0xFFE53935),
                        Color(0xFFFF7043)
                      ],
                      image: 'assets/video.jpg',
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                      onTap: () => Navigator.push(
                        context,
                        _pageRoute(const MateriListScreen(type: 'VIDEO')),
                      ),
                    ),

                    SizedBox(height: isTablet ? 36 : 28),

                    // ── TIPS SECTION ──
                    _SectionTitle(
                        text: 'Tips Belajar Efektif', isTablet: isTablet),

                    SizedBox(height: isTablet ? 16 : 12),

                    _TipsBelajarSection(
                        isTablet: isTablet, isLargeTablet: isLargeTablet),

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

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1A1A2E), size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Materi Belajar',
          style: TextStyle(
            fontSize: isTablet ? 22 : 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
            letterSpacing: 0.2,
          ),
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
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SHAPES (same as HomeScreen)
// ─────────────────────────────────────────────
class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _ShapesPainter()),
      ),
    );
  }
}

class _ShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shapes = [
      _ShapeData(
        color: const Color(0xFF5C6BC0).withOpacity(0.10),
        center: Offset(size.width * 0.90, size.height * 0.05),
        radius: size.width * 0.42,
      ),
      _ShapeData(
        color: const Color(0xFF43A047).withOpacity(0.07),
        center: Offset(size.width * 0.05, size.height * 0.45),
        radius: size.width * 0.35,
      ),
      _ShapeData(
        color: const Color(0xFFE53935).withOpacity(0.08),
        center: Offset(size.width * 0.70, size.height * 0.75),
        radius: size.width * 0.30,
      ),
    ];
    for (final s in shapes) {
      canvas.drawCircle(
        s.center,
        s.radius,
        Paint()
          ..color = s.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShapeData {
  final Color color;
  final Offset center;
  final double radius;
  const _ShapeData(
      {required this.color, required this.center, required this.radius});
}

// ─────────────────────────────────────────────
// SECTION TITLE (same style as HomeScreen)
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isTablet;
  const _SectionTitle({required this.text, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 22,
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
        Text(
          text,
          style: TextStyle(
            fontSize: isTablet ? 22 : 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HEADER BANNER
// ─────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  final bool isTablet;
  const _HeaderBanner({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 26 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D5AFE).withOpacity(0.38),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dot pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          ),
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '📖 Pilih & Pelajari',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12.5 : 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 10),
                    Text(
                      'Halo! Mau belajar\napa hari ini? 🤔',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 26 : 22,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                      'Pilih jenis materi di bawah ini\nuntuk mulai belajar Informatika.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: isTablet ? 14 : 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🚀',
                style: TextStyle(fontSize: isTablet ? 64 : 54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// MATERI CARD (matches MenuCard style)
// ─────────────────────────────────────────────
class _MateriCard extends StatefulWidget {
  final String emoji;
  final String label;
  final List<Color> labelGradient;
  final String title;
  final String description;
  final String buttonText;
  final Color bgColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final String image;
  final bool isTablet;
  final bool isLargeTablet;
  final VoidCallback onTap;

  const _MateriCard({
    required this.emoji,
    required this.label,
    required this.labelGradient,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.bgColor,
    required this.accentColor,
    required this.gradientColors,
    required this.image,
    required this.isTablet,
    required this.isLargeTablet,
    required this.onTap,
  });

  @override
  State<_MateriCard> createState() => _MateriCardState();
}

class _MateriCardState extends State<_MateriCard>
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
    final cardPadding =
        widget.isLargeTablet ? 24.0 : (widget.isTablet ? 22.0 : 18.0);

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
              BoxShadow(
                color: widget.accentColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Top color band
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: widget.gradientColors),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                      cardPadding, cardPadding + 4, cardPadding, cardPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left content
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: widget.labelGradient),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.emoji,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.label,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: widget.isTablet ? 12 : 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: widget.isTablet ? 14 : 12),

                            // Title
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: widget.isLargeTablet
                                    ? 22
                                    : (widget.isTablet ? 20 : 18),
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E),
                                height: 1.2,
                              ),
                            ),

                            SizedBox(height: widget.isTablet ? 8 : 6),

                            // Description
                            Text(
                              widget.description,
                              style: TextStyle(
                                fontSize: widget.isTablet ? 14 : 13,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),

                            SizedBox(height: widget.isTablet ? 18 : 14),

                            // Button
                            GestureDetector(
                              onTap: widget.onTap,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: widget.isTablet ? 18 : 16,
                                  vertical: widget.isTablet ? 12 : 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: widget.gradientColors),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accentColor
                                          .withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.buttonText,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize:
                                            widget.isTablet ? 14 : 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: widget.isTablet ? 20 : 14),

                      // Right image
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: widget.isLargeTablet
                              ? 150
                              : (widget.isTablet ? 140 : 130),
                          decoration: BoxDecoration(
                            color: widget.bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              widget.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  widget.emoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
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
// TIPS BELAJAR SECTION
// ─────────────────────────────────────────────
class _TipsBelajarSection extends StatelessWidget {
  final bool isTablet;
  final bool isLargeTablet;
  const _TipsBelajarSection(
      {required this.isTablet, required this.isLargeTablet});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isTablet ? 14 : 10,
      mainAxisSpacing: isTablet ? 14 : 10,
      childAspectRatio:
          isLargeTablet ? 1.1 : (isTablet ? 1.0 : 0.78),
      children: [
        _TipsCard(
          emoji: '💡',
          title: 'Fokus',
          subtitle: 'Cari tempat yang tenang.',
          bgColor: const Color(0xFFFFF8E1),
          gradientColors: const [Color(0xFFFFA726), Color(0xFFFFCC02)],
          isTablet: isTablet,
        ),
        _TipsCard(
          emoji: '⏰',
          title: 'Waktu',
          subtitle: 'Atur jadwal belajar rutin.',
          bgColor: const Color(0xFFEDFBF3),
          gradientColors: const [Color(0xFF2E7D52), Color(0xFF43A047)],
          isTablet: isTablet,
        ),
        _TipsCard(
          emoji: '📝',
          title: 'Catat',
          subtitle: 'Buat rangkuman penting.',
          bgColor: const Color(0xFFF9EEFF),
          gradientColors: const [Color(0xFF8E24AA), Color(0xFFAB47BC)],
          isTablet: isTablet,
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final List<Color> gradientColors;
  final bool isTablet;

  const _TipsCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.gradientColors,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top color band
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isTablet ? 8 : 6),
              Container(
                width: isTablet ? 52 : 46,
                height: isTablet ? 52 : 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: isTablet ? 24 : 20),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 10 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 4 : 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 11,
                  color: Colors.grey.shade500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

