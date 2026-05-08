import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'homePage.dart';
import 'pinboard.dart';
import 'challenges.dart';
import 'users.dart';
import 'supabase_client.dart';

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
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final session = supabase.auth.currentSession;
    setState(() {
      _isAuthenticated = session != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    //if (_isAuthenticated) {
      return const MyHomePage(title: 'Meninas Digitais');
    /*} else {
      return const LoginPage();
    }*/
  }
}
