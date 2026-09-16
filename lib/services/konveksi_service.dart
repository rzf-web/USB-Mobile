import '../constant/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/konveksi/employee_earnings_model.dart';
import '../models/konveksi/employee_job_model.dart';
import '../models/konveksi/employee_work_model.dart';

class KonveksiService {
  final DioClient _client;

  KonveksiService({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<EmployeeJobModel>> getAvailableJobs({
    required String idPegawai,
    String search = '',
    String idProyek = '',
    String previous = 'all',
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeJobs,
      data: {
        'idpegawai': idPegawai,
        'search': search,
        'idproyek': idProyek,
        'previous': previous,
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
      }
    } else if (data is List) {
      jobs = data
          .whereType<Map<String, dynamic>>()
          .map((e) => EmployeeJobModel.fromJson(e))
          .toList();
    }

    return jobs;
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
      final wage = data['wage'] ?? data['upah'] ?? data['harga'] ?? data['data'];
      return num.tryParse(wage?.toString() ?? '0') ?? 0;
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

    return WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil mengambil pekerjaan',
    );
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

    return WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil memperbarui alokasi pekerjaan',
    );
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

    return WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil membatalkan pekerjaan',
    );
  }

  Future<WorkActionResult> submitWork({
    required String idProyek,
    required String idPegawai,
    required String nama,
    required String kerja,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeWork,
      data: {
        'action': 'submit',
        'idproyek': idProyek,
        'idpegawai': idPegawai,
        'nama': nama,
        'kerja': kerja,
        'items': items,
      },
    );

    return WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil menyetorkan hasil pekerjaan',
    );
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

    return WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil memperbarui data setoran',
    );
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

    return WorkActionResult.fromJson(
      response.data,
      defaultSuccessMsg: 'Berhasil menghapus setoran gaji',
    );
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

    return EmployeeEarningsResponse.fromJson(response.data);
  }
}

