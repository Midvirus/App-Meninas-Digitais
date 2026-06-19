import 'package:flutter/material.dart';
import 'supabase_client.dart';
import 'global_state.dart';

class NavBar {
  static Drawer buildDrawer(BuildContext context) {
    final session = supabase.auth.currentSession;
    final isLoggedIn = session != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(isLoggedIn ? GlobalState.userName ?? GlobalState.userRole ?? 'Usuário' : 'Usuário'),
            accountEmail: Text(isLoggedIn ? session.user.email ?? '' : 'Não logado'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(isLoggedIn ? Icons.admin_panel_settings : Icons.person, color: Colors.deepPurple),
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
          if (!isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Entrar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
          ] else ...[
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
            if (GlobalState.userRole == 'Tutor')
              ListTile(
                leading: const Icon(Icons.rate_review),
                title: const Text('Feedback'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/feedback');
                },
              ),
            if (GlobalState.userRole != 'Tutoranda')
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Usuários'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/users');
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                await supabase.auth.signOut();
                GlobalState.clear();
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ],
      ),
    );
  }
}