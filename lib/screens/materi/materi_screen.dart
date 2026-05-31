import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'materi_list.dart';
import 'diskusi_form_screen.dart'; // Pastikan file form login Anda bernama ini
import '../../services/diskusi_service.dart';

// ─────────────────────────────────────────────
// MATERI SCREEN UTAMA
// ─────────────────────────────────────────────
class MateriScreen extends StatefulWidget {
  final String nis;
  final String namaSiswa;
  final String? idMateri; 

  const MateriScreen({
    super.key,
    required this.nis,
    required this.namaSiswa,
    this.idMateri,
  });

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  bool _showChat = false;

  String _activeNis = '';
  String _activeNama = '';

  @override
  void initState() {
    super.initState();
    _activeNis = widget.nis;
    _activeNama = widget.namaSiswa;

    // Cek ulang data dari SharedPreferences saat layar dibuka
    _cekSesiMemori();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  Future<void> _cekSesiMemori() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNis = prefs.getString('nis') ?? '';
    final savedNama = prefs.getString('nama_siswa') ?? 'Siswa';
    
    if (savedNis.isNotEmpty) {
      setState(() {
        _activeNis = savedNis;
        _activeNama = savedNama;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _initial {
    if (_activeNama.isEmpty) return 'SI';
    final parts = _activeNama.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].length >= 2 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── LOGIKA PEMANGGILAN DISKUSI & FORM LOGIN ──
  Future<void> _handleDiscussionTap() async {
    if (_showChat) {
      setState(() => _showChat = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedNis = prefs.getString('nis') ?? '';

    if (savedNis.isEmpty) {
      // 1. BELUM LOGIN: Buka halaman form login
      final bool? isLoginSuccess = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DiskusiFormScreen()),
      );

      // Jika berhasil login di form, update state dan buka panel
      if (isLoginSuccess == true) {
        final updatedNis = prefs.getString('nis') ?? '';
        final updatedNama = prefs.getString('nama_siswa') ?? 'Siswa';
        setState(() {
          _activeNis = updatedNis;
          _activeNama = updatedNama;
          _showChat = true;
        });
      }
    } else {
      // 2. SUDAH LOGIN: Kasih tahu pengguna, lalu buka panel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membuka diskusi sebagai $_activeNama')),
      );
      setState(() {
        _activeNis = savedNis;
        _activeNama = prefs.getString('nama_siswa') ?? 'Siswa';
        _showChat = true;
      });
    }
  }

  // ── FUNGSI LOGOUT (Hanya untuk Testing/Reset Memori) ──
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _activeNis = '';
      _activeNama = '';
      _showChat = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi dihapus! Silakan klik "Diskusi" lagi untuk tes Form Login.')),
      );
    }
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
      floatingActionButton: _DiscussionFab(
        showChat: _showChat,
        onTap: _handleDiscussionTap,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            const _BackgroundShapes(),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(context, isTablet),
                    SizedBox(height: isTablet ? 28 : 20),
                    _HeaderBanner(isTablet: isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _SectionTitle(
                        text: 'Pilih Jenis Materi', isTablet: isTablet),
                    SizedBox(height: isTablet ? 16 : 12),
                    _MateriCard(
                      emoji: '📄',
                      label: 'MODUL',
                      labelGradient: const [
                        Color(0xFF3D5AFE),
                        Color(0xFF7C4DFF)
                      ],
                      title: 'Materi Bacaan',
                      description:
                          'Kumpulan modul dan rangkuman dalam bentuk file yang lengkap dan mudah dipahami.',
                      buttonText: 'Mulai Membaca',
                      bgColor: const Color(0xFFEEF0FF),
                      accentColor: const Color(0xFF3D5AFE),
                      gradientColors: const [
                        Color(0xFF3D5AFE),
                        Color(0xFF7C4DFF)
                      ],
                      image: 'assets/buku.jpg',
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                      onTap: () => Navigator.push(
                        context,
                        _pageRoute(const MateriListScreen(type: 'FILE')),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    _MateriCard(
                      emoji: '🎬',
                      label: 'VIDEO',
                      labelGradient: const [
                        Color(0xFFE53935),
                        Color(0xFFFF7043)
                      ],
                      title: 'Video Pembelajaran',
                      description:
                          'Tonton penjelasan materi secara visual dan interaktif agar lebih mudah dimengerti.',
                      buttonText: 'Tonton Video',
                      bgColor: const Color(0xFFFFEEEC),
                      accentColor: const Color(0xFFE53935),
                      gradientColors: const [
                        Color(0xFFE53935),
                        Color(0xFFFF7043)
                      ],
                      image: 'assets/video.jpg',
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                      onTap: () => Navigator.push(
                        context,
                        _pageRoute(
                            const MateriListScreen(type: 'VIDEO')),
                      ),
                    ),
                    SizedBox(height: isTablet ? 36 : 28),
                    _SectionTitle(
                        text: 'Tips Belajar Efektif',
                        isTablet: isTablet),
                    SizedBox(height: isTablet ? 16 : 12),
                    _TipsBelajarSection(
                        isTablet: isTablet,
                        isLargeTablet: isLargeTablet),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Panel diskusi (slide dari bawah)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              left: 0,
              right: 0,
              bottom: _showChat
                  ? 0
                  : -(MediaQuery.of(context).size.height * 0.75),
              height: MediaQuery.of(context).size.height * 0.75,
              child: _activeNis.isEmpty 
                  ? const SizedBox() 
                  : _DiscussionPanel(
                      nis: _activeNis,
                      namaSiswa: _activeNama,
                      initial: _initial,
                      idMateri: widget.idMateri,
                      isTablet: isTablet,
                      onClose: () => setState(() => _showChat = false),
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
        Expanded(
          child: Text(
            'Materi Belajar',
            style: TextStyle(
              fontSize: isTablet ? 22 : 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── TOMBOL LOGOUT MERAH (MUNCUL JIKA SUDAH LOGIN) ──
        if (_activeNis.isNotEmpty)
          GestureDetector(
            onTap: _logout,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 18),
            ),
          ),

        GestureDetector(
          onTap: _handleDiscussionTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF7C4DFF)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C6BC0).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_rounded, color: Colors.white, size: 16),
                SizedBox(width: 5),
                Text(
                  'Diskusi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
// FAB DISKUSI
// ─────────────────────────────────────────────
class _DiscussionFab extends StatelessWidget {
  final bool showChat;
  final VoidCallback onTap;
  const _DiscussionFab({required this.showChat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: showChat ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C6BC0).withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                const Icon(Icons.forum_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PANEL DISKUSI — terhubung ke API real
// ─────────────────────────────────────────────
class _DiscussionPanel extends StatefulWidget {
  final String nis;
  final String namaSiswa;
  final String initial;
  final String? idMateri;
  final bool isTablet;
  final VoidCallback onClose;

  const _DiscussionPanel({
    required this.nis,
    required this.namaSiswa,
    required this.initial,
    required this.idMateri,
    required this.isTablet,
    required this.onClose,
  });

  @override
  State<_DiscussionPanel> createState() => _DiscussionPanelState();
}

class _DiscussionPanelState extends State<_DiscussionPanel> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late DiskusiService _service;
  List<DiskusiMessage> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMsg;

  DiskusiMessage? _replyingTo; // pesan yang sedang dibalas

  @override
  void initState() {
    super.initState();
    _service = DiskusiService(widget.nis);
    _loadMessages();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Load pesan dari API ──────────────────────────
  Future<void> _loadMessages() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final msgs = await _service.getMessages(idMateri: widget.idMateri);
      setState(() { _messages = msgs; _isLoading = false; });
      _scrollToBottom();
    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = e.toString(); });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Kirim pesan ──────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final newMsg = await _service.sendMessage(
        pesan: text,
        idMateri: widget.idMateri,
        replyTo: _replyingTo?.id,
      );
      setState(() {
        _messages.add(newMsg);
        _replyingTo = null;
        _inputCtrl.clear();
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal kirim: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Toggle like ──────────────────────────────────
  Future<void> _toggleLike(int index) async {
    final msg = _messages[index];
    // Optimistic update
    setState(() {
      if (msg.isLikedByMe) {
        _messages[index].totalLikes--;
        _messages[index].isLikedByMe = false;
      } else {
        _messages[index].totalLikes++;
        _messages[index].isLikedByMe = true;
      }
    });
    try {
      final res = await _service.toggleLike(msg.id);
      setState(() {
        _messages[index].totalLikes   = res['total_likes'];
        _messages[index].isLikedByMe  = res['liked'];
      });
    } catch (_) {
      // Rollback jika gagal
      setState(() {
        _messages[index].totalLikes   = msg.totalLikes;
        _messages[index].isLikedByMe  = msg.isLikedByMe;
      });
    }
  }

  // ── Hapus pesan ──────────────────────────────────
  Future<void> _deleteMessage(int index) async {
    final msg = _messages[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Pesan',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Pesan ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteMessage(msg.id);
      setState(() => _messages.removeAt(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  void _setReply(DiskusiMessage msg) {
    setState(() => _replyingTo = msg);
    _focusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyingTo = null);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 30,
              offset: Offset(0, -8)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildStats(),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(child: _buildBody()),
          if (_replyingTo != null) _buildReplyPreview(),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5C6BC0), Color(0xFF7C4DFF)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.forum_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diskusi Kelas',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                    Text('Saling berbagi & berdiskusi bersama',
                        style: TextStyle(
                            fontSize: 11.5, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: _loadMessages,
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF757575), size: 18),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF757575), size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats bar ────────────────────────────────────
  Widget _buildStats() {
    final totalLikes =
        _messages.fold<int>(0, (sum, m) => sum + m.totalLikes);
    final uniqueSenders =
        _messages.map((m) => m.nis).toSet().length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Row(
        children: [
          _StatChip(
              icon: Icons.chat_bubble_rounded,
              value: '${_messages.length}',
              label: 'Pesan',
              color: const Color(0xFF5C6BC0)),
          const SizedBox(width: 6),
          Container(width: 1, height: 24, color: const Color(0xFFE0E0E0)),
          const SizedBox(width: 6),
          _StatChip(
              icon: Icons.favorite_rounded,
              value: '$totalLikes',
              label: 'Suka',
              color: const Color(0xFFE91E8C)),
          const SizedBox(width: 6),
          Container(width: 1, height: 24, color: const Color(0xFFE0E0E0)),
          const SizedBox(width: 6),
          _StatChip(
              icon: Icons.people_rounded,
              value: '$uniqueSenders',
              label: 'Aktif',
              color: const Color(0xFF43A047)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF43A047),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Live',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF43A047))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: loading / error / list ────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF5C6BC0)),
            SizedBox(height: 14),
            Text('Memuat diskusi...',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          ],
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 12),
            const Text('Gagal memuat diskusi',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text(_errorMsg!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6BC0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                  child: Text('💬', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada diskusi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            const Text('Jadilah yang pertama\nberdiskusi di sini!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.nis == widget.nis;
        return _ChatBubble(
          message: msg,
          isMe: isMe,
          onLike: () => _toggleLike(index),
          onReply: () => _setReply(msg),
          onDelete: isMe ? () => _deleteMessage(index) : null,
        );
      },
    );
  }

  // ── Reply preview ────────────────────────────────
  Widget _buildReplyPreview() {
    final msg = _replyingTo!;
    final preview = msg.pesan.length > 50
        ? '${msg.pesan.substring(0, 50)}...'
        : msg.pesan;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
            left: BorderSide(color: Color(0xFF5C6BC0), width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF5C6BC0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membalas ${msg.namaSiswa}',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5C6BC0)),
                ),
                Text(preview,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF757575)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  // ── Input area ───────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 10, 16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar siswa login
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF5C6BC0)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E8F0)),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A1A2E)),
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan atau diskusi...',
                  hintStyle: TextStyle(
                      fontSize: 13.5, color: Color(0xFFBDBDBD)),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSending
                      ? [Colors.grey.shade400, Colors.grey.shade400]
                      : const [Color(0xFF5C6BC0), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STAT CHIP
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CHAT BUBBLE
// ─────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final DiskusiMessage message;
  final bool isMe;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.onLike,
    required this.onReply,
    this.onDelete,
  });

  Color get _avatarColor => Color(message.avatarColorValue);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar orang lain
          if (!isMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _avatarColor,
                  _avatarColor.withOpacity(0.7)
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(message.initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Nama + kelas (orang lain)
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message.namaSiswa,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _avatarColor)),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _avatarColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(message.kelas,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _avatarColor)),
                        ),
                      ],
                    ),
                  ),

                // Bubble
                Container(
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF5C6BC0)
                        : const Color(0xFFF5F5FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 18 : 4),
                      topRight: Radius.circular(isMe ? 4 : 18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? const Color(0xFF5C6BC0).withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview reply di dalam bubble
                        if (message.replyTo != null &&
                            message.replySender != null) ...[
                          _buildReplyInBubble(isMe),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          message.pesan,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isMe
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Aksi bawah bubble
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DiskusiService.formatTime(message.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFBDBDBD))),
                    const SizedBox(width: 10),
                    // Like
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            message.isLikedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: message.isLikedByMe
                                ? const Color(0xFFE91E8C)
                                : const Color(0xFFBDBDBD),
                          ),
                          if (message.totalLikes > 0) ...[
                            const SizedBox(width: 3),
                            Text('${message.totalLikes}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: message.isLikedByMe
                                        ? const Color(0xFFE91E8C)
                                        : const Color(0xFFBDBDBD))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Balas
                    GestureDetector(
                      onTap: onReply,
                      child: const Row(
                        children: [
                          Icon(Icons.reply_rounded,
                              size: 14, color: Color(0xFFBDBDBD)),
                          SizedBox(width: 3),
                          Text('Balas',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFBDBDBD))),
                        ],
                      ),
                    ),
                    // Hapus (hanya pesan sendiri)
                    if (onDelete != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 14, color: Color(0xFFBDBDBD)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Avatar sendiri
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF5C6BC0)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(message.initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyInBubble(bool isMe) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.15)
            : const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
              color: isMe ? Colors.white : const Color(0xFF7C4DFF),
              width: 2.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replySender ?? '',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isMe
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF7C4DFF)),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyPesan ?? '',
            style: TextStyle(
                fontSize: 11.5,
                color: isMe
                    ? Colors.white.withOpacity(0.8)
                    : const Color(0xFF757575),
                fontStyle: FontStyle.italic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SHAPES (tidak berubah)
// ─────────────────────────────────────────────
class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _ShapesPainter())),
    );
  }
}

