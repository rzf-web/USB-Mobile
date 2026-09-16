import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic rawData;

  ApiException({
    required this.message,
    this.statusCode,
    this.rawData,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Koneksi ke server timeout. Silakan periksa jaringan Anda.',
          statusCode: dioException.response?.statusCode,
          rawData: dioException.response?.data,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Waktu kirim request kehabisan waktu.',
          statusCode: dioException.response?.statusCode,
          rawData: dioException.response?.data,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Waktu menerima data dari server kehabisan waktu.',
          statusCode: dioException.response?.statusCode,
          rawData: dioException.response?.data,
        );
      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        final data = dioException.response?.data;
        String errorMessage = 'Terjadi kesalahan pada server ($statusCode).';

        if (data is Map) {
          if (data['message'] != null && data['message'].toString().isNotEmpty) {
            errorMessage = data['message'].toString();
          } else if (data['error'] != null && data['error'].toString().isNotEmpty) {
            errorMessage = data['error'].toString();
          } else if (data['msg'] != null && data['msg'].toString().isNotEmpty) {
            errorMessage = data['msg'].toString();
          }
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }

        return ApiException(
          message: errorMessage,
          statusCode: statusCode,
          rawData: data,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Permintaan dibatalkan.',
          statusCode: dioException.response?.statusCode,
          rawData: dioException.response?.data,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          statusCode: dioException.response?.statusCode,
          rawData: dioException.response?.data,
        );
      default:
        return ApiException(
          message: dioException.message ?? 'Terjadi kesalahan tidak dikenal.',
          statusCode: dioException.response?.statusCode,
          rawData: dioException.response?.data,
        );
    }
  }

  @override
  String toString() => message;
}

