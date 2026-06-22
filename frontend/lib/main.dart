import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'homePage.dart';
import 'pinboard.dart';
import 'challenges.dart';
import 'users.dart';
import 'feedback_page.dart';
import 'notifications_page.dart';
import 'project_data_page.dart';
import 'api_client.dart';
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
    if (GlobalState.isLoggedIn) {
      try {
        final profile = await ApiClient.getProfile();
        final backendRole = profile['role'] as String? ?? '';
        GlobalState.userRole = ApiClient.mapRoleFromBackend(backendRole);
        GlobalState.userName = profile['nome'] as String?;
        final tutora = profile['tutora'];
        if (tutora != null && tutora is Map<String, dynamic>) {
          GlobalState.tutorName = tutora['nome'] as String?;
        }
      } catch (e) {
        // Token may be expired/invalid — clear session
        GlobalState.clear();
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
