import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/quiz_service.dart';
import '../../services/nilai_service.dart';
import '../../services/ulasan_service.dart';

// ── Helper: parse teks & gambar (support URL & base64) ──
Map<String, String> parseSoal(dynamic raw) {
  if (raw == null) return {'teks': '', 'gambar': ''};
  final s = raw.toString();
  try {
    final d = jsonDecode(s);
    if (d is Map && d.containsKey('teks')) {
      return {
        'teks'  : d['teks']?.toString()   ?? '',
        'gambar': d['gambar']?.toString() ?? '',
      };
    }
  } catch (_) {}
  return {'teks': s, 'gambar': ''};
}

// ── Widget gambar: support URL dan base64 data URL ──
Widget _buildGambar(String gambar, {double? height, Color loadingColor = Colors.white54}) {
  if (gambar.isEmpty) return const SizedBox.shrink();
  if (gambar.startsWith('data:')) {
    try {
      final base64Str = gambar.contains(',') ? gambar.split(',').last : gambar;
      final bytes = base64Decode(base64Str);
      return ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, height: height, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink()));
    } catch (_) { return const SizedBox.shrink(); }
  }
  return ClipRRect(borderRadius: BorderRadius.circular(12),
    child: Image.network(gambar, height: height, fit: BoxFit.contain,
      loadingBuilder: (ctx, child, prog) => prog == null ? child
          : SizedBox(height: height ?? 120,
              child: Center(child: CircularProgressIndicator(
                  color: loadingColor, strokeWidth: 2))),
      errorBuilder: (_, __, ___) => const SizedBox.shrink()));
}

class SoalHarianScreen extends StatefulWidget {
  final String idMateri;
  final String idPertemuan; // ← TAMBAHAN BARU
  final String nis;
  final String nama;
  final String kelas;
  final String noAbsen;

  const SoalHarianScreen({
    super.key,
    required this.idMateri,
    required this.idPertemuan, // ← TAMBAHAN BARU
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.noAbsen,
  });

  @override
  State<SoalHarianScreen> createState() => _SoalHarianScreenState();
}

