// lib/screens/materi_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../config/app_config.dart';

class MateriDetailScreen extends StatefulWidget {
  final Map data;
  final String type;

  const MateriDetailScreen({
    super.key,
    required this.data,
    required this.type,
  });

  @override
  State<MateriDetailScreen> createState() => _MateriDetailScreenState();
}

class _MateriDetailScreenState extends State<MateriDetailScreen>
    with SingleTickerProviderStateMixin {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages  = 0;

  bool   _isDownloading    = false;
  bool   _downloadDone     = false;
  double _downloadProgress = 0;
  String _downloadedPath   = '';

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  static const List<Color> _gradientColors = [
    Color(0xFF3D5AFE),
    Color(0xFF7C4DFF),
  ];

  String get _pdfUrl {
    final fileName = (widget.data['nama_file'] ?? '').toString().trim();
    if (fileName.isEmpty) return '';
    final encoded = Uri.encodeComponent(fileName);
    // ✅ Pakai AppConfig.uploadsUrl — ganti IP cukup di app_config.dart
    return '${AppConfig.uploadsUrl}/materi/$encoded';
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _downloadFile() async {
    final fileName = (widget.data['nama_file'] ?? '').toString().trim();
    if (fileName.isEmpty || _pdfUrl.isEmpty) return;

    // Hapus blok Permission.storage karena bermasalah di Android 13+
    // Kita akan langsung menggunakan direktori aplikasi yang bebas izin.

    setState(() {
      _isDownloading   = true;
      _downloadProgress = 0;
      _downloadDone    = false;
    });

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        // Gunakan getExternalStorageDirectory yang AMAN dari Scoped Storage Android
        dir = await getExternalStorageDirectory(); 
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir!.path}/$fileName';
      final dio = Dio();

      await dio.download(
        _pdfUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading  = false;
          _downloadDone   = true;
          _downloadedPath = savePath;
        });
        _showDownloadDoneSheet(savePath, fileName);
      }
    } catch (e) {
      debugPrint("Error Download: $e"); // Membantu melihat error di konsol
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadDone  = false;
        });
        _showSnack('Gagal mengunduh. Pastikan server aktif & koneksi stabil.', isError: true);
      }
    }
  }

  void _openDownloaded() {
    if (_downloadedPath.isNotEmpty) OpenFilex.open(_downloadedPath);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showDownloadDoneSheet(String path, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16)),
            child:
                const Center(child: Text('✅', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 14),
          const Text('Berhasil Diunduh!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text(fileName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('Disimpan di: $path',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                      child: Text('Tutup',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280)))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _openDownloaded();
                },
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: _gradientColors),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF3D5AFE).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Buka File',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth       = MediaQuery.of(context).size.width;
    final isTablet          = screenWidth > 600;
    final horizontalPadding = isTablet ? 28.0 : 16.0;

    final judul     = (widget.data['judul']     ?? '-').toString();
    final deskripsi = (widget.data['deskripsi'] ?? '').toString();
    final bab       = (widget.data['bab']       ?? '').toString();
    final fileName  = (widget.data['nama_file'] ?? '').toString().trim();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(children: [
          const _BackgroundShapes(),
          SafeArea(
              child: Column(children: [
            // ── APP BAR ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 16, horizontalPadding, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Color(0xFF1A1A2E), size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(judul,
                      style: TextStyle(
                          fontSize: isTablet ? 19 : 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                if (widget.type == 'FILE' && fileName.isNotEmpty)
                  _DownloadButton(
                    isDownloading:    _isDownloading,
                    downloadDone:     _downloadDone,
                    downloadProgress: _downloadProgress,
                    onTap: _downloadDone ? _openDownloaded : _downloadFile,
                  ),
                if (_totalPages > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: _gradientColors),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF3D5AFE).withOpacity(0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Text('$_currentPage / $_totalPages',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 14),

            // ── INFO CARD ──
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color:
                            const Color(0xFF3D5AFE).withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child:
                            Text('📄', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        if (bab.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEEF0FF),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(bab,
                                style: const TextStyle(
                                    color: Color(0xFF3D5AFE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                          ),
                        if (deskripsi.isNotEmpty)
                          Text(deskripsi,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: isTablet ? 13 : 12,
                                  height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                      ])),
                  if (_isDownloading) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 36, height: 36,
                      child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(
                          value: _downloadProgress > 0
                              ? _downloadProgress
                              : null,
                          strokeWidth: 2.5,
                          color: const Color(0xFF3D5AFE),
                          backgroundColor: const Color(0xFFE0E7FF),
                        ),
                        if (_downloadProgress > 0)
                          Text(
                              '${(_downloadProgress * 100).toInt()}',
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3D5AFE))),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // ── PDF VIEWER ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF3D5AFE).withOpacity(0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 6)),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.type == 'FILE' && fileName.isNotEmpty
                        ? SfPdfViewer.network(
                            _pdfUrl,
                            controller: _pdfController,
                            onDocumentLoaded: (details) {
                              setState(() {
                                _totalPages =
                                    details.document.pages.count;
                                _currentPage = 1;
                              });
                            },
                            onPageChanged: (details) {
                              setState(() => _currentPage =
                                  details.newPageNumber);
                            },
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            enableDoubleTapZooming: true,
                            pageLayoutMode:
                                PdfPageLayoutMode.continuous,
                          )
                        : _buildEmptyState(fileName.isEmpty),
                  ),
                ),
              ),
            ),

            if (_totalPages > 1)
              _PageNavBar(
                currentPage: _currentPage,
                totalPages:  _totalPages,
                onPrev: () {
                  if (_currentPage > 1) _pdfController.previousPage();
                },
                onNext: () {
                  if (_currentPage < _totalPages) {
                    _pdfController.nextPage();
                  }
                },
                isTablet: isTablet,
              ),

            const SizedBox(height: 16),
          ])),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(bool isFileMissing) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(20)),
            child: const Center(
                child: Text('😔', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 20),
          Text(
            isFileMissing
                ? 'File tidak tersedia'
                : 'Tipe materi tidak dikenali',
            style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 15,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Hubungi admin untuk mengunggah\nfile materi ini.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Download Button ──
class _DownloadButton extends StatelessWidget {
  final bool isDownloading;
  final bool downloadDone;
  final double downloadProgress;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.isDownloading,
    required this.downloadDone,
    required this.downloadProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDownloading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: downloadDone
                  ? [const Color(0xFF2E7D52), const Color(0xFF43A047)]
                  : [const Color(0xFF3D5AFE), const Color(0xFF7C4DFF)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (downloadDone
                          ? const Color(0xFF43A047)
                          : const Color(0xFF3D5AFE))
                      .withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isDownloading)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                value: downloadProgress > 0 ? downloadProgress : null,
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(
              downloadDone
                  ? Icons.folder_open_rounded
                  : Icons.download_rounded,
              color: Colors.white, size: 18,
            ),
          const SizedBox(width: 6),
          Text(
            isDownloading
                ? downloadProgress > 0
                    ? '${(downloadProgress * 100).toInt()}%'
                    : 'Mengunduh...'
                : downloadDone
                    ? 'Buka File'
                    : 'Unduh',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }
}

// ── Page Nav Bar ──
class _PageNavBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool isTablet;

  const _PageNavBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = currentPage == 1;
    final isLast  = currentPage == totalPages;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 16, vertical: 10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBtn(
                  icon: Icons.chevron_left_rounded,
                  label: 'Sebelumnya',
                  enabled: !isFirst,
                  onTap: onPrev),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF3D5AFE),
                    Color(0xFF7C4DFF)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Hal. $currentPage / $totalPages',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  label: 'Berikutnya',
                  enabled: !isLast,
                  onTap: onNext,
                  isRight: true),
            ]),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isRight;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? const Color(0xFF3D5AFE) : Colors.grey.shade300;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFEEF0FF)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isRight
                ? [
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(icon, size: 18, color: color)
                  ]
                : [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600))
                  ]),
      ),
    );
  }
}

// ── Background Shapes ──
class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();
  @override
  Widget build(BuildContext context) => Positioned.fill(
      child: IgnorePointer(
          child: CustomPaint(painter: _ShapesPainter())));
}

class _ShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in [
      _BD(const Color(0xFF5C6BC0).withOpacity(0.09),
          Offset(size.width * 0.90, size.height * 0.05),
          size.width * 0.40),
      _BD(const Color(0xFF3D5AFE).withOpacity(0.07),
          Offset(size.width * 0.05, size.height * 0.50),
          size.width * 0.32),
      _BD(const Color(0xFFAB47BC).withOpacity(0.08),
          Offset(size.width * 0.75, size.height * 0.88),
          size.width * 0.28),
    ]) {
      canvas.drawCircle(
          b.center,
          b.radius,
          Paint()
            ..color = b.color
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 55));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BD {
  final Color color;
  final Offset center;
  final double radius;
  const _BD(this.color, this.center, this.radius);
}