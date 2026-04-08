import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  static const _gradient = [Color(0xFF2E7D52), Color(0xFF43A047)];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w > 600;
    final pad = isTablet ? 28.0 : 20.0;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── APP BAR ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E), size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Info Aplikasi',
                      style: TextStyle(fontSize: isTablet ? 22 : 19, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
                ],
              ),

              const SizedBox(height: 20),

              // ── HERO BANNER ──
              Container(
                height: isTablet ? 200 : 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: _gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: const Color(0xFF2E7D52).withOpacity(0.38), blurRadius: 22, offset: const Offset(0, 9))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset('assets/banner3.jpg', fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xDD2E7D52), Color(0x882E7D52), Colors.transparent],
                              begin: Alignment.centerLeft, end: Alignment.centerRight,
                              stops: [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(right: -30, top: -30,
                        child: Container(width: 140, height: 140,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10)))),
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 26 : 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                              child: const Text('💡 Panduan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 10),
                            Text('Cara Pakai\nAplikasi',
                                style: TextStyle(color: Colors.white, fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.w900, height: 1.25)),
                            const SizedBox(height: 4),
                            Text('Panduan lengkap penggunaan INFOX',
                                style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: isTablet ? 14 : 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── FITUR UNGGULAN ──
              _sectionTitle('Fitur Unggulan', isTablet),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isTablet ? 1.6 : 1.35,
                children: [
                  _fiturCard('📄', 'Materi PDF', 'Baca modul pelajaran langsung di aplikasi', isTablet),
                  _fiturCard('🎬', 'Video Belajar', 'Tonton video penjelasan materi kapan saja', isTablet),
                  _fiturCard('🧩', 'Latihan Soal', 'Uji pemahaman dengan soal interaktif', isTablet),
                  _fiturCard('🔓', 'Tanpa Login', 'Langsung belajar tanpa perlu daftar akun', isTablet),
                ],
              ),

              const SizedBox(height: 22),

              // ── CARA PENGGUNAAN ──
              _sectionTitle('Cara Penggunaan', isTablet),
              const SizedBox(height: 12),
              _stepItem('1', '🏠', 'Buka Menu Utama', 'Pilih salah satu dari 4 menu: Materi, Latihan, Info, atau Tentang.', isTablet),
              const SizedBox(height: 10),
              _stepItem('2', '📚', 'Pilih Jenis Materi', 'Pilih antara PDF untuk membaca atau Video untuk menonton penjelasan.', isTablet),
              const SizedBox(height: 10),
              _stepItem('3', '📖', 'Belajar Sesuai Bab', 'Setiap materi dikelompokkan per bab agar lebih mudah dicari.', isTablet),
              const SizedBox(height: 10),
              _stepItem('4', '🧩', 'Kerjakan Latihan', 'Setelah belajar, coba latihan soal untuk mengukur pemahamanmu.', isTablet),

              const SizedBox(height: 22),

              // ── FAQ ──
              _sectionTitle('Pertanyaan Umum', isTablet),
              const SizedBox(height: 12),
              _faqItem('Apakah perlu internet?',
                  'Ya, koneksi internet diperlukan untuk memuat materi PDF dan video pembelajaran.', isTablet),
              const SizedBox(height: 10),
              _faqItem('Apakah perlu membuat akun?',
                  'Tidak perlu! Kamu bisa langsung belajar tanpa registrasi atau login.', isTablet),
              const SizedBox(height: 10),
              _faqItem('Materi apa saja yang tersedia?',
                  'Tersedia materi Informatika kelas VII sesuai Kurikulum Merdeka dalam format PDF dan video.', isTablet),
              const SizedBox(height: 10),
              _faqItem('Bagaimana jika video tidak bisa diputar?',
                  'Pastikan koneksi internet stabil. Coba tutup lalu buka kembali halaman video.', isTablet),

              const SizedBox(height: 28),

               // ── FOOTER ──
              Center(
                child: Column(
                  children: [
                    Text('Versi Aplikasi 1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('© 2025 Infox. All rights reserved.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, bool isTablet) {
    return Row(
      children: [
        Container(
          width: 5, height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFFAB47BC)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _fiturCard(String emoji, String title, String desc, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2E7D52).withOpacity(0.09), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: _gradient))),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: TextStyle(fontSize: isTablet ? 28 : 24)),
                  const SizedBox(height: 6),
                  Text(title, style: TextStyle(fontSize: isTablet ? 14 : 13, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
                  const SizedBox(height: 3),
                  Text(desc, style: TextStyle(fontSize: isTablet ? 12 : 11, color: Colors.grey.shade500, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepItem(String number, String emoji, String title, String desc, bool isTablet) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(width: 4, height: 76,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: _gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            const SizedBox(width: 14),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), gradient: const LinearGradient(colors: _gradient)),
              child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Text(emoji, style: TextStyle(fontSize: isTablet ? 22 : 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: isTablet ? 15 : 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    Text(desc, style: TextStyle(fontSize: isTablet ? 13 : 12, color: Colors.grey.shade500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer, bool isTablet) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 4,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: _gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: _gradient)),
                          child: const Center(child: Text('?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(question,
                              style: TextStyle(fontSize: isTablet ? 14 : 13, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text(answer, style: TextStyle(fontSize: isTablet ? 13 : 12, color: Colors.grey.shade500, height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}