class _SoalHarianScreenState extends State<SoalHarianScreen>
    with SingleTickerProviderStateMixin {

  List<Map<String, dynamic>> soalList = [];
  bool    isLoading       = true;
  int     currentQuestion = 0;
  int     score           = 0;
  String? selectedKey;
  bool    answered        = false;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _bgColor       = Color(0xFFF0F4FF);
  static const _dark          = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadSoal();
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  Future<void> _loadSoal() async {
    // ← Teruskan idPertemuan ke QuizService
    final data = await QuizService.getQuiz(
      widget.idMateri,
      tipe: 'HARIAN',
      idPertemuan: widget.idPertemuan,
    );
    if (!mounted) return;
    setState(() { soalList = data; isLoading = false; });
    if (soalList.isNotEmpty) _fadeController.forward();
  }

  void _answerQuestion(String key) {
    if (answered) return;
    setState(() {
      selectedKey = key;
      answered    = true;
      if (soalList[currentQuestion]['jawaban_benar'] == key) score++;
    });
  }

  void _nextQuestion() {
    if (currentQuestion < soalList.length - 1) {
      _fadeController.reset();
      setState(() { currentQuestion++; answered = false; selectedKey = null; });
      _fadeController.forward();
    } else {
      _finishSoal();
    }
  }

  Future<void> _finishSoal() async {
    final nilaiAkhir = soalList.isEmpty
        ? 0 : ((score / soalList.length) * 100).toInt();

    await NilaiService.simpanNilai(
      nis:          widget.nis,
      nama:         widget.nama,
      kelas:        widget.kelas,
      noAbsen:      widget.noAbsen,
      idMateri:     widget.idMateri,
      idPertemuan:  widget.idPertemuan, // ← TAMBAHAN BARU
      skor:         nilaiAkhir,
      jenisSoal:    'HARIAN',
    );

    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, anim, __) => _HasilHarianScreen(
        nama: widget.nama, nis: widget.nis,
        score: score, total: soalList.length, nilaiAkhir: nilaiAkhir),
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
        Positioned.fill(child: IgnorePointer(
            child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: isLoading
            ? _buildLoading()
            : soalList.isEmpty
                ? _buildEmpty(context)
                : _buildSoal(pad, isTablet)),
      ]),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: Color(0xFF43A047)),
      SizedBox(height: 16),
      Text('Memuat soal...', style: TextStyle(
          color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
    ]));

  Widget _buildEmpty(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('😔', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        const Text('Soal Harian Belum Tersedia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Admin belum menambahkan soal harian.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: _gradientGreen)),
            child: const Text('Kembali', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700))),
        ),
      ])));

  Widget _buildSoal(double pad, bool isTablet) {
    final soal     = soalList[currentQuestion];
    final opsi     = soal['opsi'] as Map<String, dynamic>;
    final benar    = soal['jawaban_benar'] as String;
    final isLast   = currentQuestion == soalList.length - 1;
    final soalData = parseSoal(soal['pertanyaan']);

    return FadeTransition(
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
                child: const Icon(Icons.close_rounded, color: _dark, size: 20))),
            const SizedBox(width: 14),
            Expanded(child: Text('Soal Harian',
                style: TextStyle(fontSize: isTablet ? 20 : 17,
                    fontWeight: FontWeight.w800, color: _dark))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: _gradientGreen)),
              child: Text('✅ $score', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800))),
          ]),

          const SizedBox(height: 20),

          // ── PROGRESS ──
          Row(children: List.generate(soalList.length, (i) {
            final done = i < currentQuestion; final active = i == currentQuestion;
            return Expanded(child: Container(height: 6,
              margin: EdgeInsets.only(right: i < soalList.length - 1 ? 4 : 0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: done || active ? const Color(0xFF43A047) : Colors.grey.shade200)));
          })),
          const SizedBox(height: 8),
          Text('Soal ${currentQuestion + 1} dari ${soalList.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),

          const SizedBox(height: 20),

          // ── KARTU SOAL ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 22 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: _gradientGreen,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.35),
                  blurRadius: 20, offset: const Offset(0, 8))]),
            child: Stack(children: [
              Positioned(right: -15, top: -15,
                child: Container(width: 90, height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08)))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('📅 Soal Harian',
                      style: TextStyle(color: Colors.white,
                          fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w700))),
                const SizedBox(height: 12),
                Text(soalData['teks']!,
                    style: TextStyle(color: Colors.white,
                        fontSize: isTablet ? 17 : 15,
                        fontWeight: FontWeight.w700, height: 1.4)),
                if ((soalData['gambar'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(soalData['gambar']!,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(height: 120, alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                  color: Colors.white54, strokeWidth: 2)),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )),
                ],
              ]),
            ])),

          const SizedBox(height: 16),

          // ── PILIHAN JAWABAN ──
          ...opsi.entries.map((entry) {
            final key        = entry.key;
            final opsiData   = parseSoal(entry.value);
            final isSelected = selectedKey == key;
            final isBenar    = key == benar;

            Color bgColor     = Colors.white;
            Color borderColor = Colors.grey.shade200;
            Color textColor   = _dark;
            if (answered) {
              if (isBenar) {
                bgColor = const Color(0xFFE8F5E9);
                borderColor = const Color(0xFF43A047);
                textColor = const Color(0xFF2E7D52);
              } else if (isSelected) {
                bgColor = const Color(0xFFFFEBEE);
                borderColor = const Color(0xFFE53935);
                textColor = const Color(0xFFE53935);
              }
            }

            return GestureDetector(
              onTap: () => _answerQuestion(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 8, offset: const Offset(0, 3))]),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 34, height: 34,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                      gradient: answered && isBenar
                          ? const LinearGradient(colors: [Color(0xFF2E7D52), Color(0xFF43A047)])
                          : answered && isSelected
                              ? const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFE53935)])
                              : answered ? null
                                  : const LinearGradient(colors: _gradientGreen),
                      color: answered && !isBenar && !isSelected ? Colors.grey.shade200 : null),
                    child: Center(child: answered && isBenar
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : answered && isSelected
                            ? const Icon(Icons.close_rounded, color: Colors.white, size: 16)
                            : Text(key, style: TextStyle(
                                color: answered ? Colors.grey.shade500 : Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 13)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    if ((opsiData['teks'] ?? '').isNotEmpty)
                      Text(opsiData['teks']!,
                          style: TextStyle(color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 14 : 13)),
                    if ((opsiData['gambar'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: Image.network(opsiData['gambar']!,
                          height: 80, fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) => progress == null
                              ? child
                              : const SizedBox(height: 80,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        )),
                    ],
                  ])),
                  if (answered && isBenar)
                    const Padding(padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded,
                          color: Color(0xFF43A047), size: 22)),
                  if (answered && isSelected && !isBenar)
                    const Padding(padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.cancel_rounded,
                          color: Color(0xFFE53935), size: 22)),
                ]),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── TOMBOL LANJUT ──
          if (answered)
            GestureDetector(
              onTap: _nextQuestion,
              child: Container(
                width: double.infinity, height: isTablet ? 54 : 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: _gradientGreen),
                  boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.40),
                      blurRadius: 16, offset: const Offset(0, 6))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(isLast ? 'Selesai' : 'Soal Berikutnya',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 15 : 14)),
                  const SizedBox(width: 8),
                  Container(width: 24, height: 24,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.22)),
                    child: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14)),
                ]),
              )),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HASIL SCREEN + FORM ULASAN
// ─────────────────────────────────────────────
class _HasilHarianScreen extends StatefulWidget {
  final String nama;
  final String nis;
  final int score;
  final int total;
  final int nilaiAkhir;

  const _HasilHarianScreen({
    required this.nama, required this.nis,
    required this.score, required this.total, required this.nilaiAkhir,
  });

  @override
  State<_HasilHarianScreen> createState() => _HasilHarianScreenState();
}

