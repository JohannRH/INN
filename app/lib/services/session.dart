import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", token);
    await prefs.setString("user_id", user['id'] ?? "");
    await prefs.setString("user_email", user['email'] ?? "");
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");
    final id = prefs.getString("user_id");
    final email = prefs.getString("user_email");

    if (token == null || id == null) return null;

    return {
      "access_token": token,
      "user": {
        "id": id,
        "email": email,
      }
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
