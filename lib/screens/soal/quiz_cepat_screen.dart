import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/quiz_service.dart';
import '../../services/nilai_service.dart';
import '../../services/ulasan_service.dart';

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

class QuizCepatScreen extends StatefulWidget {
  final String idMateri;
  final String idPertemuan; // ← TAMBAHAN BARU
  final String nis;
  final String nama;
  final String kelas;
  final String noAbsen;

  const QuizCepatScreen({
    super.key,
    required this.idMateri,
    required this.idPertemuan, // ← TAMBAHAN BARU
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.noAbsen,
  });

  @override
  State<QuizCepatScreen> createState() => _QuizCepatScreenState();
}

class _QuizCepatScreenState extends State<QuizCepatScreen>
    with TickerProviderStateMixin {

  List<Map<String, dynamic>> quizList = [];
  bool isLoading = true;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isMuted = false;

  int currentQuestion = 0;
  int score           = 0;
  int timeLeft        = 30;
  String? selectedKey;
  bool answered       = false;
  Timer? timer;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  static const _gradientBlue = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];
  static const _bgColor      = Color(0xFFF0F4FF);
  static const _dark         = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadQuiz();
  }

  Future<void> _initAudio() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.5);
      await _bgmPlayer.play(AssetSource('sounds/Subway Surfers.mp3'));
    } catch (e) {
      print('[BGM] error: $e');
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _bgmPlayer.setVolume(_isMuted ? 0.0 : 0.5);
  }

  Future<void> _loadQuiz() async {
    // ← Teruskan idPertemuan ke QuizService
    final data = await QuizService.getQuiz(
      widget.idMateri,
      tipe: 'QUIZ',
      idPertemuan: widget.idPertemuan,
    );
    if (!mounted) return;
    setState(() { quizList = data; isLoading = false; });
    if (quizList.isNotEmpty) {
      _fadeController.forward();
      _startTimer();
      _initAudio();
    }
  }

  void _startTimer() {
    timer?.cancel();
    setState(() => timeLeft = 30);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (timeLeft == 0) { t.cancel(); _finishQuiz(); }
      else { setState(() => timeLeft--); }
    });
  }

  void _answerQuestion(String key) {
    if (answered) return;
    timer?.cancel();
    setState(() {
      selectedKey = key;
      answered    = true;
      if (quizList[currentQuestion]['jawaban_benar'] == key) score++;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (currentQuestion < quizList.length - 1) {
        setState(() { currentQuestion++; selectedKey = null; answered = false; });
        _fadeController..reset()..forward();
        _startTimer();
      } else {
        _finishQuiz();
      }
    });
  }

  Future<void> _finishQuiz() async {
    timer?.cancel();
    final nilaiAkhir = quizList.isNotEmpty
        ? ((score / quizList.length) * 100).toInt() : 0;

    await NilaiService.simpanNilai(
      nis:         widget.nis,
      nama:        widget.nama,
      kelas:       widget.kelas,
      noAbsen:     widget.noAbsen,
      idMateri:    widget.idMateri,
      idPertemuan: widget.idPertemuan, // ← TAMBAHAN BARU
      skor:        nilaiAkhir,
      jenisSoal:   'QUIZ',
    );

    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, anim, __) => QuizResultScreen(
        score: nilaiAkhir, total: quizList.length,
        nama: widget.nama, nis: widget.nis),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  void dispose() {
    timer?.cancel();
    _fadeController.dispose();
    _bgmPlayer.stop();
    _bgmPlayer.dispose();
    super.dispose();
  }

  Color _optionBg(String key) {
    if (!answered) return Colors.white;
    final correct = quizList[currentQuestion]['jawaban_benar'];
    if (key == correct) return const Color(0xFFE8F5E9);
    if (key == selectedKey) return const Color(0xFFFFEBEE);
    return Colors.white;
  }

  Color _optionBorder(String key) {
    if (!answered) return Colors.grey.shade200;
    final correct = quizList[currentQuestion]['jawaban_benar'];
    if (key == correct) return const Color(0xFF43A047);
    if (key == selectedKey) return const Color(0xFFE53935);
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad      = isTablet ? 28.0 : 20.0;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    if (isLoading) {
      return Scaffold(backgroundColor: _bgColor,
        body: Stack(children: [
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
          const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFF3D5AFE)),
            SizedBox(height: 16),
            Text('Memuat soal...', style: TextStyle(color: _dark, fontWeight: FontWeight.w600)),
          ])),
        ]));
    }

    if (quizList.isEmpty) {
      return Scaffold(backgroundColor: _bgColor,
        body: Stack(children: [
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
          SafeArea(child: Padding(padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(children: [
              const SizedBox(height: 16),
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.close_rounded, color: _dark, size: 20))),
                const SizedBox(width: 14),
                Text('Quiz Cepat', style: TextStyle(fontSize: isTablet ? 22 : 19,
                    fontWeight: FontWeight.w800, color: _dark)),
              ]),
              const Spacer(),
              const Text('😔', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text('Soal belum tersedia', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800, color: _dark)),
              const SizedBox(height: 8),
              Text('Belum ada soal quiz untuk pertemuan ini.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const Spacer(),
            ]))),
        ]));
    }

    final soal     = quizList[currentQuestion];
    final opsi     = soal['opsi'] as Map<String, dynamic>;
    final soalData = parseSoal(soal['pertanyaan']);
    final timerRatio = timeLeft / 30;
    final timerColor = timeLeft > 15
        ? const Color(0xFF43A047)
        : timeLeft > 7 ? const Color(0xFFFF9800) : const Color(0xFFE53935);

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: FadeTransition(opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),

              // ── APP BAR ──
              Row(children: [
                GestureDetector(onTap: () { timer?.cancel(); Navigator.pop(context); },
                  child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.close_rounded, color: _dark, size: 20))),
                const SizedBox(width: 14),
                Expanded(child: Text('Quiz Cepat', style: TextStyle(
                    fontSize: isTablet ? 22 : 19,
                    fontWeight: FontWeight.w800, color: _dark))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(colors: _gradientBlue)),
                  child: Text('⭐ $score', style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                          blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: const Color(0xFF3D5AFE), size: 20))),
              ]),

              const SizedBox(height: 20),

              // ── PROGRESS BAR ──
              Row(children: List.generate(quizList.length, (i) {
                final done = i < currentQuestion, active = i == currentQuestion;
                return Expanded(child: Container(
                  margin: EdgeInsets.only(right: i < quizList.length - 1 ? 6 : 0),
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: (active || done) ? const LinearGradient(colors: _gradientBlue) : null,
                    color: (active || done) ? null : Colors.grey.shade200),
                ));
              })),
              const SizedBox(height: 6),
              Text('Soal ${currentQuestion + 1} dari ${quizList.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),

              const SizedBox(height: 16),

              // ── TIMER ──
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 10, offset: const Offset(0, 3))]),
                child: Row(children: [
                  Icon(Icons.timer_rounded, color: timerColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: timerRatio, minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(timerColor)))),
                  const SizedBox(width: 10),
                  Text('$timeLeft', style: TextStyle(fontWeight: FontWeight.w800,
                      fontSize: 16, color: timerColor)),
                  Text(' detik', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),

              const SizedBox(height: 16),

              // ── QUESTION CARD ──
              Container(width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 22 : 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: _gradientBlue,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: const Color(0xFF3D5AFE).withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 8))]),
                child: Stack(children: [
                  Positioned(right: -20, top: -20,
                    child: Container(width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08)))),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('⚡ Quiz Cepat',
                          style: TextStyle(color: Colors.white,
                              fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 12),
                    Text(soalData['teks']!,
                        style: TextStyle(color: Colors.white,
                            fontSize: isTablet ? 18 : 16,
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

              // ── OPSI JAWABAN ──
              ...opsi.entries.map((entry) {
                final key      = entry.key;
                final opsiData = parseSoal(entry.value);
                final correct  = quizList[currentQuestion]['jawaban_benar'];
                final isCorrect = answered && key == correct;
                final isWrong   = answered && key == selectedKey && key != correct;

                return GestureDetector(
                  onTap: () => _answerQuestion(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 18 : 16,
                        vertical: isTablet ? 14 : 12),
                    decoration: BoxDecoration(
                      color: _optionBg(key),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _optionBorder(key), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 8, offset: const Offset(0, 3))]),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 32, height: 32,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                          gradient: !answered
                              ? const LinearGradient(colors: _gradientBlue)
                              : isCorrect
                                  ? const LinearGradient(colors: [Color(0xFF2E7D52), Color(0xFF43A047)])
                                  : isWrong
                                      ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF7043)])
                                      : null,
                          color: (answered && !isCorrect && !isWrong) ? Colors.grey.shade200 : null),
                        child: Center(child: isCorrect
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : isWrong
                                ? const Icon(Icons.close_rounded, color: Colors.white, size: 16)
                                : Text(key, style: TextStyle(
                                    color: !answered ? Colors.white : Colors.grey.shade500,
                                    fontWeight: FontWeight.w800, fontSize: 13)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if ((opsiData['teks'] ?? '').isNotEmpty)
                          Text(opsiData['teks']!,
                              style: TextStyle(fontSize: isTablet ? 14 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCorrect ? const Color(0xFF2E7D52)
                                      : isWrong ? const Color(0xFFE53935) : _dark)),
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
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 32),
            ]),
          ))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// QUIZ RESULT SCREEN
