import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'homePage.dart';
import 'pinboard.dart';
import 'challenges.dart';
import 'users.dart';
import 'supabase_client.dart';
import 'global_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Este widget é a raiz da sua aplicação.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meninas Digitais',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MyHomePage(title: 'Meninas Digitais'),
        '/pinboard': (context) => const PinboardPage(title: 'Mural'),
        '/challenges': (context) => const ChallengesPage(title: 'Desafios'),
        '/users': (context) => const UsersPage(title: 'Usuários'),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      try {
        final profile = await supabase
            .from('profiles')
            .select('role, name, tutor')
            .eq('email', session.user.email ?? '')
            .maybeSingle();
        if (profile != null) {
          GlobalState.userRole = profile['role'] as String?;
          GlobalState.userName = profile['name'] as String?;
          GlobalState.tutorName = profile['tutor'] as String?;
        }
      } catch (e) {
        // ignore errors on startup
      }
    } else {
      GlobalState.clear();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // A página inicial é sempre a Home, independente do login.
    return const MyHomePage(title: 'Meninas Digitais');
  }
}
