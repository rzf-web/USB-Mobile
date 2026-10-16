import 'package:flutter/material.dart';
import '../core/transitions/smooth_page_transition.dart';
import '../screens/buat_produk_screen.dart';
import '../screens/detail_pekerjaan_screen.dart';
import '../screens/login_pegawai_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String loginPegawai = '/login-pegawai';
  static const String home = '/home';
  static const String berandaCutting = '/beranda-cutting';
  static const String buatProduk = '/buat-produk';
  static const String pekerjaanSaya = '/pekerjaan-saya';
  static const String detailPekerjaan = '/detail-pekerjaan';
  static const String laporan = '/laporan';
  static const String profil = '/profil';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        loginPegawai: (context) => const LoginPegawaiScreen(),
        home: (context) => const MainShellScreen(initialIndex: 0),
        berandaCutting: (context) =>
            const MainShellScreen(initialIndex: 0, forceCutting: true),
        buatProduk: (context) => const BuatProdukScreen(),
        pekerjaanSaya: (context) => const MainShellScreen(initialIndex: 1),
        detailPekerjaan: (context) => const DetailPekerjaanScreen(),
        laporan: (context) => const MainShellScreen(initialIndex: 2),
        profil: (context) => const MainShellScreen(initialIndex: 3),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder == null) {
      return SmoothPageRoute(
        builder: (context) => const MainShellScreen(initialIndex: 0),
        settings: settings,
      );
    }

    return SmoothPageRoute(
      builder: builder,
      settings: settings,
    );
  }
}
