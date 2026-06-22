import 'package:flutter/material.dart';
import 'api_client.dart';
import 'global_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preencha email e senha para continuar.')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await ApiClient.login(email, password);

    if (!mounted) return;

    final token = response['token'] as String?;
    if (token != null) {
      final backendRole = response['role'] as String? ?? '';
      final role = ApiClient.mapRoleFromBackend(backendRole);
      final name = response['nome'] as String?;

      const allowedRoles = ['admin', 'Tutor', 'Tutoranda'];
      if (!allowedRoles.contains(role)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acesso negado. Usuário não possui permissão para acessar o aplicativo.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Store session in global state
      GlobalState.authToken = token;
      GlobalState.userEmail = email;
      GlobalState.userRole = role;
      GlobalState.userName = name;

      // Try to fetch tutor name from profile
      try {
        final profile = await ApiClient.getProfile();
        final tutora = profile['tutora'];
        if (tutora != null && tutora is Map<String, dynamic>) {
          GlobalState.tutorName = tutora['nome'] as String?;
        }
      } catch (_) {
        // Ignore errors fetching profile details
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bem-vinda, $role! Login realizado com sucesso.')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on ApiException catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: Colors.red),
    );
  } catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ocorreu um erro inesperado: $error'), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Image.asset(
                  'images/logo-sem-fundo.png',
                  height: 100,
                ),
                const SizedBox(height: 24),
              ],
            ),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
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
    super.dispose();
  }
}
