// lib/screens/soal_harian_pertemuan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
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

class _SoalHarianPertemuanScreenState
    extends State<SoalHarianPertemuanScreen>
    with SingleTickerProviderStateMixin {
  static String get _baseUrl => AppConfig.baseUrl;

  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _bgColor       = Color(0xFFF0F4FF);
  static const _dark          = Color(0xFF1A1A2E);

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  List<Map<String, dynamic>> _pertemuanList = [];
  bool    _isLoading = true;
  String? _error;

  final _cardColors = const [
    [Color(0xFF1565C0), Color(0xFF1E88E5)],
    [Color(0xFF2E7D52), Color(0xFF43A047)],
    [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    [Color(0xFF00695C), Color(0xFF00897B)],
    [Color(0xFF558B2F), Color(0xFF7CB342)],
    [Color(0xFF283593), Color(0xFF3949AB)],
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _fetchPertemuan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Helper 1: Untuk Label di Badge Merah (Ringkas) ──
  String _formatBadgeWaktu(String? waktuRaw) {
    if (waktuRaw == null || waktuRaw.isEmpty) return 'Terkunci';
    try {
      final dt = DateTime.parse(waktuRaw);
      final d   = dt.day.toString().padLeft(2, '0');
      final m   = dt.month.toString().padLeft(2, '0');
      final h   = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return 'Buka $d/$m $h:$min';
    } catch (e) {
      return 'Terkunci';
    }
  }

  // ── Helper 2: Untuk Pesan SnackBar (Lengkap) ──
  String _formatPesanWaktu(String? waktuRaw) {
    if (waktuRaw == null || waktuRaw.isEmpty) return 'waktu yang ditentukan';
    try {
      final dt  = DateTime.parse(waktuRaw);
      final d   = dt.day.toString().padLeft(2, '0');
      final m   = dt.month.toString().padLeft(2, '0');
      final y   = dt.year.toString();
      final h   = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return 'tanggal $d/$m/$y pukul $h:$min WIB';
    } catch (e) {
      return 'waktu yang ditentukan';
    }
  }

  Future<void> _fetchPertemuan() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final url = '$_baseUrl/get_pertemuan.php';
      print('[Pertemuan Harian] GET $url');
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      print('[Pertemuan Harian] ${res.statusCode} — ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'ok' || data['status'] == 'success') {
          setState(() {
            _pertemuanList = List<Map<String, dynamic>>.from(
                data['pertemuan'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error     = data['message'] ?? 'Gagal memuat data pertemuan';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error     = 'Gagal memuat data pertemuan (${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[Pertemuan Harian] Error: $e');
      setState(() {
        _error     = 'Tidak dapat terhubung ke server';
        _isLoading = false;
      });
    }
  }

  Future<void> _pilihPertemuan(Map<String, dynamic> pertemuan) async {
    // ── STEP 1: Cek apakah pertemuan dikunci ──
    final bool isLocked     = pertemuan['is_locked'] == true;
    final String statusAkses = pertemuan['status_akses'] ?? 'TERBUKA';

    if (isLocked) {
      String pesanPenolakan = 'Soal harian ini sedang dikunci oleh guru.';
      if (statusAkses == 'TERJADWAL') {
        final jamBukaLengkap = _formatPesanWaktu(pertemuan['waktu_buka']);
        pesanPenolakan =
            'Soal harian ini baru bisa diakses pada $jamBukaLengkap.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesanPenolakan),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // ── STEP 2: Cek apakah ada soal ──
    final jumlahSoal = int.tryParse('${pertemuan['jumlah_soal']}') ?? 0;
    if (jumlahSoal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Pertemuan ini belum memiliki soal'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final idPertemuan = pertemuan['id_pertemuan']?.toString() ?? '';
    print('[Pertemuan Harian] Dipilih: $idPertemuan — ${pertemuan['judul']}');

    // ── STEP 3: Tampilkan loading, cek status sudah mengerjakan ──
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF43A047)),
      ),
    );

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/cek_status_mengerjakan.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nis':          widget.nis,
          'id_pertemuan': idPertemuan,
          'jenis_soal':   'HARIAN',
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      final data = jsonDecode(res.body);

      if (data['status'] == 'sudah') {
        _tampilPemberitahuanSudah(data['nilai'].toString());
        return;
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal mengecek status. Periksa koneksi internet.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // ── STEP 4: Lanjut ke soal harian ──
    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => SoalHarianScreen(
            idMateri:    widget.idMateri,
            idPertemuan: idPertemuan,
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

  void _tampilPemberitahuanSudah(String nilai) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Sudah Mengerjakan',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF1A1A2E))),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, height: 1.5, color: Colors.black87),
            children: [
              const TextSpan(
                  text: 'Anda sudah mengerjakan Soal Harian ini dengan nilai '),
              TextSpan(
                  text: nilai,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF43A047))),
              const TextSpan(text: '.\n\nNilai Anda sudah masuk dan '),
              const TextSpan(
                  text: 'belum dihapus oleh Admin',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              const TextSpan(
                  text:
                      '. Anda tidak diizinkan untuk mengulang latihan ini.'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Saya Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad      = isTablet ? 28.0 : 20.0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(children: [
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(painter: _BlobPainter()))),
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
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _dark, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pilih Pertemuan',
                                style: TextStyle(
                                    fontSize: isTablet ? 22 : 19,
                                    fontWeight: FontWeight.w800,
                                    color: _dark)),
                            Text('Halo, ${widget.nama} 👋',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500)),
                          ]),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── INFO SISWA ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                                colors: _gradientGreen),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _dark),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                    '${widget.kelas}  •  No. Absen ${widget.noAbsen}  •  NIS ${widget.nis}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500)),
                              ]),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Text(
                        'Pilih pertemuan yang ingin dikerjakan',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                  ),

                  const SizedBox(height: 12),

                  // ── LIST PERTEMUAN ──
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
                                      ))),

                  const SizedBox(height: 16),
                ]))),
      ]),
    );
  }

  Widget _buildPertemuanCard(Map<String, dynamic> p, int index) {
    final colors      = _cardColors[index % _cardColors.length];
    final jumlahSoal  = int.tryParse('${p['jumlah_soal']}') ?? 0;
    final adaSoal     = jumlahSoal > 0;

    // ── Status akses (sama persis dengan quiz) ──
    final isLocked    = p['is_locked'] == true;
    final statusAkses = p['status_akses'] ?? 'TERBUKA';
    final canAccess   = adaSoal && !isLocked;

    return GestureDetector(
      onTap: () => _pilihPertemuan(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(children: [
            // Garis warna kiri
            Container(
              width: 6, height: 80,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canAccess
                        ? [colors[0], colors[1]]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )),
            ),

            // Nomor urutan
            Container(
              width: 64, height: 80,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: canAccess
                          ? [
                              colors[0].withOpacity(0.12),
                              colors[1].withOpacity(0.06),
                            ]
                          : [
                              Colors.grey.shade100,
                              Colors.grey.shade50,
                            ])),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${p['urutan']}',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: canAccess
                                ? colors[0]
                                : Colors.grey.shade400,
                            height: 1)),
                    Text('Prt',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: canAccess
                                ? colors[0].withOpacity(0.6)
                                : Colors.grey.shade400)),
                  ]),
            ),

            // Konten teks
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['judul'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _dark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if ((p['deskripsi'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(p['deskripsi'],
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                height: 1.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),

                      // ── Badge jumlah soal + status lock ──
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: canAccess
                                ? colors[0].withOpacity(0.10)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.quiz_rounded,
                                    size: 12,
                                    color: canAccess
                                        ? colors[0]
                                        : Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                    adaSoal
                                        ? '$jumlahSoal soal'
                                        : 'Belum ada soal',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: canAccess
                                            ? colors[0]
                                            : Colors.grey.shade400)),
                              ]),
                        ),

                        const SizedBox(width: 6),

                        // Badge status: terkunci / terjadwal / (kosong kalau terbuka)
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded,
                                      size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                      statusAkses == 'TERJADWAL'
                                          ? _formatBadgeWaktu(
                                              p['waktu_buka'])
                                          : 'Terkunci',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red)),
                                ]),
                          ),
                      ]),
                    ]),
              ),
            ),

            // Ikon panah / gembok
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: canAccess
                      ? colors[0].withOpacity(0.10)
                      : Colors.grey.shade100,
                ),
                child: Icon(
                  canAccess
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  size: 15,
                  color: canAccess ? colors[0] : Colors.grey.shade400,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchPertemuan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ]),
        ),
      );

  Widget _buildEmpty() =>
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_rounded,
            size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Belum ada pertemuan',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Silakan hubungi guru kamu',
            style:
                TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]));
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
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}