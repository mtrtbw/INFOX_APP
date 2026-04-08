import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'soal_harian_screen.dart';

class SoalHarianPertemuanScreen extends StatefulWidget {
  final String idMateri;
  final String nis;
  final String nama;
  final String kelas;
  final String noAbsen;

  const SoalHarianPertemuanScreen({
    super.key,
    required this.idMateri,
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.noAbsen,
  });

  @override
  State<SoalHarianPertemuanScreen> createState() =>
      _SoalHarianPertemuanScreenState();
}

class _SoalHarianPertemuanScreenState extends State<SoalHarianPertemuanScreen>
    with SingleTickerProviderStateMixin {
  static const _baseUrl = 'https://domain-kamu.com'; // <-- ganti sesuai server
  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _bgColor = Color(0xFFF0F4FF);
  static const _dark = Color(0xFF1A1A2E);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  List<Map<String, dynamic>> _pertemuanList = [];
  bool _isLoading = true;
  String? _error;

  // Warna kartu berganti-ganti
  final _cardColors = const [
    [Color(0xFF1565C0), Color(0xFF1E88E5)], // biru
    [Color(0xFF2E7D52), Color(0xFF43A047)], // hijau
    [Color(0xFF6A1B9A), Color(0xFF8E24AA)], // ungu
    [Color(0xFF00695C), Color(0xFF00897B)], // teal
    [Color(0xFF558B2F), Color(0xFF7CB342)], // hijau muda
    [Color(0xFF283593), Color(0xFF3949AB)], // indigo
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
      final res = await http.get(Uri.parse(
          '$_baseUrl/api/get_pertemuan.php?id_materi=${widget.idMateri}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _pertemuanList = List<Map<String, dynamic>>.from(data['pertemuan'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Gagal memuat data pertemuan'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; _isLoading = false; });
    }
  }

  void _pilihPertemuan(Map<String, dynamic> pertemuan) {
    final jumlahSoal = int.tryParse('${pertemuan['jumlah_soal']}') ?? 0;
    if (jumlahSoal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pertemuan ini belum memiliki soal'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => SoalHarianScreen(
          idMateri:    widget.idMateri,
          idPertemuan: pertemuan['id_pertemuan'],
          nis:         widget.nis,
          nama:        widget.nama,
          kelas:       widget.kelas,
          noAbsen:     widget.noAbsen,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad = isTablet ? 28.0 : 20.0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(children: [
        Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── APP BAR ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Row(children: [
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _dark, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pilih Pertemuan',
                          style: TextStyle(
                              fontSize: isTablet ? 22 : 19,
                              fontWeight: FontWeight.w800,
                              color: _dark)),
                      Text('Halo, ${widget.nama} 👋',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── INFO SISWA ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(colors: _gradientGreen),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${widget.kelas}  •  No. Absen ${widget.noAbsen}  •  NIS ${widget.nis}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── LABEL ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Text('Pilih pertemuan yang ingin dikerjakan',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                ),

                const SizedBox(height: 12),

                // ── KONTEN ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF43A047)))
                      : _error != null
                          ? _buildError()
                          : _pertemuanList.isEmpty
                              ? _buildEmpty()
                              : RefreshIndicator(
                                  onRefresh: _fetchPertemuan,
                                  color: const Color(0xFF43A047),
                                  child: ListView.separated(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: pad, vertical: 4),
                                    itemCount: _pertemuanList.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (ctx, i) =>
                                        _buildPertemuanCard(
                                            _pertemuanList[i], i),
                                  ),
                                ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPertemuanCard(Map<String, dynamic> p, int index) {
    final colors = _cardColors[index % _cardColors.length];
    final jumlahSoal = int.tryParse('${p['jumlah_soal']}') ?? 0;
    final adaSoal = jumlahSoal > 0;

    return GestureDetector(
      onTap: () => _pilihPertemuan(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(children: [
            // ── Strip kiri ──
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: adaSoal ? colors : [Colors.grey.shade300, Colors.grey.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
            ),

            // ── Nomor pertemuan ──
            Container(
              width: 64, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: adaSoal
                        ? [colors[0].withOpacity(0.12), colors[1].withOpacity(0.06)]
                        : [Colors.grey.shade100, Colors.grey.shade50]),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${p['urutan']}',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: adaSoal ? colors[0] : Colors.grey.shade400,
                        height: 1)),
                Text('Prt',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: adaSoal ? colors[0].withOpacity(0.6) : Colors.grey.shade400)),
              ]),
            ),

            // ── Info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['judul'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if ((p['deskripsi'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(p['deskripsi'],
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3),
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.quiz_rounded, size: 12,
                            color: adaSoal ? colors[0] : Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          adaSoal ? '$jumlahSoal soal' : 'Belum ada soal',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: adaSoal ? colors[0] : Colors.grey.shade400),
                        ),
                      ]),
                    ),
                  ]),
                ]),
              ),
            ),

            // ── Arrow ──
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: adaSoal
                      ? colors[0].withOpacity(0.10)
                      : Colors.grey.shade100,
                ),
                child: Icon(
                  adaSoal
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  size: 15,
                  color: adaSoal ? colors[0] : Colors.grey.shade400,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchPertemuan,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Belum ada pertemuan',
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Silakan hubungi guru kamu',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
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