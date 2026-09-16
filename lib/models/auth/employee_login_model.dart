class EmployeeLoginResponse {
  final bool success;
  final String message;
  final String? employeeId;
  final String? employeeName;
  final String? role;
  final String? companyName;
  final dynamic rawData;

  EmployeeLoginResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeName,
    this.role,
    this.companyName,
    this.rawData,
  });

  factory EmployeeLoginResponse.fromJson(dynamic json, {String? defaultUsername}) {
    if (json is! Map<String, dynamic>) {
      return EmployeeLoginResponse(
        success: false,
        message: 'Format respon server tidak valid.',
      );
    }

    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final employeeId = data['idpegawai']?.toString() ??
        data['id_pegawai']?.toString() ??
        data['employeeId']?.toString() ??
        data['id']?.toString() ??
        json['idpegawai']?.toString() ??
        json['employeeId']?.toString();

    final employeeName = data['nama']?.toString() ??
        data['username']?.toString() ??
        data['employeeName']?.toString() ??
        json['nama']?.toString() ??
        json['username']?.toString() ??
        defaultUsername;

    final role = data['kerja']?.toString() ??
        data['pekerjaan']?.toString() ??
        data['role']?.toString() ??
        data['jabatan']?.toString() ??
        json['kerja']?.toString() ??
        json['role']?.toString();

    final companyName = data['nama_usaha']?.toString() ??
        data['perusahaan']?.toString() ??
        data['company']?.toString() ??
        data['namaUsaha']?.toString() ??
        json['nama_usaha']?.toString() ??
        json['perusahaan']?.toString();

    final isSuccess = json['status'] == true ||
        json['status'] == 200 ||
        json['success'] == true ||
        (employeeId != null && employeeId.isNotEmpty);

    final message = json['message']?.toString() ??
        json['msg']?.toString() ??
        (isSuccess ? 'Login pegawai berhasil' : 'Login pegawai gagal');

    return EmployeeLoginResponse(
      success: isSuccess,
      message: message,
      employeeId: employeeId,
      employeeName: employeeName,
      role: role,
      companyName: companyName,
      rawData: json,
    );
  }
}

