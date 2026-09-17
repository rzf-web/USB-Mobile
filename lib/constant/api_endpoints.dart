import 'package:flutter/foundation.dart';
import '../core/session/session_manager.dart';

class ApiEndpoints {
  ApiEndpoints._();

  /// Default Base URL sesuai platform & dokumentasi Docker Local:
  /// - Android Emulator: http://10.0.2.2:8080
  /// - iOS Simulator: http://127.0.0.1:8080
  /// - Web / Windows Desktop: http://localhost:8080
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://127.0.0.1:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  /// Base URL aktif (menggunakan customBaseUrl jika diset oleh user, atau fallback ke default)
  static String get baseUrl {
    final custom = SessionManager.customBaseUrl;
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return defaultBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Endpoint sesuai Dokumentasi API Konveksi (Local Docker)
  static const String customerLogin = '/login.php';

  static const String employeeLogin = '/konveksi/login_employee.php';
  static const String changeEmployeePassword = '/konveksi/change_employee_password.php';
  static const String employeeJobs = '/konveksi/employee_jobs.php';
  static const String jobWage = '/konveksi/wage.php';
  static const String employeeEarnings = '/konveksi/employee_earnings.php';
  static const String employeeWork = '/konveksi/employee_work.php';

  /// Helper untuk mendapatkan URL lengkap foto produk dari backend Docker/API
  static String getImageUrl(String photoName) {
    final clean = photoName.trim();
    if (clean.isEmpty) return '';
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.encodeFull('$base/images/$clean');
  }
}
