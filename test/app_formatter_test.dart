import 'package:flutter_test/flutter_test.dart';
import 'package:usb_mobile/core/utils/app_formatter.dart';

void main() {
  setUpAll(() async {
    await AppFormatter.init();
  });

  group('AppFormatter Currency Tests', () {
    test('rupiah formatting', () {
      expect(AppFormatter.rupiah(150000), 'Rp 150.000');
      expect(AppFormatter.rupiah(0), 'Rp 0');
      expect(AppFormatter.rupiah(null), 'Rp 0');
      expect(AppFormatter.rupiah('25000'), 'Rp 25.000');
      expect(AppFormatter.rupiah(50000, withSymbol: false), '50.000');
    });

    test('number formatting', () {
      expect(AppFormatter.number(1250000), '1.250.000');
      expect(AppFormatter.number(40), '40');
      expect(AppFormatter.number(null), '0');
    });
  });

  group('AppFormatter Date & Time Tests', () {
    test('month names and numbers', () {
      expect(AppFormatter.monthName(1), 'Januari');
      expect(AppFormatter.monthName(9), 'September');
      expect(AppFormatter.monthName(12), 'Desember');
      expect(AppFormatter.monthNumber('September'), 9);
      expect(AppFormatter.monthNumber('januari'), 1);
    });

    test('date formatting', () {
      final dt = DateTime(2026, 9, 17);
      expect(AppFormatter.formatDate(dt), '17 September 2026');
      expect(AppFormatter.formatDate('2026-09-17'), '17 September 2026');
      expect(AppFormatter.formatDate(null), '-');
    });

    test('date range for month', () {
      final (start, end) = AppFormatter.dateRangeForMonth('2026', 'September');
      expect(start, '2026-09-01');
      expect(end, '2026-09-30');
    });

    test('year list', () {
      final years = AppFormatter.getYearList(pastYears: 1, futureYears: 1);
      final current = DateTime.now().year;
      expect(years.contains(current.toString()), true);
      expect(years.contains((current - 1).toString()), true);
      expect(years.contains((current + 1).toString()), true);
    });
  });
}

