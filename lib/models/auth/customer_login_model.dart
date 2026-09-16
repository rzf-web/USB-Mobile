class CustomerLoginResponse {
  final bool success;
  final String message;
  final String? customerId;
  final String? tenantDb;
  final String? email;
  final dynamic rawData;

  CustomerLoginResponse({
    required this.success,
    required this.message,
    this.customerId,
    this.tenantDb,
    this.email,
    this.rawData,
  });

  factory CustomerLoginResponse.fromJson(dynamic json, {String? defaultEmail}) {
    if (json is! Map<String, dynamic>) {
      return CustomerLoginResponse(
        success: false,
        message: 'Format respon server tidak valid.',
      );
    }

    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final customerId = data['customerId']?.toString() ??
        data['customer_id']?.toString() ??
        data['id_customer']?.toString() ??
        data['idCustomer']?.toString() ??
        data['id']?.toString() ??
        json['customerId']?.toString() ??
        json['customer_id']?.toString() ??
        json['id_customer']?.toString();

    final tenantDb = data['tenantDb']?.toString() ??
        data['db_name']?.toString() ??
        data['database']?.toString() ??
        json['tenantDb']?.toString() ??
        json['db_name']?.toString();

    final email = data['email']?.toString() ??
        json['email']?.toString() ??
        defaultEmail;

    final isSuccess = json['status'] == true ||
        json['status'] == 200 ||
        json['success'] == true ||
        (customerId != null && customerId.isNotEmpty);

    final message = json['message']?.toString() ??
        json['msg']?.toString() ??
        (isSuccess ? 'Login berhasil' : 'Login gagal');

    return CustomerLoginResponse(
      success: isSuccess,
      message: message,
      customerId: customerId,
      tenantDb: tenantDb,
      email: email,
      rawData: json,
    );
  }
}

