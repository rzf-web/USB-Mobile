import 'package:flutter/material.dart';
import '../core/transitions/smooth_page_transition.dart';
import '../screens/beranda_screen.dart';
import '../screens/detail_pekerjaan_screen.dart';
import '../screens/laporan_screen.dart';
import '../screens/login_pegawai_screen.dart';
import '../screens/login_screen.dart';
import '../screens/pekerjaan_saya_screen.dart';
import '../screens/profil_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String loginPegawai = '/login-pegawai';
  static const String home = '/home';
  static const String pekerjaanSaya = '/pekerjaan-saya';
  static const String detailPekerjaan = '/detail-pekerjaan';
  static const String laporan = '/laporan';
  static const String profil = '/profil';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        loginPegawai: (context) => const LoginPegawaiScreen(),
        home: (context) => const BerandaScreen(),
        pekerjaanSaya: (context) => const PekerjaanSayaScreen(),
        detailPekerjaan: (context) => const DetailPekerjaanScreen(),
        laporan: (context) => const LaporanScreen(),
        profil: (context) => const ProfilScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder == null) {
      return SmoothPageRoute(
        builder: (context) => const BerandaScreen(),
        settings: settings,
      );
    }

    return SmoothPageRoute(
      builder: builder,
      settings: settings,
    );
  }
}

