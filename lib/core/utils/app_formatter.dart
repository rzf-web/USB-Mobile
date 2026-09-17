import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Utility helper terpusat untuk formatting harga / mata uang (Rupiah)
/// dan format waktu, tanggal, serta bulan Indonesia menggunakan package [intl].
class AppFormatter {
  AppFormatter._();

  static bool _isInitialized = false;

  /// Inisialisasi locale 'id_ID' untuk intl. Panggil di `main()` sebelum `runApp()`.
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await initializeDateFormatting('id_ID', null);
      _isInitialized = true;
    } catch (_) {
      // Fallback jika gagal memuat locale data
    }
  }

  // ==========================================
  // 1. FORMATTER HARGA & MATA UANG (RUPIAH)
  // ==========================================

  /// Format angka ke Rupiah standar Indonesia.
  /// Contoh: `150000` -> `"Rp 150.000"`, `2500.5` -> `"Rp 2.501"` (atau dengan desimal).
  /// Mendukung input berupa [int], [double], [num], [String], atau [null].
  static String rupiah(
    dynamic amount, {
    bool withSymbol = true,
    int decimalDigits = 0,
  }) {
    if (amount == null) return withSymbol ? 'Rp 0' : '0';

    num value = 0;
    if (amount is num) {
      value = amount;
    } else if (amount is String) {
      value = num.tryParse(amount.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: withSymbol ? 'Rp ' : '',
      decimalDigits: decimalDigits,
    );

    return formatter.format(value).trim();
  }

  /// Format angka dengan pemisah ribuan titik (.) khas Indonesia tanpa simbol "Rp ".
  /// Contoh: `15000` -> `"15.000"`
  static String number(dynamic amount) {
    if (amount == null) return '0';

    num value = 0;
    if (amount is num) {
      value = amount;
    } else if (amount is String) {
      value = num.tryParse(amount.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
    }

    final formatter = NumberFormat.decimalPattern('id_ID');
    return formatter.format(value);
  }

  // ==========================================
  // 2. FORMATTER TANGGAL & WAKTU (INDONESIA)
  // ==========================================

  /// Daftar lengkap 12 nama bulan dalam Bahasa Indonesia.
  static const List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Mengubah nomor bulan (1-12) menjadi nama bulan Bahasa Indonesia.
  /// Contoh: `9` -> `"September"`
  static String monthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) return '';
    return months[monthNumber - 1];
  }

  /// Mengubah nama bulan menjadi nomor bulan (1-12).
  /// Contoh: `"September"` -> `9`. Jika tidak valid, mengembalikan bulan saat ini.
  static int monthNumber(String monthName) {
    final idx = months.indexWhere(
      (m) => m.toLowerCase() == monthName.trim().toLowerCase(),
    );
    return idx >= 0 ? idx + 1 : DateTime.now().month;
  }

  /// Format tanggal ke format teks Indonesia yang rapi.
  /// Contoh:
  /// - `formatDate('2026-09-17')` -> `"17 September 2026"`
  /// - `formatDate('2026-09-17', format: 'EEEE, dd MMM yyyy')` -> `"Kamis, 17 Sep 2026"`
  /// - `formatDate('2026-09-17', format: 'dd/MM/yyyy')` -> `"17/09/2026"`
  static String formatDate(
    dynamic date, {
    String format = 'dd MMMM yyyy',
  }) {
    final parsed = _parseDate(date);
    if (parsed == null) return date?.toString() ?? '-';

    try {
      return DateFormat(format, 'id_ID').format(parsed);
    } catch (_) {
      // Manual fallback jika locale data belum terinisialisasi
      return '${parsed.day} ${monthName(parsed.month)} ${parsed.year}';
    }
  }

  /// Format jam & menit dari DateTime atau string waktu.
  /// Contoh: `DateTime(2026, 9, 17, 14, 30)` -> `"14:30"` (atau `"14:30 WIB"` jika `withZone: true`)
  static String formatTime(dynamic date, {bool withZone = false}) {
    final parsed = _parseDate(date);
    if (parsed == null) return '-';

    final timeStr = DateFormat('HH:mm').format(parsed);
    return withZone ? '$timeStr WIB' : timeStr;
  }

  /// Format lengkap tanggal beserta jam.
  /// Contoh: `"17 September 2026, 14:30 WIB"`
  static String formatDateTime(dynamic date) {
    final parsed = _parseDate(date);
    if (parsed == null) return date?.toString() ?? '-';

    final d = formatDate(parsed, format: 'dd MMMM yyyy');
    final t = formatTime(parsed, withZone: true);
    return '$d, $t';
  }

  /// Menghasilkan rentang tanggal awal dan akhir (YYYY-MM-DD) untuk bulan & tahun tertentu.
  /// Berguna untuk parameter filter API `startDate` dan `endDate`.
  /// Contoh: `dateRangeForMonth("2026", "September")` -> `("2026-09-01", "2026-09-30")`
  static (String startDate, String endDate) dateRangeForMonth(
    String yearStr,
    String monthStr,
  ) {
    final year = int.tryParse(yearStr) ?? DateTime.now().year;
    final mIndex = monthNumber(monthStr);

    final start = DateTime(year, mIndex, 1);
    final end = DateTime(year, mIndex + 1, 0);

    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    return (startStr, endStr);
  }

  /// Menghasilkan daftar tahun untuk dropdown periode filter.
  /// Dibuat dinamis ke masa depan (minimal tahun 2050 atau 25 tahun ke depan dari tahun saat ini)
  static List<String> getYearList({
    int? pastYears,
    int? futureYears,
    int startYear = 2020,
    int? endYear,
    String? selectedYear,
  }) {
    final currentYear = DateTime.now().year;
    final minYear = pastYears != null ? currentYear - pastYears : startYear;
    final defaultEndYear = (currentYear + 25 > 2050) ? currentYear + 25 : 2050;
    final maxYear = futureYears != null
        ? currentYear + futureYears
        : (endYear ?? defaultEndYear);

    final years = <String>[];
    for (int y = minYear; y <= maxYear; y++) {
      years.add(y.toString());
    }

    if (selectedYear != null && !years.contains(selectedYear)) {
      years.add(selectedYear);
      years.sort();
    }

    return years;
  }



  // ==========================================
  // HELPER INTERNAL
  // ==========================================

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) {
      if (date.trim().isEmpty || date == '-') return null;
      return DateTime.tryParse(date.trim());
    }
    return null;
  }
}

