import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_cepat_screen.dart';

class QuizFormScreen extends StatefulWidget {
  final String idMateri;

  const QuizFormScreen({
    super.key,
    required this.idMateri,
  });

  @override
  State<QuizFormScreen> createState() => _QuizFormScreenState();
}

class _QuizFormScreenState extends State<QuizFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nisController    = TextEditingController();
  final TextEditingController namaController   = TextEditingController();
  final TextEditingController kelasController  = TextEditingController();
  final TextEditingController absenController  = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ── Design tokens ──
  static const _gradientBlue  = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];
  static const _gradientGreen = [Color(0xFF2E7D52), Color(0xFF43A047)];
  static const _bgColor       = Color(0xFFF0F4FF);
  static const _dark          = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    nisController.dispose();
    namaController.dispose();
    kelasController.dispose();
    absenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad = isTablet ? 28.0 : 20.0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background blobs
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BlobPainter())),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── APP BAR ──
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: _dark, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Identitas Peserta',
                            style: TextStyle(
                                fontSize: isTablet ? 22 : 19,
                                fontWeight: FontWeight.w800,
                                color: _dark)),
                      ]),

                      const SizedBox(height: 24),

                      // ── HERO BANNER ──
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                              colors: _gradientBlue,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          boxShadow: [BoxShadow(
                              color: const Color(0xFF3D5AFE).withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10))],
                        ),
                        child: Stack(children: [
                          Positioned(right: -15, top: -15,
                            child: Container(width: 100, height: 100,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08)))),
                          Positioned(right: 30, bottom: -20,
                            child: Container(width: 60, height: 60,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06)))),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.20),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text('⚡ Quiz Cepat',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 10),
                              Text('Isi Data Dulu\nSebelum Mulai! 📝',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 22 : 19,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3)),
                              const SizedBox(height: 6),
                              Text('Data ini digunakan untuk mencatat hasil quiz kamu.',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.80),
                                      fontSize: isTablet ? 13 : 12)),
                            ],
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // ── FORM CARD ──
                      Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data Peserta',
                                style: TextStyle(
                                    fontSize: isTablet ? 16 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: _dark)),
                            const SizedBox(height: 4),
                            Text('Pastikan data yang diisi sudah benar',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                            const SizedBox(height: 20),

                            _buildField(
                              controller: nisController,
                              label: 'NIS',
                              hint: 'Masukkan NIS kamu',
                              icon: Icons.badge_rounded,
                              keyboardType: TextInputType.number,
                              isTablet: isTablet,
                              validator: (v) =>
                                  v!.isEmpty ? 'NIS wajib diisi' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: namaController,
                              label: 'Nama Siswa',
                              hint: 'Masukkan nama lengkap',
                              icon: Icons.person_rounded,
                              isTablet: isTablet,
                              validator: (v) =>
                                  v!.isEmpty ? 'Nama wajib diisi' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildDropdownKelas(isTablet),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: absenController,
                              label: 'No Absen',
                              hint: 'Masukkan nomor absen',
                              icon: Icons.format_list_numbered_rounded,
                              keyboardType: TextInputType.number,
                              isTablet: isTablet,
                              validator: (v) =>
                                  v!.isEmpty ? 'No Absen wajib diisi' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── INFO CHIP ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF43A047).withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF2E7D52), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pastikan data sudah benar sebelum memulai quiz. Data tidak bisa diubah setelah quiz dimulai.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF2E7D52),
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // ── TOMBOL MULAI ──
                      GestureDetector(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, anim, __) => QuizCepatScreen(
                                  idMateri: widget.idMateri,
                                  nis: nisController.text,
                                  nama: namaController.text,
                                  kelas: kelasController.text,
                                  noAbsen: absenController.text,
                                ),
                                transitionsBuilder:
                                    (_, anim, __, child) =>
                                        FadeTransition(
                                            opacity: anim, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: isTablet ? 56 : 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                                colors: _gradientGreen),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFF43A047).withOpacity(0.40),
                                blurRadius: 16,
                                offset: const Offset(0, 6))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text('Mulai Quiz',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: isTablet ? 16 : 15)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownKelas(bool isTablet) {
    final kelasList = ['7A','7B','7C','7D','7E','7F','7G','7H','7I','7J'];

    return DropdownButtonFormField<String>(
      initialValue: kelasController.text.isEmpty ? null : kelasController.text,
      validator: (v) => v == null ? 'Kelas wajib dipilih' : null,
      onChanged: (val) => kelasController.text = val ?? '',
      style: TextStyle(
          fontSize: isTablet ? 14 : 13,
          fontWeight: FontWeight.w600,
          color: _dark),
      decoration: InputDecoration(
        labelText: 'Kelas',
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: _gradientBlue),
          ),
          child: const Icon(Icons.class_rounded, color: Colors.white, size: 18),
        ),
        labelStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: kelasList.map((kelas) => DropdownMenuItem(
        value: kelas,
        child: Text(kelas,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: _dark)),
      )).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isTablet,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
          fontSize: isTablet ? 14 : 13,
          fontWeight: FontWeight.w600,
          color: _dark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: _gradientBlue),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        labelStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND BLOB PAINTER
// ─────────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in [
      (const Color(0xFF5C6BC0), 0.90, 0.05, 0.42),
      (const Color(0xFF43A047), 0.05, 0.55, 0.35),
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