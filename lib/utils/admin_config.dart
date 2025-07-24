// lib/utils/admin_config.dart
import 'package:shared_preferences/shared_preferences.dart';

class AdminConfig {
  // Default credentials (fallback)
  static const String defaultEmail = "admin@loker.com";
  static const String defaultPassword = "admin123";

  // Keys for SharedPreferences
  static const String _emailKey = 'admin_email';
  static const String _passwordKey = 'admin_password';
  static const String _isFirstTimeKey = 'is_first_time';

  // Get admin credentials from SharedPreferences
  static Future<Map<String, String>> getAdminCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if first time setup
    bool isFirstTime = prefs.getBool(_isFirstTimeKey) ?? true;

    if (isFirstTime) {
      // Set default credentials on first time
      await prefs.setString(_emailKey, defaultEmail);
      await prefs.setString(_passwordKey, defaultPassword);
      await prefs.setBool(_isFirstTimeKey, false);
    }

    String email = prefs.getString(_emailKey) ?? defaultEmail;
    String password = prefs.getString(_passwordKey) ?? defaultPassword;

    return {'email': email, 'password': password};
  }

  // Update admin credentials
  static Future<bool> updateAdminCredentials(
    String newEmail,
    String newPassword,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, newEmail);
      await prefs.setString(_passwordKey, newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Validate admin credentials
  static Future<bool> validateCredentials(String email, String password) async {
    Map<String, String> credentials = await getAdminCredentials();
    return credentials['email'] == email && credentials['password'] == password;
  }

  // Reset to default credentials
  static Future<void> resetToDefault() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, defaultEmail);
    await prefs.setString(_passwordKey, defaultPassword);
  }

  // Get current admin email
  static Future<String> getCurrentAdminEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? defaultEmail;
  }
}
