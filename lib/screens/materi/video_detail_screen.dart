import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoDetailScreen extends StatefulWidget {
  final Map data;
  const VideoDetailScreen({super.key, required this.data});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with SingleTickerProviderStateMixin {
  YoutubePlayerController? _controller;
  String videoId = '';

  bool _isGDrive     = false;
  String _fileId     = '';
  WebViewController? _webViewController;
  bool _webLoading   = true;
  bool _isFullscreen = false;
  bool _isDescExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    final url = (widget.data['link_video'] ?? '').toString().trim();

    if (url.contains('drive.google.com')) {
      _isGDrive = true;
      _fileId   = _extractGdriveFileId(url);
      _initWebView();
    } else {
      videoId = _extractYoutubeId(url);
      if (videoId.isNotEmpty) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
              autoPlay: false, mute: false, enableCaption: true),
        );
      }
    }
  }

  String _extractGdriveFileId(String url) {
    final regex = RegExp(r'drive\.google\.com/file/d/([^/?\s]+)');
    final match = regex.firstMatch(url);
    return match != null ? match.group(1)! : '';
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      // User agent Chrome desktop — GDrive load lebih cepat
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 12; Mobile) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _webLoading = true),
        onPageFinished: (_) async {
          setState(() => _webLoading = false);

          // Auto-play saat page selesai load
          await _webViewController?.runJavaScript('''
            (function() {
              // Coba langsung play video
              var v = document.querySelector('video');
              if (v) { v.play(); return; }

              // Klik tengah layar untuk trigger GDrive player
              setTimeout(function() {
                var cx = window.innerWidth / 2;
                var cy = window.innerHeight / 2;
                var el = document.elementFromPoint(cx, cy);
                if (el) el.click();

                // Coba play video lagi setelah klik
                setTimeout(function() {
                  var v2 = document.querySelector('video');
                  if (v2) v2.play();
                }, 800);
              }, 500);
            })();
          ''');
        },
        onWebResourceError: (_) => setState(() => _webLoading = false),
      ))
      // Pakai /preview — paling cepat untuk streaming GDrive
      ..loadRequest(Uri.parse(
          'https://drive.google.com/file/d/$_fileId/preview'));
  }

  String _extractYoutubeId(String url) {
    if (url.isEmpty) return '';
    final regExp = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11}).*',
        caseSensitive: false);
    final match = regExp.firstMatch(url);
    return match != null ? match.group(1)! : '';
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fadeController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet     = screenWidth > 600;
    final judul        = (widget.data['judul']     ?? '-').toString();
    final deskripsi    = (widget.data['deskripsi'] ?? '').toString();
    final bab          = (widget.data['bab']        ?? '').toString();

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.black));

    if (_isGDrive) {
      return _buildGDriveScaffold(
          judul, deskripsi, bab, isTablet, screenHeight);
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller ??
            YoutubePlayerController(initialVideoId: ''),
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFFF0000),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFFF0000), handleColor: Color(0xFFFF0000),
          bufferedColor: Color(0x55FFFFFF), backgroundColor: Color(0x33FFFFFF),
        ),
      ),
      onEnterFullScreen: () =>
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light),
      onExitFullScreen: () => SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.black)),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Column(children: [
            Container(color: Colors.black,
              child: SafeArea(bottom: false, child: Column(children: [
                _buildTopBar(judul),
                videoId.isNotEmpty && _controller != null
                    ? player : _buildVideoUnavailable(isTablet),
              ]))),
            Expanded(child: _buildContentScroll(deskripsi, bab, isTablet,
                playButton: _controller != null
                    ? _buildYouTubePlayButton(isTablet) : null)),
          ]),
        ),
      ),
    );
  }

  Widget _buildGDriveScaffold(String judul, String deskripsi,
      String bab, bool isTablet, double screenHeight) {

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),
          if (_webLoading)
            const Center(child: CircularProgressIndicator(
                color: Color(0xFF1A73E8))),
          Positioned(top: 40, right: 16,
            child: GestureDetector(
              onTap: _toggleFullscreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fullscreen_exit_rounded,
                    color: Colors.white, size: 24)))),
        ]),
      );
    }

    final videoHeight = (screenHeight * 0.42).clamp(250.0, 380.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          Container(
            color: const Color(0xFF1565C0),
            child: SafeArea(bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context)),
                  Expanded(child: Text(judul,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ])))),

          SizedBox(
            height: videoHeight,
            child: Stack(children: [

              // WebView full size
              if (_webViewController != null)
                Positioned.fill(
                    child: WebViewWidget(controller: _webViewController!)),

              // Loading overlay
              if (_webLoading)
                Positioned.fill(
                  child: Container(color: Colors.black,
                    child: const Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1A73E8)),
                        SizedBox(height: 12),
                        Text('Memuat video...',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ])))),

              // Tombol fullscreen
              if (!_webLoading)
                Positioned(bottom: 10, right: 10,
                  child: GestureDetector(
                    onTap: _toggleFullscreen,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.black54,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 22)))),
            ])),

          Expanded(child: _buildContentScroll(
              deskripsi, bab, isTablet, isGDrive: true)),
        ]),
      ),
    );
  }

  Widget _buildTopBar(String judul) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 22),
        onPressed: () => Navigator.pop(context)),
      Expanded(child: Text(judul,
        style: const TextStyle(color: Colors.white,
            fontSize: 15, fontWeight: FontWeight.w600),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]));

  Widget _buildContentScroll(String deskripsi, String bab, bool isTablet,
      {Widget? playButton, bool isGDrive = false}) {
    final judul = (widget.data['judul'] ?? '-').toString();
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              isTablet ? 20 : 16, 14, isTablet ? 20 : 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            if (bab.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGDrive
                      ? const Color(0xFFE8F0FE) : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(5)),
                child: Text(bab, style: TextStyle(
                  color: isGDrive
                      ? const Color(0xFF1565C0) : const Color(0xFFCC0000),
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 0.3))),
            Text(judul, style: TextStyle(
                fontSize: isTablet ? 20 : 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F0F0F), height: 1.3)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  setState(() => _isDescExpanded = !_isDescExpanded),
              child: Row(children: [
                Text(
                  isGDrive
                      ? 'Video Google Drive  •  Informatika SMP'
                      : 'Video Pembelajaran  •  Informatika SMP',
                  style: TextStyle(color: const Color(0xFF606060),
                      fontSize: isTablet ? 13 : 12)),
                const SizedBox(width: 4),
                Icon(_isDescExpanded
                    ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF0F0F0F), size: 18),
              ])),
          ])),
        _buildDivider(),
        if (deskripsi.isNotEmpty) _buildDescription(deskripsi, isTablet),
        if (playButton != null) ...[
          _buildDivider(),
          Padding(
            padding: EdgeInsets.fromLTRB(
                isTablet ? 20 : 16, 16, isTablet ? 20 : 16, 0),
            child: playButton),
        ],
        const SizedBox(height: 32),
      ]));
  }

  Widget _buildDivider() =>
      Container(height: 1, color: const Color(0xFFE5E5E5));

  Widget _buildDescription(String deskripsi, bool isTablet) {
    return GestureDetector(
      onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16, vertical: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            const Text('Deskripsi', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: Color(0xFF0F0F0F))),
            const Spacer(),
            Icon(_isDescExpanded
                ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF606060), size: 20),
          ]),
          AnimatedCrossFade(
            firstChild: Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(deskripsi,
                style: const TextStyle(fontSize: 13,
                    color: Color(0xFF606060), height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(height: 1, color: const Color(0xFFE0E0E0)),
                  const SizedBox(height: 10),
                  Text(deskripsi, style: const TextStyle(fontSize: 14,
                      color: Color(0xFF0F0F0F), height: 1.6)),
                ]),
            crossFadeState: _isDescExpanded
                ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250)),
        ])));
  }

  Widget _buildYouTubePlayButton(bool isTablet) => GestureDetector(
    onTap: () => _controller?.play(),
    child: Container(
      width: double.infinity, height: isTablet ? 52 : 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(
            color: const Color(0xFFFF0000).withOpacity(0.30),
            blurRadius: 14, offset: const Offset(0, 5))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text('Putar Video', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 15 : 14, letterSpacing: 0.3)),
      ])));

  Widget _buildVideoUnavailable(bool isTablet) => Container(
    height: isTablet ? 260 : 210, color: const Color(0xFF1A1A1A),
    alignment: Alignment.center,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.videocam_off_rounded,
          color: Colors.white.withOpacity(0.35), size: 52),
      const SizedBox(height: 12),
      Text('Video tidak tersedia',
          style: TextStyle(
              color: Colors.white.withOpacity(0.5), fontSize: 14)),
    ]));
}