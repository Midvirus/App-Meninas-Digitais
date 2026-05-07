import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'homePage.dart';
import 'pinboard.dart';
import 'challenges.dart';
import 'users.dart';

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
      home: const MyHomePage(title: 'Meninas Digitais'),
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
