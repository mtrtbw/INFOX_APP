import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/materi_service.dart';
import 'materi_detail.dart';
import 'video_detail_screen.dart';

class MateriListScreen extends StatefulWidget {
  final String type; // FILE atau VIDEO

  const MateriListScreen({
    super.key,
    required this.type,
  });

  @override
  State<MateriListScreen> createState() => _MateriListScreenState();
}

class _MateriListScreenState extends State<MateriListScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String selectedBab = ''; // '' = Semua
  List allData = [];
  bool isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  bool get isPdf => widget.type == 'FILE';

  // Colors per type
  List<Color> get _gradientColors => isPdf
      ? const [Color(0xFF3D5AFE), Color(0xFF7C4DFF)]
      : const [Color(0xFFE53935), Color(0xFFFF7043)];

  Color get _accentColor =>
      isPdf ? const Color(0xFF3D5AFE) : const Color(0xFFE53935);

  Color get _bgColor =>
      isPdf ? const Color(0xFFEEF0FF) : const Color(0xFFFFEEEC);

  String get _emoji => isPdf ? '📄' : '🎬';
  String get _emptyEmoji => isPdf ? '📭' : '📺';

  @override
  void initState() {
    super.initState();
    _loadData();

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

  Future<void> _loadData() async {
    try {
      final data = await MateriService.getMateri(widget.type);
      setState(() {
        allData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Ambil daftar bab unik dari data, urut secara natural
  List<String> get babList {
    final set = <String>{};
    for (final item in allData) {
      final bab = (item['bab'] ?? '').toString().trim();
      if (bab.isNotEmpty) set.add(bab);
    }
    final list = set.toList()..sort();
    return list;
  }

  List get filteredData {
    return allData.where((item) {
      final judul = (item['judul'] ?? '').toString().toLowerCase();
      final deskripsi = (item['deskripsi'] ?? '').toString().toLowerCase();
      final bab = (item['bab'] ?? '').toString();

      // Filter bab
      final babMatch = selectedBab.isEmpty || bab == selectedBab;

      // Filter search
      final query = searchQuery.toLowerCase();
      final searchMatch = query.isEmpty ||
          judul.contains(query) ||
          deskripsi.contains(query) ||
          bab.toLowerCase().contains(query);

      return babMatch && searchMatch;
    }).toList();
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
            // Background blobs
            const _BackgroundShapes(),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── APP BAR ──
                        _buildAppBar(context, isTablet),

                        SizedBox(height: isTablet ? 24 : 18),

                        // ── HEADER BANNER ──
                        _HeaderBanner(
                          isPdf: isPdf,
                          gradientColors: _gradientColors,
                          isTablet: isTablet,
                        ),

                        SizedBox(height: isTablet ? 22 : 16),

                        // ── SEARCH BAR ──
                        _SearchBar(
                          hintText: isPdf
                              ? 'Cari modul PDF...'
                              : 'Cari video pembelajaran...',
                          accentColor: _accentColor,
                          query: searchQuery,
                          onChanged: (v) =>
                              setState(() => searchQuery = v),
                          onClear: () =>
                              setState(() => searchQuery = ''),
                          isTablet: isTablet,
                        ),

                        SizedBox(height: isTablet ? 14 : 10),

                        // ── FILTER BAB ──
                        if (!isLoading && babList.isNotEmpty)
                          _BabFilterChips(
                            babList: babList,
                            selectedBab: selectedBab,
                            accentColor: _accentColor,
                            gradientColors: _gradientColors,
                            bgColor: _bgColor,
                            onSelected: (bab) =>
                                setState(() => selectedBab = bab),
                            isTablet: isTablet,
                          ),

                        SizedBox(height: isTablet ? 12 : 10),

                        // ── RESULT COUNT / SECTION TITLE ──
                        if (searchQuery.isNotEmpty || selectedBab.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Ditemukan ${filteredData.length} hasil'
                              '${selectedBab.isNotEmpty ? ' di $selectedBab' : ''}',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          _SectionTitle(
                            text: isPdf ? 'Semua Modul PDF' : 'Semua Video',
                            isTablet: isTablet,
                          ),

                        SizedBox(height: isTablet ? 12 : 10),
                      ],
                    ),
                  ),

                  // ── LIST ──
                  Expanded(
                    child: isLoading
                        ? _buildLoading()
                        : filteredData.isEmpty
                            ? _buildEmpty(isTablet)
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  0,
                                  horizontalPadding,
                                  32,
                                ),
                                itemCount: filteredData.length,
                                itemBuilder: (context, index) {
                                  final item = filteredData[index];
                                  return isPdf
                                      ? _PdfListItem(
                                          item: item,
                                          gradientColors: _gradientColors,
                                          accentColor: _accentColor,
                                          bgColor: _bgColor,
                                          isTablet: isTablet,
                                          onTap: () => Navigator.push(
                                            context,
                                            _pageRoute(MateriDetailScreen(
                                              data: item,
                                              type: 'FILE',
                                            )),
                                          ),
                                        )
                                      : _VideoListItem(
                                          item: item,
                                          gradientColors: _gradientColors,
                                          accentColor: _accentColor,
                                          bgColor: _bgColor,
                                          isTablet: isTablet,
                                          onTap: () => Navigator.push(
                                            context,
                                            _pageRoute(VideoDetailScreen(
                                                data: item)),
                                          ),
                                        );
                                },
                              ),
                  ),
                ],
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
          isPdf ? 'Materi Bacaan' : 'Video Pembelajaran',
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

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: _accentColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildEmpty(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_emptyEmoji,
              style: TextStyle(fontSize: isTablet ? 72 : 60)),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            searchQuery.isEmpty
                ? (isPdf
                    ? 'Belum ada materi PDF'
                    : 'Belum ada video pembelajaran')
                : 'Tidak ada hasil untuk\n"$searchQuery"',
            style: TextStyle(
              color: const Color(0xFF1A1A2E).withOpacity(0.5),
              fontSize: isTablet ? 17 : 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
// BAB FILTER CHIPS
// ─────────────────────────────────────────────
class _BabFilterChips extends StatelessWidget {
  final List<String> babList;
  final String selectedBab;
  final Color accentColor;
  final List<Color> gradientColors;
  final Color bgColor;
  final ValueChanged<String> onSelected;
  final bool isTablet;

  const _BabFilterChips({
    required this.babList,
    required this.selectedBab,
    required this.accentColor,
    required this.gradientColors,
    required this.bgColor,
    required this.onSelected,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isTablet ? 38 : 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Chip "Semua"
          _chip('Semua', selectedBab.isEmpty),
          ...babList.map((bab) => _chip(bab, selectedBab == bab)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => onSelected(isActive && label != 'Semua' ? '' : (label == 'Semua' ? '' : label)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 12,
            vertical: isTablet ? 8 : 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? LinearGradient(colors: gradientColors)
              : null,
          color: isActive ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? accentColor.withOpacity(0.30)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isActive ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontSize: isTablet ? 13 : 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
      _SD(const Color(0xFF5C6BC0).withOpacity(0.10),
          Offset(size.width * 0.90, size.height * 0.05), size.width * 0.42),
      _SD(const Color(0xFF43A047).withOpacity(0.07),
          Offset(size.width * 0.05, size.height * 0.45), size.width * 0.35),
      _SD(const Color(0xFFE53935).withOpacity(0.08),
          Offset(size.width * 0.70, size.height * 0.80), size.width * 0.30),
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

class _SD {
  final Color color;
  final Offset center;
  final double radius;
  const _SD(this.color, this.center, this.radius);
}

// ─────────────────────────────────────────────
// HEADER BANNER
// ─────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  final bool isPdf;
  final List<Color> gradientColors;
  final bool isTablet;

  const _HeaderBanner({
    required this.isPdf,
    required this.gradientColors,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 22 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.38),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dot pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _DotPainter()),
            ),
          ),
          // Decorative circles
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.09),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -35,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
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
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPdf ? '📄 Modul PDF' : '🎬 Video Belajar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12.5 : 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 10 : 8),
                    Text(
                      'Selamat Belajar! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 22 : 19,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      isPdf
                          ? 'Temukan modul PDF untuk\nmenunjang belajarmu.'
                          : 'Tonton video supaya materi\nlebih mudah dipahami.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: isTablet ? 13 : 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isPdf ? '📚' : '🎥',
                style: TextStyle(fontSize: isTablet ? 52 : 44),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String hintText;
  final Color accentColor;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isTablet;

  const _SearchBar({
    required this.hintText,
    required this.accentColor,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTablet ? 54 : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          fontSize: isTablet ? 15 : 14,
          color: const Color(0xFF1A1A2E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: accentColor, size: isTablet ? 22 : 20),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isTablet ? 16 : 14,
          ),
        ),
      ),
    );
  }
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
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
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
            fontSize: isTablet ? 18 : 16,
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
// PDF LIST ITEM
// ─────────────────────────────────────────────
class _PdfListItem extends StatefulWidget {
  final dynamic item;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color bgColor;
  final bool isTablet;
  final VoidCallback onTap;

  const _PdfListItem({
    required this.item,
    required this.gradientColors,
    required this.accentColor,
    required this.bgColor,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_PdfListItem> createState() => _PdfListItemState();
}

class _PdfListItemState extends State<_PdfListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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
    final item = widget.item;
    final bab = (item['bab'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.10),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Left accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    widget.isTablet ? 16 : 14,
                    16,
                    widget.isTablet ? 16 : 14,
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: widget.isTablet ? 52 : 46,
                        height: widget.isTablet ? 52 : 46,
                        decoration: BoxDecoration(
                          color: widget.bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('📄',
                              style: TextStyle(
                                  fontSize: widget.isTablet ? 24 : 20)),
                        ),
                      ),

                      SizedBox(width: widget.isTablet ? 16 : 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bab.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bab,
                                  style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: widget.isTablet ? 11 : 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            Text(
                              item['judul'] ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: widget.isTablet ? 15 : 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['deskripsi'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: widget.isTablet ? 13 : 12,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Arrow
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: widget.gradientColors),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 15),
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
// VIDEO LIST ITEM
// ─────────────────────────────────────────────
class _VideoListItem extends StatefulWidget {
  final dynamic item;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color bgColor;
  final bool isTablet;
  final VoidCallback onTap;

  const _VideoListItem({
    required this.item,
    required this.gradientColors,
    required this.accentColor,
    required this.bgColor,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<_VideoListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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
    final item = widget.item;
    final bab = (item['bab'] ?? '').toString();

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.10),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Left accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    widget.isTablet ? 16 : 14,
                    16,
                    widget.isTablet ? 16 : 14,
                  ),
                  child: Row(
                    children: [
                      // Play icon container
                      Container(
                        width: widget.isTablet ? 52 : 46,
                        height: widget.isTablet ? 52 : 46,
                        decoration: BoxDecoration(
                          color: widget.bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('🎬',
                              style: TextStyle(
                                  fontSize: widget.isTablet ? 24 : 20)),
                        ),
                      ),

                      SizedBox(width: widget.isTablet ? 16 : 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bab.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bab,
                                  style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: widget.isTablet ? 11 : 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            Text(
                              item['judul'] ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: widget.isTablet ? 15 : 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['deskripsi'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: widget.isTablet ? 13 : 12,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Play button arrow
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: widget.gradientColors),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 17),
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