import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/transitions/smooth_page_transition.dart';
import 'app_color.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
      textTheme: GoogleFonts.robotoTextTheme(),
      primaryTextTheme: GoogleFonts.robotoTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.primary,
        primary: AppColor.primary,
      ),
      scaffoldBackgroundColor: Colors.white,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SmoothPageTransitionsBuilder(),
        },
      ),
    );
  }
}

