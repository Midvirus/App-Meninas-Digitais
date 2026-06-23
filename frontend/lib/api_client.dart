import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'global_state.dart';

/// Central HTTP client for the Render backend.
/// Replaces the old Supabase client with REST API calls.
class ApiClient {
  static const String baseUrl = 'https://app-meninas-digitais-1.onrender.com';

  /// Timeout for HTTP requests (Render free tier can take 30-50s to cold start).
  static const Duration _timeout = Duration(seconds: 60);

  /// Standard headers including JWT auth token when available.
  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (GlobalState.authToken != null) {
      headers['Authorization'] = 'Bearer ${GlobalState.authToken}';
    }
    return headers;
  }

  // ─── Generic HTTP Helpers ──────────────────────────────────────────────

  static Future<dynamic> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ).timeout(_timeout);
      _checkResponse(response);
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou muito para responder. Ele pode estar iniciando (cold start). Tente novamente em alguns segundos.',
        408,
      );
    }
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      _checkResponse(response);
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou muito para responder. Ele pode estar iniciando (cold start). Tente novamente em alguns segundos.',
        408,
      );
    }
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      _checkResponse(response);
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou muito para responder. Ele pode estar iniciando (cold start). Tente novamente em alguns segundos.',
        408,
      );
    }
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      _checkResponse(response);
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou muito para responder. Ele pode estar iniciando (cold start). Tente novamente em alguns segundos.',
        408,
      );
    }
  }

  static Future<void> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ).timeout(_timeout);
      _checkResponse(response);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou muito para responder. Ele pode estar iniciando (cold start). Tente novamente em alguns segundos.',
        408,
      );
    }
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? body['error'] ?? response.body;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Erro ${response.statusCode}';
    }
    throw ApiException(message, response.statusCode);
  }

  // ─── Auth ──────────────────────────────────────────────────────────────

  /// Login via POST /api/auth/login
  /// Returns { "token": "...", "role": "...", "nome": "..." }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('/api/auth/login', body: {
      'email': email,
      'senha': password,
    });
    return data as Map<String, dynamic>;
  }

  /// Fetch current user profile via GET /api/perfil
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await get('/api/perfil');
    return data as Map<String, dynamic>;
  }

  // ─── Users (Admin) ────────────────────────────────────────────────────

  /// List all users via GET /api/admin/usuarios
  static Future<List<dynamic>> listUsers() async {
    final data = await get('/api/admin/usuarios');
    return data as List<dynamic>;
  }

  /// Create user via POST /api/admin/usuarios
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final data = await post('/api/admin/usuarios', body: userData);
    return data as Map<String, dynamic>;
  }

  /// Delete user via DELETE /api/admin/usuarios/{id}
  static Future<void> deleteUser(dynamic id) async {
    await delete('/api/admin/usuarios/$id');
  }

  /// Change user role via PATCH /api/admin/usuarios/{id}/role?role=ROLE
  static Future<Map<String, dynamic>> changeUserRole(dynamic id, String role) async {
    final data = await patch('/api/admin/usuarios/$id/role?role=$role');
    return data as Map<String, dynamic>;
  }

  /// Bind tutoranda to tutora via PATCH /api/admin/usuarios/{tutorandaId}/vincular/{tutoraId}
  static Future<void> bindTutoranda(dynamic tutorandaId, dynamic tutoraId) async {
    await patch('/api/admin/usuarios/$tutorandaId/vincular/$tutoraId');
  }

  // ─── Posts ─────────────────────────────────────────────────────────────

  /// List posts via GET /api/posts
  static Future<List<dynamic>> listPosts({String? category}) async {
    final path = category != null ? '/api/posts?categoria=$category' : '/api/posts';
    final data = await get(path);
    return data as List<dynamic>;
  }

  /// Delete post via DELETE /api/posts/{id}  (admin only)
  static Future<void> deletePost(dynamic id) async {
    await delete('/api/posts/$id');
  }

  /// Like post via POST /api/posts/{id}/curtir
  static Future<Map<String, dynamic>> likePost(dynamic id) async {
    final data = await post('/api/posts/$id/curtir');
    return data as Map<String, dynamic>;
  }

  // ─── Challenges (Tutora) ──────────────────────────────────────────────

  /// Create challenge via POST /api/tutora/desafios
  static Future<Map<String, dynamic>> createChallenge(Map<String, dynamic> challengeData) async {
    final data = await post('/api/tutora/desafios', body: challengeData);
    return data as Map<String, dynamic>;
  }

  // ─── Challenges (Tutoranda) ───────────────────────────────────────────

  /// List challenges for tutoranda via GET /api/tutoranda/desafios
  static Future<List<dynamic>> listChallengesForTutoranda() async {
    final data = await get('/api/tutoranda/desafios');
    return data as List<dynamic>;
  }

  // ─── Role Mapping ─────────────────────────────────────────────────────

  /// Maps backend role enum (ADMIN, TUTORA, TUTORANDA) to frontend display string.
  static String mapRoleFromBackend(String backendRole) {
    switch (backendRole.toUpperCase()) {
      case 'ADMIN':
        return 'admin';
      case 'TUTORA':
        return 'Tutor';
      case 'TUTORANDA':
        return 'Tutoranda';
      default:
        return backendRole;
    }
  }

  /// Maps frontend display role to backend enum value.
  static String mapRoleToBackend(String frontendRole) {
    switch (frontendRole.toLowerCase()) {
      case 'admin':
        return 'ADMIN';
      case 'tutor':
        return 'TUTORA';
      case 'tutoranda':
        return 'TUTORANDA';
      default:
        return frontendRole.toUpperCase();
    }
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
