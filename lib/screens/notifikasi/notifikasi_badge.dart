import 'package:flutter/material.dart';
import '../../services/notifikasi_service.dart';
import '../notifikasi/notifikasi_screen.dart';

// ── Pasang widget ini di AppBar atau header home screen ──
// Contoh penggunaan:
//   actions: [NotifikasiBadge()]
//
// Atau di dalam Row:
//   NotifikasiBadge()

class NotifikasiBadge extends StatelessWidget {
  const NotifikasiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotifikasiService.badgeCount,
      builder: (context, count, _) {
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: Color(0xFF1A1A2E), size: 22),
            ),
            if (count > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}