import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyCustomerId = 'customer_id';
  static const String _keyCustomerEmail = 'customer_email';
  static const String _keyTenantDb = 'tenant_db';
  static const String _keyEmployeeId = 'employee_id';
  static const String _keyEmployeeName = 'employee_name';
  static const String _keyEmployeeRole = 'employee_role';
  static const String _keyCompanyName = 'company_name';
  static const String _keyBaseUrl = 'custom_base_url';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _safePrefs {
    if (_prefs == null) {
      throw StateError('SessionManager has not been initialized. Call SessionManager.init() first.');
    }
    return _prefs!;
  }

  static Future<void> saveCustomerSession({
    required String customerId,
    String? email,
    String? tenantDb,
  }) async {
    final prefs = _safePrefs;
    await prefs.setString(_keyCustomerId, customerId);
    if (email != null) await prefs.setString(_keyCustomerEmail, email);
    if (tenantDb != null) await prefs.setString(_keyTenantDb, tenantDb);
  }

  static String? get customerId => _safePrefs.getString(_keyCustomerId);
  static String? get customerEmail => _safePrefs.getString(_keyCustomerEmail);
  static String? get tenantDb => _safePrefs.getString(_keyTenantDb);

  static bool get isCustomerLoggedIn {
    final id = customerId;
    return id != null && id.isNotEmpty;
  }

  static Future<void> saveEmployeeSession({
    required String employeeId,
    required String employeeName,
    String? role,
    String? companyName,
  }) async {
    final prefs = _safePrefs;
    await prefs.setString(_keyEmployeeId, employeeId);
    await prefs.setString(_keyEmployeeName, employeeName);
    if (role != null) await prefs.setString(_keyEmployeeRole, role);
    if (companyName != null) await prefs.setString(_keyCompanyName, companyName);
  }

  static String? get employeeId => _safePrefs.getString(_keyEmployeeId);
  static String? get employeeName => _safePrefs.getString(_keyEmployeeName);
  static String? get employeeRole => _safePrefs.getString(_keyEmployeeRole);
  static String? get companyName => _safePrefs.getString(_keyCompanyName);

  static bool get isEmployeeLoggedIn {
    final empId = employeeId;
    return empId != null && empId.isNotEmpty;
  }

  static Future<void> logoutEmployee() async {
    final prefs = _safePrefs;
    await prefs.remove(_keyEmployeeId);
    await prefs.remove(_keyEmployeeName);
    await prefs.remove(_keyEmployeeRole);
    await prefs.remove(_keyCompanyName);
  }

  static String? get customBaseUrl {
    try {
      return _safePrefs.getString(_keyBaseUrl);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    await _safePrefs.clear();
  }
}

