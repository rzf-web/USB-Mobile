import 'package:flutter/material.dart';

/// Transisi halaman fade yang sangat halus, cepat, dan tidak mengganggu user.
/// - Menghilangkan 100% animasi geser/slide agar tidak kaku & tidak memusingkan.
/// - Menghilangkan flicker/kedipan dengan mempertahankan halaman sebelumnya tetap solid saat transisi.
/// - Durasi cepat (180ms / 140ms reverse) dengan kurva easeOut agar terasa instan, responsif, dan mulus.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SmoothPageRoute({
    required this.builder,
    super.settings,
    Duration duration = const Duration(milliseconds: 180),
    Duration reverseDuration = const Duration(milliseconds: 140),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          opaque: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return buildSmoothFadeTransition(
              animation: animation,
              child: child,
            );
          },
        );
}

/// Global [PageTransitionsBuilder] untuk [ThemeData.pageTransitionsTheme].
/// Menjamin seluruh navigasi halaman di semua platform menggunakan fade lembut tanpa geser.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildSmoothFadeTransition(
      animation: animation,
      child: child,
    );
  }
}

/// Helper transisi fade murni:
/// - Hanya menggerakkan opacity halaman baru (0.0 -> 1.0).
/// - Halaman dasar di belakangnya tetap utuh sehingga tidak ada celah transparan/kedipan latar belakang.
Widget buildSmoothFadeTransition({
  required Animation<double> animation,
  required Widget child,
}) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ),
    child: child,
  );
}