// ─────────────────────────────────────────────
class QuizResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final String nama;
  final String nis;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.nama,
    required this.nis,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  int    _rating        = 0;
  final  _komentarCtrl  = TextEditingController();
  bool   _ulasanDikirim = false;
  bool   _isSubmitting  = false;

  static const _gradientBlue = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];

  @override
  void dispose() { _komentarCtrl.dispose(); super.dispose(); }

  Future<void> _kirimUlasan() async {
    setState(() => _isSubmitting = true);
    final ok = await UlasanService.simpanUlasan(
      nis: widget.nis, namaSiswa: widget.nama, jenisSoal: 'QUIZ',
      rating: _rating == 0 ? 5 : _rating, komentar: _komentarCtrl.text.trim(),
    );
    setState(() { _isSubmitting = false; _ulasanDikirim = ok; });
  }

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad      = isTablet ? 28.0 : 20.0;
    final benar    = widget.total > 0 ? (widget.score * widget.total / 100).round() : 0;
    final salah    = widget.total - benar;

    final (emoji, label, gradient) = widget.score >= 80
        ? ('🏆', 'Luar Biasa!', [const Color(0xFFFFCA28), const Color(0xFFFF6F00)])
        : widget.score >= 50
            ? ('👍', 'Bagus!', [const Color(0xFF3D5AFE), const Color(0xFF7C4DFF)])
            : ('💪', 'Terus Semangat!', [const Color(0xFFE53935), const Color(0xFFFF7043)]);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
        SafeArea(child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(children: [
            const SizedBox(height: 40),

            Container(width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 32 : 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(colors: gradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.40),
                    blurRadius: 28, offset: const Offset(0, 12))]),
              child: Column(children: [
                Text(emoji, style: TextStyle(fontSize: isTablet ? 72 : 60)),
                const SizedBox(height: 12),
                Text(label, style: TextStyle(color: Colors.white,
                    fontSize: isTablet ? 28 : 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Hei ${widget.nama}, quiz selesai!',
                    style: TextStyle(color: Colors.white.withOpacity(0.85),
                        fontSize: isTablet ? 15 : 13)),
              ])),

            const SizedBox(height: 20),

            Container(padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 14, offset: const Offset(0, 5))]),
              child: Column(children: [
                Row(children: [
                  _statItem('📊', 'Nilai', '${widget.score}', const Color(0xFF3D5AFE), isTablet),
                  _divider(),
                  _statItem('✅', 'Benar', '$benar', const Color(0xFF43A047), isTablet),
                  _divider(),
                  _statItem('❌', 'Salah', '$salah', const Color(0xFFE53935), isTablet),
                ]),
                const SizedBox(height: 16),
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: widget.score / 100,
                    minHeight: 10, backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(gradient[0]))),
                const SizedBox(height: 8),
                Text('Nilai akhir: ${widget.score} dari 100',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ])),

            const SizedBox(height: 20),

            Container(width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 16, offset: const Offset(0, 6))]),
              child: _ulasanDikirim ? _buildSukses() : _buildFormUlasan(isTablet)),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: Container(width: double.infinity, height: isTablet ? 52 : 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.home_rounded, color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 8),
                  Text('Kembali ke Menu', style: TextStyle(color: Colors.grey.shade600,
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
            gradient: const LinearGradient(colors: _gradientBlue)),
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
                    color: i < _rating ? const Color(0xFFFFB300) : Colors.grey.shade300)))))),
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
        hintText: 'Tulis pendapatmu tentang quiz ini...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2)),
        contentPadding: const EdgeInsets.all(14))),
    const SizedBox(height: 16),
    GestureDetector(
      onTap: _isSubmitting ? null : _kirimUlasan,
      child: Container(width: double.infinity, height: 48,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: _gradientBlue),
          boxShadow: [BoxShadow(color: const Color(0xFF3D5AFE).withOpacity(0.35),
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
              fontWeight: FontWeight.w600, decoration: TextDecoration.underline)))),
  ]);

  Widget _buildSukses() => Column(children: [
    const SizedBox(height: 8),
    const Text('🎉', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    const Text('Terima kasih!', style: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 6),
    Text('Ulasan kamu sudah dikirim.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    const SizedBox(height: 8),
  ]);

  Widget _statItem(String emoji, String label, String value, Color color, bool isTablet) =>
    Expanded(child: Column(children: [
      Text(emoji, style: TextStyle(fontSize: isTablet ? 24 : 20)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: isTablet ? 22 : 20,
          fontWeight: FontWeight.w900, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]));

  Widget _divider() => Container(width: 1, height: 50, color: Colors.grey.shade100);
}

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