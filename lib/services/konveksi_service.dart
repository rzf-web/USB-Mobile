import '../constant/api_endpoints.dart';
import '../core/cache/app_cache_manager.dart';
import '../core/network/dio_client.dart';
import '../models/konveksi/employee_earnings_model.dart';
import '../models/konveksi/employee_job_model.dart';
import '../models/konveksi/employee_work_model.dart';

class KonveksiService {
  final DioClient _client;

  KonveksiService({DioClient? client}) : _client = client ?? DioClient.instance;

  // Key generator untuk cache
  static String _cacheKeyAvailableJobs(
          String idPegawai, String startDate, String endDate, String search) =>
      'jobs_available_${idPegawai}_${startDate}_${endDate}_$search';

  static String _cacheKeyMyJobs(
          String idPegawai, String kerja, String startDate, String endDate) =>
      'jobs_my_${idPegawai}_${kerja}_${startDate}_$endDate';


  static String _cacheKeyEarnings(
          String idPegawai, String? startDate, String? endDate, String? status) =>
      'earnings_${idPegawai}_${startDate ?? ""}_${endDate ?? ""}_${status ?? ""}';

  /// Mengambil daftar pekerjaan tersedia yang sudah tersimpan di cache lokal (instan 0 ms).
  List<EmployeeJobModel>? getCachedAvailableJobs({
    required String idPegawai,
    String search = '',
    String startDate = '',
    String endDate = '',
  }) {
    final key = _cacheKeyAvailableJobs(idPegawai, startDate, endDate, search);
    final raw = AppCacheManager.getJson(key);
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => EmployeeJobModel.fromJson(e))
          .toList();
    }
    return null;
  }

  /// Mengambil daftar pekerjaan pegawai yang tersimpan di cache lokal (instan 0 ms).
  List<EmployeeJobModel>? getCachedMyJobs({
    required String idPegawai,
    String kerja = '',
    String startDate = '',
    String endDate = '',
  }) {
    final key = _cacheKeyMyJobs(idPegawai, kerja, startDate, endDate);
    final raw = AppCacheManager.getJson(key);
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => EmployeeJobModel.fromJson(e))
          .toList();
    }
    return null;
  }

  /// Mengambil data laporan pendapatan pegawai dari cache lokal (instan 0 ms).
  EmployeeEarningsResponse? getCachedEmployeeEarnings({
    required String idPegawai,
    String? startDate,
    String? endDate,
    String? status,
  }) {
    final key = _cacheKeyEarnings(idPegawai, startDate, endDate, status);
    final raw = AppCacheManager.getJson(key);
    if (raw is Map<String, dynamic>) {
      try {
        return EmployeeEarningsResponse.fromJson(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<List<EmployeeJobModel>> getAvailableJobs({
    required String idPegawai,
    String search = '',
    String idProyek = '',
    String previous = 'all',
    String startDate = '',
    String endDate = '',
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeJobs,
      data: {
        'idpegawai': idPegawai,
        'search': search,
        'idproyek': idProyek,
        'previous': previous,
        if (startDate.isNotEmpty) 'startDate': startDate,
        if (endDate.isNotEmpty) 'endDate': endDate,
      },
    );

    final data = response.data;
    List<EmployeeJobModel> jobs = [];

    if (data is Map<String, dynamic>) {
      final rawList = data['data'] ?? data['items'] ?? data['list'];
      if (rawList is List) {
        jobs = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => EmployeeJobModel.fromJson(e))
            .toList();
        AppCacheManager.setJson(
          _cacheKeyAvailableJobs(idPegawai, startDate, endDate, search),
          rawList,
          ttl: const Duration(hours: 6),
        );
      }
    } else if (data is List) {
      jobs = data
          .whereType<Map<String, dynamic>>()
          .map((e) => EmployeeJobModel.fromJson(e))
          .toList();
      AppCacheManager.setJson(
        _cacheKeyAvailableJobs(idPegawai, startDate, endDate, search),
        data,
        ttl: const Duration(hours: 6),
      );
    }

    return jobs;
  }

  Future<List<EmployeeJobModel>> getMyJobs({
    required String idPegawai,
    String kerja = '',
    String startDate = '',
    String endDate = '',
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.employeeWork,
        data: {
          'action': 'my_jobs',
          'idpegawai': idPegawai,
          'kerja': kerja,
          'mode': 'project',
          if (startDate.isNotEmpty) 'startDate': startDate,
          if (endDate.isNotEmpty) 'endDate': endDate,
        },
      );

      final data = response.data;
      List<EmployeeJobModel> jobs = [];

      if (data is Map<String, dynamic>) {
        final rawList = data['data'] ?? data['items'] ?? data['list'];
        if (rawList is List) {
          jobs = rawList
              .whereType<Map<String, dynamic>>()
              .map((e) => EmployeeJobModel.fromJson(e))
              .toList();
          AppCacheManager.setJson(
            _cacheKeyMyJobs(idPegawai, kerja, startDate, endDate),
            rawList,
            ttl: const Duration(hours: 12),
          );
        }
      } else if (data is List) {
        jobs = data
            .whereType<Map<String, dynamic>>()
            .map((e) => EmployeeJobModel.fromJson(e))
            .toList();
        AppCacheManager.setJson(
          _cacheKeyMyJobs(idPegawai, kerja, startDate, endDate),
          data,
          ttl: const Duration(hours: 12),
        );
      }

      return jobs;
    } catch (_) {
      return [];
    }
  }


  Future<num> getJobWage({
    required String barcode,
    required String idItem,
    required String idPegawai,
    required String pekerjaan,
  }) async {
    final response = await _client.get(
      ApiEndpoints.jobWage,
      queryParameters: {
        'barcode': barcode,
        'idItem': idItem,
        'idPegawai': idPegawai,
        'pekerjaan': pekerjaan,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        final innerWage = inner['upah'] ?? inner['wage'] ?? inner['harga'];
        return num.tryParse(innerWage?.toString() ?? '0') ?? 0;
      }
      final outerWage = data['wage'] ?? data['upah'] ?? data['harga'] ?? inner;
      return num.tryParse(outerWage?.toString() ?? '0') ?? 0;
    } else if (data is num) {
      return data;
    }
    return 0;
  }

  Future<WorkActionResult> takeOrder({
    required String idProyek,
    required String idPegawai,
    required String nama,
    required String kerja,
    required List<Map<String, dynamic>> items,
    String mode = 'project',
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: {
        'action': 'take_order',
        'mode': mode,
        'idproyek': idProyek,
        'idpegawai': idPegawai,
        'nama': nama,
        'kerja': kerja,
        'items': items,
      },
    );

    final result = WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil mengambil pekerjaan',
    );

    if (result.success) {
      await AppCacheManager.removePrefix('jobs_available_');
      await AppCacheManager.removePrefix('jobs_my_');
    }

    return result;
  }

  Future<WorkActionResult> updateOrder({
    required String idProyek,
    required String idPegawai,
    required String kerja,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: {
        'action': 'update_order',
        'idproyek': idProyek,
        'idpegawai': idPegawai,
        'kerja': kerja,
        'items': items,
      },
    );

    final result = WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil memperbarui alokasi pekerjaan',
    );

    if (result.success) {
      await AppCacheManager.removePrefix('jobs_available_');
      await AppCacheManager.removePrefix('jobs_my_');
    }

    return result;
  }

  Future<WorkActionResult> deleteOrder({
    required String idProyek,
    required String idPegawai,
    required String kerja,
    String barcode = '',
  }) async {
    final Map<String, dynamic> payload = {
      'action': 'delete_order',
      'idproyek': idProyek,
      'idpegawai': idPegawai,
      'kerja': kerja,
    };

    if (barcode.isNotEmpty) {
      payload['barcode'] = barcode;
    }

    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: payload,
    );

    final result = WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil membatalkan pekerjaan',
    );

    if (result.success) {
      await AppCacheManager.removePrefix('jobs_available_');
      await AppCacheManager.removePrefix('jobs_my_');
    }

    return result;
  }

  Future<WorkActionResult> submitWork({
    required String idProyek,
    required String idPegawai,
    required String nama,
    required String kerja,
    required List<Map<String, dynamic>> items,
    String mode = 'project',
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: {
        'action': 'submit',
        'mode': mode,
        'idproyek': idProyek,
        'idpegawai': idPegawai,
        'nama': nama,
        'kerja': kerja,
        'items': items,
      },
    );

    final result = WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil menyetorkan hasil pekerjaan',
    );

    if (result.success) {
      await AppCacheManager.removePrefix('jobs_my_');
      await AppCacheManager.removePrefix('earnings_');
    }

    return result;
  }

  Future<WorkActionResult> updateSubmit({
    required String idGaji,
    required String idPegawai,
    required String kerja,
    required int jumlah,
    required num harga,
    String status = 'Belum Lunas',
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: {
        'action': 'update_submit',
        'idgaji': idGaji,
        'idpegawai': idPegawai,
        'kerja': kerja,
        'jumlah': jumlah,
        'harga': harga,
        'status': status,
      },
    );

    final result = WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil memperbarui data setoran',
    );

    if (result.success) {
      await AppCacheManager.removePrefix('jobs_my_');
      await AppCacheManager.removePrefix('earnings_');
    }

    return result;
  }

  Future<WorkActionResult> deleteSubmit({
    required String idGaji,
    required String idPegawai,
    required String kerja,
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: {
        'action': 'delete_submit',
        'idgaji': idGaji,
        'idpegawai': idPegawai,
        'kerja': kerja,
      },
    );

    final result = WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil menghapus setoran gaji',
    );

    if (result.success) {
      await AppCacheManager.removePrefix('jobs_my_');
      await AppCacheManager.removePrefix('earnings_');
    }

    return result;
  }

  Future<EmployeeEarningsResponse> getEmployeeEarnings({
    required String idPegawai,
    String? startDate,
    String? endDate,
    String? status,
    String? kategori = 'Produksi',
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final Map<String, dynamic> queryParams = {
      'idpegawai': idPegawai,
      'page': page,
      'limit': limit,
    };

    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (kategori != null && kategori.isNotEmpty) {
      queryParams['kategori'] = kategori;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _client.get(
      ApiEndpoints.employeeEarnings,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      AppCacheManager.setJson(
        _cacheKeyEarnings(idPegawai, startDate, endDate, status),
        response.data,
        ttl: const Duration(hours: 12),
      );
    }

    return EmployeeEarningsResponse.fromJson(response.data);
  }

}

