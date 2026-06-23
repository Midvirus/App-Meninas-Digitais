import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_state.dart';
import 'api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'TUTORANDA';

  static String _normalizeRole(String role) {
    switch (role.toUpperCase()) {
      case 'TUTORA':
        return 'Tutor';
      case 'TUTORANDA':
        return 'Tutoranda';
      case 'ADMIN':
        return 'Admin';
      default:
        return role;
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Preencha email e senha para continuar.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('https://app-meninas-digitais-1.onrender.com/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await ApiClient.saveToken(data['token'] as String);

        GlobalState.userRole = _normalizeRole(data['role'] as String? ?? '');
        GlobalState.userName = data['nome'] as String?;
        GlobalState.userEmail = email;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bem-vinda, ${GlobalState.userName ?? ''}! Login realizado com sucesso.')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showError('Email ou senha incorretos.');
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        _showError(body?['error'] as String? ?? 'Erro ao fazer login.');
      }
    } on SocketException {
      if (!mounted) return;
      _showError('Sem conexão com o servidor. Verifique sua internet.');
    } catch (error) {
      if (!mounted) return;
      _showError('Ocorreu um erro inesperado: $error');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final institution = _institutionController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showError('Preencha nome, email e senha para continuar.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('https://app-meninas-digitais-1.onrender.com/api/auth/cadastrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': name,
          'email': email,
          'senha': password,
          'escolaInstituicao': institution,
          'role': _selectedRole,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Faça o login agora.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() { _isLogin = true; });
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        _showError(body?['error'] as String? ?? 'Erro ao criar conta: ${response.body}');
      }
    } on SocketException {
      if (!mounted) return;
      _showError('Sem conexão com o servidor. Verifique sua internet.');
    } catch (error) {
      if (!mounted) return;
      _showError('Ocorreu um erro inesperado: $error');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Entrar' : 'Criar Conta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Image.asset(
              'images/logo-sem-fundo.png',
              height: 100,
            ),
            const SizedBox(height: 24),

            if (!_isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            if (!_isLogin) ...[
              TextField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Escola / Instituição',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Perfil',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'TUTORA', child: Text('Tutora')),
                  DropdownMenuItem(value: 'TUTORANDA', child: Text('Tutoranda')),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value != null) _selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            if (_isLogin) const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : (_isLogin ? _signIn : _signUp),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Entrar' : 'Cadastrar'),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _emailController.clear();
                  _passwordController.clear();
                  _nameController.clear();
                  _institutionController.clear();
                });
              },
              child: Text(_isLogin
                  ? 'Não possui uma conta? Cadastre-se'
                  : 'Já possui uma conta? Entrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _institutionController.dispose();
    super.dispose();
  }
}
