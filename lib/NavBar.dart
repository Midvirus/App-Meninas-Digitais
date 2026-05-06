import 'package:flutter/material.dart';

class NavBar {
  static Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Usuário Meninas Digitais'),
            accountEmail: Text('usuario@meninasdigitais.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple),
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Entrar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.push_pin),
            title: const Text('Mural'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/pinboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Desafios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/challenges');
            },
          ),
        ],
      ),
    );
  }
}