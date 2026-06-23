import 'dart:async';
import 'package:dio/dio.dart';
import 'global_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central HTTP client for the backend.
class ApiClient {
  // Como o backend está hospedado no Render, usamos a URL abaixo:
  static const String baseUrl = 'https://app-meninas-digitais-1.onrender.com';
  // static const String baseUrl = 'http://192.168.1.160:8080';

  static const int _timeoutMilliseconds = 60000;

  /// Obtém o cliente Dio configurado com o token, conforme sugerido.
  static Future<Dio> getClient() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: _timeoutMilliseconds),
      receiveTimeout: const Duration(milliseconds: _timeoutMilliseconds),
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    return dio;
  }

  // ─── Generic HTTP Helpers ──────────────────────────────────────────────

  static Future<dynamic> get(String path) async {
    try {
      final dio = await getClient();
      final response = await dio.get(path);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  static Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final dio = await getClient();
      final response = await dio.post(path, data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  static Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final dio = await getClient();
      final response = await dio.patch(path, data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  static Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final dio = await getClient();
      final response = await dio.put(path, data: body);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  static Future<void> delete(String path) async {
    try {
      final dio = await getClient();
      await dio.delete(path);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  static void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw ApiException(
        'O servidor demorou muito para responder. Tente novamente.',
        408,
      );
    }
    
    int statusCode = e.response?.statusCode ?? 500;
    String message = 'Erro desconhecido ($statusCode)';
    
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? data.toString();
      } else {
        message = data.toString();
      }
    } else if (e.message != null && e.message!.isNotEmpty) {
      message = e.message!;
    }

    // O Spring Security retorna 403 com corpo vazio quando as credenciais estão erradas
    if (statusCode == 403 && (message.isEmpty || message == 'Erro desconhecido (403)')) {
      message = 'Email ou senha incorretos, ou acesso negado.';
    } else if (message.trim().isEmpty) {
      message = 'Erro no servidor ($statusCode).';
    }

    throw ApiException(message, statusCode);
  }

  // ─── Auth ──────────────────────────────────────────────────────────────

  /// Login via POST /api/auth/login
  /// Returns { "token": "...", "role": "...", "nome": "..." }
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    // Para o login, usamos um cliente sem token
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: _timeoutMilliseconds),
      receiveTimeout: const Duration(milliseconds: _timeoutMilliseconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    try {
      final response = await dio.post(
        '/api/auth/login',
        data: {'email': email, 'senha': password},
      );
      
      final responseData = response.data as Map<String, dynamic>;
      
      // Salva o token após o login bem-sucedido (como sugerido pela outra IA)
      if (responseData.containsKey('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        GlobalState.authToken = responseData['token'];
      }
      
      return responseData;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Fetch current user profile via GET /api/perfil
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await get('/api/perfil');
    return data as Map<String, dynamic>;
  }

  // ─── Users (Admin) ────────────────────────────────────────────────────

  static Future<List<dynamic>> listUsers() async {
    final data = await get('/api/admin/usuarios');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> userData,
  ) async {
    final data = await post('/api/admin/usuarios', body: userData);
    return data as Map<String, dynamic>;
  }

  static Future<void> deleteUser(dynamic id) async {
    await delete('/api/admin/usuarios/$id');
  }

  static Future<Map<String, dynamic>> changeUserRole(
    dynamic id,
    String role,
  ) async {
    final data = await patch('/api/admin/usuarios/$id/role?role=$role');
    return data as Map<String, dynamic>;
  }

  static Future<void> bindTutoranda(
    dynamic tutorandaId,
    dynamic tutoraId,
  ) async {
    await patch('/api/admin/usuarios/$tutorandaId/vincular/$tutoraId');
  }

  // ─── Posts ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> listPosts({String? category}) async {
    final path = category != null
        ? '/api/posts?categoria=$category'
        : '/api/posts';
    final data = await get(path);
    return data as List<dynamic>;
  }

  static Future<void> deletePost(dynamic id) async {
    await delete('/api/posts/$id');
  }

  static Future<Map<String, dynamic>> likePost(dynamic id) async {
    final data = await post('/api/posts/$id/curtir');
    return data as Map<String, dynamic>;
  }

  // ─── Challenges (Tutora) ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> createChallenge(
    Map<String, dynamic> challengeData,
  ) async {
    final data = await post('/api/tutora/desafios', body: challengeData);
    return data as Map<String, dynamic>;
  }

  // ─── Challenges (Tutoranda) ───────────────────────────────────────────

  static Future<List<dynamic>> listChallengesForTutoranda() async {
    final data = await get('/api/tutoranda/desafios');
    return data as List<dynamic>;
  }

  // ─── Role Mapping ─────────────────────────────────────────────────────

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

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
