import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manajer cache lokal berbasis SharedPreferences dengan dukungan
/// Time-To-Live (TTL), invalidasi pola prefix, dan penyimpanan JSON terstruktur.
class AppCacheManager {
  static SharedPreferences? _prefs;
  static const String _cacheKeyPrefix = 'app_cache_';

  /// Inisialisasi SharedPreferences untuk cache.
  static Future<void> init({SharedPreferences? prefs}) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  static SharedPreferences get _safePrefs {
    if (_prefs == null) {
      throw StateError(
        'AppCacheManager has not been initialized. Call AppCacheManager.init() first.',
      );
    }
    return _prefs!;
  }

  static String _formatKey(String key) => '$_cacheKeyPrefix$key';

  /// Menyimpan data JSON (Map, List, num, String, bool) ke dalam cache.
  /// [ttl] bersifat opsional. Jika diberikan, data akan kedaluwarsa setelah durasi tersebut.
  static Future<bool> setJson(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt =
          ttl != null ? now + ttl.inMilliseconds : null;

      final record = {
        'cached_at': now,
        'expires_at': expiresAt,
        'payload': data,
      };

      final encoded = jsonEncode(record);
      return await _safePrefs.setString(_formatKey(key), encoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â [AppCacheManager] Gagal menyimpan cache untuk key "$key": $e');
      }
      return false;
    }
  }

  /// Mengambil data JSON dari cache.
  /// Mengembalikan `null` jika tidak ada atau jika sudah kedaluwarsa (expired).
  static dynamic getJson(String key) {
    try {
      final raw = _safePrefs.getString(_formatKey(key));
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final expiresAt = decoded['expires_at'] as int?;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > expiresAt) {
          // Sudah kedaluwarsa, hapus dari storage secara asinkron
          remove(key);
          return null;
        }
      }

      return decoded['payload'];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â [AppCacheManager] Gagal membaca cache untuk key "$key": $e');
      }
      return null;
    }
  }

  /// Memeriksa apakah cache dengan [key] ada dan belum kedaluwarsa.
  static bool has(String key) {
    return getJson(key) != null;
  }

  /// Menghapus cache dengan [key] tertentu.
  static Future<bool> remove(String key) async {
    try {
      return await _safePrefs.remove(_formatKey(key));
    } catch (_) {
      return false;
    }
  }

  /// Menghapus semua cache yang diawali dengan [prefix].
  /// Sangat berguna untuk invalidasi data terkait (contoh: menghapus semua `jobs_available_`).
  static Future<int> removePrefix(String prefix) async {
    try {
      final targetPrefix = '$_cacheKeyPrefix$prefix';
      final keys = _safePrefs.getKeys().where((k) => k.startsWith(targetPrefix)).toList();
      int count = 0;
      for (final key in keys) {
        if (await _safePrefs.remove(key)) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Membersihkan seluruh data cache yang dikelola oleh AppCacheManager.
  /// Tidak akan menghapus sesi login pengguna (customer_id, employee_id, dll).
  static Future<int> clearAll() async {
    try {
      final keys = _safePrefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix)).toList();
      int count = 0;
      for (final key in keys) {
        if (await _safePrefs.remove(key)) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }
}

