import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'supabase_client.dart';
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
    // O Supabase agora lança exceções em vez de retornar .error
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (response.session != null) {
      // Check if user is admin
      try {
        final userProfile = await supabase
            .from('profiles')
            .select('role, name, tutor')
            .eq('email', email)
            .maybeSingle();

        const allowedRoles = ['admin', 'Tutor', 'Tutoranda'];
        if (userProfile == null || !allowedRoles.contains(userProfile['role'])) {
          await supabase.auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acesso negado. Usuário não possui permissão para acessar o aplicativo.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final role = userProfile['role'] as String;
        final name = userProfile['name'] as String?;
        final tutor = userProfile['tutor'] as String?;
        GlobalState.userRole = role;
        GlobalState.userName = name;
        GlobalState.tutorName = tutor;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bem-vinda, $role! Login realizado com sucesso.')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } on PostgrestException catch (error) {
        if (!mounted) return;
        await supabase.auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar perfil: ${error.message}'), backgroundColor: Colors.red),
        );
      }
    }
  } on AuthException catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: Colors.red),
    );
  } on PostgrestException catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao acessar dados: ${error.message}'), backgroundColor: Colors.red),
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
