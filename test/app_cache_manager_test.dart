import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_mobile/core/cache/app_cache_manager.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheManager.init();
  });

  group('AppCacheManager Tests', () {
    test('setJson and getJson should store and retrieve data', () async {
      final sampleData = {
        'id': 'MP001',
        'name': 'Kemeja RZF',
        'qty': 40,
        'items': ['hitam', 'putih'],
      };

      final saved = await AppCacheManager.setJson('test_job', sampleData);
      expect(saved, isTrue);

      final retrieved = AppCacheManager.getJson('test_job');
      expect(retrieved, isNotNull);
      expect(retrieved['id'], 'MP001');
      expect(retrieved['qty'], 40);
      expect(retrieved['items'], contains('hitam'));
    });

    test('getJson should return null if key does not exist', () {
      final retrieved = AppCacheManager.getJson('non_existent_key');
      expect(retrieved, isNull);
    });

    test('TTL expiration should return null when expired', () async {
      final data = {'status': 'active'};
      // Simpan dengan TTL 50ms
      await AppCacheManager.setJson(
        'expiring_key',
        data,
        ttl: const Duration(milliseconds: 50),
      );

      expect(AppCacheManager.has('expiring_key'), isTrue);

      // Tunggu hingga kedaluwarsa
      await Future.delayed(const Duration(milliseconds: 70));

      expect(AppCacheManager.getJson('expiring_key'), isNull);
      expect(AppCacheManager.has('expiring_key'), isFalse);
    });

    test('removePrefix should invalidate matching keys only', () async {
      await AppCacheManager.setJson('jobs_available_sep', {'count': 10});
      await AppCacheManager.setJson('jobs_available_okt', {'count': 20});
      await AppCacheManager.setJson('earnings_sep', {'total': 500000});

      final removed = await AppCacheManager.removePrefix('jobs_available_');
      expect(removed, 2);

      expect(AppCacheManager.getJson('jobs_available_sep'), isNull);
      expect(AppCacheManager.getJson('jobs_available_okt'), isNull);
      expect(AppCacheManager.getJson('earnings_sep'), isNotNull);
    });

    test('clearAll should remove all cache entries', () async {
      await AppCacheManager.setJson('key_1', 'val1');
      await AppCacheManager.setJson('key_2', 'val2');

      final count = await AppCacheManager.clearAll();
      expect(count, 2);

      expect(AppCacheManager.getJson('key_1'), isNull);
      expect(AppCacheManager.getJson('key_2'), isNull);
    });
  });
}

