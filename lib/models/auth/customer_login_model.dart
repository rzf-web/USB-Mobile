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

    Map<String, dynamic> data = {};
    if (json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    } else if (json['data'] is List && (json['data'] as List).isNotEmpty) {
      final first = (json['data'] as List).first;
      if (first is Map<String, dynamic>) {
        data = first;
      }
    } else {
      data = json;
    }

    String? customerId;
    if (json['data'] is int || json['data'] is String) {
      customerId = json['data'].toString();
    } else {
      customerId = data['customerId']?.toString() ??
          data['customer_id']?.toString() ??
          data['id_customer']?.toString() ??
          data['idCustomer']?.toString() ??
          data['id']?.toString() ??
          data['id_user']?.toString() ??
          data['idUser']?.toString() ??
          data['user_id']?.toString() ??
          data['id_member']?.toString() ??
          data['member_id']?.toString() ??
          data['cust_id']?.toString() ??
          data['kode_customer']?.toString() ??
          json['customerId']?.toString() ??
          json['customer_id']?.toString() ??
          json['id_customer']?.toString() ??
          json['id']?.toString();
    }

    final tenantDb = data['tenantDb']?.toString() ??
        data['tenant_db']?.toString() ??
        data['db_name']?.toString() ??
        data['dbname']?.toString() ??
        data['database']?.toString() ??
        data['db']?.toString() ??
        json['tenantDb']?.toString() ??
        json['tenant_db']?.toString() ??
        json['db_name']?.toString() ??
        json['database']?.toString();

    final email = data['email']?.toString() ??
        json['email']?.toString() ??
        defaultEmail;

    final hasStatusSuccess = json['status'] == true ||
        json['status'] == 200 ||
        json['success'] == true;

    final hasValidCustomerId = customerId != null &&
        customerId.isNotEmpty &&
        customerId.trim() != '0';

    final isSuccess = hasStatusSuccess && hasValidCustomerId;

    final message = json['message']?.toString() ??
        json['msg']?.toString() ??
        (isSuccess
            ? 'Login berhasil'
            : (hasStatusSuccess && !hasValidCustomerId
                ? 'Login berhasil tetapi ID Customer tidak ditemukan dalam respon server.'
                : 'Login gagal'));

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

