import 'dart:convert';
import 'package:http/http.dart' as http;
import 'global_state.dart';

/// Central HTTP client for the Render backend.
/// Replaces the old Supabase client with REST API calls.
class ApiClient {
  static const String baseUrl = 'https://app-meninas-digitais-1.onrender.com';

  /// Standard headers including JWT auth token when available.
  static Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (GlobalState.authToken != null) {
      headers['Authorization'] = 'Bearer ${GlobalState.authToken}';
    }
    return headers;
  }

  static void _logRequest(String method, String path) {
    print('=== LOG DE DEBUG: REQUEST ===');
    print('Método: $method');
    print('URL: $baseUrl$path');
    final token = GlobalState.authToken;
    print('Token enviado: ${token != null ? 'Bearer $token' : 'NENHUM TOKEN (null)'}');
    print('=============================');
  }

  // ─── Generic HTTP Helpers ──────────────────────────────────────────────

  static Future<dynamic> get(String path) async {
    _logRequest('GET', path);
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: getAuthHeaders(),
    );
    _checkResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    _logRequest('POST', path);
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: getAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    _logRequest('PATCH', path);
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: getAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    _logRequest('PUT', path);
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: getAuthHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Future<void> delete(String path) async {
    _logRequest('DELETE', path);
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: getAuthHeaders(),
    );
    _checkResponse(response);
  }

  static Future<dynamic> _multipartRequest(
    String method,
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    _logRequest(method, path);
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
    
    if (GlobalState.authToken != null) {
      request.headers['Authorization'] = 'Bearer ${GlobalState.authToken}';
    }
    
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      request.files.addAll(files);
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _checkResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }


  static void _checkResponse(http.Response response) {
    print('=== LOG DE DEBUG: RESPONSE ===');
    print('Código HTTP retornado: ${response.statusCode}');
    print('Corpo da resposta: ${response.body}');
    print('==============================');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      // O token expirou ou acesso negado
      throw ApiException('Sessão expirada ou acesso negado. Faça login novamente. (HTTP ${response.statusCode})', response.statusCode);
    }

    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? body['error'] ?? body['erro'] ?? response.body;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Erro desconhecido na requisição (${response.statusCode})';
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

  // ─── Desafios Tutoranda ───────────────────────────────────────────────

  /// POST /api/tutoranda/desafios/{desafioId}/resposta
  static Future<Map<String, dynamic>> enviarResposta(
    dynamic desafioId, {
    String? textoResposta,
    String? linkExterno,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final queryParams = <String>[];
    if (textoResposta != null) queryParams.add('textoResposta=${Uri.encodeComponent(textoResposta)}');
    if (linkExterno != null) queryParams.add('linkExterno=${Uri.encodeComponent(linkExterno)}');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final path = '/api/tutoranda/desafios/$desafioId/resposta$queryString';
    
    List<http.MultipartFile>? files;
    if (filePath != null) {
      files = [await http.MultipartFile.fromPath('arquivo', filePath)];
    } else if (fileBytes != null && fileName != null) {
      files = [http.MultipartFile.fromBytes('arquivo', fileBytes, filename: fileName)];
    }
    
    final data = await _multipartRequest('POST', path, files: files);
    return data as Map<String, dynamic>? ?? {};
  }

  /// GET /api/tutoranda/desafios/minhas-respostas
  static Future<List<dynamic>> minhasRespostas() async {
    final data = await get('/api/tutoranda/desafios/minhas-respostas');
    return data as List<dynamic>? ?? [];
  }

  // ─── Observações Tutora ───────────────────────────────────────────────

  /// GET /api/tutora/observacoes/{tutorandaId}
  static Future<List<dynamic>> listarObservacoes(dynamic tutorandaId) async {
    final data = await get('/api/tutora/observacoes/$tutorandaId');
    return data as List<dynamic>? ?? [];
  }

  /// POST /api/tutora/observacoes/{tutorandaId}
  static Future<Map<String, dynamic>> registrarObservacao(dynamic tutorandaId, String conteudo) async {
    final data = await post('/api/tutora/observacoes/$tutorandaId', body: {'conteudo': conteudo});
    return data as Map<String, dynamic>? ?? {};
  }

  // ─── Posts ─────────────────────────────────────────────────────────────

  /// POST /api/posts
  static Future<Map<String, dynamic>> publicar(Map<String, dynamic> dados) async {
    final data = await post('/api/posts', body: dados);
    return data as Map<String, dynamic>? ?? {};
  }

  /// POST /api/posts/com-imagem
  static Future<Map<String, dynamic>> publicarComImagem(
    Map<String, dynamic> dados, {
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    List<http.MultipartFile>? files;
    if (filePath != null) {
      files = [await http.MultipartFile.fromPath('imagem', filePath)];
    } else if (fileBytes != null && fileName != null) {
      files = [http.MultipartFile.fromBytes('imagem', fileBytes, filename: fileName)];
    }
    
    final fields = {'dados': jsonEncode(dados)};
    
    final data = await _multipartRequest('POST', '/api/posts/com-imagem', fields: fields, files: files);
    return data as Map<String, dynamic>? ?? {};
  }

  // ─── Desafios Tutora (Additional) ─────────────────────────────────────

  /// PATCH /api/tutora/desafios/respostas/{respostaId}/feedback
  static Future<Map<String, dynamic>> feedbackResposta(dynamic respostaId, String feedback, bool aprovado) async {
    final data = await patch('/api/tutora/desafios/respostas/$respostaId/feedback', body: {
      'feedback': feedback,
      'aprovado': aprovado,
    });
    return data as Map<String, dynamic>? ?? {};
  }

  /// PATCH /api/tutora/desafios/respostas/{respostaId}/destaque
  static Future<Map<String, dynamic>> destaqueResposta(dynamic respostaId, String comentario) async {
    final data = await patch('/api/tutora/desafios/respostas/$respostaId/destaque', body: {
      'comentarioDestaque': comentario,
    });
    return data as Map<String, dynamic>? ?? {};
  }

  /// GET /api/tutora/desafios/{desafioId}/respostas
  static Future<List<dynamic>> respostasDoDesafio(dynamic desafioId) async {
    final data = await get('/api/tutora/desafios/$desafioId/respostas');
    return data as List<dynamic>? ?? [];
  }

  /// GET /api/tutora/desafios/{desafioId}/progresso
  static Future<Map<String, dynamic>> progressoDesafio(dynamic desafioId) async {
    final data = await get('/api/tutora/desafios/$desafioId/progresso');
    return data as Map<String, dynamic>? ?? {};
  }

  // ─── Perfil ────────────────────────────────────────────────────────────

  /// PATCH /api/perfil
  static Future<Map<String, dynamic>> atualizarPerfil({
    String? nome,
    String? escolaInstituicao,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final queryParams = <String>[];
    if (nome != null) queryParams.add('nome=${Uri.encodeComponent(nome)}');
    if (escolaInstituicao != null) queryParams.add('escolaInstituicao=${Uri.encodeComponent(escolaInstituicao)}');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final path = '/api/perfil$queryString';
    
    List<http.MultipartFile>? files;
    if (filePath != null) {
      files = [await http.MultipartFile.fromPath('foto', filePath)];
    } else if (fileBytes != null && fileName != null) {
      files = [http.MultipartFile.fromBytes('foto', fileBytes, filename: fileName)];
    }
    
    final data = await _multipartRequest('PATCH', path, files: files);
    return data as Map<String, dynamic>? ?? {};
  }

  // ─── Admin ──────────────────────────────────────────────────────────────

  /// PATCH /api/admin/usuarios/{tutorandaId}/autorizacao
  static Future<void> registrarAutorizacao(dynamic tutorandaId, bool autorizado) async {
    await patch('/api/admin/usuarios/$tutorandaId/autorizacao?autorizado=$autorizado');
  }

  /// GET /api/admin/indicadores
  static Future<Map<String, dynamic>> indicadores() async {
    final data = await get('/api/admin/indicadores');
    return data as Map<String, dynamic>? ?? {};
  }

  /// DELETE /api/admin/destaques/{respostaId}
  static Future<void> removerDestaque(dynamic respostaId) async {
    await delete('/api/admin/destaques/$respostaId');
  }

  /// DELETE /api/admin/desafios/{desafioId}
  static Future<void> removerDesafio(dynamic desafioId) async {
    await delete('/api/admin/desafios/$desafioId');
  }

  // ─── Mural ──────────────────────────────────────────────────────────────

  /// GET /api/mural
  static Future<List<dynamic>> mural() async {
    final data = await get('/api/mural');
    return data as List<dynamic>? ?? [];
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
