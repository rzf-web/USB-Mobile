import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/session/session_manager.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String? _getEnv(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.maybeGet(key);
  }

  /// Default Base URL yang dimuat dari `.env`, disesuaikan dengan platform:
  /// - Override Umum: dotenv.env['API_BASE_URL']
  /// - Android Emulator: dotenv.env['API_BASE_URL_ANDROID'] (default: http://10.0.2.2:8080)
  /// - iOS Simulator: dotenv.env['API_BASE_URL_IOS'] (default: http://127.0.0.1:8080)
  /// - Web: dotenv.env['API_BASE_URL_WEB'] (default: http://localhost:8080)
  /// - Windows / macOS / Linux Desktop: dotenv.env['API_BASE_URL_DESKTOP'] (default: http://localhost:8080)
  static String get defaultBaseUrl {
    final overrideUrl = _getEnv('API_BASE_URL');
    if (overrideUrl != null && overrideUrl.trim().isNotEmpty) {
      return overrideUrl.trim();
    }

    if (kIsWeb) {
      return _getEnv('API_BASE_URL_WEB') ?? 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _getEnv('API_BASE_URL_ANDROID') ?? 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return _getEnv('API_BASE_URL_IOS') ?? 'http://127.0.0.1:8080';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return _getEnv('API_BASE_URL_DESKTOP') ??
            _getEnv('API_BASE_URL_WEB') ??
            'http://localhost:8080';
      default:
        return _getEnv('API_BASE_URL_DESKTOP') ??
            _getEnv('API_BASE_URL_WEB') ??
            'http://localhost:8080';
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

  static Duration get connectTimeout {
    final seconds = int.tryParse(_getEnv('CONNECT_TIMEOUT_SECONDS') ?? '');
    return Duration(seconds: seconds ?? 20);
  }

  static Duration get receiveTimeout {
    final seconds = int.tryParse(_getEnv('RECEIVE_TIMEOUT_SECONDS') ?? '');
    return Duration(seconds: seconds ?? 20);
  }

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