class _HasilHarianScreenState extends State<_HasilHarianScreen> {
  int    _rating        = 0;
  final  _komentarCtrl  = TextEditingController();
  bool   _ulasanDikirim = false;
  bool   _isSubmitting  = false;

  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];

  @override
  void dispose() { _komentarCtrl.dispose(); super.dispose(); }

  Future<void> _kirimUlasan() async {
    setState(() => _isSubmitting = true);
    final ok = await UlasanService.simpanUlasan(
      nis: widget.nis, namaSiswa: widget.nama, jenisSoal: 'HARIAN',
      rating: _rating == 0 ? 5 : _rating, komentar: _komentarCtrl.text.trim(),
    );
    setState(() { _isSubmitting = false; _ulasanDikirim = ok; });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    final (emoji, label, gradients) = widget.nilaiAkhir >= 80
        ? ('🏆', 'Luar Biasa!', [const Color(0xFF1565C0), const Color(0xFF3D5AFE)])
        : widget.nilaiAkhir >= 60
            ? ('👍', 'Bagus!', [const Color(0xFF2E7D52), const Color(0xFF43A047)])
            : ('💪', 'Terus Semangat!', [const Color(0xFFB71C1C), const Color(0xFFE53935)]);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(
            child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(children: [

            // HERO HASIL
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 32 : 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(colors: gradients,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: gradients[0].withOpacity(0.40),
                    blurRadius: 28, offset: const Offset(0, 12))]),
              child: Column(children: [
                Text(emoji, style: TextStyle(fontSize: isTablet ? 64 : 56)),
                const SizedBox(height: 12),
                Text(label, style: TextStyle(color: Colors.white,
                    fontSize: isTablet ? 26 : 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Hei ${widget.nama.trim()}, soal harian selesai!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.85),
                        fontSize: isTablet ? 14 : 13)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${widget.nilaiAkhir}',
                      style: TextStyle(color: Colors.white,
                          fontSize: isTablet ? 52 : 46, fontWeight: FontWeight.w900))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _statItem('📊', 'Nilai', '${widget.nilaiAkhir} / 100'),
                  _statItem('✅', 'Benar', '${widget.score}'),
                  _statItem('❌', 'Salah', '${widget.total - widget.score}'),
                ]),
                const SizedBox(height: 20),
                ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: widget.nilaiAkhir / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white))),
              ])),

            const SizedBox(height: 20),

            // FORM ULASAN
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 16, offset: const Offset(0, 6))]),
              child: _ulasanDikirim ? _buildSukses() : _buildFormUlasan(isTablet)),

            const SizedBox(height: 16),

            // TOMBOL KEMBALI
            GestureDetector(
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Container(
                width: double.infinity, height: isTablet ? 54 : 50,
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 3))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.home_rounded, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text('Kembali ke Menu', style: TextStyle(color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700, fontSize: isTablet ? 15 : 14)),
                ]))),

            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }

  Widget _buildFormUlasan(bool isTablet) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: _gradientGreen)),
        child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 20)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Beri Ulasan', style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        Text('Opsional · bantu kami berkembang 🙏',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    ]),
    const SizedBox(height: 20),
    const Text('Rating', style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(i < _rating ? '★' : '☆',
                style: TextStyle(fontSize: isTablet ? 42 : 36,
                    color: i < _rating
                        ? const Color(0xFFFFB300)
                        : Colors.grey.shade300)))))),
    if (_rating > 0)
      Center(child: Padding(padding: const EdgeInsets.only(top: 6),
        child: Text(
          _rating == 5 ? '😍 Luar biasa!' : _rating == 4 ? '😊 Bagus!' :
          _rating == 3 ? '😐 Cukup' : _rating == 2 ? '😕 Kurang' : '😞 Sangat kurang',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600,
              fontWeight: FontWeight.w600)))),
    const SizedBox(height: 16),
    const Text('Komentar', style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 8),
    TextFormField(
      controller: _komentarCtrl, maxLines: 3, maxLength: 200,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: 'Tulis pendapatmu tentang soal ini...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF43A047), width: 2)),
        contentPadding: const EdgeInsets.all(14))),
    const SizedBox(height: 16),
    GestureDetector(
      onTap: _isSubmitting ? null : _kirimUlasan,
      child: Container(width: double.infinity, height: 48,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: _gradientGreen),
          boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.35),
              blurRadius: 12, offset: const Offset(0, 5))]),
        child: Center(child: _isSubmitting
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Kirim Ulasan', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 14))))),
    const SizedBox(height: 10),
    GestureDetector(
      onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
      child: Center(child: Text('Lewati',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline)))),
  ]);

  Widget _buildSukses() => Column(children: [
    const SizedBox(height: 8),
    const Text('🎉', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    const Text('Terima kasih!', style: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 6),
    Text('Ulasan kamu sudah dikirim dan\nakan membantu kami berkembang.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    const SizedBox(height: 8),
  ]);

  Widget _statItem(String icon, String label, String value) =>
    Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.w800, fontSize: 18)),
      Text(label, style: TextStyle(
          color: Colors.white.withOpacity(0.75), fontSize: 11)),
    ]);
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (const Color(0xFF43A047), 0.90, 0.05, 0.42),
      (const Color(0xFF5C6BC0), 0.05, 0.45, 0.35),
      (const Color(0xFFFF7043), 0.70, 0.80, 0.30),
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