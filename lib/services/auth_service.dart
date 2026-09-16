import '../constant/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../core/session/session_manager.dart';
import '../models/auth/customer_login_model.dart';
import '../models/auth/employee_login_model.dart';

class AuthService {
  final DioClient _client;

  AuthService({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<CustomerLoginResponse> loginCustomer({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.customerLogin,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final result = CustomerLoginResponse.fromJson(
      response.data,
      defaultEmail: email.trim(),
    );

    if (result.success && result.customerId != null) {
      await SessionManager.saveCustomerSession(
        customerId: result.customerId!,
        email: result.email,
        tenantDb: result.tenantDb,
      );
    }

    return result;
  }

  Future<EmployeeLoginResponse> loginEmployee({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.employeeLogin,
      data: {
        'username': username.trim(),
        'password': password,
      },
    );

    final result = EmployeeLoginResponse.fromJson(
      response.data,
      defaultUsername: username.trim(),
    );

    if (result.success && result.employeeId != null) {
      await SessionManager.saveEmployeeSession(
        employeeId: result.employeeId!,
        employeeName: result.employeeName ?? username.trim(),
        role: result.role,
        companyName: result.companyName,
      );
    }

    return result;
  }

  Future<bool> changeEmployeePassword({
    required String employeeId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      ApiEndpoints.changeEmployeePassword,
      data: {
        'employeeId': employeeId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );

    final data = response.data;
    if (data is Map) {
      return data['status'] == true || data['status'] == 200 || data['success'] == true;
    }
    return true;
  }

  Future<bool> pingServer() async {
    try {
      final response = await _client.get(ApiEndpoints.ping);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

