import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  static const _gradient = [Color(0xFF3D5AFE), Color(0xFF7C4DFF)];
  static const _orangeGrad = [Color(0xFFFF6F00), Color(0xFFFFCA28)];

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
                  Text('Tentang Aplikasi',
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
                  gradient: const LinearGradient(colors: _orangeGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withOpacity(0.38), blurRadius: 22, offset: const Offset(0, 9))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Banner image (kanan)
                      Positioned.fill(
                        child: Image.asset(
                          'assets/banner2.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                      // Gradient overlay agar teks terbaca
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xDDFF6F00), Color(0x88FF8F00), Colors.transparent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Decorative circle
                      Positioned(right: -30, top: -30,
                        child: Container(width: 140, height: 140,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10)))),
                      // Text
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 26 : 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                              child: const Text('👥 Profil Pengembang', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 10),
                            Text('Informatika VII',
                                style: TextStyle(color: Colors.white, fontSize: isTablet ? 26 : 22, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text('Edisi Mobile Learning v1.0',
                                style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: isTablet ? 14 : 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── TENTANG APLIKASI ──
              _sectionTitle('Tentang Aplikasi', isTablet),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aplikasi ini adalah media pembelajaran interaktif berbasis mobile yang dirancang khusus untuk mata pelajaran Informatika kelas VII SMP/MTs.',
                      style: TextStyle(height: 1.6, fontSize: isTablet ? 15 : 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(height: 1.6, fontSize: isTablet ? 15 : 14, color: Colors.grey.shade600),
                        children: const [
                          TextSpan(text: 'Kami mengutamakan kemudahan akses, sehingga '),
                          TextSpan(text: 'siswa tidak perlu login akun',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D5AFE))),
                          TextSpan(text: ' untuk membuka materi. Materi disajikan secara ringkas, visual, dan mudah dipahami.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── TUJUAN PENGEMBANGAN ──
              _sectionTitle('Tujuan Pengembangan', isTablet),
              const SizedBox(height: 12),
              _tujuanItem('🔓', 'Akses Tanpa Hambatan', 'Menghilangkan proses registrasi yang rumit agar siswa bisa langsung fokus pada materi.', isTablet),
              const SizedBox(height: 10),
              _tujuanItem('📱', 'Mobile Learning', 'Memanfaatkan smartphone sebagai media belajar yang fleksibel di mana saja.', isTablet),
              const SizedBox(height: 10),
              _tujuanItem('💡', 'Interaktif & Menarik', 'Meningkatkan motivasi belajar melalui penyajian konten digital yang modern.', isTablet),

              const SizedBox(height: 22),

              // ── PROFIL PENGEMBANG ──
              _sectionTitle('Profil Pengembang', isTablet),
              const SizedBox(height: 12),
              _card(
                accentColors: _orangeGrad,
                child: Column(
                  children: [
                    // ── Foto besar di atas ──
                    Container(
                      width: isTablet ? 130 : 110,
                      height: isTablet ? 130 : 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(colors: _orangeGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withOpacity(0.40), blurRadius: 18, offset: const Offset(0, 7))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/profil.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('MT', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Nama & badge ──
                    Text('Muhammad Tartib Wicaksana',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: _orangeGrad),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Pengembang Aplikasi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    Text('Universitas Muhammadiyah Purwokerto',
                        style: TextStyle(fontSize: isTablet ? 13 : 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('Program Studi: Teknik Informatika',
                        style: TextStyle(fontSize: isTablet ? 13 : 12, color: Colors.grey.shade500)),

                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 12),

                    // ── Deskripsi ──
                    Text(
                      'Aplikasi ini dikembangkan sebagai bagian dari penelitian tugas akhir dengan tujuan menyediakan media pembelajaran digital yang interaktif dan mudah digunakan. Diharapkan aplikasi ini dapat membantu meningkatkan pemahaman siswa terhadap materi pembelajaran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isTablet ? 13 : 12, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async => launchUrl(Uri(scheme: 'mailto', path: 'muhtartibw@gmail.com')),
                      child: const Text('muhtartibw@gmail.com',
                          style: TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── FOOTER ──
              Center(
                child: Column(
                  children: [
                    Text('Versi Aplikasi 1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('© 2026 Infox. All rights reserved.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
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

  Widget _card({required Widget child, List<Color> accentColors = _gradient}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: accentColors[0].withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 5)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(height: 5, decoration: BoxDecoration(gradient: LinearGradient(colors: accentColors))),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }

  Widget _tujuanItem(String emoji, String title, String desc, bool isTablet) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(width: 4, height: 72,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: _gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            const SizedBox(width: 14),
            Text(emoji, style: TextStyle(fontSize: isTablet ? 26 : 22)),
            const SizedBox(width: 12),
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
}