class _ShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shapes = [
      _ShapeData(
          color: const Color(0xFF5C6BC0).withOpacity(0.10),
          center: Offset(size.width * 0.90, size.height * 0.05),
          radius: size.width * 0.42),
      _ShapeData(
          color: const Color(0xFF43A047).withOpacity(0.07),
          center: Offset(size.width * 0.05, size.height * 0.45),
          radius: size.width * 0.35),
      _ShapeData(
          color: const Color(0xFFE53935).withOpacity(0.08),
          center: Offset(size.width * 0.70, size.height * 0.75),
          radius: size.width * 0.30),
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

class _ShapeData {
  final Color color;
  final Offset center;
  final double radius;
  const _ShapeData(
      {required this.color, required this.center, required this.radius});
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
          height: 22,
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
        Text(text,
            style: TextStyle(
                fontSize: isTablet ? 22 : 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                letterSpacing: 0.2)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HEADER BANNER (tidak berubah)
// ─────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  final bool isTablet;
  const _HeaderBanner({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 26 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D5AFE).withOpacity(0.38),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          ),
          Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08)),
              )),
          Positioned(
              right: 30,
              bottom: -40,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06)),
              )),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('📖 Pilih & Pelajari',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 12.5 : 11.5,
                              fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(height: isTablet ? 12 : 10),
                    Text('Halo! Mau belajar\napa hari ini? 🤔',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.w900,
                            height: 1.2)),
                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                        'Pilih jenis materi di bawah ini\nuntuk mulai belajar Informatika.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: isTablet ? 14 : 12.5,
                            height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('🚀',
                  style: TextStyle(fontSize: isTablet ? 64 : 54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
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
// MATERI CARD (tidak berubah dari versi asli)
// ─────────────────────────────────────────────
class _MateriCard extends StatefulWidget {
  final String emoji;
  final String label;
  final List<Color> labelGradient;
  final String title;
  final String description;
  final String buttonText;
  final Color bgColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final String image;
  final bool isTablet;
  final bool isLargeTablet;
  final VoidCallback onTap;

  const _MateriCard({
    required this.emoji,
    required this.label,
    required this.labelGradient,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.bgColor,
    required this.accentColor,
    required this.gradientColors,
    required this.image,
    required this.isTablet,
    required this.isLargeTablet,
    required this.onTap,
  });

  @override
  State<_MateriCard> createState() => _MateriCardState();
}

class _MateriCardState extends State<_MateriCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 130),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardPadding =
        widget.isLargeTablet ? 24.0 : (widget.isTablet ? 22.0 : 18.0);

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: widget.accentColor.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0, height: 6,
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: widget.gradientColors)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(cardPadding,
                      cardPadding + 4, cardPadding, cardPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: widget.labelGradient),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(widget.emoji,
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text(widget.label,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize:
                                              widget.isTablet ? 12 : 11,
                                          letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                            SizedBox(
                                height: widget.isTablet ? 14 : 12),
                            Text(widget.title,
                                style: TextStyle(
                                    fontSize: widget.isLargeTablet
                                        ? 22
                                        : (widget.isTablet ? 20 : 18),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A2E),
                                    height: 1.2)),
                            SizedBox(height: widget.isTablet ? 8 : 6),
                            Text(widget.description,
                                style: TextStyle(
                                    fontSize: widget.isTablet ? 14 : 13,
                                    color: Colors.grey.shade500,
                                    height: 1.5)),
                            SizedBox(
                                height: widget.isTablet ? 18 : 14),
                            GestureDetector(
                              onTap: widget.onTap,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: widget.isTablet ? 18 : 16,
                                    vertical: widget.isTablet ? 12 : 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: widget.gradientColors),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: widget.accentColor
                                            .withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.buttonText,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: widget.isTablet
                                                ? 14
                                                : 13)),
                                    const SizedBox(width: 6),
                                    const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: widget.isTablet ? 20 : 14),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: widget.isLargeTablet
                              ? 150
                              : (widget.isTablet ? 140 : 130),
                          decoration: BoxDecoration(
                              color: widget.bgColor,
                              borderRadius: BorderRadius.circular(16)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              widget.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(widget.emoji,
                                    style: const TextStyle(
                                        fontSize: 48)),
                              ),
                            ),
                          ),
                        ),
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
// TIPS BELAJAR (tidak berubah)
// ─────────────────────────────────────────────
class _TipsBelajarSection extends StatelessWidget {
  final bool isTablet;
  final bool isLargeTablet;
  const _TipsBelajarSection(
      {required this.isTablet, required this.isLargeTablet});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isTablet ? 14 : 10,
      mainAxisSpacing: isTablet ? 14 : 10,
      childAspectRatio:
          isLargeTablet ? 1.1 : (isTablet ? 1.0 : 0.78),
      children: [
        _TipsCard(
            emoji: '💡',
            title: 'Fokus',
            subtitle: 'Cari tempat yang tenang.',
            bgColor: const Color(0xFFFFF8E1),
            gradientColors: const [Color(0xFFFFA726), Color(0xFFFFCC02)],
            isTablet: isTablet),
        _TipsCard(
            emoji: '⏰',
            title: 'Waktu',
            subtitle: 'Atur jadwal belajar rutin.',
            bgColor: const Color(0xFFEDFBF3),
            gradientColors: const [Color(0xFF2E7D52), Color(0xFF43A047)],
            isTablet: isTablet),
        _TipsCard(
            emoji: '📝',
            title: 'Catat',
            subtitle: 'Buat rangkuman penting.',
            bgColor: const Color(0xFFF9EEFF),
            gradientColors: const [Color(0xFF8E24AA), Color(0xFFAB47BC)],
            isTablet: isTablet),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final List<Color> gradientColors;
  final bool isTablet;

  const _TipsCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.gradientColors,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: gradientColors[0].withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 5)),
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18)),
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isTablet ? 8 : 6),
              Container(
                width: isTablet ? 52 : 46,
                height: isTablet ? 52 : 46,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(emoji,
                        style: TextStyle(
                            fontSize: isTablet ? 24 : 20))),
              ),
              SizedBox(height: isTablet ? 10 : 8),
              Text(title,
                  style: TextStyle(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E)),
                  textAlign: TextAlign.center),
              SizedBox(height: isTablet ? 4 : 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      color: Colors.grey.shade500,
                      height: 1.3),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}