import 'package:shared_preferences/shared_preferences.dart';

class GlobalState {
  static String? userRole;
  static String? userName;
  static String? tutorName;
  static String? authToken;
  static String? userEmail;

  static bool get isLoggedIn => authToken != null;

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('token');
    userEmail = prefs.getString('email');
    userRole = prefs.getString('role');
    userName = prefs.getString('name');
    tutorName = prefs.getString('tutorName');
  }

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (authToken != null) await prefs.setString('token', authToken!);
    if (userEmail != null) await prefs.setString('email', userEmail!);
    if (userRole != null) await prefs.setString('role', userRole!);
    if (userName != null) await prefs.setString('name', userName!);
    if (tutorName != null) await prefs.setString('tutorName', tutorName!);
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
