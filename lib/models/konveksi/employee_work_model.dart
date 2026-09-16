class WorkActionResult {
  final bool success;
  final String message;
  final dynamic data;

  WorkActionResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory WorkActionResult.fromJson(dynamic json, {String defaultSuccessMsg = 'Berhasil memproses pekerjaan'}) {
    if (json is! Map<String, dynamic>) {
      return WorkActionResult(
        success: true,
        message: defaultSuccessMsg,
        data: json,
      );
    }

    final isSuccess = json['status'] == true ||
        json['status'] == 200 ||
        json['success'] == true;

    final message = json['message']?.toString() ??
        json['msg']?.toString() ??
        (isSuccess ? defaultSuccessMsg : 'Gagal memproses pekerjaan');

    return WorkActionResult(
      success: isSuccess,
      message: message,
      data: json['data'] ?? json,
    );
  }
}

