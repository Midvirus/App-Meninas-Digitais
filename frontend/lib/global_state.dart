class GlobalState {
  static String? userRole;
  static String? userName;
  static String? tutorName;
  static String? userEmail;

  static bool get isLoggedIn => userRole != null;

  static void clear() {
    userRole = null;
    userName = null;
    tutorName = null;
    userEmail = null;
  }
}
