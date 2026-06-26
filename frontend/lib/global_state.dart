import 'package:shared_preferences/shared_preferences.dart';

class GlobalState {
  static String? userRole;
  static String? userName;
  static String? tutorName;
  static String? authToken;
  static String? userEmail;

  static bool get isLoggedIn => authToken != null;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken');
    userRole = prefs.getString('userRole');
    userName = prefs.getString('userName');
    tutorName = prefs.getString('tutorName');
    userEmail = prefs.getString('userEmail');
  }

  static Future<void> saveToken({
    required String token,
    required String role,
    String? name,
    required String email,
    String? tutor,
  }) async {
    authToken = token;
    userRole = role;
    userName = name;
    userEmail = email;
    tutorName = tutor;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userRole', role);
    if (name != null) {
      await prefs.setString('userName', name);
    } else {
      await prefs.remove('userName');
    }
    await prefs.setString('userEmail', email);
    if (tutor != null) {
      await prefs.setString('tutorName', tutor);
    } else {
      await prefs.remove('tutorName');
    }
  }

  static Future<void> clear() async {
    userRole = null;
    userName = null;
    tutorName = null;
    authToken = null;
    userEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
