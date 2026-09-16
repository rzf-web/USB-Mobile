import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../constant/api_endpoints.dart';
import '../session/session_manager.dart';
import 'api_exception.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio dio;

  DioClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!options.headers.containsKey('X-Customer-ID')) {
            try {
              final custId = SessionManager.customerId;
              if (custId != null && custId.isNotEmpty) {
                options.headers['X-Customer-ID'] = custId;
              }
            } catch (_) {}
          }

          if (kDebugMode) {
            debugPrint('--> [DIO] ${options.method} ${options.uri}');
            debugPrint('--> [DIO] Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('--> [DIO] Body: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('<-- [DIO] ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('<-- [DIO] Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            debugPrint('<-- [DIO ERROR] ${error.type} ${error.message}');
            debugPrint('<-- [DIO ERROR Response] ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

