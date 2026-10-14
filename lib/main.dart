import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constant/app_theme.dart';
import 'core/cache/app_cache_manager.dart';
import 'core/session/session_manager.dart';
import 'core/utils/app_formatter.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) {
      debugPrint("Warning: Gagal memuat file .env: $e");
    }
  }
  await SessionManager.init();
  await AppCacheManager.init();
  await AppFormatter.init();


  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String get _initialRoute {
    if (SessionManager.isCustomerLoggedIn && SessionManager.isEmployeeLoggedIn) {
      return AppRoutes.home;
    } else if (SessionManager.isCustomerLoggedIn) {
      return AppRoutes.loginPegawai;
    }
    return AppRoutes.splash;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB Mobile',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.lightTheme,
      initialRoute: _initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
