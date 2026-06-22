class GlobalState {
  static String? userRole;
  static String? userName;
  static String? tutorName;
  static String? authToken;
  static String? userEmail;

  static bool get isLoggedIn => authToken != null;

  static void clear() {
    userRole = null;
    userName = null;
    tutorName = null;
    authToken = null;
    userEmail = null;
  }
}
