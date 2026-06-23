class GlobalState {
  static String? userRole;
  static String? userName;
  static String? tutorName;

  static void clear() {
    userRole = null;
    userName = null;
    tutorName = null;
  }
}
