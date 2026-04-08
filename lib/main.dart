import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'services/notifikasi_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotifikasiService.init();
  runApp(const InfoxApp());
}

class InfoxApp extends StatelessWidget {
  const InfoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Infox App',

      // ← Pasang navigatorKey agar bisa navigasi dari luar context
      navigatorKey: NotifikasiService.navigatorKey,

      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
      ),

      // ← Daftarkan route /notifikasi
      routes: {
        '/notifikasi': (context) => const NotifikasiScreen(),
      },

      home: const HomeScreen(),
    );
  }
}