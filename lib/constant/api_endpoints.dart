class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://rzfkomputer.com/desktop-api';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String customerLogin = '/login';
  static const String ping = '/ping';

  static const String employeeLogin = '/konveksi/login-employee';
  static const String changeEmployeePassword = '/konveksi/change-employee-password';
  static const String employeeJobs = '/konveksi/employee-jobs';
  static const String jobWage = '/konveksi/wage';
  static const String employeeEarnings = '/konveksi/employee-earnings';
  static const String employeeWork = '/konveksi/employee-work';
}

