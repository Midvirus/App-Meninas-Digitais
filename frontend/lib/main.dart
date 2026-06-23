import 'dart:convert';
import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'homePage.dart';
import 'pinboard.dart';
import 'challenges.dart';
import 'users.dart';
import 'feedback_page.dart';
import 'notifications_page.dart';
import 'project_data_page.dart';
import 'global_state.dart';
import 'api_client.dart';

void main() {
  runApp(const MyApp());
}

String _normalizeRole(String role) {
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/feedback': (context) => const FeedbackPage(title: 'Feedback'),
        '/notifications': (context) => const NotificationsPage(title: 'Notificações'),
        '/project-data': (context) => const ProjectDataPage(title: 'Dados do Projeto'),
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
    try {
      final response = await ApiClient.get('/api/perfil');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        GlobalState.userRole = _normalizeRole(data['role'] as String? ?? '');
        GlobalState.userName = data['nome'] as String?;
        GlobalState.userEmail = data['email'] as String?;
        final tutora = data['tutora'] as Map<String, dynamic>?;
        GlobalState.tutorName = tutora?['nome'] as String?;
      } else {
        await ApiClient.logout();
        GlobalState.clear();
      }
    } catch (_) {
      GlobalState.clear();
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const MyHomePage(title: 'Meninas Digitais');
  }
}
