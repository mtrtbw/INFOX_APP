import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'quiz_cepat_screen.dart';

class QuizPertemuanScreen extends StatefulWidget {
  final String idMateri;
  final String nis;
  final String nama;
  final String kelas;
  final String noAbsen;

  const QuizPertemuanScreen({
    super.key,
    required this.idMateri,
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.noAbsen,
  });

  @override
  State<QuizPertemuanScreen> createState() => _QuizPertemuanScreenState();
}

class _QuizPertemuanScreenState extends State<QuizPertemuanScreen>
    with SingleTickerProviderStateMixin {
  static const _baseUrl      = 'http://192.168.100.82/infox-backend/api';
  static const _gradientBlue = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];
  static const _bgColor      = Color(0xFFF0F4FF);
  static const _dark         = Color(0xFF1A1A2E);

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  List<Map<String, dynamic>> _pertemuanList = [];
  bool    _isLoading = true;
  String? _error;

  final _cardColors = const [
    [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
    [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    [Color(0xFF283593), Color(0xFF3949AB)],
    [Color(0xFF1565C0), Color(0xFF1E88E5)],
    [Color(0xFF4527A0), Color(0xFF5E35B1)],
    [Color(0xFF0277BD), Color(0xFF0288D1)],
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _fetchPertemuan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchPertemuan() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // ✅ FIX: tidak pakai ?id_materi — pertemuan bersifat global
      final url = '$_baseUrl/get_pertemuan_quiz.php';
      print('[Pertemuan Quiz] GET $url');
      final res = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      print('[Pertemuan Quiz] ${res.statusCode} — ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // ✅ FIX: key PHP mengembalikan 'ok', bukan 'success'
        if (data['status'] == 'ok' || data['status'] == 'success') {
          setState(() {
            _pertemuanList = List<Map<String, dynamic>>.from(
                data['pertemuan'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Gagal memuat data pertemuan';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Gagal memuat data pertemuan (${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[Pertemuan Quiz] Error: $e');
      setState(() { _error = 'Tidak dapat terhubung ke server'; _isLoading = false; });
    }
  }

  void _pilihPertemuan(Map<String, dynamic> pertemuan) {
    final jumlahSoal = int.tryParse('${pertemuan['jumlah_soal']}') ?? 0;
    if (jumlahSoal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Pertemuan ini belum memiliki soal'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final idPertemuan = pertemuan['id_pertemuan']?.toString() ?? '';
    print('[Pertemuan Quiz] Dipilih: $idPertemuan — ${pertemuan['judul']}');

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, anim, __) => QuizCepatScreen(
        idMateri:    widget.idMateri,
        idPertemuan: idPertemuan,   // ✅ diteruskan dengan benar
        nis:         widget.nis,
        nama:        widget.nama,
        kelas:       widget.kelas,
        noAbsen:     widget.noAbsen,
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
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: FadeTransition(opacity: _fadeAnim,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const SizedBox(height: 16),

            // ── APP BAR ──
            Padding(padding: EdgeInsets.symmetric(horizontal: pad),
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _dark, size: 18))),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pilih Pertemuan', style: TextStyle(
                      fontSize: isTablet ? 22 : 19,
                      fontWeight: FontWeight.w800, color: _dark)),
                  Text('Halo, ${widget.nama} 👋', style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
                ]),
              ])),

            const SizedBox(height: 20),

            // ── INFO SISWA ──
            Padding(padding: EdgeInsets.symmetric(horizontal: pad),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 4))]),
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: _gradientBlue)),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.nama, style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${widget.kelas}  •  No. Absen ${widget.noAbsen}  •  NIS ${widget.nis}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                  ])),
                ]),
              )),

            const SizedBox(height: 20),

            Padding(padding: EdgeInsets.symmetric(horizontal: pad),
              child: Text('Pilih pertemuan yang ingin dikerjakan',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500))),

            const SizedBox(height: 12),

            // ── LIST PERTEMUAN ──
            Expanded(child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D5AFE)))
                : _error != null
                    ? _buildError()
                    : _pertemuanList.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _fetchPertemuan,
                            color: const Color(0xFF3D5AFE),
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 4),
                              itemCount: _pertemuanList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) =>
                                  _buildPertemuanCard(_pertemuanList[i], i),
                            ))),

            const SizedBox(height: 16),
          ]))),
      ]),
    );
  }

  Widget _buildPertemuanCard(Map<String, dynamic> p, int index) {
    final colors     = _cardColors[index % _cardColors.length];
    final jumlahSoal = int.tryParse('${p['jumlah_soal']}') ?? 0;
    final adaSoal    = jumlahSoal > 0;

    return GestureDetector(
      onTap: () => _pilihPertemuan(p),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, 4))]),
        child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: Row(children: [

            // Strip warna kiri
            Container(width: 6, height: 80,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: adaSoal
                    ? [colors[0], colors[1]]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topCenter, end: Alignment.bottomCenter))),

            // Nomor urutan
            Container(width: 64, height: 80,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: adaSoal
                    ? [colors[0].withOpacity(0.12), colors[1].withOpacity(0.06)]
                    : [Colors.grey.shade100, Colors.grey.shade50])),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${p['urutan']}', style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: adaSoal ? colors[0] : Colors.grey.shade400, height: 1)),
                Text('Prt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: adaSoal ? colors[0].withOpacity(0.6) : Colors.grey.shade400)),
              ])),

            // Konten teks
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['judul'] ?? '', style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if ((p['deskripsi'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(p['deskripsi'], style: TextStyle(fontSize: 12,
                      color: Colors.grey.shade500, height: 1.3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: adaSoal
                          ? colors[0].withOpacity(0.10)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.quiz_rounded, size: 12,
                          color: adaSoal ? colors[0] : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(adaSoal ? '$jumlahSoal soal' : 'Belum ada soal',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: adaSoal ? colors[0] : Colors.grey.shade400)),
                    ])),
                  if (adaSoal) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.timer_rounded, size: 12, color: Color(0xFFFF9800)),
                        SizedBox(width: 4),
                        Text('30 detik/soal', style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: Color(0xFFFF9800))),
                      ])),
                  ],
                ]),
              ]))),

            // Arrow / lock
            Padding(padding: const EdgeInsets.only(right: 14),
              child: Container(width: 32, height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    color: adaSoal ? colors[0].withOpacity(0.10) : Colors.grey.shade100),
                child: Icon(
                  adaSoal
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  size: 15,
                  color: adaSoal ? colors[0] : Colors.grey.shade400))),
          ])),
      ),
    );
  }

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _fetchPertemuan,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba Lagi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D5AFE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
    ])));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.quiz_rounded, size: 56, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('Belum ada pertemuan', style: TextStyle(color: Colors.grey.shade500,
        fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    Text('Silakan hubungi guru kamu',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
  ]));
}

// ── Blob background painter ──
class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (const Color(0xFF5C6BC0), 0.90, 0.05, 0.42),
      (const Color(0xFF43A047), 0.05, 0.45, 0.35),
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