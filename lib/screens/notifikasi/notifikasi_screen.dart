import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/notifikasi_service.dart';
import '../materi/materi_detail.dart';
import '../materi/video_detail_screen.dart';
import '../soal/soal_menu_screen.dart';
import '../soal/soal_harian_form_screen.dart';
import '../soal/quiz_form_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  static const _bgColor = Color(0xFFF0F4FF);
  static const _dark    = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await NotifikasiService.getNotifikasi();
    if (!mounted) return;
    setState(() { _data = data; _isLoading = false; });
  }

  Future<void> _tandaiSemuaDibaca() async {
    await NotifikasiService.tandaiSemuaDibaca();
    setState(() {
      _data = _data.map((e) => {...e, 'dibaca': '1'}).toList();
    });
  }

  // ── Navigasi langsung ke konten berdasarkan tipe ──
  Future<void> _bukaKonten(Map<String, dynamic> item) async {
    // Tandai dibaca dulu
    if (item['dibaca'] == '0') {
      await NotifikasiService.tandaiSatuDibaca(item['id_notif']);
      setState(() => item['dibaca'] = '1');
      NotifikasiService.badgeCount.value =
          _data.where((e) => e['dibaca'] == '0').length;
    }

    if (!mounted) return;

    final tipe   = item['tipe'] ?? '';
    final detail = item['detail'] as Map? ?? {};

    switch (tipe) {
      case 'MATERI':
        if (detail.isNotEmpty) {
          Navigator.push(context, _pageRoute(
            MateriDetailScreen(
              data: detail,
              type: detail['tipe_materi'] ?? 'FILE',
            ),
          ));
        }
        break;

      case 'VIDEO':
        if (detail.isNotEmpty) {
          Navigator.push(context, _pageRoute(
            VideoDetailScreen(data: detail),
          ));
        }
        break;

      case 'SOAL_HARIAN':
        final idMateri = detail['id_materi'] ?? '';
        if (idMateri.isNotEmpty) {
          Navigator.push(context, _pageRoute(
            SoalHarianFormScreen(idMateri: idMateri),
          ));
        } else {
          // Kalau id_materi kosong, buka menu soal
          Navigator.push(context, _pageRoute(const SoalMenuScreen()));
        }
        break;

      case 'QUIZ':
        final idMateri = detail['id_materi'] ?? '';
        if (idMateri.isNotEmpty) {
          Navigator.push(context, _pageRoute(
            QuizFormScreen(idMateri: idMateri),
          ));
        } else {
          Navigator.push(context, _pageRoute(const SoalMenuScreen()));
        }
        break;
    }
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

  String _iconTipe(String tipe) {
    switch (tipe) {
      case 'MATERI':      return '📚';
      case 'VIDEO':       return '🎥';
      case 'SOAL_HARIAN': return '📅';
      case 'QUIZ':        return '⚡';
      default:            return '🔔';
    }
  }

  Color _colorTipe(String tipe) {
    switch (tipe) {
      case 'MATERI':      return const Color(0xFF3D5AFE);
      case 'VIDEO':       return const Color(0xFFE53935);
      case 'SOAL_HARIAN': return const Color(0xFF43A047);
      case 'QUIZ':        return const Color(0xFF7C4DFF);
      default:            return const Color(0xFF607D8B);
    }
  }

  String _labelTipe(String tipe) {
    switch (tipe) {
      case 'MATERI':      return 'Materi Baru';
      case 'VIDEO':       return 'Video Baru';
      case 'SOAL_HARIAN': return 'Soal Harian Baru';
      case 'QUIZ':        return 'Soal Ujian Baru';
      default:            return 'Notifikasi';
    }
  }

  String _aksiBadge(String tipe) {
    switch (tipe) {
      case 'MATERI':      return 'Baca Materi →';
      case 'VIDEO':       return 'Tonton Video →';
      case 'SOAL_HARIAN': return 'Kerjakan →';
      case 'QUIZ':        return 'Mulai Ujian →';
      default:            return 'Buka →';
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final dt   = DateTime.parse(tanggal);
      final now  = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
      if (diff.inDays < 7)     return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet    = MediaQuery.of(context).size.width > 600;
    final belumDibaca = _data.where((e) => e['dibaca'] == '0').length;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: Column(children: [

          // ── APP BAR ──
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28 : 20, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _dark, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Notifikasi', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
                if (belumDibaca > 0)
                  Text('$belumDibaca belum dibaca',
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF3D5AFE), fontWeight: FontWeight.w600)),
              ])),
              if (belumDibaca > 0)
                GestureDetector(
                  onTap: _tandaiSemuaDibaca,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)]),
                    ),
                    child: const Text('Baca semua',
                        style: TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),

          // ── CONTENT ──
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D5AFE)))
              : _data.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF3D5AFE),
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28 : 20),
                        itemCount: _data.length,
                        itemBuilder: (ctx, i) => _buildItem(_data[i], isTablet),
                      ),
                    )),
        ])),
      ]),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, bool isTablet) {
    final tipe      = item['tipe'] ?? '';
    final belumBaca = item['dibaca'] == '0';
    final color     = _colorTipe(tipe);
    final hasDetail = item['detail'] != null;

    return GestureDetector(
      onTap: () => _bukaKonten(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: belumBaca ? Colors.white : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: belumBaca ? color.withOpacity(0.3) : Colors.grey.shade200,
              width: belumBaca ? 1.5 : 1),
          boxShadow: belumBaca
              ? [BoxShadow(color: color.withOpacity(0.10),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon tipe
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withOpacity(0.12)),
              child: Center(child: Text(_iconTipe(tipe),
                  style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_labelTipe(tipe),
                      style: TextStyle(fontSize: 10, color: color,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(_formatTanggal(item['tanggal'] ?? ''),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ]),
              const SizedBox(height: 6),
              Text(item['judul'] ?? '',
                  style: TextStyle(fontSize: isTablet ? 14 : 13,
                      fontWeight: belumBaca ? FontWeight.w700 : FontWeight.w500,
                      color: belumBaca ? _dark : Colors.grey.shade600)),
              if ((item['isi'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item['isi'] ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ])),
            if (belumBaca) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            ],
          ]),

          // ── TOMBOL AKSI ── hanya tampil jika ada detail
          if (hasDetail) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                ),
                child: Text(_aksiBadge(tipe),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🔔', style: TextStyle(fontSize: 56)),
    const SizedBox(height: 16),
    const Text('Belum ada notifikasi', style: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
    const SizedBox(height: 8),
    Text('Notifikasi akan muncul saat admin\nmenambahkan konten baru.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
  ]));
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (const Color(0xFF3D5AFE), 0.90, 0.05, 0.42),
      (const Color(0xFF43A047), 0.05, 0.55, 0.35),
      (const Color(0xFFFF7043), 0.70, 0.85, 0.30),
    ]) {
      canvas.drawCircle(
        Offset(size.width * s.$2, size.height * s.$3),
        size.width * s.$4,
        Paint()
          ..color = s.$1.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}